///|
/// Finite proof kernel for Belnap-Dunn FDE (B_4), with designated values {Tv, Bv}.
/// Formula evaluation is truth-functional; proof rules are checked against the
/// designation-preserving consequence relation rather than classical explosion.

///|
/// Four-valued propositional formula. Connective children are arrays so the recursive
/// representation is heap-safe; evaluators reject malformed arities instead of guessing.
#derive(Debug, Eq)
pub(all) enum B4Formula {
  Atom(Int32)
  Value(FourVal)
  Not(Array[B4Formula])
  And(Array[B4Formula])
  Or(Array[B4Formula])
  Imp(Array[B4Formula])
}

///|
fn b4_has_positive_evidence(value : FourVal) -> Bool {
  value.is_designated()
}

///|
fn b4_has_negative_evidence(value : FourVal) -> Bool {
  value == Fv || value == Bv
}

///|
fn b4_from_evidence(positive : Bool, negative : Bool) -> FourVal {
  match (positive, negative) {
    (false, false) => Nv
    (false, true) => Fv
    (true, false) => Tv
    (true, true) => Bv
  }
}

///|
/// A truth-functional, MP-valid conditional. Its positive evidence is `not A+ or B+`
/// and its negative evidence is `A+ and B-`; it agrees with classical material
/// implication on {Fv,Tv}. Deliberately, this is NOT the FDE material formula
/// `neg(A) lor B`, which fails MP on gluts (Bv -> Fv is designated while Fv is not).
/// The chosen conditional makes A and (A -> B) designated only when B is designated.
pub fn FourVal::implies(a : FourVal, b : FourVal) -> FourVal {
  let positive = !b4_has_positive_evidence(a) || b4_has_positive_evidence(b)
  let negative = b4_has_positive_evidence(a) && b4_has_negative_evidence(b)
  b4_from_evidence(positive, negative)
}

///|
fn b4_evaluate_binary(
  children : Array[B4Formula],
  valuation : Array[FourVal],
  operator : (FourVal, FourVal) -> FourVal,
) -> FourVal? {
  if children.length() != 2 {
    return None
  }
  match
    (b4_evaluate(children[0], valuation), b4_evaluate(children[1], valuation)) {
    (Some(a), Some(b)) => Some(operator(a, b))
    _ => None
  }
}

///|
/// Evaluate a formula under an atom-indexed B_4 valuation. `None` signals an
/// out-of-range atom or a malformed connective node.
pub fn b4_evaluate(formula : B4Formula, valuation : Array[FourVal]) -> FourVal? {
  match formula {
    Atom(id) =>
      if id >= 0 && id < valuation.length() {
        Some(valuation[id])
      } else {
        None
      }
    Value(value) => Some(value)
    Not(children) =>
      if children.length() != 1 {
        None
      } else {
        match b4_evaluate(children[0], valuation) {
          Some(value) => Some(FourVal::neg(value))
          None => None
        }
      }
    And(children) =>
      b4_evaluate_binary(children, valuation, (a, b) => FourVal::land(a, b))
    Or(children) =>
      b4_evaluate_binary(children, valuation, (a, b) => FourVal::lor(a, b))
    Imp(children) =>
      b4_evaluate_binary(children, valuation, (a, b) => FourVal::implies(a, b))
  }
}

///|
/// Simultaneous atom substitution sigma : B4Atom -> B4Formula. If a caller supplies
/// duplicate atom IDs, the first binding wins; canonical substitutions should be unique.
#derive(Debug, Eq)
pub(all) struct B4FormulaSubstitution {
  bindings : Array[(Int32, B4Formula)]
}

///|
pub fn B4FormulaSubstitution::new(
  bindings : Array[(Int32, B4Formula)],
) -> B4FormulaSubstitution {
  { bindings, }
}

///|
fn B4FormulaSubstitution::lookup(
  self : B4FormulaSubstitution,
  atom : Int32,
) -> B4Formula? {
  for binding in self.bindings {
    if binding.0 == atom {
      return Some(binding.1)
    }
  }
  None
}

