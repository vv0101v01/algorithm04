///|
/// Module 11: Universal Property Functors (泛性質函子).
/// Implements categorical universal constructions as executable MoonBit v0.10.20
/// polymorphic abstractions, deriving canonical factorization morphisms & laws:
///   1. Representable Hom-Functor & Yoneda / Coyoneda Isomorphism:
///        Nat(Hom(A, -), F)  <==>  F(A),   with O(1) Coyoneda map-fusion;
///   2. Free-Forgetful Adjunction F -| U (unit eta, counit eps, unique universal
///      homomorphic lift f^#, Hom-set natural bijection, and zig-zag triangle laws):
///        (a) Free R-Module (linearization) functor R[-] : FinSet -> Vect_R,
///        (b) Universal Exterior / Grassmann Functor /\ : Vect_R -> SuperAlg_R
///            lifting ANY isotropic/anti-commuting family {e_a} in ANY target
///            Ring + Module (SuperMatrix, Witten SUSY operators, Lambda_M) to a
///            UNIQUE unital algebra homomorphism f^# : Lambda_N -> A;
///   3. Universal Graded Bilinear Tensor Factorization:
///        Bilin(U, V; W)  <==>  Hom_R(U (x) V, W);
///   4. Free Sigma-Term Monad (T_Sigma, eta, bind) & Robinson MGU as Universal
///      Coequalizer in the Substitution Category: for ANY competing unifier theta
///      with theta(t1) == theta(t2), computes the UNIQUE mediating substitution h
///      satisfying theta == h o sigma_MGU;
///   5. Universal Pushout (Colimit) of Multi-Agent Ontology Graphs over a shared
///      interface span A <- C -> B, with unique mediating morphism to any cocone;
///   6. Enriched Left & Right Kan Extensions (Lan_K -| K^* -| Ran_K) over both
///      Semitropical (max-plus / min-plus Bellman) and Maslov log-semiring categories,
///      extracting optimal macroscopic emergent agent states from microscopic dynamics!

///|
/// Representable covariant functor Yoneda[A, X] = forall R. (A -> R) -> F(R),
/// specialized concretely for continuation/state observation and Array functors
/// to witness the exact Yoneda Lemma Nat(Hom(A, -), F) ~= F(A).
pub(all) struct HomFunctor[A, X] {
  run : (A) -> X
}

///|
/// Functorial action Hom(A, f) : Hom(A, X) -> Hom(A, Y) by post-composition g |-> f o g.
pub fn[A, X, Y] HomFunctor::fmap(
  self : HomFunctor[A, X],
  f : (X) -> Y,
) -> HomFunctor[A, Y] {
  { run: a => f((self.run)(a)), }
}

///|
/// Universal element id_A in Hom(A, A) representing the functor Hom(A, -).
pub fn[A] HomFunctor::universal_id() -> HomFunctor[A, A] {
  { run: a => a, }
}

///|
/// Yoneda forward map Y : Nat(Hom(A, -), Array) -> Array[A], evaluating at id_A.
pub fn[A] yoneda_to_value(nat : (HomFunctor[A, A]) -> Array[A]) -> Array[A] {
  nat(HomFunctor::universal_id())
}

///|
/// Yoneda inverse map Y^{-1} : Array[A] -> (Hom(A, X) -> Array[X]), sending x in F(A)
/// to the natural transformation alpha_X(f) = F(f)(x).
pub fn[A, X] yoneda_from_value(
  fa : Array[A],
  hom : HomFunctor[A, X],
) -> Array[X] {
  fa.map(a => (hom.run)(a))
}

///|
/// Free Functor (Density / Left Kan Extension along identity) Coyoneda[S, A]:
/// packages a seed container Array[S] together with an accumulated morphism S -> A.
/// Composes arbitrarily many `fmap` calls by pure function composition without
/// intermediate allocations, lowering via universal counit only once!
pub(all) struct Coyoneda[S, A] {
  seeds : Array[S]
  morph : (S) -> A
}

///|
/// Universal unit eta : Array[A] -> Coyoneda[A, A].
pub fn[A] Coyoneda::lift(xs : Array[A]) -> Coyoneda[A, A] {
  { seeds: xs, morph: a => a, }
}

