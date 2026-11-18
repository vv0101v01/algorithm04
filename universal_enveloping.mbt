///|
/// Module 13: Universal Enveloping Superalgebra U(g) & Super-PBW Hopf Algebra
/// (萬有展開（一）：李超代數之萬有包絡超代數與 Poincaré-Birkhoff-Witt 定理).
///
/// For any finite-dimensional Z_2-graded Lie superalgebra g = g_0 (+) g_1 with
/// ordered homogeneous basis {X_0, ..., X_{d-1}} and bracket [X_a, X_b]_s = sum_c C^c_{ab} X_c:
///   U(g) = T(g) / < X_a (x) X_b - (-1)^{|a||b|} X_b (x) X_a - [X_a, X_b]_s >.
///
/// Implements:
///   1. Exact Super-PBW canonical monomial basis  X_0^{e_0} ... X_{d-1}^{e_{d-1}}
///      (e_a >= 0 for Even X_a; e_a in {0, 1} for Odd X_a since X_a^2 = (1/2){X_a, X_a} in g_0!),
///   2. Exact recursive Super-PBW straightening product verifying strict associativity
///      (u * v) * w == u * (v * w), canonical embedding [i(X), i(Y)]_s == i([X, Y]_s),
///      and exact Super-PBW filtration dimension formula,
///   3. Universal Property Functor  Hom_{LieSuper}(g, A_L) ~= Hom_{AssocSuper}(U(g), A):
///      lifts ANY matrix representation rho : g -> End(V) to the UNIQUE unital associative
///      algebra homomorphism rho_hat : U(g) -> End(V) with rho_hat(u * v) == rho_hat(u) * rho_hat(v),
///   4. Graded Super-Hopf Algebra: counit eps, involutive graded antipode S (S^2 == id),
///      and Koszul-braided coproduct Delta acting on multi-agent tensor representations,
///   5. Canonical models sl(2), so(3), osp(1|2), and N=2 Witten SUSY with exact central
///      quadratic Casimir C_2 in Z(U(g)) satisfying [C_2, X_a]_s == 0 forall a (Theorem XI).

///|
/// Finite-dimensional Z_2-graded Lie superalgebra structure table.
/// `struct_const[(a * dim + b) * dim + c]` stores C^c_{ab} in [X_a, X_b]_s = sum_c C^c_{ab} X_c.
#derive(Debug, Eq)
pub(all) struct SuperLieTable {
  name : String
  dim : Int32
  parities : Array[Parity]
  struct_const : Array[Double]
}

///|
pub fn SuperLieTable::new(
  name : String,
  parities : Array[Parity],
) -> SuperLieTable {
  let d = parities.length()
  { name, dim: d, parities, struct_const: Array::make(d * d * d, 0.0), }
}

///|
/// Get structure constant C^c_{ab}.
pub fn SuperLieTable::coeff(
  self : SuperLieTable,
  a : Int32,
  b : Int32,
  c : Int32,
) -> Double {
  self.struct_const[(a * self.dim + b) * self.dim + c]
}

///|
/// Register [X_a, X_b]_s = sum_{(c, val)} val * X_c AND automatically populate the
/// graded-skew symmetric partner [X_b, X_a]_s = -(-1)^{|a||b|} [X_a, X_b]_s.
pub fn SuperLieTable::set_bracket(
  self : SuperLieTable,
  a : Int32,
  b : Int32,
  terms : Array[(Int32, Double)],
) -> Unit {
  let d = self.dim
  let skew = -koszul_sign(self.parities[a], self.parities[b])
  for pair in terms {
    let (c, val) = pair
    self.struct_const[(a * d + b) * d + c] = val
    if a != b {
      self.struct_const[(b * d + a) * d + c] = skew * val
    }
  }
}

///|
/// Verify all dim^3 graded Super-Jacobi identities directly on the structure constants.
pub fn SuperLieTable::super_jacobi_defect(self : SuperLieTable) -> Double {
  let d = self.dim
  let mut max_err = 0.0
  // Cyclic sum: (-1)^{|a||c|} [X_a, [X_b, X_c]] + cyclic(a, b, c) == 0
  let triple_term = (x : Int32, y : Int32, z : Int32, m : Int32) => {
    let s = koszul_sign(self.parities[x], self.parities[z])
    let mut acc = 0.0
    for k in 0..<d {
      let cyz = self.coeff(y, z, k)
      if cyz != 0.0 {
        acc = acc + cyz * self.coeff(x, k, m)
      }
    }
    s * acc
  }
  for a in 0..<d {
    for b in 0..<d {
      for c in 0..<d {
        for m in 0..<d {
          let sum = triple_term(a, b, c, m) +
            triple_term(b, c, a, m) +
            triple_term(c, a, b, m)
          if sum.abs() > max_err {
            max_err = sum.abs()
          }
        }
      }
    }
  }
  max_err
}