///|
/// Apply sigma once at each source atom (substitution is simultaneous, not recursively
/// applied inside the replacement formula).
pub fn B4FormulaSubstitution::apply(
  self : B4FormulaSubstitution,
  formula : B4Formula,
) -> B4Formula {
  match formula {
    Atom(id) =>
      match self.lookup(id) {
        Some(replacement) => replacement
        None => Atom(id)
      }
    Value(value) => Value(value)
    Not(children) => Not(children.map(child => self.apply(child)))
    And(children) => And(children.map(child => self.apply(child)))
    Or(children) => Or(children.map(child => self.apply(child)))
    Imp(children) => Imp(children.map(child => self.apply(child)))
  }
}

///|
fn b4_substituted_valuation(
  substitution : B4FormulaSubstitution,
  valuation : Array[FourVal],
) -> Array[FourVal]? {
  let out : Array[FourVal] = Array(capacity=valuation.length())
  for atom in 0..<valuation.length() {
    match b4_evaluate(substitution.apply(Atom(atom)), valuation) {
      Some(value) => out.push(value)
      None => return None
    }
  }
  Some(out)
}

///|
/// Semantic substitution law: eval(sigma(F),v) == eval(F,v_sigma).
pub fn b4_substitution_law_holds(
  formula : B4Formula,
  substitution : B4FormulaSubstitution,
  valuation : Array[FourVal],
) -> Bool {
  match
    (
      b4_evaluate(substitution.apply(formula), valuation),
      b4_substituted_valuation(substitution, valuation),
    ) {
    (Some(lhs), Some(v_sigma)) =>
      match b4_evaluate(formula, v_sigma) {
        Some(rhs) => lhs == rhs
        None => false
      }
    _ => false
  }
}

///|
/// A sequent premise can be marked quarantined. Quarantined assumptions are not
/// conditions in designation checking and cannot be selected as cut/MP inputs.
#derive(Debug, Eq)
pub(all) struct B4Premise {
  formula : B4Formula
  quarantined : Bool
}

///|
/// Gentzen-style sequent Gamma |- A. The conclusion can itself be quarantined, in
/// which case it remains inspectable but cannot be used as a later cut formula.
#derive(Debug, Eq)
pub(all) struct B4Sequent {
  assumptions : Array[B4Premise]
  conclusion : B4Premise
}

///|
/// Result of attempting a Gentzen inference. An absent result means invalid shape or
/// a blocked quarantined premise; the flags distinguish those cases.
#derive(Debug, Eq)
pub(all) struct B4RuleApplication {
  input_valid : Bool
  applied : Bool
  blocked_by_quarantine : Bool
  result : B4Sequent?
}

///|
pub fn b4_identity(formula : B4Formula) -> B4Sequent {
  {
    assumptions: [{ formula, quarantined: false, }],
    conclusion: { formula, quarantined: false, },
  }
}

///|
/// Evaluate one sequent at one valuation under FDE designation semantics. Quarantined
/// assumptions are deliberately omitted from the active antecedent.
pub fn b4_sequent_preserves_designation(
  sequent : B4Sequent,
  valuation : Array[FourVal],
) -> Bool {
  let mut antecedent_designated = true
  for premise in sequent.assumptions {
    if !premise.quarantined {
      match b4_evaluate(premise.formula, valuation) {
        Some(value) =>
          if !value.is_designated() {
            antecedent_designated = false
          }
        None => return false
      }
    }
  }
  match b4_evaluate(sequent.conclusion.formula, valuation) {
    Some(value) => !antecedent_designated || value.is_designated()
    None => false
  }
}

///|
/// A concrete FDE countermodel to explosion: p and not-p are both designated at Bv,
/// while an unrelated conclusion is undesignated at Nv. This checks the consequence
/// relation itself, not merely the existence of both kinds of truth value.
pub fn b4_non_explosion_counterexample_exists() -> Bool {
  let p = Atom(0)
  let unrelated = Atom(1)
  let valuation = [Bv, Nv]
  let contradiction_sequent : B4Sequent = {
    assumptions: [
      { formula: p, quarantined: false, },
      { formula: Not([p]), quarantined: false, },
    ],
    conclusion: { formula: unrelated, quarantined: false, },
  }
  match
    (
      b4_evaluate(p, valuation),
      b4_evaluate(Not([p]), valuation),
      b4_evaluate(unrelated, valuation),
    ) {
    (Some(p_value), Some(not_p_value), Some(q_value)) =>
      p_value.is_designated() &&
      not_p_value.is_designated() &&
      !q_value.is_designated() &&
      !b4_sequent_preserves_designation(contradiction_sequent, valuation)
    _ => false
  }
}