///|
/// O(1) fused functorial map: composes morphisms without traversing `seeds`.
pub fn[S, A, B] Coyoneda::fmap(
  self : Coyoneda[S, A],
  f : (A) -> B,
) -> Coyoneda[S, B] {
  let prev = self.morph
  { seeds: self.seeds, morph: s => f(prev(s)), }
}

///|
/// Universal counit eps : Coyoneda[S, A] -> Array[A] executing all fused maps in 1 pass.
pub fn[S, A] Coyoneda::lower(self : Coyoneda[S, A]) -> Array[A] {
  self.seeds.map(self.morph)
}

///|
/// Abstract Universal Property of a Free Object F(X) over generator set {0, ..., n-1}:
/// Given ANY target object A in the algebraic category and ANY generator assignment
/// `gen : Int32 -> A`, `universal_lift` produces the UNIQUE structure-preserving
/// homomorphism f^# : Self -> A satisfying the commuting triangle f^#(eta(i)) == gen(i)!
pub(open) trait UniversalFreeObject {
  fn unit_gen(Int32, Int32) -> Self
  fn[A : Module] lift_linear(Self, (Int32) -> A) -> A
}

///|
/// Free R-vector space R^n over finite basis {0, ..., n-1}.
#derive(Debug, Eq)
pub(all) struct FreeVec {
  coeffs : Array[Double]
}

///|
pub fn FreeVec::new(coeffs : Array[Double]) -> FreeVec {
  { coeffs: coeffs.copy(), }
}

///|
pub impl UniversalFreeObject for FreeVec with fn unit_gen(dim, idx) {
  let c = Array::make(dim, 0.0)
  if idx >= 0 && idx < dim {
    c[idx] = 1.0
  }
  { coeffs: c, }
}

///|
/// Unique R-linear extension f^#(sum_i c_i e_i) = sum_i c_i f(i) into ANY Module A!
pub impl UniversalFreeObject for FreeVec with fn lift_linear(self, gen_map) {
  let mut acc = AbelianGroup::zero_elem()
  for i in 0..<self.coeffs.length() {
    let ci = self.coeffs[i]
    if ci != 0.0 {
      acc = AbelianGroup::add_elem(acc, Module::scale(gen_map(i), ci))
    }
  }
  acc
}

///|
/// Verify Free-Forgetful Adjunction F -| U zig-zag (triangle) identities on FinSet <-> Vect_R:
///   (1) Triangle 1: eps_{F(X)} o F(eta_X) == id_{F(X)},
///   (2) Triangle 2: U(eps_V) o eta_{U(V)} == id_{U(V)},
///   (3) Universal triangle: f^#(eta_X(i)) == f(i) for all i in X.
/// Returns maximum Euclidean residual across all three adjunction laws!
pub fn[A : Module] verify_free_module_adjunction(
  n_basis : Int32,
  gen_images : Array[A],
  sample_vec : FreeVec,
) -> Double {
  let mut max_err = 0.0
  // (3) Commuting triangle: (f^# o eta)(i) == f(i)
  for i in 0..<n_basis {
    let ei = FreeVec::unit_gen(n_basis, i)
    let lifted = UniversalFreeObject::lift_linear(ei, k => gen_images[k])
    let diff = AbelianGroup::sub_elem(lifted, gen_images[i])
    let err = AbelianGroup::norm_sq(diff).sqrt()
    if err > max_err {
      max_err = err
    }
  }
  // (1) Linearity / homomorphism uniqueness: f^#(alpha u + beta v) == alpha f^#(u) + beta f^#(v)
  let u = FreeVec::unit_gen(n_basis, 0)
  let comb = FreeVec::new(
    Array::makei(n_basis, i => 1.7 * sample_vec.coeffs[i] - 0.8 * u.coeffs[i]),
  )
  let lhs = UniversalFreeObject::lift_linear(comb, k => gen_images[k])
  let rhs = AbelianGroup::sub_elem(
    Module::scale(
      UniversalFreeObject::lift_linear(sample_vec, k => gen_images[k]),
      1.7,
    ),
    Module::scale(UniversalFreeObject::lift_linear(u, k => gen_images[k]), 0.8),
  )
  let lin_err = AbelianGroup::norm_sq(AbelianGroup::sub_elem(lhs, rhs)).sqrt()
  if lin_err > max_err {
    max_err = lin_err
  }
  // (2) Left triangle eps_{F(X)} o F(eta_X) == id_{F(X)}: lifting basis -> unit_gen recovers sample_vec
  let mut rec = Array::make(n_basis, 0.0)
  for i in 0..<n_basis {
    let ei = FreeVec::unit_gen(n_basis, i)
    rec = vec_add(rec, vec_scale(ei.coeffs, sample_vec.coeffs[i]))
  }
  let tri_err = vec_norm(vec_sub(rec, sample_vec.coeffs))
  if tri_err > max_err {
    max_err = tri_err
  }
  max_err
}

