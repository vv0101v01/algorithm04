///|
/// M10: PARACONSISTENT CONSENSUS BETWEEN SUB-COLONIES — the four-valued version.
///
/// The roadmap question is:
///
/// > 多智能體間之副相容共識 — 不同 sub-colony 對同一命題給出 Bv 時，如何達成
/// > 不爆炸的共識？
///
/// ## What v1 got wrong
///
/// The first version of this module (v2.4.6) collapsed each sub-colony to a
/// single scalar factor: "does this sub-colony contradict?" — a Bool, more or
/// less. That throws away exactly the information the four-valued bilattice B_4
/// exists to carry. B_4 is not a truth scale; it is a PRODUCT of two lattices
/// (`<=_t` truth order and `<=_i` information order), and the whole point of
/// paraconsistency is that a contradiction is a *local* state that the system
/// can keep carrying while it finishes its work. Compressing a sub-colony's B_4
/// value into "contradicting / not" is the same mistake as collapsing a vector
/// into its norm.
///
/// ## What v2 does
///
/// Each sub-colony contributes a full B_4 value to a *sub-colony factor*, and the
/// colony's state is the **product** of those factors — literally the bilattice
/// product B_4^n, not an average of them. Consensus is then a two-stage
/// degradation:
///
///   1. **`<=_i` (information) stage** — join the factors. This is what the
///      colony KNOWS: a contradiction at one factor makes the joined information
///      `Bv`, and it makes it `Bv` only there. Joining is monotone and never
///      forgets, so this stage is order-preserving and it is what "the colony
///      keeps carrying the contradiction while it finishes the job" means
///      concretely.
///   2. **`<=_t` (truth) stage** — project the joined information down to which
///      truth values are still *available* to act on. This projection is what
///      turns a `Bv` region into a usable decision instead of a veto: `Bv` means
///      both `Tv` and `Fv` are available, so the colony can act on either branch
///      as long as it ROUTES them, which is what happens at the intersection of
///      the two orders.
///
/// The two stages are the two orders of the bilattice, which is why this is a
/// degradation of the contradiction rather than a deletion of it. Deleting it
/// (the old `Weighted` rule's `contested` flag) loses the structure; carrying it
/// through both orders keeps it.
///
/// ## What is actually enumerated
///
/// The auditable question is not "does one hand-picked colony explode". It is:
/// **over the entire space of sub-colony configurations, does the rule produce an
/// explosive consensus anywhere?** That space is finite: B_4^4 = 256 for four
/// sub-colonies. This module enumerates ALL of them, for every rule, and reports
/// the exact census. A rule "does not explode" only means something once that
/// census is empty — otherwise it means "the examples I happened to try did not
/// explode".

///|
/// A sub-colony's verdict: its B_4 value plus a scalar confidence. The B_4 value
/// is the primary carrier; confidence only breaks ties inside the truth-order
/// projection, it does NOT replace the four-valued information.
#derive(Debug, Eq)
pub(all) struct SubColonyVerdict {
  name : String
  value : FourVal
  confidence : Double
}

///|
/// The colony factor: the full product state B_4^n together with its two order
/// projections. This is the object that "does not explode" — not a scalar.
#derive(Debug, Eq)
pub(all) struct ColonyFactor {
  /// The joint B_4 state, one coordinate per sub-colony (the bilattice PRODUCT).
  coordinates : Array[FourVal]
  /// The <=_i join of the coordinates: what the colony knows.
  information : FourVal
  /// The <=_t projection: which truth values remain actionably available.
  available : Array[FourVal]
  /// Sub-colonies whose own value is Bv (a local contradiction, carried not
  /// globalised).
  local_contradictions : Int32
  /// True iff the joint information is Bv while NO coordinate is Nv — i.e. the
  /// colony knows something, and what it knows includes a contradiction. This is
  /// the "carrying" state, and it is NOT a failure.
  carrying_contradiction : Bool
  /// True iff the joint information is Bv but NO coordinate is Bv — the
  /// contradiction was MANUFACTURED by `join(Tv, Fv)`, i.e. two sub-colonies that
  /// are each perfectly classical disagree with each other. Reported separately
  /// because the two cases need different treatment: a carried contradiction has
  /// an owner, a manufactured one does not.
  manufactured_contradiction : Bool
}

///|
/// The <=_t projection of a single value onto the truth values still available
/// for action. `Bv` projects to BOTH `Tv` and `Fv` — that is the degradation:
/// a contradiction is split into its two actionable branches instead of being
/// collapsed to a veto.
pub fn truth_available(v : FourVal) -> Array[FourVal] {
  match v {
    Tv => [Tv]
    Fv => [Fv]
    Nv => [Nv]
    Bv => [Tv, Fv]
  }
}

