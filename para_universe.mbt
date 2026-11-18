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
pub fn ParaUniverse::lookup(self : ParaUniverse, name : String) -> FourVal? {
  for i in 0..<self.props.length() {
    if self.props[i] == name {
      return Some(self.vals[i])
    }
  }
  None
}

///|
/// Multi-world epistemic product aggregating heterogeneous agent universes via information-join |_|_i.
#derive(Debug, Eq)
pub(all) struct MultiWorld {
  worlds : Array[ParaUniverse]
}

///|
/// Pointwise information-join fusion across all worlds: conflicting agent beliefs (Tv vs Fv)
/// elevate cleanly to `Bv` (quarantined contradiction) without corrupting orthogonal propositions!
pub fn MultiWorld::merge_pointwise(self : MultiWorld) -> Array[FourVal] {
  if self.worlds.length() == 0 {
    return []
  }
  let n = self.worlds[0].vals.length()
  Array::makei(n, i => {
    let mut acc = self.worlds[0].vals[i]
    for wi in 1..<self.worlds.length() {
      acc = FourVal::join(acc, self.worlds[wi].vals[i])
    }
    acc
  })
}
