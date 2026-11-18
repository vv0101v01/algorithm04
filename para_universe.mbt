///|
/// Module 23 (Unified from `algo8`): Para-Universe, Belnap Four-Valued Bilattice B_4,
/// Paraconsistent Non-Explosion, Knaster-Tarski Fixed Points & Multi-World Epistemic Fusion
/// (仿宇宙：Belnap 四值雙格、副相容矛盾隔離、Tarski 不動點與多世界語義融合).

///|
/// Belnap-Dunn four-valued epistemic/truth bilattice B_4 = {Nv, Fv, Tv, Bv}:
///   - `Nv` (Neither): epistemically ungrounded / unknown (bottom of information order <=_i),
///   - `Fv` (False)  : refuted (bottom of truth order <=_t),
///   - `Tv` (True)   : certified true (top of truth order <=_t),
///   - `Bv` (Both)   : dialetheic conflict / local contradiction (top of information order <=_i).
#derive(Debug, Eq, Hash)
pub(all) enum FourVal {
  Nv
  Fv
  Tv
  Bv
}

///|
/// Information-order least upper bound x |_|_i y (consensus evidence accumulation: Fv |_|_i Tv = Bv).
pub fn FourVal::join(a : FourVal, b : FourVal) -> FourVal {
  match (a, b) {
    (Nv, x) | (x, Nv) => x
    (Bv, _) | (_, Bv) => Bv
    (Fv, Fv) => Fv
    (Tv, Tv) => Tv
    (Fv, Tv) | (Tv, Fv) => Bv
  }
}

///|
/// Information-order greatest lower bound x |^|_i y (strictly agreed information: Fv |^|_i Tv = Nv).
pub fn FourVal::meet(a : FourVal, b : FourVal) -> FourVal {
  match (a, b) {
    (Bv, x) | (x, Bv) => x
    (Nv, _) | (_, Nv) => Nv
    (Fv, Fv) => Fv
    (Tv, Tv) => Tv
    (Fv, Tv) | (Tv, Fv) => Nv
  }
}

///|
/// De Morgan negation ~a inverting truth order (Fv <-> Tv) while fixing information extrema (Nv, Bv).
pub fn FourVal::neg(a : FourVal) -> FourVal {
  match a {
    Nv => Nv
    Fv => Tv
    Tv => Fv
    Bv => Bv
  }
}

///|
/// TRUTH-ORDER MEET (paraconsistent conjunction a /\_t b).
/// The truth order <=_t has `Fv` as the bottom, `Tv` as the top and `Nv` / `Bv` as
/// INCOMPARABLE middle elements (Nv <=_t Bv does NOT hold and vice versa).
/// `land` is the genuine greatest lower bound of that order, hence
///   land(Nv, Tv) = Nv,  land(Bv, Tv) = Bv,  land(Nv, Bv) = Fv,
/// and it is conservative over the classical image {Fv, Tv}.
/// (MERGE FIX: the pre-merge `algo8` implementation returned `land(Nv, Tv) = Tv` and
/// `land(Bv, Tv) = Tv`, which contradicted its own documented truth order.)
pub fn FourVal::land(a : FourVal, b : FourVal) -> FourVal {
  match (a, b) {
    (Fv, _) | (_, Fv) => Fv
    (Nv, Nv) => Nv
    (Bv, Bv) => Bv
    (Nv, Bv) | (Bv, Nv) => Fv
    (Tv, x) | (x, Tv) => x
  }
}

///|
/// TRUTH-ORDER JOIN (paraconsistent disjunction a \/_t b): the genuine least upper bound
/// of the truth order, hence
///   lor(Fv, Nv) = Nv,  lor(Fv, Bv) = Bv,  lor(Nv, Bv) = Tv,
/// conservative over the classical image {Fv, Tv}.
/// (MERGE FIX: the pre-merge `algo8` implementation returned `lor(Fv, Nv) = Fv` and
/// `lor(Fv, Bv) = Fv`, contradicting its own documented truth order.)
pub fn FourVal::lor(a : FourVal, b : FourVal) -> FourVal {
  match (a, b) {
    (Tv, _) | (_, Tv) => Tv
    (Fv, Fv) => Fv
    (Nv, Nv) => Nv
    (Bv, Bv) => Bv
    (Nv, Bv) | (Bv, Nv) => Tv
    (Fv, x) | (x, Fv) => x
  }
}

///|
/// Designated truth predicate D = {Tv, Bv} defining Dunn-Belnap First-Degree Entailment (FDE).
pub fn FourVal::is_designated(self : FourVal) -> Bool {
  match self {
    Tv | Bv => true
    Nv | Fv => false
  }
}