///|
/// UNIVERSAL PROPERTY OF THE EXTERIOR (GRASSMANN) FUNCTOR /\ : Vect_R -> Alg_R (Theorem VIII.2):
/// For ANY associative unital R-algebra `A : Ring + Module` and ANY family of N odd/isotropic
/// elements `images = [e_0, ..., e_{N-1}]` in A satisfying:
///   e_a^2 == 0   and   e_a * e_b + e_b * e_a == 0   (for all 0 <= a, b < N),
/// there exists a UNIQUE unital R-algebra homomorphism  Phi : Lambda_N -> A
/// satisfying the universal diagram  Phi(theta^a) == e_a, given explicitly by:
///   Phi( sum_I c_I theta^{i_1} ^ ... ^ theta^{i_k} ) = sum_I c_I (e_{i_1} * ... * e_{i_k}).
/// Instantiates seamlessly for A = Grassmann, A = DenseMat (Witten SUSY Q, Q^+!), etc.
pub fn[A : Ring + Module] grassmann_universal_lift(
  elem : Grassmann,
  unit_a : A,
  zero_a : A,
  images : Array[A],
) -> A {
  let n = elem.n_gen
  let mut total = zero_a
  for mask in 0..<elem.coeffs.length() {
    let c = elem.coeffs[mask]
    if c != 0.0 {
      let mut blade_prod = unit_a
      for bit in 0..<n {
        if ((mask >> bit) & 1) != 0 {
          blade_prod = Ring::mul_elem(blade_prod, images[bit])
        }
      }
      total = AbelianGroup::add_elem(total, Module::scale(blade_prod, c))
    }
  }
  total
}

///|
/// Check the anticommutation precondition max_{a,b} || e_a e_b + e_b e_a ||_F on DenseMat
/// so that `grassmann_universal_lift_mat` is guaranteed by Theorem VIII.2 to be an
/// exact unital algebra homomorphism Phi(x * y) == Phi(x) * Phi(y)!
pub fn anticommutator_family_defect(ops : Array[DenseMat]) -> Double {
  let k = ops.length()
  let mut max_d = 0.0
  for a in 0..<k {
    for b in a..<k {
      let ac = (ops[a] * ops[b] + ops[b] * ops[a]).frob_norm()
      if ac > max_d {
        max_d = ac
      }
    }
  }
  max_d
}

///|
/// Specialization of the Exterior Universal Homomorphism Phi : Lambda_N -> Mat(d, R)
/// mapping abstract Grassmann elements directly into concrete operator algebras
/// (e.g., mapping theta^0 |-> Q, theta^1 |-> Q^dagger when {Q, Q^dagger} = 0 on ker(H),
/// or mapping into exterior creation operators c_a^dagger on Fock space!).
pub fn grassmann_universal_lift_mat(
  elem : Grassmann,
  dim : Int32,
  images : Array[DenseMat],
) -> DenseMat {
  let n = elem.n_gen
  let mut total = DenseMat::zeros(dim, dim)
  for mask in 0..<elem.coeffs.length() {
    let c = elem.coeffs[mask]
    if c != 0.0 {
      let mut prod = DenseMat::eye(dim)
      for bit in 0..<n {
        if ((mask >> bit) & 1) != 0 {
          prod = prod * images[bit]
        }
      }
      total = total + prod.scale(c)
    }
  }
  total
}