///|
/// Gentzen cut: from Gamma |- A and Delta,A |- C derive Gamma,Delta |- C.
/// A quarantined conclusion or quarantined occurrence of A is inspectable but blocks
/// this inference; unrelated quarantined side assumptions are carried, never activated.
pub fn b4_apply_cut(first : B4Sequent, second : B4Sequent) -> B4RuleApplication {
  let mut cut_index = -1
  let mut found_quarantined_cut = false
  for i in 0..<second.assumptions.length() {
    let premise = second.assumptions[i]
    if premise.formula == first.conclusion.formula {
      if premise.quarantined {
        found_quarantined_cut = true
      } else if cut_index < 0 {
        cut_index = i
      }
    }
  }
  if cut_index < 0 && !found_quarantined_cut {
    return {
      input_valid: false,
      applied: false,
      blocked_by_quarantine: false,
      result: None,
    }
  }
  if first.conclusion.quarantined || found_quarantined_cut {
    return {
      input_valid: true,
      applied: false,
      blocked_by_quarantine: true,
      result: None,
    }
  }
  let assumptions : Array[B4Premise] = Array(
    capacity=first.assumptions.length() + second.assumptions.length() - 1,
  )
  for premise in first.assumptions {
    assumptions.push(premise)
  }
  for i in 0..<second.assumptions.length() {
    if i != cut_index {
      assumptions.push(second.assumptions[i])
    }
  }
  {
    input_valid: true,
    applied: true,
    blocked_by_quarantine: false,
    result: Some({ assumptions, conclusion: second.conclusion, }),
  }
}

///|
/// Modus ponens as the sequent A, A -> B |- B. The implication shape is validated
/// first; a well-formed step using quarantined evidence is then blocked.
pub fn b4_apply_modus_ponens(
  antecedent : B4Premise,
  conditional : B4Premise,
) -> B4RuleApplication {
  match conditional.formula {
    Imp(children) =>
      if children.length() != 2 || children[0] != antecedent.formula {
        {
          input_valid: false,
          applied: false,
          blocked_by_quarantine: false,
          result: None,
        }
      } else if antecedent.quarantined || conditional.quarantined {
        {
          input_valid: true,
          applied: false,
          blocked_by_quarantine: true,
          result: None,
        }
      } else {
        {
          input_valid: true,
          applied: true,
          blocked_by_quarantine: false,
          result: Some({
            assumptions: [antecedent, conditional],
            conclusion: { formula: children[1], quarantined: false, },
          }),
        }
      }
    _ =>
      {
        input_valid: false,
        applied: false,
        blocked_by_quarantine: false,
        result: None,
      }
  }
}

///|
/// Formula substitution acts homomorphically on every sequent formula and preserves
/// quarantine flags, so substitution cannot silently release quarantined evidence.
pub fn B4Sequent::substitute(
  self : B4Sequent,
  substitution : B4FormulaSubstitution,
) -> B4Sequent {
  {
    assumptions: self.assumptions.map(premise => {
      formula: substitution.apply(premise.formula),
      quarantined: premise.quarantined,
    }),
    conclusion: {
      formula: substitution.apply(self.conclusion.formula),
      quarantined: self.conclusion.quarantined,
    },
  }
}