///|
/// Truth-order partial order x <=_t y  <==>  x \/_t y == y  (Fv <=_t {Nv, Bv} <=_t Tv).
pub fn FourVal::truth_le(x : FourVal, y : FourVal) -> Bool {
  FourVal::lor(x, y) == y
}

///|
pub fn FourVal::to_string(self : FourVal) -> String {
  match self {
    Nv => "N"
    Fv => "F"
    Tv => "T"
    Bv => "B"
  }
}

///|
/// Canonical enumeration of all 4 Belnap truth values.
pub fn four_all_values() -> Array[FourVal] {
  [Nv, Fv, Tv, Bv]
}

///|
/// Conservative Boolean embedding i : Bool -> {Fv, Tv} subset B_4 preserving ~, /\, \/.
pub fn classic_embed(b : Bool) -> FourVal {
  if b {
    Tv
  } else {
    Fv
  }
}

///|
/// Exhaustive witness of paraconsistent non-explosion (ex contradictione quodlibet fails):
/// exists (p, q, r) in B_4^3 with (p /\ ~p) in D and q in D while r not in D (namely p = Bv, r = Fv/Nv).
pub fn explosion_counterexample_exists() -> Bool {
  let vs = four_all_values()
  for p in vs {
    let contradiction = FourVal::land(p, FourVal::neg(p))
    if contradiction.is_designated() {
      for q in vs {
        if q.is_designated() {
          for r in vs {
            if !r.is_designated() {
              return true
            }
          }
        }
      }
    }
  }
  false
}

///|
/// Information-order partial order x <=_i y  <==>  x |_|_i y == y  (Nv <=_i {Fv, Tv} <=_i Bv).
pub fn four_le(x : FourVal, y : FourVal) -> Bool {
  FourVal::join(x, y) == y
}

///|
/// The canonical monotone "quarantine" belief operator on B_4:
///   Nv |-> Nv  (no information stays no information)
///   Fv |-> Bv  (a false belief is quarantined as a contradiction)
///   Tv |-> Bv  (a true belief is quarantined as a contradiction)
///   Bv |-> Bv  (an existing contradiction stays quarantined)
/// It is <=_i-monotone with least fixed point Nv, and it is THE reference operator
/// for the paraconsistent quarantine semantics of Theorems XVI and XVIII.
pub fn epistemic_quarantine_map(v : FourVal) -> FourVal {
  match v {
    Nv => Nv
    Fv => Bv
    Tv => Bv
    Bv => Bv
  }
}

///|
/// Constructive Knaster-Tarski least fixed point lfp_{<=_i}(f) = |_|_{k>=0} f^k(Nv)
/// for any <=_i-monotone belief operator f : B_4 -> B_4 (stabilizes in <= 2 steps since height(B_4) = 2).
pub fn tarski_least_fixed_point(f : (FourVal) -> FourVal) -> FourVal {
  let mut cur = Nv
  for _ in 0..<4 {
    let nxt = f(cur)
    if nxt == cur {
      return cur
    }
    cur = nxt
  }
  cur
}

///|
/// Exhaustive Knaster-Tarski verification over ALL 4^4 = 256 operators f : B_4 -> B_4:
/// every <=_i-monotone map admits a fixed point, AND `tarski_least_fixed_point(f)` hits the exact least one!
pub fn all_monotone_maps_have_fixed_point() -> Bool {
  let vs = four_all_values()
  for c0 in 0..<4 {
    for c1 in 0..<4 {
      for c2 in 0..<4 {
        for c3 in 0..<4 {
          let tbl = [vs[c0], vs[c1], vs[c2], vs[c3]]
          let mut mono = true
          for x in 0..<4 {
            for y in 0..<4 {
              if four_le(vs[x], vs[y]) && !four_le(tbl[x], tbl[y]) {
                mono = false
              }
            }
          }
          if mono {
            let lfp = tarski_least_fixed_point(v => {
              match v {
                Nv => tbl[0]
                Fv => tbl[1]
                Tv => tbl[2]
                Bv => tbl[3]
              }
            })
            let flfp = match lfp {
              Nv => tbl[0]
              Fv => tbl[1]
              Tv => tbl[2]
              Bv => tbl[3]
            }
            if flfp != lfp {
              return false
            }
            // Verify minimality: lfp <=_i x for every other fixed point f(x) == x
            for x in 0..<4 {
              if tbl[x] == vs[x] && !four_le(lfp, vs[x]) {
                return false
              }
            }
          }
        }
      }
    }
  }
  true
}

///|
/// Single epistemic world assigning Belnap B_4 valuations to named mathematical propositions.
#derive(Debug, Eq)
pub(all) struct ParaUniverse {
  props : Array[String]
  vals : Array[FourVal]
}