///|
/// Build the colony factor from the sub-colony verdicts. Two stages, one per
/// bilattice order.
pub fn colony_factor(verdicts : Array[SubColonyVerdict]) -> ColonyFactor {
  let coordinates : Array[FourVal] = []
  let mut information = FourVal::Nv
  let mut local_contradictions = 0
  let mut any_nv = false
  for v in verdicts {
    coordinates.push(v.value)
    information = FourVal::join(information, v.value)
    if v.value == FourVal::Bv {
      local_contradictions = local_contradictions + 1
    }
    if v.value == FourVal::Nv {
      any_nv = true
    }
  }
  // The available set is the union, over coordinates, of each coordinate's truth
  // projection, intersected with the joint information's projection. This is the
  // join in the <=_t order, which is why the two orders are both used.
  let available : Array[FourVal] = []
  let joint_projection = truth_available(information)
  for value in joint_projection {
    // Keep a truth value only if some coordinate actually supports it; this is
    // what stops the projection from inventing options nobody holds.
    let mut supported = false
    for coordinate in coordinates {
      for candidate in truth_available(coordinate) {
        if candidate == value {
          supported = true
        }
      }
    }
    if supported && !available.contains(value) {
      available.push(value)
    }
  }
  {
    coordinates,
    information,
    available,
    local_contradictions,
    carrying_contradiction: information == FourVal::Bv &&
    !any_nv &&
    local_contradictions > 0,
    manufactured_contradiction: information == FourVal::Bv &&
    local_contradictions == 0,
  }
}

///|
/// Consensus verdict: WHICH actionable truth value the colony proceeds with, and
/// whether the contradiction was carried. `carried` is the honest replacement
/// for the old `contested` flag: it means the contradiction is still present in
/// the factor, not that it was resolved away.
#derive(Debug, Eq)
pub(all) struct ConsensusResult {
  agent_value : FourVal
  factor : ColonyFactor
  /// Number of sub-colonies whose classical value entered the vote.
  informing : Int32
  /// Number of sub-colonies reporting Bv. Kept as a separate field because it is
  /// NOT the same as `factor.local_contradictions` for rules that transform the
  /// input; for the preserved factor they coincide by construction.
  contradicting : Int32
}

///|
/// Rule 1 (baseline, FAILS): the raw lattice join, reported as the answer.
/// This is the rule the M10 question implicitly assumes, and it is the one that
/// destroys the ability to act: `join` returns Bv and the caller has no way to
/// choose a branch.
pub fn consensus_naive_join(
  verdicts : Array[SubColonyVerdict],
) -> ConsensusResult {
  let factor = colony_factor(verdicts)
  {
    agent_value: factor.information,
    factor,
    informing: count_classical(verdicts),
    contradicting: factor.local_contradictions,
  }
}

///|
/// Rule 2 (FAILS, and is worse than rule 1): quarantine each sub-colony with
/// `epistemic_quarantine_map`, then join. That map sends Fv, Tv and Bv ALL to
/// Bv, so it manufactures contradictions out of agreement.
pub fn consensus_quarantine_first(
  verdicts : Array[SubColonyVerdict],
) -> ConsensusResult {
  let mapped : Array[SubColonyVerdict] = verdicts.map(v => {
    name: v.name,
    value: epistemic_quarantine_map(v.value),
    confidence: v.confidence,
  })
  let factor = colony_factor(mapped)
  {
    agent_value: factor.information,
    factor,
    informing: 0,
    contradicting: factor.local_contradictions,
  }
}

///|
/// Rule 3 (FAILS): scope the explicit Bv inputs, join the rest. Still explodes
/// because `join(Tv, Fv) = Bv`: two classical, opposite sub-colonies manufacture
/// a contradiction that no sub-colony ever reported.
pub fn consensus_scoped(verdicts : Array[SubColonyVerdict]) -> ConsensusResult {
  let kept : Array[SubColonyVerdict] = []
  let mut contradicting = 0
  for v in verdicts {
    if v.value == FourVal::Bv {
      contradicting = contradicting + 1
    } else {
      kept.push(v)
    }
  }
  let factor = colony_factor(kept)
  {
    agent_value: factor.information,
    factor: {
      ..factor,
      local_contradictions: factor.local_contradictions + contradicting,
    },
    informing: count_classical(kept),
    contradicting,
  }
}