///|
/// Check uniform-substitution invariance of a sequent at one valuation: evaluating the
/// substituted sequent at v must agree with evaluating the source sequent at v_sigma,
/// where v_sigma(x) = eval(sigma(x), v). Quarantine annotations remain structural.
pub fn b4_substitution_preserves_sequent_semantics(
  sequent : B4Sequent,
  substitution : B4FormulaSubstitution,
  valuation : Array[FourVal],
) -> Bool {
  for premise in sequent.assumptions {
    if !b4_substitution_law_holds(premise.formula, substitution, valuation) {
      return false
    }
  }
  if !b4_substitution_law_holds(
      sequent.conclusion.formula,
      substitution,
      valuation,
    ) {
    return false
  }
  let substituted_sequent = sequent.substitute(substitution)
  if substituted_sequent.assumptions.length() != sequent.assumptions.length() {
    return false
  }
  for i in 0..<sequent.assumptions.length() {
    if substituted_sequent.assumptions[i].quarantined !=
      sequent.assumptions[i].quarantined {
      return false
    }
  }
  if substituted_sequent.conclusion.quarantined !=
    sequent.conclusion.quarantined {
    return false
  }
  match b4_substituted_valuation(substitution, valuation) {
    Some(substituted_valuation) =>
      b4_sequent_preserves_designation(substituted_sequent, valuation) ==
      b4_sequent_preserves_designation(sequent, substituted_valuation)
    None => false
  }
}

///|
/// M2.1 certificate: all local truth-value tuples are enumerated, with the remaining
/// 16-atom assignments counted by an exact power-of-four factor.
#derive(Debug, Eq)
pub(all) struct B4ReasoningSoundnessReport {
  atom_count : Int32
  total_assignments : Int64
  modus_ponens_value_classes : Int32
  modus_ponens_extensions_per_class : Int64
  modus_ponens_covered_assignments : Int64
  cut_value_classes : Int32
  cut_extensions_per_class : Int64
  cut_covered_assignments : Int64
  substitution_value_classes : Int32
  substitution_extensions_per_class : Int64
  substitution_covered_assignments : Int64
  modus_ponens_cases : Int32
  cut_cases : Int32
  substitution_cases : Int32
  substitution_sequent_cases : Int32
  modus_ponens_sound : Bool
  cut_sound : Bool
  substitution_sound : Bool
  coverage_exact : Bool
  sound : Bool
}

///|
fn b4_power_of_four(exp : Int32) -> Int64 {
  let four : Int64 = 4
  let mut out : Int64 = 1
  for _ in 0..<exp {
    out = out * four
  }
  out
}