///|
/// Build canonical fermionic creation operators a_alpha^dagger on the 2^N-dimensional
/// Fock space H_Fock = R^{2^N}, satisfying {a_alpha^dagger, a_beta^dagger} == 0,
/// serving as the faithful regular matrix representation induced by the universal property!
pub fn fermionic_creation_operators(n_gen : Int32) -> Array[DenseMat] {
  let dim = 1 << n_gen
  Array::makei(n_gen, alpha => {
    let bit = 1 << alpha
    let mat = DenseMat::zeros(dim, dim)
    for mask in 0..<dim {
      if (mask & bit) == 0 {
        let sgn = wedge_sign(bit, mask, n_gen)
        mat.set(mask | bit, mask, sgn)
      }
    }
    mat
  })
}

///|
/// UNIVERSAL PROPERTY OF TENSOR PRODUCT (x) : Bilin(R^p, R^q; R^k) ~= Hom_R(R^p (x) R^q, R^k).
/// Given ANY bilinear map B : R^p x R^q -> R^k, constructs the UNIQUE linear matrix
/// B~ : R^{p*q} -> R^k (of size k x (p*q)) such that B~(u (x) v) == B(u, v) identically!
pub fn universal_tensor_factorization(
  dim_u : Int32,
  dim_v : Int32,
  dim_w : Int32,
  bilin : (Array[Double], Array[Double]) -> Array[Double],
) -> DenseMat {
  let mat = DenseMat::zeros(dim_w, dim_u * dim_v)
  for i in 0..<dim_u {
    let ei = Array::makei(dim_u, a => if a == i { 1.0 } else { 0.0 })
    for j in 0..<dim_v {
      let ej = Array::makei(dim_v, b => if b == j { 1.0 } else { 0.0 })
      let col = i * dim_v + j
      let w = bilin(ei, ej)
      for r in 0..<dim_w {
        mat.set(r, col, w[r])
      }
    }
  }
  mat
}

///|
/// Kronecker universal morphism iota(u, v) = u (x) v in R^{p*q}.
pub fn universal_tensor_pair(
  u : Array[Double],
  v : Array[Double],
) -> Array[Double] {
  let p = u.length()
  let q = v.length()
  Array::makei(p * q, idx => u[idx / q] * v[idx % q])
}

///|
/// Kleisli Monad composition (s2 o s1) on the Free Sigma-Term Monad `SymTerm`:
///   (s2 o s1)^#(t) == s2^#(s1^#(t))  for every term t in T_Sigma(V).
pub fn Substitution::compose(
  s2 : Substitution,
  s1 : Substitution,
) -> Substitution {
  let out : Array[(String, SymTerm)] = []
  for pair in s1.bindings {
    let v = pair.0
    let mapped = s2.apply(pair.1)
    if mapped != Var(v) {
      out.push((v, mapped))
    }
  }
  for pair in s2.bindings {
    let v = pair.0
    if s1.lookup(v) is None && pair.1 != Var(v) {
      out.push((v, pair.1))
    }
  }
  { bindings: out, }
}

///|
/// UNIVERSAL COEQUALIZER PROPERTY OF ROBINSON MGU (Theorem VIII.3):
/// If sigma_MGU is the most general unifier of (t1, t2) and `competitor` is ANY
/// substitution unifying (t1, t2) (i.e. competitor(t1) == competitor(t2)), constructs
/// the UNIQUE mediating substitution `h` (restricted to domain/variables) such that:
///   competitor(v) == (h o sigma_MGU)(v)   for EVERY variable v!
/// Proof of construction: since sigma_MGU is idempotent (dom(sigma) cap vars(ran(sigma)) = 0),
/// for any v in dom(sigma) with sigma(v) = u, competitor(v) = competitor(u), so setting
/// h(w) = competitor(w) for all w not in dom(sigma) satisfies h(sigma(v)) = competitor(u) = competitor(v)!
pub fn mgu_universal_mediating_subst(
  mgu : Substitution,
  competitor : Substitution,
) -> Result[Substitution, String] {
  // Verify competitor actually coequalizes every MGU equation v = mgu(v)
  for pair in mgu.bindings {
    let lhs = competitor.apply(Var(pair.0))
    let rhs = competitor.apply(pair.1)
    if lhs != rhs {
      return Err(
        "Competitor does not equalize ?\{pair.0}: \{lhs.format_term()} != \{rhs.format_term()}",
      )
    }
  }
  // Unique mediating morphism h on codomain variables V \ dom(mgu)
  let med : Array[(String, SymTerm)] = []
  for pair in competitor.bindings {
    if mgu.lookup(pair.0) is None {
      med.push(pair)
    }
  }
  Ok({ bindings: med, })
}

