///|
/// Module 18 (Unified from `algo8`, dualizing `universal_functor.mbt`):
/// Finite Categorical Limits — Terminal Object, Binary Product, Pullback & Endofunctor Laws
/// (有限範疇極限：終物件、乘積泛錐、拉回與笛卡爾函子律).
/// Together with `FinitePushout` and MGU coequalizers in `universal_functor.mbt`, equips
/// the framework with a finitely bicomplete category for goal decomposition & solution gluing!

///|
/// Finite skeletal category object tag `[n] = {0, ..., n - 1}` in FinSet.
#derive(Debug, Eq)
pub(all) struct Obj {
  tag : Int32
}

///|
/// Morphism f : [src] -> [dst] in FinSet represented by its explicit total function table.
#derive(Debug, Eq)
pub(all) struct Hom {
  src : Int32
  dst : Int32
  map : Array[Int32]
}

///|
/// Categorical diagram composition (f ; g) = g o f : f.src -> g.dst.
pub fn Hom::compose(f : Hom, g : Hom) -> Hom {
  { src: f.src, dst: g.dst, map: f.map.map(x => g.map[x]), }
}

///|
/// Identity morphism id_{[n]} : [n] -> [n].
pub fn Hom::identity(n : Int32) -> Hom {
  { src: n, dst: n, map: Array::makei(n, i => i), }
}

///|
/// Predicate testing whether f == id_{[src]}.
pub fn Hom::is_identity(f : Hom) -> Bool {
  if f.src != f.dst || f.map.length() != f.src {
    return false
  }
  for i in 0..<f.src {
    if f.map[i] != i {
      return false
    }
  }
  true
}

///|
/// Witness that any endo-morphism on terminal object 1 = [1] is the unique identity isomorphism.
pub fn terminal_is_unique_up_to_iso() -> Bool {
  let f : Hom = { src: 1, dst: 1, map: [0], }
  Hom::is_identity(f) && f.map.length() == 1
}

///|
/// Unique universal morphism !_n : [n] -> [1] into the terminal object 1.
pub fn terminal_unique_arrow(n : Int32) -> Hom {
  { src: n, dst: 1, map: Array::make(n, 0), }
}

///|
/// Cardinality |Hom_FinSet([n], [1])| = 1^n == 1 for all finite objects [n] (n >= 0).
pub fn count_terminal_arrows(n : Int32) -> Int32 {
  let out : Array[Array[Int32]] = []
  enumerate_funcs(n.min(8), 1, out)
  out.length()
}

///|
/// Binary cone (C, f : C -> A, g : C -> B) over discrete diagram (A, B).
#derive(Debug, Eq)
pub(all) struct Cone {
  c_size : Int32
  f : Array[Int32]
  g : Array[Int32]
}

///|
/// First product projection pi_1 : A x B -> A under canonical encoding (i, j) |-> i * |B| + j.
pub fn product_pi1(a_size : Int32, b_size : Int32) -> Hom {
  {
    src: a_size * b_size,
    dst: a_size,
    map: Array::makei(a_size * b_size, idx => idx / b_size),
  }
}

///|
/// Second product projection pi_2 : A x B -> B under canonical encoding (i, j) |-> i * |B| + j.
pub fn product_pi2(a_size : Int32, b_size : Int32) -> Hom {
  {
    src: a_size * b_size,
    dst: b_size,
    map: Array::makei(a_size * b_size, idx => idx % b_size),
  }
}

///|
/// Unique universal mediating morphism <f, g> : C -> A x B for `cone = (C, f, g)`.
pub fn pair(cone : Cone, a_size : Int32, b_size : Int32) -> Hom {
  {
    src: cone.c_size,
    dst: a_size * b_size,
    map: Array::makei(cone.c_size, x => cone.f[x] * b_size + cone.g[x]),
  }
}

///|
fn enumerate_funcs(n : Int32, m : Int32, out : Array[Array[Int32]]) -> Unit {
  if n == 0 {
    out.push([])
    return
  }
  let subs : Array[Array[Int32]] = []
  enumerate_funcs(n - 1, m, subs)
  for s in subs {
    for v in 0..<m {
      let cur = s.copy()
      cur.push(v)
      out.push(cur)
    }
  }
}