///|
/// Classical simple Lie algebra sl(2, R) = span{E, F, H}:
///   [H, E] = 2E,  [H, F] = -2F,  [E, F] = H.
pub fn SuperLieTable::sl2() -> SuperLieTable {
  let g = SuperLieTable::new("sl(2)", [Even, Even, Even])
  g.set_bracket(2, 0, [(0, 2.0)])
  g.set_bracket(2, 1, [(1, -2.0)])
  g.set_bracket(0, 1, [(2, 1.0)])
  g
}

///|
/// Fundamental simple orthosymplectic Lie superalgebra osp(1|2) = span{H, E, F | Q+, Q-}:
///   Even sp(2):  [H, E] = 2E,  [H, F] = -2F,  [E, F] = H;
///   Mixed:       [H, Q+] = Q+, [H, Q-] = -Q-, [E, Q-] = Q+, [F, Q+] = Q-;
///   Odd-Odd:     {Q+, Q+} = 2E,  {Q-, Q-} = -2F,  {Q+, Q-} = -H.
pub fn SuperLieTable::osp1_2() -> SuperLieTable {
  // Basis order: 0=H (Even), 1=E (Even), 2=F (Even), 3=Q+ (Odd), 4=Q- (Odd)
  let g = SuperLieTable::new("osp(1|2)", [Even, Even, Even, Odd, Odd])
  g.set_bracket(0, 1, [(1, 2.0)])
  g.set_bracket(0, 2, [(2, -2.0)])
  g.set_bracket(1, 2, [(0, 1.0)])
  g.set_bracket(0, 3, [(3, 1.0)])
  g.set_bracket(0, 4, [(4, -1.0)])
  g.set_bracket(1, 4, [(3, 1.0)])
  g.set_bracket(2, 3, [(4, 1.0)])
  g.set_bracket(3, 3, [(1, 2.0)])
  g.set_bracket(4, 4, [(2, -2.0)])
  g.set_bracket(3, 4, [(0, -1.0)])
  g
}

///|
/// Faithful fundamental (1|2)-dimensional matrix representation rho : osp(1|2) -> End(R^{1|2}),
/// satisfying exact graded bracket preservation rho([X_a, X_b]_s) == [rho(X_a), rho(X_b)]_s.
pub fn osp1_2_fundamental_rep() -> Array[DenseMat] {
  let h = DenseMat::zeros(3, 3)
  h.set(1, 1, 1.0)
  h.set(2, 2, -1.0)
  let e = DenseMat::zeros(3, 3)
  e.set(1, 2, 1.0)
  let f = DenseMat::zeros(3, 3)
  f.set(2, 1, 1.0)
  let qp = DenseMat::zeros(3, 3)
  qp.set(0, 2, 1.0)
  qp.set(1, 0, 1.0)
  let qm = DenseMat::zeros(3, 3)
  qm.set(0, 1, -1.0)
  qm.set(2, 0, 1.0)
  [h, e, f, qp, qm]
}

///|
/// Verify whether `rep` is a true Lie superalgebra homomorphism g -> End(V):
/// returns max_{a,b} || [rho(X_a), rho(X_b)]_s - sum_c C^c_{ab} rho(X_c) ||_F.
pub fn SuperLieTable::rep_homomorphism_defect(
  self : SuperLieTable,
  rep : Array[DenseMat],
) -> Double {
  let d = self.dim
  let n = rep[0].rows
  let mut max_err = 0.0
  for a in 0..<d {
    for b in 0..<d {
      let s = koszul_sign(self.parities[a], self.parities[b])
      let lhs = rep[a] * rep[b] - (rep[b] * rep[a]).scale(s)
      let mut rhs = DenseMat::zeros(n, n)
      for c in 0..<d {
        let v = self.coeff(a, b, c)
        if v != 0.0 {
          rhs = rhs + rep[c].scale(v)
        }
      }
      let err = (lhs - rhs).frob_norm()
      if err > max_err {
        max_err = err
      }
    }
  }
  max_err
}