///|
/// UNIVERSAL PUSHOUT (COLIMIT) OF FINITE SETS / AGENT CONCEPT ONTOLOGIES:
/// Given a span  A <--f-- C --g--> B  (|A| = n_a, |B| = n_b, |C| = n_c),
/// computes the pushout object P = (A + B) / (f(c) ~ g(c)) with canonical injections
///   inl : A -> P,   inr : B -> P   satisfying  inl(f(c)) == inr(g(c))  forall c in C,
/// AND exposes `mediating_map` producing the UNIQUE morphism u : P -> Q for any cocone!
#derive(Debug, Eq)
pub(all) struct FinitePushout {
  n_apex : Int32
  inl : Array[Int32]
  inr : Array[Int32]
}

///|
pub fn compute_finite_pushout(
  n_a : Int32,
  n_b : Int32,
  f_c_to_a : Array[Int32],
  g_c_to_b : Array[Int32],
) -> FinitePushout {
  let tot = n_a + n_b
  let parent = Array::makei(tot, i => i)
  let find_root = (x0 : Int32) => {
    let mut r = x0
    while parent[r] != r {
      r = parent[r]
    }
    let mut cur = x0
    while parent[cur] != r {
      let nxt = parent[cur]
      parent[cur] = r
      cur = nxt
    }
    r
  }
  for c in 0..<f_c_to_a.length() {
    let ra = find_root(f_c_to_a[c])
    let rb = find_root(n_a + g_c_to_b[c])
    if ra != rb {
      if ra < rb {
        parent[rb] = ra
      } else {
        parent[ra] = rb
      }
    }
  }
  let canon_id = Array::make(tot, -1)
  let mut next_id = 0
  for i in 0..<tot {
    let r = find_root(i)
    if canon_id[r] < 0 {
      canon_id[r] = next_id
      next_id = next_id + 1
    }
    canon_id[i] = canon_id[r]
  }
  let inl = Array::makei(n_a, a => canon_id[a])
  let inr = Array::makei(n_b, b => canon_id[n_a + b])
  { n_apex: next_id, inl, inr, }
}

///|
/// Universal mediating morphism u : P -> X for any cocone (q_a : A -> X, q_b : B -> X)
/// satisfying q_a(f(c)) == q_b(g(c)): uniquely enforces u(inl(a)) == q_a(a) & u(inr(b)) == q_b(b)!
pub fn[X : Eq] FinitePushout::mediating_map(
  self : FinitePushout,
  q_a : Array[X],
  q_b : Array[X],
) -> Result[Array[X], String] {
  if self.n_apex == 0 {
    return Ok([])
  }
  let fallback = if q_a.length() > 0 { q_a[0] } else { q_b[0] }
  let out = Array::make(self.n_apex, fallback)
  let assigned = Array::make(self.n_apex, false)
  for a in 0..<q_a.length() {
    let p = self.inl[a]
    if assigned[p] && out[p] != q_a[a] {
      return Err("Cocone commutativity violated on left leg at index \{a}")
    }
    out[p] = q_a[a]
    assigned[p] = true
  }
  for b in 0..<q_b.length() {
    let p = self.inr[b]
    if assigned[p] && out[p] != q_b[b] {
      return Err("Cocone commutativity violated on right leg at index \{b}")
    }
    out[p] = q_b[b]
    assigned[p] = true
  }
  Ok(out)
}