///|
/// Exhaustive decision procedure witnessing existence AND uniqueness of h = <f, g> : C -> A x B
/// satisfying pi_1 o h == f and pi_2 o h == g across ALL cones in Hom(C, A) x Hom(C, B).
pub fn universal_property_product_witness(
  a_size : Int32,
  b_size : Int32,
  c_size : Int32,
) -> Bool {
  let pi1 = product_pi1(a_size, b_size)
  let pi2 = product_pi2(a_size, b_size)
  let f_maps : Array[Array[Int32]] = []
  enumerate_funcs(c_size, a_size, f_maps)
  let g_maps : Array[Array[Int32]] = []
  enumerate_funcs(c_size, b_size, g_maps)
  let candidates : Array[Array[Int32]] = []
  enumerate_funcs(c_size, a_size * b_size, candidates)
  for fm in f_maps {
    let f_hom : Hom = { src: c_size, dst: a_size, map: fm, }
    for gm in g_maps {
      let g_hom : Hom = { src: c_size, dst: b_size, map: gm, }
      let cone : Cone = { c_size, f: fm, g: gm, }
      let h = pair(cone, a_size, b_size)
      if Hom::compose(h, pi1) != f_hom || Hom::compose(h, pi2) != g_hom {
        return false
      }
      for cand in candidates {
        let hp : Hom = { src: c_size, dst: a_size * b_size, map: cand, }
        if Hom::compose(hp, pi1) == f_hom &&
          Hom::compose(hp, pi2) == g_hom &&
          hp != h {
          return false
        }
      }
    }
  }
  true
}

///|
fn lift_with_k(f : Hom, k : Int32) -> Hom {
  let m : Array[Int32] = Array(capacity=f.src * k)
  for x in f.map {
    for t in 0..<k {
      m.push(x * k + t)
    }
  }
  { src: f.src * k, dst: f.dst * k, map: m, }
}

///|
/// Verify covariance laws F(id_A) == id_{F(A)} and F(g o f) == F(g) o F(f)
/// for the Cartesian product endofunctor F(-) = (-) x [k] : FinSet -> FinSet.
pub fn functor_laws_product_with_k(
  a_size : Int32,
  b_size : Int32,
  k : Int32,
) -> Bool {
  if !Hom::is_identity(lift_with_k(Hom::identity(a_size), k)) {
    return false
  }
  let f : Hom = {
    src: a_size,
    dst: b_size,
    map: Array::makei(a_size, i => i % b_size),
  }
  let g : Hom = {
    src: b_size,
    dst: a_size,
    map: Array::makei(b_size, i => i % a_size),
  }
  let left = lift_with_k(Hom::compose(f, g), k)
  let right = Hom::compose(lift_with_k(f, k), lift_with_k(g, k))
  left == right
}

///|
/// UNIVERSAL PULLBACK (FIBER PRODUCT LIMIT) A x_C B in FinSet (exact categorical dual of
/// `FinitePushout` in `universal_functor.mbt`):
/// Given a cospan A --f--> C <--g-- B, computes P = {(a, b) in A x B : f(a) == g(b)}
/// with projections (p_A : P -> A, p_B : P -> B) verifying f o p_A == g o p_B, and exposes
/// `mediating_map` constructing the unique arrow u : W -> P for any commuting cone!
#derive(Debug, Eq)
pub(all) struct FinitePullback {
  n_apex : Int32
  proj_a : Hom
  proj_b : Hom
}

///|
pub fn compute_finite_pullback(f : Hom, g : Hom) -> FinitePullback {
  let pa : Array[Int32] = []
  let pb : Array[Int32] = []
  for a in 0..<f.src {
    for b in 0..<g.src {
      if f.map[a] == g.map[b] {
        pa.push(a)
        pb.push(b)
      }
    }
  }
  let n = pa.length()
  {
    n_apex: n,
    proj_a: { src: n, dst: f.src, map: pa, },
    proj_b: { src: n, dst: g.src, map: pb, },
  }
}

///|
/// Unique universal mediating morphism u : W -> A x_C B for any cone (q_a : W -> A, q_b : W -> B)
/// satisfying f o q_a == g o q_b (returns Err if the cone violates fiber compatibility).
pub fn FinitePullback::mediating_map(
  self : FinitePullback,
  q_a : Hom,
  q_b : Hom,
) -> Result[Hom, String] {
  if q_a.src != q_b.src {
    return Err("Pullback cone source mismatch: \{q_a.src} != \{q_b.src}")
  }
  let out : Array[Int32] = Array(capacity=q_a.src)
  for w in 0..<q_a.src {
    let mut found = -1
    for p in 0..<self.n_apex {
      if self.proj_a.map[p] == q_a.map[w] && self.proj_b.map[p] == q_b.map[w] {
        found = p
        break
      }
    }
    if found < 0 {
      return Err(
        "Cone commutativity f(q_a(w)) == g(q_b(w)) violated at w = \{w}",
      )
    }
    out.push(found)
  }
  Ok({ src: q_a.src, dst: self.n_apex, map: out, })
}