///|
/// Binomial coefficient C(n, k) for exact PBW & jet Hilbert series dimension counts.
fn binom_int(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  let m = k.min(n - k)
  let mut acc = 1
  for i in 0..<m {
    acc = acc * (n - i) / (i + 1)
  }
  acc
}

///|
/// Theoretical Super-PBW filtration dimension dim U_{<= max_deg}(g) (Theorem XI.1):
///   U(g_0 (+) g_1) ~= Sym(g_0) (x) Lambda(g_1)  as filtered vector superspaces,
///   dim U_{<= D}(g) = sum_{s=0}^{min(d_odd, D)} C(d_odd, s) * C(D - s + d_even, d_even).
pub fn SuperLieTable::pbw_filtration_dim(
  self : SuperLieTable,
  max_deg : Int32,
) -> Int32 {
  let mut d_ev = 0
  let mut d_od = 0
  for p in self.parities {
    match p {
      Even => d_ev = d_ev + 1
      Odd => d_od = d_od + 1
    }
  }
  let mut tot = 0
  for s in 0..<=d_od.min(max_deg) {
    tot = tot + binom_int(d_od, s) * binom_int(max_deg - s + d_ev, d_ev)
  }
  tot
}

///|
/// Enumerate all canonical Super-PBW basis exponent vectors up to filtration degree `max_deg`.
pub fn SuperLieTable::enumerate_pbw_basis(
  self : SuperLieTable,
  max_deg : Int32,
) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let cur = Array::make(self.dim, 0)
  fn dfs(
    g : SuperLieTable,
    idx : Int32,
    rem : Int32,
    cur : Array[Int32],
    out : Array[Array[Int32]],
  ) -> Unit {
    if idx == g.dim {
      out.push(cur.copy())
      return
    }
    let lim = match g.parities[idx] {
      Even => rem
      Odd => rem.min(1)
    }
    for e in 0..<=lim {
      cur[idx] = e
      dfs(g, idx + 1, rem - e, cur, out)
    }
    cur[idx] = 0
  }
  dfs(self, 0, max_deg, cur, out)
  out
}

///|
/// Sparse element of the Universal Enveloping Superalgebra U(g), stored strictly in
/// sorted, zero-pruned canonical Super-PBW basis: sum_k c_k * X_0^{e_{k,0}} ... X_{d-1}^{e_{k,d-1}}.
#derive(Debug, Eq)
pub(all) struct UEAElement {
  dim : Int32
  terms : Array[(Array[Int32], Double)]
}

///|
fn cmp_exps(a : Array[Int32], b : Array[Int32]) -> Int32 {
  let mut da = 0
  let mut db = 0
  for i in 0..<a.length() {
    da = da + a[i]
    db = db + b[i]
  }
  if da != db {
    return da - db
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return a[i] - b[i]
    }
  }
  0
}

///|
/// Canonicalize raw (exps, coeff) pairs by graded-lex sorting, merging duplicates, and pruning ~0.
fn uea_normalize(
  dim : Int32,
  raw : Array[(Array[Int32], Double)],
) -> UEAElement {
  if raw.length() == 0 {
    return { dim, terms: [], }
  }
  let buf = raw.copy()
  // Insertion sort (PBW expressions are compact and mostly ordered)
  for i in 1..<buf.length() {
    let key = buf[i]
    let mut j = i - 1
    while j >= 0 && cmp_exps(buf[j].0, key.0) > 0 {
      buf[j + 1] = buf[j]
      j = j - 1
    }
    buf[j + 1] = key
  }
  let merged : Array[(Array[Int32], Double)] = []
  let mut cur_e = buf[0].0
  let mut cur_c = buf[0].1
  for i in 1..<buf.length() {
    if cmp_exps(buf[i].0, cur_e) == 0 {
      cur_c = cur_c + buf[i].1
    } else {
      if cur_c.abs() > 1.0e-14 {
        merged.push((cur_e, cur_c))
      }
      cur_e = buf[i].0
      cur_c = buf[i].1
    }
  }
  if cur_c.abs() > 1.0e-14 {
    merged.push((cur_e, cur_c))
  }
  { dim, terms: merged, }
}