///|
/// Verify the rule schemas over B_4. MP and cut reduce to two/three evaluated formula
/// values, so all local tuples are checked and the other 14/13 atom slots are counted.
/// Substitution checks a three-atom skeleton over every possible triple of replacement
/// values; structural homomorphism supplies the induction step for arbitrary formula
/// trees. Thus the three schema quotients each account for 4^16 = 4,294,967,296 cases
/// (16 * 4^14 or 64 * 4^13). This is an exact finite truth-table quotient, not a claim
/// that a 4-billion-iteration loop or every syntactic formula was enumerated.
pub fn audit_b4_reasoning_soundness() -> B4ReasoningSoundnessReport {
  let values = four_all_values()
  let valuation = Array::make(16, Nv)
  let mut mp_sound = true
  let mut cut_sound = true
  let mut substitution_sound = true
  let mut mp_cases = 0
  let mut cut_cases = 0
  let mut substitution_cases = 0
  let mut substitution_sequent_cases = 0

  for a in values {
    for b in values {
      let a_formula = Value(a)
      let b_formula = Value(b)
      let mp = b4_apply_modus_ponens(
        { formula: a_formula, quarantined: false, },
        { formula: Imp([a_formula, b_formula]), quarantined: false, },
      )
      mp_cases = mp_cases + 1
      match mp.result {
        Some(sequent) =>
          if !b4_sequent_preserves_designation(sequent, valuation) {
            mp_sound = false
          }
        None => mp_sound = false
      }
    }
  }

  let atom0 = Atom(0)
  let atom1 = Atom(1)
  let atom2 = Atom(2)
  let substitution_templates : Array[B4Formula] = [
    atom0,
    Not([atom0]),
    And([atom0, atom1]),
    Or([atom0, atom1]),
    Imp([atom0, atom1]),
    And([Imp([atom0, atom1]), atom2]),
    Or([atom0, Not([And([atom1, atom2])])]),
  ]
  let substitution_sequent : B4Sequent = {
    assumptions: [
      { formula: And([atom0, atom1]), quarantined: false, },
      { formula: atom2, quarantined: true, },
    ],
    conclusion: {
      formula: Or([Imp([atom0, atom1]), atom2]),
      quarantined: false,
    },
  }
  let substitution_identity = b4_identity(Or([atom0, And([atom1, atom2])]))

  for a in values {
    for b in values {
      for c in values {
        let a_formula = Value(a)
        let b_formula = Value(b)
        let c_formula = Value(c)
        let first : B4Sequent = {
          assumptions: [{ formula: a_formula, quarantined: false, }],
          conclusion: { formula: b_formula, quarantined: false, },
        }
        let second : B4Sequent = {
          assumptions: [{ formula: b_formula, quarantined: false, }],
          conclusion: { formula: c_formula, quarantined: false, },
        }
        let cut = b4_apply_cut(first, second)
        cut_cases = cut_cases + 1
        match cut.result {
          Some(composed) => {
            let premises_valid = b4_sequent_preserves_designation(
                first, valuation,
              ) &&
              b4_sequent_preserves_designation(second, valuation)
            if premises_valid &&
              !b4_sequent_preserves_designation(composed, valuation) {
              cut_sound = false
            }
          }
          None => cut_sound = false
        }

        let substitution = B4FormulaSubstitution::new([
          (0, a_formula),
          (1, b_formula),
          (2, c_formula),
        ])
        for formula in substitution_templates {
          substitution_cases = substitution_cases + 1
          if !b4_substitution_law_holds(formula, substitution, valuation) {
            substitution_sound = false
          }
        }
        substitution_sequent_cases = substitution_sequent_cases + 1
        if !b4_substitution_preserves_sequent_semantics(
            substitution_sequent, substitution, valuation,
          ) {
          substitution_sound = false
        }
        let substituted_identity = substitution_identity.substitute(
          substitution,
        )
        substitution_sequent_cases = substitution_sequent_cases + 1
        if !b4_sequent_preserves_designation(substituted_identity, valuation) {
          substitution_sound = false
        }
      }
    }
  }

  let atom_count = 16
  let total_assignments = b4_power_of_four(atom_count)
  let mp_value_classes = 16
  let mp_extensions = b4_power_of_four(14)
  let mp_covered = mp_value_classes.to_int64() * mp_extensions
  let cut_value_classes = 64
  let cut_extensions = b4_power_of_four(13)
  let cut_covered = cut_value_classes.to_int64() * cut_extensions
  let substitution_value_classes = 64
  let substitution_extensions = b4_power_of_four(13)
  let substitution_covered = substitution_value_classes.to_int64() *
    substitution_extensions
  let coverage_exact = mp_covered == total_assignments &&
    cut_covered == total_assignments &&
    substitution_covered == total_assignments
  {
    atom_count,
    total_assignments,
    modus_ponens_value_classes: mp_value_classes,
    modus_ponens_extensions_per_class: mp_extensions,
    modus_ponens_covered_assignments: mp_covered,
    cut_value_classes,
    cut_extensions_per_class: cut_extensions,
    cut_covered_assignments: cut_covered,
    substitution_value_classes,
    substitution_extensions_per_class: substitution_extensions,
    substitution_covered_assignments: substitution_covered,
    modus_ponens_cases: mp_cases,
    cut_cases,
    substitution_cases,
    substitution_sequent_cases,
    modus_ponens_sound: mp_sound,
    cut_sound,
    substitution_sound,
    coverage_exact,
    sound: mp_sound && cut_sound && substitution_sound && coverage_exact,
  }
}

///|
/// An unresolved proposition can be reviewed without being admitted as a proof premise.
#derive(Debug, Eq)
pub(all) struct B4QuarantineRecord {
  proposition_id : Int32
  name : String
  value : FourVal
  quarantined : Bool
  reason : String
}

///|
/// External, auditable evidence proposed to resolve one quarantined proposition.
#derive(Debug, Eq)
pub(all) struct B4RepairDecision {
  proposition_id : Int32
  repaired_value : FourVal
  evidence : String
}

///|
/// Summary and updated records from inspecting a quarantine set.
#derive(Debug, Eq)
pub(all) struct B4RepairReport {
  input_valid : Bool
  inspection_complete : Bool
  records : Array[B4QuarantineRecord]
  inspected : Int32
  repaired : Int32
  unresolved : Int32
  repair_rate : Double
  non_explosion_preserved : Bool
}