///|
pub fn ParaUniverse::new(
  props : Array[String],
  vals : Array[FourVal],
) -> ParaUniverse {
  { props, vals, }
}

///|
fn b4_duplicate_proposition(props : Array[String]) -> String? {
  let sorted = props.copy()
  sorted.sort_by(String::lexical_compare)
  for i in 1..<sorted.length() {
    if sorted[i - 1] == sorted[i] {
      return Some(sorted[i])
    }
  }
  None
}

///|
pub fn ParaUniverse::is_well_formed(self : ParaUniverse) -> Bool {
  self.props.length() == self.vals.length() &&
  b4_duplicate_proposition(self.props) is None
}

///|
/// Look up the first matching proposition. The checked aggregation API rejects duplicate
/// names; this compatibility lookup returns `None` rather than indexing misaligned arrays.
pub fn ParaUniverse::lookup(self : ParaUniverse, name : String) -> FourVal? {
  if self.props.length() != self.vals.length() {
    return None
  }
  for i in 0..<self.props.length() {
    if self.props[i] == name {
      return Some(self.vals[i])
    }
  }
  None
}

///|
/// Invalid finite-world input: mismatched proposition/value arrays or duplicate names.
#derive(Debug, Eq)
pub(all) enum EpistemicAggregationError {
  MisalignedWorld(Int32)
  DuplicateProposition(Int32, String)
}

///|
/// Multi-world epistemic product aggregating finite named belief states in the B_4
/// information order. Missing propositions contribute `Nv`, the information bottom.
#derive(Debug, Eq)
pub(all) struct MultiWorld {
  worlds : Array[ParaUniverse]
}

///|
fn b4_propositions_are_sorted(props : Array[String]) -> Bool {
  for i in 1..<props.length() {
    if String::lexical_compare(props[i - 1], props[i]) > 0 {
      return false
    }
  }
  true
}

///|
/// Pointwise join on the union of proposition names. Names use canonical lexicographic
/// (UTF-16 code-unit) order; missing entries are Nv, and malformed worlds return an error.
pub fn MultiWorld::aggregate(
  self : MultiWorld,
) -> Result[ParaUniverse, EpistemicAggregationError] {
  for world_index in 0..<self.worlds.length() {
    let world = self.worlds[world_index]
    if world.props.length() != world.vals.length() {
      return Err(MisalignedWorld(world_index))
    }
    match b4_duplicate_proposition(world.props) {
      Some(name) => return Err(DuplicateProposition(world_index, name))
      None => ()
    }
  }

  let all_props : Array[String] = []
  for world in self.worlds {
    for name in world.props {
      all_props.push(name)
    }
  }
  all_props.sort_by(String::lexical_compare)
  let props : Array[String] = []
  for name in all_props {
    if props.length() == 0 || props[props.length() - 1] != name {
      props.push(name)
    }
  }
  let values = Array::makei(props.length(), i => {
    let mut aggregate = Nv
    for world in self.worlds {
      match world.lookup(props[i]) {
        Some(value) => aggregate = FourVal::join(aggregate, value)
        None => ()
      }
    }
    aggregate
  })
  Ok(ParaUniverse::new(props, values))
}

///|
/// Associative, commutative, idempotent information join over named B_4 worlds, with Nv
/// as the identity and the B_4 information order as its induced product partial order.
pub fn ParaUniverse::information_join(
  self : ParaUniverse,
  other : ParaUniverse,
) -> Result[ParaUniverse, EpistemicAggregationError] {
  MultiWorld::aggregate({ worlds: [self, other], })
}

///|
/// Legacy array-view fusion. It keeps the first world's proposition ordering; use
/// `MultiWorld::aggregate` when heterogeneous supports or validation details are needed.
pub fn MultiWorld::merge_pointwise(self : MultiWorld) -> Array[FourVal] {
  if self.worlds.length() == 0 {
    return []
  }
  let first_props = self.worlds[0].props.copy()
  match MultiWorld::aggregate(self) {
    Ok(aggregate) =>
      Array::makei(first_props.length(), i => {
        match aggregate.lookup(first_props[i]) {
          Some(value) => value
          None => Nv
        }
      })
    Err(_) => []
  }
}

///|
/// Finite certificate for the B_4 information-join algebra and its named-world lift.
#derive(Debug, Eq)
pub(all) struct EpistemicAggregationLawReport {
  associativity_cases : Int32
  commutativity_cases : Int32
  idempotence_cases : Int32
  least_upper_bound_cases : Int32
  associative : Bool
  commutative : Bool
  idempotent : Bool
  least_upper_bound : Bool
  named_union_laws : Bool
  malformed_inputs_rejected : Bool
  certified : Bool
}