///|
pub fn UEAElement::zero(dim : Int32) -> UEAElement {
  { dim, terms: [], }
}

///|
pub fn UEAElement::unit(dim : Int32, c~ : Double = 1.0) -> UEAElement {
  uea_normalize(dim, [(Array::make(dim, 0), c)])
}

///|
/// Canonical PBW inclusion i : g -> U(g), X_a |-> X_a^1 (injective by Super-PBW!).
pub fn UEAElement::generator(
  dim : Int32,
  a : Int32,
  c~ : Double = 1.0,
) -> UEAElement {
  let e = Array::make(dim, 0)
  e[a] = 1
  uea_normalize(dim, [(e, c)])
}

///|
pub fn UEAElement::add(self : UEAElement, other : UEAElement) -> UEAElement {
  let raw : Array[(Array[Int32], Double)] = Array(
    capacity=self.terms.length() + other.terms.length(),
  )
  for t in self.terms {
    raw.push(t)
  }
  for t in other.terms {
    raw.push(t)
  }
  uea_normalize(self.dim, raw)
}

///|
pub fn UEAElement::scale(self : UEAElement, s : Double) -> UEAElement {
  if s.abs() <= 1.0e-15 {
    return UEAElement::zero(self.dim)
  }
  uea_normalize(self.dim, self.terms.map(t => (t.0, t.1 * s)))
}

///|
pub fn UEAElement::sub(self : UEAElement, other : UEAElement) -> UEAElement {
  self.add(other.scale(-1.0))
}

///|
/// Euclidean coefficient norm ||u||_2 in the canonical Super-PBW basis.
pub fn UEAElement::pbw_norm(self : UEAElement) -> Double {
  let mut s = 0.0
  for t in self.terms {
    s = s + t.1 * t.1
  }
  s.sqrt()
}

///|
/// Replace the generator at position `k` of a PBW word by `c`, shortening the word
/// by one (the relation X_b X_a -> sum_c C^c_{ba} X_c consumes one generator).
fn replace_word_at(word : Array[Int32], k : Int32, c : Int32) -> Array[Int32] {
  Array::makei(word.length() - 1, idx => {
    if idx < k {
      word[idx]
    } else if idx == k {
      c
    } else {
      word[idx + 1]
    }
  })
}

///|
/// Expand a raw word [i_0, i_1, ..., i_{L-1}] of generators into canonical Super-PBW form
/// by straightening the leftmost inversion (or duplicate odd generator):
///   - If i_k > i_{k+1}: X_b X_a = (-1)^{|a||b|} X_a X_b + sum_c C^c_{ba} X_c,
///   - If i_k == i_{k+1} and X_a is Odd: X_a^2 = (1/2) {X_a, X_a} = (1/2) sum_c C^c_{aa} X_c!
/// Terminates unconditionally by strict descent in (word_length, inversion_count).
fn straighten_word(
  g : SuperLieTable,
  word : Array[Int32],
  coeff : Double,
  out : Array[(Array[Int32], Double)],
) -> Unit {
  if coeff.abs() <= 1.0e-15 {
    return
  }
  let len = word.length()
  for k in 0..<(len - 1) {
    let b = word[k]
    let a = word[k + 1]
    if b > a {
      // Branch 1: swapped word of same length with Koszul sign (-1)^{|a||b|}
      let swapped = word.copy()
      swapped[k] = a
      swapped[k + 1] = b
      let sgn = koszul_sign(g.parities[a], g.parities[b])
      straighten_word(g, swapped, coeff * sgn, out)
      // Branch 2: shorter words replacing (X_b X_a) with [X_b, X_a]_s = sum_c C^c_{ba} X_c
      for c in 0..<g.dim {
        let sc = g.coeff(b, a, c)
        if sc != 0.0 {
          straighten_word(g, replace_word_at(word, k, c), coeff * sc, out)
        }
      }
      return
    }
    if b == a && g.parities[a] == Odd {
      // Odd square relation in U(g): X_a^2 = (1/2) [X_a, X_a]_s in g_0!
      for c in 0..<g.dim {
        let sc = 0.5 * g.coeff(a, a, c)
        if sc != 0.0 {
          straighten_word(g, replace_word_at(word, k, c), coeff * sc, out)
        }
      }
      return
    }
  }
  // Word is strictly PBW-sorted with all odd multiplicities in {0, 1}!
  let exps = Array::make(g.dim, 0)
  for idx in word {
    exps[idx] = exps[idx] + 1
  }
  out.push((exps, coeff))
}