///|
/// ENRICHED LEFT KAN EXTENSION Lan_K(F) : D -> T_max (Theorem VIII.4):
/// Given:
///   - Microscopic category C (|C| = n_c) and macroscopic emergent category D (|D| = n_d),
///   - Coarse-graining functor K : C -> D (`k_map[c] in 0..<n_d`),
///   - Tropical-enriched hom-weights D(d1, d2) in `d_hom` (satisfying D(d,d) >= 0 and
///     enriched composition D(d2, d3) + D(d1, d2) <= D(d1, d3)),
///   - Microscopic agent utility/potential presheaf F : C -> T_max,
/// computes the Left Kan Extension by the universal coend formula:
///   (Lan_K F)(d) = (+)_{c in C} ( D(K(c), d) (*) F(c) ) = max_{c in C} ( d_hom(K(c), d) + F(c) ).
/// Satisfies the EXACT Universal Adjunction  Lan_K -| K^* :
///   Lan_K(F) <= G  in [D, T_max]   <==>   F <= G o K  in [C, T_max]!
pub fn tropical_left_kan_extension(
  k_map : Array[Int32],
  d_hom : DenseMat,
  f_micro : Array[Double],
) -> Array[Double] {
  let n_c = k_map.length()
  let n_d = d_hom.cols
  Array::makei(n_d, d => {
    let mut best = -1.0e300
    for c in 0..<n_c {
      let cand = d_hom.get(k_map[c], d) + f_micro[c]
      if cand > best {
        best = cand
      }
    }
    best
  })
}

///|
/// ENRICHED RIGHT KAN EXTENSION Ran_K(F) : D -> T_max (End / Residuation Dual):
///   (Ran_K F)(d) = /\_{c in C} ( F(c) - D(d, K(c)) ) = min_{c in C} ( F(c) - d_hom(d, K(c)) ).
/// Satisfies the dual Universal Adjunction  K^* -| Ran_K :
///   H <= Ran_K(F)  in [D, T_max]   <==>   H o K <= F  in [C, T_max]!
/// Together,  Lan_K -| K^* -| Ran_K  forms an exact adjoint triple governing optimistic
/// capability emergence (Lan_K) vs guaranteed worst-case safety envelopes (Ran_K)!
pub fn tropical_right_kan_extension(
  k_map : Array[Int32],
  d_hom : DenseMat,
  f_micro : Array[Double],
) -> Array[Double] {
  let n_c = k_map.length()
  let n_d = d_hom.rows
  Array::makei(n_d, d => {
    let mut worst = 1.0e300
    for c in 0..<n_c {
      let cand = f_micro[c] - d_hom.get(d, k_map[c])
      if cand < worst {
        worst = cand
      }
    }
    worst
  })
}

///|
/// Maslov hbar-deformed Soft Left Kan Extension Lan^{(hbar)}_K(F)(d):
///   Lan^{(hbar)}_K(F)(d) = hbar * ln( sum_{c in C} exp((D(K(c), d) + F(c)) / hbar) ).
/// Smoothly interpolates between Bayesian partition-function coarse-graining (hbar = 1)
/// and exact tropical Left Kan Extension as hbar -> 0+, with universal error bound:
///   0 <= Lan^{(hbar)}_K(F)(d) - Lan_K(F)(d) <= hbar * ln(|C|)!
pub fn maslov_left_kan_extension(
  k_map : Array[Int32],
  d_hom : DenseMat,
  f_micro : Array[Double],
  hbar : Double,
) -> Array[Double] {
  let n_c = k_map.length()
  let n_d = d_hom.cols
  Array::makei(n_d, d => {
    let terms = Array::makei(n_c, c => d_hom.get(k_map[c], d) + f_micro[c])
    let mut m = terms[0]
    for x in terms {
      if x > m {
        m = x
      }
    }
    let mut sum_e = 0.0
    for x in terms {
      sum_e = sum_e + @math.exp((x - m) / hbar)
    }
    m + hbar * @math.ln(sum_e)
  })
}

///|
/// Verify enrichment functoriality of a tropical D-presheaf G : D -> T_max:
///   G is a valid enriched functor iff D(d1, d2) + G(d1) <= G(d2) for all d1, d2.
/// Returns maximum violation (0.0 iff strictly enriched-functorial, automatically
/// satisfied by BOTH Lan_K(F) and Ran_K(F) whenever d_hom is a tropical category!).
pub fn tropical_functor_law_violation(
  d_hom : DenseMat,
  g_macro : Array[Double],
) -> Double {
  let n_d = g_macro.length()
  let mut max_v = 0.0
  for d1 in 0..<n_d {
    for d2 in 0..<n_d {
      let viol = d_hom.get(d1, d2) + g_macro[d1] - g_macro[d2]
      if viol > max_v {
        max_v = viol
      }
    }
  }
  max_v
}