///|
fn b4_try_information_join(
  left : ParaUniverse,
  right : ParaUniverse,
) -> ParaUniverse? {
  match left.information_join(right) {
    Ok(aggregate) => Some(aggregate)
    Err(_) => None
  }
}

///|
fn b4_para_universes_equivalent(
  left : ParaUniverse,
  right : ParaUniverse,
) -> Bool {
  if !left.is_well_formed() ||
    !right.is_well_formed() ||
    left.props.length() != right.props.length() {
    return false
  }
  for i in 0..<left.props.length() {
    match right.lookup(left.props[i]) {
      Some(value) => if value != left.vals[i] { return false }
      None => return false
    }
  }
  true
}

///|
fn b4_optional_universes_equivalent(
  left : ParaUniverse?,
  right : ParaUniverse?,
) -> Bool {
  match (left, right) {
    (Some(a), Some(b)) => b4_para_universes_equivalent(a, b)
    (None, None) => true
    _ => false
  }
}

///|
pub fn audit_epistemic_aggregation_laws() -> EpistemicAggregationLawReport {
  let values = four_all_values()
  let mut associative = true
  let mut commutative = true
  let mut idempotent = true
  let mut least_upper_bound = true
  let mut associativity_cases = 0
  let mut commutativity_cases = 0
  let mut idempotence_cases = 0
  let mut least_upper_bound_cases = 0

  for a in values {
    let aa = FourVal::join(a, a)
    idempotence_cases = idempotence_cases + 1
    if aa != a {
      idempotent = false
    }
    for b in values {
      commutativity_cases = commutativity_cases + 1
      if FourVal::join(a, b) != FourVal::join(b, a) {
        commutative = false
      }
      let joined = FourVal::join(a, b)
      for upper in values {
        least_upper_bound_cases = least_upper_bound_cases + 1
        if !four_le(a, joined) ||
          !four_le(b, joined) ||
          (four_le(a, upper) && four_le(b, upper) && !four_le(joined, upper)) {
          least_upper_bound = false
        }
      }
      for c in values {
        associativity_cases = associativity_cases + 1
        if FourVal::join(FourVal::join(a, b), c) !=
          FourVal::join(a, FourVal::join(b, c)) {
          associative = false
        }
      }
    }
  }

  let left : ParaUniverse = { props: ["zeta", "alpha"], vals: [Tv, Nv], }
  let middle : ParaUniverse = { props: ["beta", "alpha"], vals: [Bv, Fv], }
  let right : ParaUniverse = { props: ["zeta", "gamma"], vals: [Fv, Tv], }
  let empty = ParaUniverse::new([], [])
  let left_middle = b4_try_information_join(left, middle)
  let middle_left = b4_try_information_join(middle, left)
  let middle_right = b4_try_information_join(middle, right)
  let left_empty = b4_try_information_join(left, empty)
  let empty_left = b4_try_information_join(empty, left)
  let left_left = b4_try_information_join(left, left)
  let left_middle_right = match left_middle {
    Some(aggregate) => b4_try_information_join(aggregate, right)
    None => None
  }
  let left_middle_right_alt = match middle_right {
    Some(aggregate) => b4_try_information_join(left, aggregate)
    None => None
  }
  let canonical_names = match left_middle {
    Some(aggregate) => b4_propositions_are_sorted(aggregate.props)
    None => false
  }
  let named_union_laws = b4_optional_universes_equivalent(
      left_middle, middle_left,
    ) &&
    b4_optional_universes_equivalent(left_empty, Some(left)) &&
    b4_optional_universes_equivalent(empty_left, Some(left)) &&
    b4_optional_universes_equivalent(left_left, Some(left)) &&
    b4_optional_universes_equivalent(left_middle_right, left_middle_right_alt) &&
    canonical_names

  let duplicate_world : ParaUniverse = { props: ["p", "p"], vals: [Tv, Fv], }
  let misaligned_world : ParaUniverse = { props: ["p"], vals: [], }
  let duplicate_rejected = match
    MultiWorld::aggregate({ worlds: [duplicate_world], }) {
    Err(DuplicateProposition(0, _)) => true
    _ => false
  }
  let misaligned_rejected = match
    MultiWorld::aggregate({ worlds: [misaligned_world], }) {
    Err(MisalignedWorld(0)) => true
    _ => false
  }
  let malformed_inputs_rejected = duplicate_rejected && misaligned_rejected
  {
    associativity_cases,
    commutativity_cases,
    idempotence_cases,
    least_upper_bound_cases,
    associative,
    commutative,
    idempotent,
    least_upper_bound,
    named_union_laws,
    malformed_inputs_rejected,
    certified: associative &&
    commutative &&
    idempotent &&
    least_upper_bound &&
    named_union_laws &&
    malformed_inputs_rejected,
  }
}