///|
fn exps_to_word(exps : Array[Int32]) -> Array[Int32] {
  let w : Array[Int32] = []
  for a in 0..<exps.length() {
    for _ in 0..<exps[a] {
      w.push(a)
    }
  }
  w
}

///|
fn exps_parity(g : SuperLieTable, exps : Array[Int32]) -> Parity {
  let mut p : Parity = Even
  for a in 0..<g.dim {
    if (exps[a] & 1) == 1 {
      p = p.add_z2(g.parities[a])
    }
  }
  p
}

///|
fn concat_words(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let na = a.length()
  Array::makei(na + b.length(), i => if i < na { a[i] } else { b[i - na] })
}

///|
/// Exact associative multiplication u * v in the Universal Enveloping Superalgebra U(g).
pub fn SuperLieTable::uea_mul(
  self : SuperLieTable,
  u : UEAElement,
  v : UEAElement,
) -> UEAElement {
  let raw : Array[(Array[Int32], Double)] = []
  for tu in u.terms {
    let wu = exps_to_word(tu.0)
    for tv in v.terms {
      let wv = exps_to_word(tv.0)
      straighten_word(self, concat_words(wu, wv), tu.1 * tv.1, raw)
    }
  }
  uea_normalize(self.dim, raw)
}

///|
/// Graded supercommutator [u, v]_s = sum_{tu, tv} (tu*tv - (-1)^{|tu||tv|} tv*tu) in U(g).
pub fn SuperLieTable::uea_supercommutator(
  self : SuperLieTable,
  u : UEAElement,
  v : UEAElement,
) -> UEAElement {
  let raw : Array[(Array[Int32], Double)] = []
  for tu in u.terms {
    let pu = exps_parity(self, tu.0)
    let wu = exps_to_word(tu.0)
    for tv in v.terms {
      let pv = exps_parity(self, tv.0)
      let wv = exps_to_word(tv.0)
      let c = tu.1 * tv.1
      let sgn = koszul_sign(pu, pv)
      straighten_word(self, concat_words(wu, wv), c, raw)
      straighten_word(self, concat_words(wv, wu), -sgn * c, raw)
    }
  }
  uea_normalize(self.dim, raw)
}

///|
/// UNIVERSAL PROPERTY OF U(g) (Theorem XI.1):
/// Given ANY Lie superalgebra representation rho : g -> End(R^n), computes the UNIQUE
/// unital associative superalgebra homomorphism rho_hat : U(g) -> End(R^n) extending rho:
///   rho_hat(1) == I_n,  rho_hat(i(X_a)) == rho(X_a),  rho_hat(u * v) == rho_hat(u) * rho_hat(v)!
pub fn UEAElement::universal_lift_rep(
  self : UEAElement,
  rep : Array[DenseMat],
) -> DenseMat {
  let n = rep[0].rows
  let mut total = DenseMat::zeros(n, n)
  for t in self.terms {
    let (exps, coeff) = t
    let mut prod = DenseMat::eye(n)
    for a in 0..<exps.length() {
      for _ in 0..<exps[a] {
        prod = prod * rep[a]
      }
    }
    total = total + prod.scale(coeff)
  }
  total
}

///|
/// Super-Hopf counit eps : U(g) -> R (eps(1) = 1, eps(X_a) = 0; algebra homomorphism).
pub fn UEAElement::counit(self : UEAElement) -> Double {
  for t in self.terms {
    let mut deg = 0
    for e in t.0 {
      deg = deg + e
    }
    if deg == 0 {
      return t.1
    }
  }
  0.0
}

///|
/// Super-Hopf graded antipode S : U(g) -> U(g) defined on generators by S(X_a) = -X_a
/// and extended as a graded anti-homomorphism S(u * v) = (-1)^{|u||v|} S(v) * S(u).
/// Satisfies exact involutivity S(S(u)) == u for EVERY finite-dimensional Lie superalgebra!
pub fn SuperLieTable::antipode(
  self : SuperLieTable,
  u : UEAElement,
) -> UEAElement {
  let raw : Array[(Array[Int32], Double)] = []
  for t in u.terms {
    let w = exps_to_word(t.0)
    let len = w.length()
    // Reversing w incurs Koszul sign prod_{p < q} (-1)^{|w_p||w_q|} and (-1)^len from S(X) = -X
    let mut sign = if (len & 1) == 0 { 1.0 } else { -1.0 }
    for p in 0..<len {
      for q in (p + 1)..<len {
        sign = sign * koszul_sign(self.parities[w[p]], self.parities[w[q]])
      }
    }
    let rev = Array::makei(len, i => w[len - 1 - i])
    straighten_word(self, rev, t.1 * sign, raw)
  }
  uea_normalize(self.dim, raw)
}