///|
fn b4_contains_id(ids : Array[Int32], id : Int32) -> Bool {
  for x in ids {
    if x == id {
      return true
    }
  }
  false
}

///|
fn b4_is_quarantined_id(
  records : Array[B4QuarantineRecord],
  id : Int32,
) -> Bool {
  for record in records {
    if record.proposition_id == id {
      return record.quarantined
    }
  }
  false
}

///|
/// Inspect every quarantined record. Repair decisions are reviewer-supplied, nonempty
/// evidence plus a proposed value; this kernel records but does not authenticate that
/// external evidence. A non-Bv value clears quarantine; Bv or no decision remains
/// quarantined. Repair rate = repaired / quarantined records inspected, with 0.0 when
/// the denominator is zero.
pub fn inspect_and_repair_quarantine(
  records : Array[B4QuarantineRecord],
  decisions : Array[B4RepairDecision],
) -> B4RepairReport {
  let mut input_valid = true
  let seen_record_ids : Array[Int32] = []
  let seen_decision_ids : Array[Int32] = []
  let mut quarantined_count = 0
  for record in records {
    if record.proposition_id < 0 ||
      b4_contains_id(seen_record_ids, record.proposition_id) {
      input_valid = false
    }
    seen_record_ids.push(record.proposition_id)
    if record.quarantined {
      quarantined_count = quarantined_count + 1
      if record.value != Bv {
        input_valid = false
      }
    }
  }
  for decision in decisions {
    if decision.proposition_id < 0 ||
      b4_contains_id(seen_decision_ids, decision.proposition_id) ||
      !b4_contains_id(seen_record_ids, decision.proposition_id) ||
      !b4_is_quarantined_id(records, decision.proposition_id) ||
      decision.evidence.length() == 0 {
      input_valid = false
    }
    seen_decision_ids.push(decision.proposition_id)
  }
  if !input_valid {
    return {
      input_valid: false,
      inspection_complete: false,
      records: records.copy(),
      inspected: 0,
      repaired: 0,
      unresolved: quarantined_count,
      repair_rate: 0.0,
      non_explosion_preserved: false,
    }
  }

  let updated = records.copy()
  let mut inspected = 0
  let mut repaired = 0
  let mut unresolved = 0
  for i in 0..<records.length() {
    let record = records[i]
    if record.quarantined {
      inspected = inspected + 1
      let mut decision_index = -1
      for j in 0..<decisions.length() {
        if decisions[j].proposition_id == record.proposition_id {
          decision_index = j
        }
      }
      if decision_index >= 0 && decisions[decision_index].repaired_value != Bv {
        let decision = decisions[decision_index]
        updated[i] = {
          proposition_id: record.proposition_id,
          name: record.name,
          value: decision.repaired_value,
          quarantined: false,
          reason: "Reviewed and repaired with evidence: " + decision.evidence,
        }
        repaired = repaired + 1
      } else {
        let unresolved_reason = if decision_index >= 0 {
          "Inspected; conflict remains with evidence: " +
          decisions[decision_index].evidence
        } else {
          "Inspected; no repair decision supplied."
        }
        updated[i] = {
          proposition_id: record.proposition_id,
          name: record.name,
          value: record.value,
          quarantined: true,
          reason: unresolved_reason,
        }
        unresolved = unresolved + 1
      }
    }
  }
  let repair_rate = if inspected > 0 {
    repaired.to_double() / inspected.to_double()
  } else {
    0.0
  }
  let mut quarantine_invariant = true
  for record in updated {
    if record.quarantined && record.value != Bv {
      quarantine_invariant = false
    }
  }
  {
    input_valid: true,
    inspection_complete: inspected == quarantined_count,
    records: updated,
    inspected,
    repaired,
    unresolved,
    repair_rate,
    non_explosion_preserved: quarantine_invariant &&
    b4_non_explosion_counterexample_exists(),
  }
}

///|
/// Convert a quarantine record to a proof premise without dropping its quarantine flag.
pub fn B4QuarantineRecord::as_premise(self : B4QuarantineRecord) -> B4Premise {
  { formula: Atom(self.proposition_id), quarantined: self.quarantined, }
}