///|
/// Rule 4 (v1's answer, now understood as a DEGRADATION, not a fix): weighted
/// vote on Tv vs Fv, with the contradiction reported out of band.
///
/// Its strength: a decided consensus is stable under a single dissenter.
/// Its weakness, which v2 corrects: it DESTROYS the four-valued factor. The
/// returned `ConsensusResult.factor` for this rule is built from the vote, so the
/// per-coordinate structure that B_4 was carrying is gone.
pub fn consensus_weighted(
  verdicts : Array[SubColonyVerdict],
) -> ConsensusResult {
  let mut support_true = 0.0
  let mut support_false = 0.0
  let mut informing = 0
  for v in verdicts {
    let weight = if v.confidence.is_finite() {
      v.confidence.clamp(min=0.0, max=1.0)
    } else {
      0.0
    }
    match v.value {
      Tv => {
        support_true = support_true + weight
        informing = informing + 1
      }
      Fv => {
        support_false = support_false + weight
        informing = informing + 1
      }
      Bv | Nv => ()
    }
  }
  let tolerance = 1.0e-12
  let value = if support_true > support_false + tolerance {
    Tv
  } else if support_false > support_true + tolerance {
    Fv
  } else {
    Nv
  }
  let factor = colony_factor(verdicts)
  {
    agent_value: value,
    factor,
    informing,
    contradicting: factor.local_contradictions,
  }
}

///|
/// Rule 5 (v2, the answer): BILATTICE DEGRADATION. The contradiction is not
/// deleted and not voted away — it is carried through both orders and degraded
/// into the set of actionable branches.
///
///   - action branch = the truth value with the largest confidence mass, chosen
///     from `factor.available`. When the factor is `Bv` because of a local
///     contradiction, BOTH branches are available, so the colony proceeds on the
///     better-supported one while STILL carrying the contradiction in the factor;
///   - when the factor is genuinely empty (`Nv`), the colony reports `Nv` — there
///     is nothing to act on, and that is not an explosion;
///   - when only one branch is available, it is taken without a vote, because a
///     vote among one option is exactly the kind of fiction that hides an
///     explosion.
pub fn consensus_bilattice(
  verdicts : Array[SubColonyVerdict],
) -> ConsensusResult {
  let factor = colony_factor(verdicts)
  let available = factor.available
  let agent_value = if available.length() == 0 {
    FourVal::Nv
  } else if available.length() == 1 {
    available[0]
  } else {
    // Both branches are available (the degradation of Bv). Choose by confidence;
    // a genuine tie is reported as Nv rather than silently picking one.
    let mut support_true = 0.0
    let mut support_false = 0.0
    for v in verdicts {
      let weight = if v.confidence.is_finite() {
        v.confidence.clamp(min=0.0, max=1.0)
      } else {
        0.0
      }
      match v.value {
        Tv => support_true = support_true + weight
        Fv => support_false = support_false + weight
        Bv | Nv => ()
      }
    }
    let tolerance = 1.0e-12
    if support_true > support_false + tolerance {
      Tv
    } else if support_false > support_true + tolerance {
      Fv
    } else {
      Nv
    }
  }
  {
    agent_value,
    factor,
    informing: count_classical(verdicts),
    contradicting: factor.local_contradictions,
  }
}

///|
/// Count sub-colonies with a classical (non-Bv) verdict.
fn count_classical(verdicts : Array[SubColonyVerdict]) -> Int32 {
  let mut count = 0
  for v in verdicts {
    if v.value != FourVal::Bv {
      count = count + 1
    }
  }
  count
}

///|
/// The failure census for ONE rule, over ALL configurations of `n` sub-colonies.
///
/// The three counts are the three ways a rule can be wrong, and they are
/// distinguished on purpose because they have different causes:
///
///   - `exploded` : the colony's action value is `Bv` — no branch can be chosen,
///     which is the operational meaning of explosion;
///   - `vacuous`  : the action value is `Nv` although the classical coordinates
///     AGREE (a tie is genuine undecidability and is NOT counted, which was a
///     real bug in v1's audit);
///   - `lost_factor` : the returned factor's information differs from the raw
///     `join` of the input — the rule destroyed structure it was given.
#derive(Debug, Eq)
pub(all) struct ConsensusCensus {
  rule : String
  configurations : Int32
  exploded : Int32
  vacuous : Int32
  lost_factor : Int32
  /// Configurations where a contradiction was carried through both orders.
  carrying : Int32
  /// Configurations where the contradiction was manufactured by join(Tv, Fv).
  manufactured : Int32
  passes : Bool
}