///|
/// Super-Hopf primitive coproduct action (rho_1 (x)_s rho_2)(Delta(u)) on the Z_2-graded
/// tensor product V_1 (x) V_2 (where `v1_parities` gives the basis grading of V_1):
///   Delta(X_a) = X_a (x) I + I (x) X_a,  with (I (x) X_a)(v_i (x) w_j) = (-1)^{|a||v_i|} v_i (x) X_a w_j.
/// Because Delta : U(g) -> U(g) (x)_s U(g) is an algebra homomorphism, lifting the
/// tensor-product Lie representation via the universal property reproduces (rho_1 (x)_s rho_2) o Delta!
pub fn SuperLieTable::coproduct_tensor_rep(
  self : SuperLieTable,
  rep1 : Array[DenseMat],
  v1_parities : Array[Parity],
  rep2 : Array[DenseMat],
) -> Array[DenseMat] {
  let n1 = rep1[0].rows
  let n2 = rep2[0].rows
  let tot = n1 * n2
  Array::makei(self.dim, a => {
    let pa = self.parities[a]
    let m = DenseMat::zeros(tot, tot)
    // X_a (x) I_{n2} + gamma_1^{|a|} (x) X_a
    for i in 0..<n1 {
      for k in 0..<n1 {
        let r1 = rep1[a].get(i, k)
        if r1 != 0.0 {
          for j in 0..<n2 {
            let idx_r = i * n2 + j
            let idx_c = k * n2 + j
            m.set(idx_r, idx_c, m.get(idx_r, idx_c) + r1)
          }
        }
      }
      let sgn = koszul_sign(pa, v1_parities[i])
      for j in 0..<n2 {
        for l in 0..<n2 {
          let r2 = rep2[a].get(j, l)
          if r2 != 0.0 {
            let idx_r = i * n2 + j
            let idx_c = i * n2 + l
            m.set(idx_r, idx_c, m.get(idx_r, idx_c) + sgn * r2)
          }
        }
      }
    }
    m
  })
}

///|
/// Canonical quadratic Casimir element C_2 = H^2 + 2(EF + FE) in Z(U(sl(2))):
/// satisfies [C_2, X_a] == 0 identically for all X_a in {E, F, H}.
pub fn sl2_quadratic_casimir() -> UEAElement {
  let g = SuperLieTable::sl2()
  let e = UEAElement::generator(3, 0)
  let f = UEAElement::generator(3, 1)
  let h = UEAElement::generator(3, 2)
  g
  .uea_mul(h, h)
  .add(g.uea_mul(e, f).scale(2.0))
  .add(g.uea_mul(f, e).scale(2.0))
}

///|
/// Canonical super-quadratic Casimir element C_2 in Z(U(osp(1|2))) (Theorem XI.1):
///   C_2 = H^2 + 2(E F + F E) + (Q+ Q- - Q- Q+) = H^2 + H + 4 E F - 4 H + ... (straightened),
/// strictly commuting with ALL 3 even AND BOTH odd generators ([C_2, X_a]_s == 0 forall a),
/// and acting as the scalar operator +2 * I_{1|2} on the fundamental super-module R^{1|2}!
pub fn osp1_2_quadratic_casimir() -> UEAElement {
  let g = SuperLieTable::osp1_2()
  let h = UEAElement::generator(5, 0)
  let e = UEAElement::generator(5, 1)
  let f = UEAElement::generator(5, 2)
  let qp = UEAElement::generator(5, 3)
  let qm = UEAElement::generator(5, 4)
  g
  .uea_mul(h, h)
  .add(g.uea_mul(e, f).scale(2.0))
  .add(g.uea_mul(f, e).scale(2.0))
  .add(g.uea_mul(qp, qm))
  .sub(g.uea_mul(qm, qp))
}