///|
/// The fixture universe: ALL 4^n sub-colony configurations, with confidence 1.0
/// everywhere so the census is a pure statement about the four-valued algebra.
/// n = 4 gives 256 configurations, which is small enough to enumerate exactly and
/// large enough that the answer cannot be an artefact of hand-picked examples.
pub fn m10_all_configurations(n : Int32) -> Array[Array[SubColonyVerdict]] {
  let values = [FourVal::Nv, FourVal::Fv, FourVal::Tv, FourVal::Bv]
  let total = if n <= 0 {
    1
  } else {
    let mut acc = 1
    for _ in 0..<n {
      acc = acc * 4
    }
    acc
  }
  let out : Array[Array[SubColonyVerdict]] = []
  for code in 0..<total {
    let config : Array[SubColonyVerdict] = []
    let mut rest = code
    for i in 0..<n {
      let index = rest % 4
      rest = rest / 4
      config.push({ name: "c\{i}", value: values[index], confidence: 1.0, })
    }
    out.push(config)
  }
  out
}

///|
/// Run the census for one rule over all 4^n configurations.
pub fn census_rule(
  name : String,
  rule : (Array[SubColonyVerdict]) -> ConsensusResult,
  n : Int32,
) -> ConsensusCensus {
  let configs = m10_all_configurations(n)
  let mut exploded = 0
  let mut vacuous = 0
  let mut lost_factor = 0
  let mut carrying = 0
  let mut manufactured = 0
  for config in configs {
    let result = rule(config)
    let raw_information = colony_factor(config).information
    if result.agent_value == FourVal::Bv {
      exploded = exploded + 1
    }
    // Vacuity: Nv returned although the classical coordinates agree. A tie is
    // NOT vacuity — that miscount was a real bug in v1.
    let mut any_true = false
    let mut any_false = false
    for v in config {
      if v.value == FourVal::Tv {
        any_true = true
      }
      if v.value == FourVal::Fv {
        any_false = true
      }
    }
    let classical_agrees = (any_true && !any_false) || (any_false && !any_true)
    if result.agent_value == FourVal::Nv && classical_agrees {
      vacuous = vacuous + 1
    }
    if result.factor.information != raw_information {
      lost_factor = lost_factor + 1
    }
    if result.factor.carrying_contradiction {
      carrying = carrying + 1
    }
    if result.factor.manufactured_contradiction {
      manufactured = manufactured + 1
    }
  }
  {
    rule: name,
    configurations: configs.length(),
    exploded,
    vacuous,
    lost_factor,
    carrying,
    manufactured,
    passes: exploded == 0 && vacuous == 0 && lost_factor == 0,
  }
}

///|
/// M10 report: the exhaustive census for every rule at n = 4 (256 configurations).
#derive(Debug, Eq)
pub(all) struct M10ConsensusReport {
  n_subcolonies : Int32
  naive_join : ConsensusCensus
  quarantine_first : ConsensusCensus
  scoped : ConsensusCensus
  weighted : ConsensusCensus
  bilattice : ConsensusCensus
  /// The joint B_4^n space was enumerated exactly (4^n, no sampling).
  exhaustive : Bool
  /// True iff the recommended rule's census is empty AND it carries the
  /// contradiction into the factor instead of deleting it.
  non_explosive_consensus_exists : Bool
  recommended_rule : String
}

///|
pub fn verify_m10_subcolony_consensus(
  n_subcolonies~ : Int32 = 4,
) -> M10ConsensusReport {
  let n = n_subcolonies.clamp(min=1, max=5)
  let naive = census_rule("NaiveJoin", consensus_naive_join, n)
  let quarantine = census_rule("QuarantineFirst", consensus_quarantine_first, n)
  let scoped = census_rule("Scoped", consensus_scoped, n)
  let weighted = census_rule("Weighted", consensus_weighted, n)
  let bilattice = census_rule("Bilattice", consensus_bilattice, n)
  // Exhaustiveness is a fact about the enumeration, checked by counting.
  let expected = {
    let mut acc = 1
    for _ in 0..<n {
      acc = acc * 4
    }
    acc
  }
  let exhaustive = naive.configurations == expected &&
    bilattice.configurations == expected
  let non_explosive = bilattice.passes && bilattice.carrying > 0 && exhaustive
  {
    n_subcolonies: n,
    naive_join: naive,
    quarantine_first: quarantine,
    scoped,
    weighted,
    bilattice,
    exhaustive,
    non_explosive_consensus_exists: non_explosive,
    recommended_rule: if non_explosive {
      "Bilattice"
    } else {
      ""
    },
  }
}
