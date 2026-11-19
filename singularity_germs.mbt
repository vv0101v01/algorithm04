///|
/// Module 14: Singularity Theory & Analytic Space Germs (奇點論與解析空間胚統一引擎):
///   - (12b) 萬有展開 / 萬有開折 (Thom-Mather Universal K-Unfolding F(x, u) = f(x) + sum u_a phi_a(x)),
///   - (13)  胚的接觸等價性 (Mather Contact K-Equivalence g(x) = M(x) * f(phi(x)), Milnor vs Tjurina),
///   - (14)  完備相交胚 (Isolated Complete Intersection Singularity ICIS: Koszul acyclicity,
///           Le-Greuel Milnor formula, 0D Gorenstein 1D Jacobian socle & Grothendieck pairing),
///   - (15)  正規環胚 (Normal Ring Germ: Serre's R_1 + S_2 criterion, integral closure normalization
///           O_{X,0} -> C{t}, Frobenius conductor ideal, delta-invariant, Gorenstein semigroup
///           symmetry, and Milnor-Jung theorem mu = 2 delta - r + 1),
///   - (18)  等價類映射胚 (Filtered-colimit stalk equivalence lim_{U ni x_0}, jet functoriality
///           j^k(g o f) == j^k(g) o_k j^k(f), universal quotient-germ descent h = h_bar o pi,
///           and Mather ADE K-equivalence-class normal-form classifier).

///|
/// Graded-lexicographic monomial basis of the truncated local power series algebra
/// O_n^{(k)} = R[x_0, ..., x_{n-1}] / m_n^{k+1}, of exact dimension C(n + k, k).
#derive(Debug, Eq)
pub(all) struct JetBasis {
  n_vars : Int32
  max_deg : Int32
  monoms : Array[Array[Int32]]
}

///|
pub fn JetBasis::new(n_vars : Int32, max_deg : Int32) -> JetBasis {
  let monoms : Array[Array[Int32]] = []
  let cur = Array::make(n_vars, 0)
  fn gen_deg(
    n : Int32,
    idx : Int32,
    rem : Int32,
    cur : Array[Int32],
    out : Array[Array[Int32]],
  ) -> Unit {
    if idx == n - 1 {
      cur[idx] = rem
      out.push(cur.copy())
      cur[idx] = 0
      return
    }
    for e in rem>=..0 {
      cur[idx] = e
      gen_deg(n, idx + 1, rem - e, cur, out)
    }
    cur[idx] = 0
  }
  if n_vars == 0 {
    monoms.push([])
  } else {
    for d in 0..<=max_deg {
      gen_deg(n_vars, 0, d, cur, monoms)
    }
  }
  { n_vars, max_deg, monoms, }
}

///|
pub fn JetBasis::dim(self : JetBasis) -> Int32 {
  self.monoms.length()
}

///|
pub fn monom_deg(exps : Array[Int32]) -> Int32 {
  let mut d = 0
  for e in exps {
    d = d + e
  }
  d
}

///|
/// Locate exact index of exponent vector `exps` in `self.monoms` (-1 if deg > max_deg).
pub fn JetBasis::index_of(self : JetBasis, exps : Array[Int32]) -> Int32 {
  if monom_deg(exps) > self.max_deg {
    return -1
  }
  for idx in 0..<self.monoms.length() {
    let m = self.monoms[idx]
    let mut same = true
    for v in 0..<self.n_vars {
      if m[v] != exps[v] {
        same = false
        break
      }
    }
    if same {
      return idx
    }
  }
  -1
}

///|
/// Scalar analytic function germ f in O_{n, 0} truncated at jet order `max_deg`.
#derive(Debug, Eq)
pub(all) struct PolyGerm {
  basis : JetBasis
  coeffs : Array[Double]
}

///|
pub fn PolyGerm::zero(basis : JetBasis) -> PolyGerm {
  { basis, coeffs: Array::make(basis.dim(), 0.0), }
}

///|
pub fn PolyGerm::constant(basis : JetBasis, c : Double) -> PolyGerm {
  let g = PolyGerm::zero(basis)
  g.coeffs[0] = c
  g
}

///|
pub fn PolyGerm::coord(basis : JetBasis, var_idx : Int32) -> PolyGerm {
  let exps = Array::make(basis.n_vars, 0)
  exps[var_idx] = 1
  PolyGerm::monomial(basis, exps, 1.0)
}

///|
pub fn PolyGerm::monomial(
  basis : JetBasis,
  exps : Array[Int32],
  coeff : Double,
) -> PolyGerm {
  let g = PolyGerm::zero(basis)
  let idx = basis.index_of(exps)
  if idx >= 0 {
    g.coeffs[idx] = coeff
  }
  g
}

///|
pub fn PolyGerm::from_terms(
  basis : JetBasis,
  terms : Array[(Array[Int32], Double)],
) -> PolyGerm {
  let g = PolyGerm::zero(basis)
  for pair in terms {
    let idx = basis.index_of(pair.0)
    if idx >= 0 {
      g.coeffs[idx] = g.coeffs[idx] + pair.1
    }
  }
  g
}

///|
pub fn PolyGerm::add(self : PolyGerm, other : PolyGerm) -> PolyGerm {
  { basis: self.basis, coeffs: vec_add(self.coeffs, other.coeffs), }
}

///|
pub fn PolyGerm::sub(self : PolyGerm, other : PolyGerm) -> PolyGerm {
  { basis: self.basis, coeffs: vec_sub(self.coeffs, other.coeffs), }
}

///|
pub fn PolyGerm::scale(self : PolyGerm, s : Double) -> PolyGerm {
  { basis: self.basis, coeffs: vec_scale(self.coeffs, s), }
}

///|
pub fn PolyGerm::jet_norm(self : PolyGerm) -> Double {
  vec_norm(self.coeffs)
}

///|
/// Value f(0) in R; f lies in maximal ideal m_n iff f(0) == 0, and in O_{n,0}^x iff f(0) != 0.
pub fn PolyGerm::val_at_origin(self : PolyGerm) -> Double {
  self.coeffs[0]
}

///|
/// Evaluate representative polynomial at a point x in R^n.
pub fn PolyGerm::eval(self : PolyGerm, x : Array[Double]) -> Double {
  let mut acc = 0.0
  for i in 0..<self.coeffs.length() {
    let c = self.coeffs[i]
    if c != 0.0 {
      let m = self.basis.monoms[i]
      let mut prod = c
      for v in 0..<self.basis.n_vars {
        for _ in 0..<m[v] {
          prod = prod * x[v]
        }
      }
      acc = acc + prod
    }
  }
  acc
}

///|
/// Truncated local-algebra multiplication (f * g) mod m_n^{k+1}.
pub fn PolyGerm::mul(self : PolyGerm, other : PolyGerm) -> PolyGerm {
  let b = self.basis
  let out = Array::make(b.dim(), 0.0)
  for i in 0..<self.coeffs.length() {
    let ci = self.coeffs[i]
    if ci.abs() > 1.0e-15 {
      let mi = b.monoms[i]
      let di = monom_deg(mi)
      for j in 0..<other.coeffs.length() {
        let cj = other.coeffs[j]
        if cj.abs() > 1.0e-15 {
          let mj = b.monoms[j]
          if di + monom_deg(mj) <= b.max_deg {
            let sum_e = Array::makei(b.n_vars, v => mi[v] + mj[v])
            let idx = b.index_of(sum_e)
            if idx >= 0 {
              out[idx] = out[idx] + ci * cj
            }
          }
        }
      }
    }
  }
  { basis: b, coeffs: out, }
}

///|
/// Exact multiplicative inverse u^{-1} in the local ring O_n^{(k)} for any unit germ
/// u = c_0 (1 + m) with c_0 = u(0) != 0 and m in m_n, via finite Neumann series
/// (1 + m)^{-1} = sum_{j=0}^{k} (-m)^j (terminates strictly since m^{k+1} == 0 mod m_n^{k+1}!).
pub fn PolyGerm::unit_inv(self : PolyGerm) -> PolyGerm {
  let c0 = self.val_at_origin()
  let b = self.basis
  let one = PolyGerm::constant(b, 1.0)
  let neg_m = one.sub(self.scale(1.0 / c0))
  let mut acc = one
  let mut pow = one
  for _ in 1..<=b.max_deg {
    pow = pow.mul(neg_m)
    acc = acc.add(pow)
  }
  acc.scale(1.0 / c0)
}

///|
/// Formal partial derivative d f / d x_v in O_n^{(k)}.
pub fn PolyGerm::partial(self : PolyGerm, v : Int32) -> PolyGerm {
  let b = self.basis
  let out = Array::make(b.dim(), 0.0)
  for i in 0..<self.coeffs.length() {
    let c = self.coeffs[i]
    let e = b.monoms[i][v]
    if c != 0.0 && e > 0 {
      let de = b.monoms[i].copy()
      de[v] = e - 1
      let idx = b.index_of(de)
      if idx >= 0 {
        out[idx] = out[idx] + c * e.to_double()
      }
    }
  }
  { basis: b, coeffs: out, }
}

///|
/// Truncated pullback (f o_k phi)(x) for phi : (R^m, 0) -> (R^n, 0) (phi_v in m_m O_m^{(k)}).
/// Descends canonically to jet equivalence classes: j^k(f o phi) == j^k(f) o_k j^k(phi)!
pub fn PolyGerm::compose(self : PolyGerm, phi : Array[PolyGerm]) -> PolyGerm {
  let dst = phi[0].basis
  let n = self.basis.n_vars
  let k = dst.max_deg
  // Precompute powers phi[v]^e for e = 0..<=k
  let pows : Array[Array[PolyGerm]] = Array::makei(n, v => {
    let arr : Array[PolyGerm] = Array(capacity=k + 1)
    arr.push(PolyGerm::constant(dst, 1.0))
    for e in 1..<=k {
      arr.push(arr[e - 1].mul(phi[v]))
    }
    arr
  })
  let mut acc = PolyGerm::zero(dst)
  for i in 0..<self.coeffs.length() {
    let c = self.coeffs[i]
    if c.abs() > 1.0e-15 {
      let m = self.basis.monoms[i]
      let mut term = PolyGerm::constant(dst, c)
      for v in 0..<n {
        if m[v] > 0 {
          term = term.mul(pows[v][m[v]])
        }
      }
      acc = acc.add(term)
    }
  }
  acc
}

///|
/// Pointed analytic map-germ f = (f_0, ..., f_{p-1}) : (R^n, 0) -> (R^p, 0).
#derive(Debug, Eq)
pub(all) struct MapGerm {
  basis : JetBasis
  comps : Array[PolyGerm]
}

///|
pub fn MapGerm::new(comps : Array[PolyGerm]) -> MapGerm {
  { basis: comps[0].basis, comps, }
}

///|
pub fn MapGerm::target_dim(self : MapGerm) -> Int32 {
  self.comps.length()
}

///|
/// Categorical composition of pointed map-germs (g o_k f) : (R^n, 0) -> (R^q, 0).
pub fn MapGerm::compose(g : MapGerm, f : MapGerm) -> MapGerm {
  MapGerm::new(g.comps.map(gc => gc.compose(f.comps)))
}

///|
/// Differential df(0) in Hom(R^n, R^p) and corank = min(n, p) - rank(df(0)).
pub fn MapGerm::jacobian_at_origin(self : MapGerm) -> DenseMat {
  let p = self.target_dim()
  let n = self.basis.n_vars
  DenseMat::from_fn(p, n, (a, v) => self.comps[a].partial(v).val_at_origin())
}

///|
pub fn MapGerm::corank(self : MapGerm) -> Int32 {
  let df0 = self.jacobian_at_origin()
  let mn = df0.rows.min(df0.cols)
  mn - df0.numerical_rank()
}

///|
/// Hessian corank used for ADE classification of scalar function germs.
/// This is intentionally distinct from the differential corank of a general map-germ.
fn scalar_function_hessian_corank(f : MapGerm) -> Int32 {
  let n = f.basis.n_vars
  let hessian = DenseMat::from_fn(n, n, (i, j) => {
    f.comps[0].partial(i).partial(j).val_at_origin()
  })
  n - hessian.numerical_rank()
}

///|
/// MATHER CONTACT GROUP K ACTION (Concept 13 — 胚的接觸等價性):
/// Applies (M, phi) in K = C |x R to f : (R^n, 0) -> (R^p, 0):
///   (M . f)(x)_a = sum_{b=0}^{p-1} M_{ab}(x) * f_b(phi(x)),
/// where phi : (R^n, 0) -> (R^n, 0) has det D phi(0) != 0 and M(0) in GL(p, R).
/// Preserves the local contact algebra Q_K(f) = O_n / I(f), Tjurina number tau(f),
/// strict K-codimension d(f, K), corank, and zero-set germ (V(f), 0) up to isomorphism!
pub fn MapGerm::apply_contact_transform(
  self : MapGerm,
  mat_germ : Array[Array[PolyGerm]],
  phi : Array[PolyGerm],
) -> MapGerm {
  let pulled = self.comps.map(fc => fc.compose(phi))
  let p = self.target_dim()
  let out = Array::makei(p, a => {
    let mut acc = PolyGerm::zero(self.basis)
    for b in 0..<p {
      acc = acc.add(mat_germ[a][b].mul(pulled[b]))
    }
    acc
  })
  MapGerm::new(out)
}

///|
/// Pack an O_n-submodule of (O_n^{(k)})^p generated by vector generators `mod_gens`
/// (multiplied by all monomials of degree >= `min_mult_deg`) into a row matrix of
/// column dimension p * dim(O_n^{(k)}), then extract exact RREF and pivot columns.
fn submodule_rref(
  basis : JetBasis,
  p : Int32,
  mod_gens : Array[Array[PolyGerm]],
  min_mult_deg : Int32,
  tol~ : Double = 1.0e-9,
) -> (DenseMat, Array[Int32]) {
  let d = basis.dim()
  let tot_cols = p * d
  let rows : Array[Array[Double]] = []
  for gen in mod_gens {
    for m_idx in 0..<d {
      if monom_deg(basis.monoms[m_idx]) >= min_mult_deg {
        let mult = PolyGerm::monomial(basis, basis.monoms[m_idx], 1.0)
        let row = Array::make(tot_cols, 0.0)
        let mut nz = false
        for a in 0..<p {
          let prod = mult.mul(gen[a])
          for c_idx in 0..<d {
            let v = prod.coeffs[c_idx]
            if v.abs() > 1.0e-14 {
              row[a * d + c_idx] = v
              nz = true
            }
          }
        }
        if nz {
          rows.push(row)
        }
      }
    }
  }
  if rows.length() == 0 {
    return (DenseMat::zeros(0, tot_cols), [])
  }
  let mat = DenseMat::from_fn(rows.length(), tot_cols, (i, j) => rows[i][j])
  mat.rref_with_pivots(tol~)
}

///|
/// Compute exact colength dim_R (O_n^{(k)} / <ideal_gens>) of an ideal in O_n^{(k)}.
pub fn ideal_colength(basis : JetBasis, ideal_gens : Array[PolyGerm]) -> Int32 {
  let vec_gens = ideal_gens.map(g => [g])
  let (_, pivs) = submodule_rref(basis, 1, vec_gens, 0)
  basis.dim() - pivs.length()
}

///|
/// Degree-by-degree Hilbert function h_d = dim_R (O_n / I)_d for d = 0..<=max_deg
/// of the local contact algebra Q_K(f) = O_n / <f_0, ..., f_{p-1}> (invariant under K!).
pub fn MapGerm::contact_hilbert_function(self : MapGerm) -> Array[Int32] {
  let b = self.basis
  let vec_gens = self.comps.map(fc => [fc])
  let (_, pivs) = submodule_rref(b, 1, vec_gens, 0)
  let is_piv = Array::make(b.dim(), false)
  for col in pivs {
    is_piv[col] = true
  }
  let h = Array::make(b.max_deg + 1, 0)
  for idx in 0..<b.dim() {
    if !is_piv[idx] {
      let deg = monom_deg(b.monoms[idx])
      h[deg] = h[deg] + 1
    }
  }
  h
}

///|
/// Generators of Mather's extended contact tangent space:
///   T K_e(f) = df(O_n^n) + f^*(m_p) O_n^p = < d f / d x_v >_{O_n} + < f_b * e_a >_{O_n},
/// where `include_contact == true` yields T K_e(f) (Tjurina) and `false` yields T R_e(f) (Milnor).
fn mather_tangent_generators(
  f : MapGerm,
  include_contact : Bool,
) -> Array[Array[PolyGerm]] {
  let b = f.basis
  let n = b.n_vars
  let p = f.target_dim()
  let gens : Array[Array[PolyGerm]] = []
  // Jacobian column generators: v |-> (d f_0 / d x_v, ..., d f_{p-1} / d x_v)
  for v in 0..<n {
    gens.push(Array::makei(p, a => f.comps[a].partial(v)))
  }
  if include_contact {
    // Contact ideal generators: f_c * e_a for 0 <= c, a < p
    for c in 0..<p {
      for a in 0..<p {
        gens.push(
          Array::makei(p, idx => {
            if idx == a {
              f.comps[c]
            } else {
              PolyGerm::zero(b)
            }
          }),
        )
      }
    }
  }
  gens
}

///|
/// Milnor number mu(f) = dim_R O_n / J(f) for a function germ f : (R^n, 0) -> (R, 0)
/// (extended right-equivalence codimension; counts vanishing spheres in the Milnor fiber!).
pub fn MapGerm::milnor_number(self : MapGerm) -> Int32 {
  let (_, pivs) = submodule_rref(
    self.basis,
    self.target_dim(),
    mather_tangent_generators(self, false),
    0,
  )
  self.target_dim() * self.basis.dim() - pivs.length()
}

///|
/// Tjurina number / extended K_e-codimension  tau(f) = dim_R (O_n^p / T K_e(f)):
///   - Strictly invariant under Mather contact equivalence K,
///   - Satisfies tau(f) <= mu(f) for hypersurfaces, with equality iff f is quasihomogeneous
///     (Saito's Theorem, e.g. all ADE singularities), and STRICT inequality tau(f) < mu(f)
///     on non-quasihomogeneous germs (e.g. f = x^5 + y^5 + x^2 y^2 has tau = 10 < mu = 11!),
///   - Equals the exact minimal parameter dimension of a Universal K-Unfolding!
pub fn MapGerm::tjurina_number(self : MapGerm) -> Int32 {
  let (_, pivs) = submodule_rref(
    self.basis,
    self.target_dim(),
    mather_tangent_generators(self, true),
    0,
  )
  self.target_dim() * self.basis.dim() - pivs.length()
}

///|
/// Strict Mather contact codimension  d(f, K) = dim_R (m_n O_n^p / T K(f)),
/// where T K(f) = df(m_n O_n^n) + I(f) O_n^p.
pub fn MapGerm::strict_k_codimension(self : MapGerm) -> Int32 {
  let b = self.basis
  let n = b.n_vars
  let p = self.target_dim()
  let d = b.dim()
  let gens : Array[Array[PolyGerm]] = []
  // m_n * df(O_n^n): multiply partials by coordinate variables x_w
  for v in 0..<n {
    for w in 0..<n {
      let xw = PolyGerm::coord(b, w)
      gens.push(Array::makei(p, a => xw.mul(f_comp_partial(self, a, v))))
    }
  }
  for c in 0..<p {
    for a in 0..<p {
      gens.push(
        Array::makei(p, idx => {
          if idx == a {
            self.comps[c]
          } else {
            PolyGerm::zero(b)
          }
        }),
      )
    }
  }
  let (_, pivs) = submodule_rref(b, p, gens, 0)
  // Subtract constant slots p * 1 since m_n O_n^p has dimension p * (d - 1)
  p * (d - 1) - pivs.length()
}

///|
fn f_comp_partial(f : MapGerm, a : Int32, v : Int32) -> PolyGerm {
  f.comps[a].partial(v)
}

///|
/// THOM-MATHER UNIVERSAL K-UNFOLDING (Concept 12b — 奇點萬有展開 / 萬有開折):
///   F(x, u) = f(x) + sum_{a=0}^{tau-1} u_a * directions[a](x),   u in (R^tau, 0),
/// where `directions` is an exact normal basis of N_{K_e}(f) = O_n^p / T K_e(f).
#derive(Debug, Eq)
pub(all) struct UniversalUnfolding {
  base : MapGerm
  codim : Int32
  directions : Array[MapGerm]
}

///|
/// Construct the canonical miniversal (universal) K-unfolding of `f` by extracting the
/// exact complementary cobasis of T K_e(f) inside O_n^p via pivoted RREF.
pub fn MapGerm::universal_k_unfolding(self : MapGerm) -> UniversalUnfolding {
  let b = self.basis
  let p = self.target_dim()
  let d = b.dim()
  let (_, pivs) = submodule_rref(b, p, mather_tangent_generators(self, true), 0)
  let is_piv = Array::make(p * d, false)
  for col in pivs {
    is_piv[col] = true
  }
  let directions : Array[MapGerm] = []
  for col in 0..<(p * d) {
    if !is_piv[col] {
      let comp_i = col / d
      let mon_i = col % d
      let comps = Array::makei(p, a => {
        if a == comp_i {
          PolyGerm::monomial(b, b.monoms[mon_i], 1.0)
        } else {
          PolyGerm::zero(b)
        }
      })
      directions.push(MapGerm::new(comps))
    }
  }
  { base: self, codim: directions.length(), directions, }
}

///|
/// Evaluate an unfolding fiber after checking parameter dimension and finiteness.
/// This checked entry point is used by the M4 controller so malformed controls cannot
/// be silently truncated or propagate NaN/Inf into the germ classifier.
pub fn UniversalUnfolding::fiber_at_checked(
  self : UniversalUnfolding,
  u : Array[Double],
) -> Result[MapGerm, String] {
  if self.codim != self.directions.length() || u.length() != self.codim {
    return Err("unfolding parameter dimension mismatch")
  }
  for value in u {
    if !value.is_finite() {
      return Err("unfolding parameters must be finite")
    }
  }
  let p = self.base.target_dim()
  let comps = Array::makei(p, a => {
    let mut g = self.base.comps[a]
    for k in 0..<self.codim {
      if u[k] != 0.0 {
        g = g.add(self.directions[k].comps[a].scale(u[k]))
      }
    }
    g
  })
  Ok(MapGerm::new(comps))
}

///|
/// Backwards-compatible permissive evaluator: missing controls are zero-padded and
/// excess controls ignored. New code that needs input validation should use
/// `fiber_at_checked`.
pub fn UniversalUnfolding::fiber_at(
  self : UniversalUnfolding,
  u : Array[Double],
) -> MapGerm {
  let controls = Array::makei(self.codim, i => {
    if i < u.length() {
      u[i]
    } else {
      0.0
    }
  })
  match self.fiber_at_checked(controls) {
    Ok(fiber) => fiber
    Err(_) => self.base
  }
}

///|
/// Mather's Infinitesimal K-Versality Theorem (Theorem XII.2):
/// An r-parameter unfolding F(x, w) with initial velocities v_j = dF/dw_j|_{w=0} is
/// K-versal iff T K_e(f) + span_R{v_1, ..., v_r} == O_n^p, and UNIVERSAL (miniversal)
/// iff additionally r == tau(f)!
pub fn is_k_versal_unfolding(f : MapGerm, velocities : Array[MapGerm]) -> Bool {
  let b = f.basis
  let p = f.target_dim()
  let d = b.dim()
  let tot = p * d
  let (tk_rref, tk_pivs) = submodule_rref(
    b,
    p,
    mather_tangent_generators(f, true),
    0,
  )
  let n_tk = tk_pivs.length()
  let n_v = velocities.length()
  let combined = DenseMat::from_fn(n_tk + n_v, tot, (r, c) => {
    if r < n_tk {
      tk_rref.get(r, c)
    } else {
      let vel = velocities[r - n_tk]
      vel.comps[c / d].coeffs[c % d]
    }
  })
  combined.numerical_rank() == tot
}

///|
/// Universal Factoring Property of `UniversalUnfolding`:
/// Decomposes ANY infinitesimal perturbation `psi` in O_n^p UNIQUELY as
///   psi == sum_{a=0}^{tau-1} alpha_a * phi_a  (mod T K_e(f)),
/// returning the canonical inducing parameter vector alpha in R^tau!
pub fn UniversalUnfolding::induce_perturbation_params(
  self : UniversalUnfolding,
  psi : MapGerm,
) -> Array[Double] {
  let b = self.base.basis
  let p = self.base.target_dim()
  let d = b.dim()
  let tot = p * d
  let (rref, pivs) = submodule_rref(
    b,
    p,
    mather_tangent_generators(self.base, true),
    0,
  )
  // Reduce psi modulo RREF rows of T K_e(f)
  let rem = Array::makei(tot, c => psi.comps[c / d].coeffs[c % d])
  for r in 0..<pivs.length() {
    let pc = pivs[r]
    let f = rem[pc]
    if f.abs() > 1.0e-15 {
      for c in pc..<tot {
        rem[c] = rem[c] - f * rref.get(r, c)
      }
    }
  }
  let is_piv = Array::make(tot, false)
  for pc in pivs {
    is_piv[pc] = true
  }
  let alpha : Array[Double] = Array(capacity=self.codim)
  for c in 0..<tot {
    if !is_piv[c] {
      alpha.push(rem[c])
    }
  }
  alpha
}

///|
/// COMPLETE INTERSECTION GERM AUDIT (Concept 14 — 完備相交胚 ICIS):
/// Tests Koszul complex K_*(f; O_n) boundary nilpotency & degree-1 acyclicity,
/// computes exact Le-Greuel ICIS Milnor number, and audits 0D Gorenstein socle duality.
#derive(Debug, Eq)
pub(all) struct CompleteIntersectionReport {
  ambient_dim : Int32
  num_eqs : Int32
  krull_dim : Int32
  koszul_d2_residual : Double
  koszul_h1_low_deg : Int32
  is_complete_intersection : Bool
  le_greuel_milnor : Int32
  tjurina : Int32
  socle_dim : Int32
  jacobian_in_socle : Bool
  gorenstein_pairing_nondeg : Bool
}

///|
/// Compute all p x p maximal minors of the p x n polynomial Jacobian matrix df(x).
fn maximal_jacobian_minors(f : MapGerm) -> Array[PolyGerm] {
  let b = f.basis
  let p = f.target_dim()
  let n = b.n_vars
  let jmat : Array[Array[PolyGerm]] = Array::makei(p, a => {
    Array::makei(n, v => f.comps[a].partial(v))
  })
  let minors : Array[PolyGerm] = []
  let cols = Array::make(p, 0)
  fn det_sub(
    b : JetBasis,
    jmat : Array[Array[PolyGerm]],
    cols : Array[Int32],
    sz : Int32,
  ) -> PolyGerm {
    if sz == 1 {
      return jmat[0][cols[0]]
    }
    if sz == 2 {
      return jmat[0][cols[0]]
        .mul(jmat[1][cols[1]])
        .sub(jmat[0][cols[1]].mul(jmat[1][cols[0]]))
    }
    let mut acc = PolyGerm::zero(b)
    for k in 0..<sz {
      let sub_j = Array::makei(sz - 1, r => jmat[r + 1])
      let sub_c = Array::makei(sz - 1, idx => {
        if idx < k {
          cols[idx]
        } else {
          cols[idx + 1]
        }
      })
      let term = jmat[0][cols[k]].mul(det_sub(b, sub_j, sub_c, sz - 1))
      acc = if (k & 1) == 0 { acc.add(term) } else { acc.sub(term) }
    }
    acc
  }
  fn choose_cols(
    b : JetBasis,
    jmat : Array[Array[PolyGerm]],
    n : Int32,
    p : Int32,
    idx : Int32,
    start : Int32,
    cols : Array[Int32],
    out : Array[PolyGerm],
  ) -> Unit {
    if idx == p {
      out.push(det_sub(b, jmat, cols, p))
      return
    }
    for c in start..<=(n - (p - idx)) {
      cols[idx] = c
      choose_cols(b, jmat, n, p, idx + 1, c + 1, cols, out)
    }
  }
  if p <= n {
    choose_cols(b, jmat, n, p, 0, 0, cols, minors)
  }
  minors
}

///|
/// Analyze Koszul complex K_2 --d_2--> K_1 --d_1--> K_0 of f = (f_0, ..., f_{p-1}):
///   d_1(e_a) = f_a,   d_2(e_a ^ e_b) = f_a e_b - f_b e_a  (a < b).
/// To avoid artificial truncation artifacts near max_deg, measures ker(d_1) / im(d_2)
/// on homogeneous degrees <= check_deg (for regular sequences, H_1 == 0 identically!).
pub fn koszul_h1_check(f : MapGerm, check_deg : Int32) -> (Double, Int32) {
  let b = f.basis
  let p = f.target_dim()
  let d = b.dim()
  // Assemble d_1 : (O_n)^p -> O_n (matrix of size d x (p * d))
  let d1 = DenseMat::zeros(d, p * d)
  for a in 0..<p {
    for m_idx in 0..<d {
      let prod = PolyGerm::monomial(b, b.monoms[m_idx], 1.0).mul(f.comps[a])
      for r in 0..<d {
        d1.set(r, a * d + m_idx, prod.coeffs[r])
      }
    }
  }
  // Assemble d_2 : (O_n)^{C(p,2)} -> (O_n)^p
  let n_pairs = p * (p - 1) / 2
  let d2 = DenseMat::zeros(p * d, n_pairs * d)
  let mut pair_idx = 0
  for a in 0..<p {
    for c in (a + 1)..<p {
      for m_idx in 0..<d {
        let mon = PolyGerm::monomial(b, b.monoms[m_idx], 1.0)
        let fa = mon.mul(f.comps[a])
        let fc = mon.mul(f.comps[c])
        let col = pair_idx * d + m_idx
        // d_2(e_a ^ e_c) = f_a e_c - f_c e_a
        for r in 0..<d {
          d2.set(c * d + r, col, d2.get(c * d + r, col) + fa.coeffs[r])
          d2.set(a * d + r, col, d2.get(a * d + r, col) - fc.coeffs[r])
        }
      }
      pair_idx = pair_idx + 1
    }
  }
  // Exact Koszul complex identity d_1 o d_2 == 0!
  let d2_res = if n_pairs > 0 { (d1 * d2).frob_norm() } else { 0.0 }
  // Restrict K_1 to slots with monom_deg <= check_deg and test ker(d_1_sub) == im(d_2_sub)
  let low_cols : Array[Int32] = []
  for a in 0..<p {
    for m_idx in 0..<d {
      if monom_deg(b.monoms[m_idx]) <= check_deg {
        low_cols.push(a * d + m_idx)
      }
    }
  }
  let n_low = low_cols.length()
  if n_low == 0 {
    return (d2_res, 0)
  }
  let d1_low = DenseMat::from_fn(d, n_low, (r, j) => d1.get(r, low_cols[j]))
  let ker_dim = n_low - d1_low.numerical_rank()
  // Find subspace of im(d_2) strictly supported inside low_cols:
  // collect columns of d_2 whose entries vanish outside low_cols
  let in_low = Array::make(p * d, false)
  for col in low_cols {
    in_low[col] = true
  }
  let valid_im : Array[Array[Double]] = []
  for col in 0..<d2.cols {
    let mut fits = true
    for r in 0..<(p * d) {
      if !in_low[r] && d2.get(r, col).abs() > 1.0e-12 {
        fits = false
        break
      }
    }
    if fits {
      valid_im.push(Array::makei(n_low, j => d2.get(low_cols[j], col)))
    }
  }
  let im_dim = if valid_im.length() == 0 {
    0
  } else {
    DenseMat::from_fn(n_low, valid_im.length(), (i, j) => valid_im[j][i]).numerical_rank()
  }
  (d2_res, (ker_dim - im_dim).max(0))
}

///|
/// Complete algebraic & homological audit of a Complete Intersection Germ (X, 0) = V(f)
/// (Theorem XII.3: Koszul acyclicity, Le-Greuel ICIS Milnor number, and 0D Gorenstein
/// Scheja-Storch Jacobian socle + Grothendieck local residue pairing non-degeneracy!).
pub fn audit_complete_intersection(
  f : MapGerm,
  koszul_check_deg~ : Int32 = 2,
) -> CompleteIntersectionReport {
  let b = f.basis
  let n = b.n_vars
  let p = f.target_dim()
  let (d2_res, h1_dim) = koszul_h1_check(f, koszul_check_deg)
  let is_ci = p <= n && h1_dim == 0
  let krull_dim = if is_ci { n - p } else { -1 }

  // Le-Greuel inductive formula:
  //   mu(X, 0) + mu(X', 0) = dim_K O_{n,0} / <f_0, ..., f_{p-2}, I_p(df)>
  let mut mu_cur = 0
  if is_ci {
    for step in 1..<=p {
      let sub_f = MapGerm::new(Array::makei(step, i => f.comps[i]))
      let lg_gens : Array[PolyGerm] = []
      for i in 0..<(step - 1) {
        lg_gens.push(f.comps[i])
      }
      for minor in maximal_jacobian_minors(sub_f) {
        lg_gens.push(minor)
      }
      let colen = ideal_colength(b, lg_gens)
      mu_cur = colen - mu_cur
    }
  }
  let tau = f.tjurina_number()

  // For 0-dimensional complete intersections (p == n): verify Gorenstein property!
  //   1. Soc(A) = { a in A : x_v * a == 0 in A forall v } has EXACT dimension 1,
  //   2. Jacobian determinant J = det(df) is NONZERO in A and lies strictly in Soc(A),
  //   3. Grothendieck multiplication pairing <e_i, e_j> = soc_coeff(e_i * e_j) is invertible!
  let mut socle_dim = 0
  let mut jac_in_soc = false
  let mut gor_nondeg = false
  if is_ci && p == n {
    let d = b.dim()
    let (rref, pivs) = submodule_rref(b, 1, f.comps.map(fc => [fc]), 0)
    let is_piv = Array::make(d, false)
    for pc in pivs {
      is_piv[pc] = true
    }
    let cobasis : Array[Int32] = []
    for idx in 0..<d {
      if !is_piv[idx] {
        cobasis.push(idx)
      }
    }
    let dim_a = cobasis.length()
    let reduce_mod_i = (g : PolyGerm) => {
      let rem = g.coeffs.copy()
      for r in 0..<pivs.length() {
        let pc = pivs[r]
        let factor = rem[pc]
        if factor.abs() > 1.0e-15 {
          for c in pc..<d {
            rem[c] = rem[c] - factor * rref.get(r, c)
          }
        }
      }
      Array::makei(dim_a, k => rem[cobasis[k]])
    }
    // Stack multiplication-by-x_v matrices (n * dim_a) x dim_a to find Soc(A) = ker
    let soc_mat = DenseMat::zeros(n * dim_a, dim_a)
    for v in 0..<n {
      let xv = PolyGerm::coord(b, v)
      for j in 0..<dim_a {
        let prod = xv.mul(PolyGerm::monomial(b, b.monoms[cobasis[j]], 1.0))
        let coords = reduce_mod_i(prod)
        for i in 0..<dim_a {
          soc_mat.set(v * dim_a + i, j, coords[i])
        }
      }
    }
    socle_dim = dim_a - soc_mat.numerical_rank()
    let minors = maximal_jacobian_minors(f)
    if minors.length() == 1 && dim_a > 0 {
      let jac_vec = reduce_mod_i(minors[0])
      let jac_nrm = vec_norm(jac_vec)
      let kill_nrm = vec_norm(soc_mat.matvec(jac_vec))
      jac_in_soc = jac_nrm > 1.0e-8 && kill_nrm < 1.0e-8
      // Linear functional l_soc projecting along jac_vec (normalized)
      let dual = vec_scale(jac_vec, 1.0 / (jac_nrm * jac_nrm))
      let gram = DenseMat::from_fn(dim_a, dim_a, (i, j) => {
        let ei = PolyGerm::monomial(b, b.monoms[cobasis[i]], 1.0)
        let ej = PolyGerm::monomial(b, b.monoms[cobasis[j]], 1.0)
        vec_dot(dual, reduce_mod_i(ei.mul(ej)))
      })
      gor_nondeg = gram.numerical_rank() == dim_a
    }
  }
  {
    ambient_dim: n,
    num_eqs: p,
    krull_dim,
    koszul_d2_residual: d2_res,
    koszul_h1_low_deg: h1_dim,
    is_complete_intersection: is_ci,
    le_greuel_milnor: mu_cur,
    tjurina: tau,
    socle_dim,
    jacobian_in_socle: jac_in_soc,
    gorenstein_pairing_nondeg: gor_nondeg,
  }
}

///|
/// NORMAL RING GERM AUDIT (Concept 15 — 正規環胚: Serre's R_1 + S_2 & Normalization):
/// Audits Serre's normality criterion  O_{X,0} normal <==> (R_1) and (S_2)
/// on a reduced complete-intersection germ (X, 0) = V(f) subset (C^n, 0):
///   - Cohen-Macaulay => (S_2) holds automatically (depth == dim X >= min(2, dim X)),
///   - (R_1) holds iff codim_X(Sing(X)) = dim(X) - dim(Sing(X)) >= 2!
/// Determines dim(Sing(X)) directly from the Hilbert polynomial growth of O_n / (I(f) + I_p(df)):
///   - colength == 0  => smooth germ (Sing = empty, codim = +inf => NORMAL!),
///   - 0 < h_d == 0 for high d => isolated singularity dim(Sing) = 0 (NORMAL iff dim X >= 2!),
///   - h_d == const > 0 for high d => 1D singular locus dim(Sing) = 1 (e.g. Whitney umbrella!).
#derive(Debug, Eq)
pub(all) struct SerreNormalityReport {
  dim_x : Int32
  dim_sing : Int32
  codim_sing : Int32
  satisfies_r1 : Bool
  satisfies_s2 : Bool
  is_normal : Bool
}

///|
pub fn audit_serre_normality(f : MapGerm) -> SerreNormalityReport {
  let b = f.basis
  let dim_x = b.n_vars - f.target_dim()
  // Jacobian singular-locus ideal J_Sing = <f_0, ..., f_{p-1}, I_p(df)>
  let sing_gens : Array[PolyGerm] = []
  for fc in f.comps {
    sing_gens.push(fc)
  }
  for minor in maximal_jacobian_minors(f) {
    sing_gens.push(minor)
  }
  let sing_map = MapGerm::new(sing_gens)
  let h = sing_map.contact_hilbert_function()
  let k = b.max_deg
  let dim_sing = if h[0] == 0 {
    -1 // Sing(X, 0) is empty (smooth germ!)
  } else if h[k] == 0 {
    0 // Artinian Jacobian quotient => isolated point singularity at 0!
  } else if h[k] == h[k - 1] {
    1 // Constant Hilbert tail => 1-dimensional singular curve through 0!
  } else {
    2 // Linear+ Hilbert growth => >= 2-dimensional singular locus
  }
  let codim_sing = if dim_sing < 0 { 99 } else { dim_x - dim_sing }
  let r1 = codim_sing >= 2
  let s2 = true // Every complete intersection germ is Cohen-Macaulay => satisfies S_2!
  {
    dim_x,
    dim_sing,
    codim_sing,
    satisfies_r1: r1,
    satisfies_s2: s2,
    is_normal: r1 && s2,
  }
}

///|
/// INTEGRAL CLOSURE / NORMALIZATION nu^* : O_{X,0} = C{t^{a_1}, ..., t^{a_s}} -> C{t}
/// of a 1D monomial curve ring germ (with gcd(a_1, ..., a_s) = 1):
///   - `gaps`: exponents n in N \ S representing integral fractions in C{t} \ O_{X,0}
///     (e.g. for cusp y^2 = x^3, S = <2, 3>, gap = [1] is t = y/x with t^2 = x in O_{X,0}!),
///   - `delta_invariant`: dim_C(O_tilde / O) = |N \ S| (equals 0 iff ALREADY NORMAL!),
///   - `conductor`: smallest c >= 0 with t^c C{t} subset O_{X,0} (annihilator of O_tilde / O),
///   - `is_gorenstein`: Kunz's Theorem: O_{X,0} is Gorenstein iff conductor == 2 * delta,
///   - `milnor_jung`: for r = 1 unibranch plane curves, mu(X, 0) == 2 * delta (Milnor-Jung!).
#derive(Debug, Eq)
pub(all) struct CurveNormalization {
  gaps : Array[Int32]
  delta_invariant : Int32
  conductor : Int32
  is_normal : Bool
  is_gorenstein : Bool
  milnor_jung_number : Int32
}

///|
pub fn normalize_semigroup_curve_germ(
  generators : Array[Int32],
  branches~ : Int32 = 1,
) -> CurveNormalization {
  let mut max_g = 1
  let mut min_g = generators[0]
  for g in generators {
    if g > max_g {
      max_g = g
    }
    if g < min_g {
      min_g = g
    }
  }
  let bound = max_g * min_g + max_g + 4
  let in_s = Array::make(bound + 1, false)
  in_s[0] = true
  for n in 0..<=bound {
    if in_s[n] {
      for g in generators {
        if n + g <= bound {
          in_s[n + g] = true
        }
      }
    }
  }
  let gaps : Array[Int32] = []
  let mut last_gap = -1
  for n in 0..<=bound {
    if !in_s[n] {
      gaps.push(n)
      last_gap = n
    }
  }
  let delta = gaps.length()
  let conductor = last_gap + 1
  {
    gaps,
    delta_invariant: delta,
    conductor,
    is_normal: delta == 0,
    is_gorenstein: conductor == 2 * delta,
    milnor_jung_number: 2 * delta - branches + 1,
  }
}

///|
/// EQUIVALENCE CLASS OF MAP-GERMS (Concept 18 — 等價類映射胚):
///   1. Filtered-colimit stalk equivalence [f]_{x_0} == [g]_{x_0} in lim_{U ni x_0} Map(U, R^m):
///      true iff there exists an open ball B(x_0, r) (r > 0) on which f == g identically
///      (collapsing smooth bump perturbations supported outside B(x_0, r) to zero!).
pub fn same_map_germ_stalk(
  f : (Array[Double]) -> Array[Double],
  g : (Array[Double]) -> Array[Double],
  x0 : Array[Double],
  tol~ : Double = 1.0e-12,
) -> Bool {
  let d = x0.length()
  let radii = [0.25, 0.05, 0.01, 0.002, 0.0004]
  for r in radii {
    let mut agrees_on_ball = true
    for s in 0..<12 {
      let sf = (s + 1).to_double()
      let frac = r * (s % 4 + 1).to_double() * 0.22
      let pt = Array::makei(d, i => {
        x0[i] + frac * @math.sin(sf * (i + 2).to_double() + 0.37)
      })
      if vec_norm(vec_sub(f(pt), g(pt))) > tol {
        agrees_on_ball = false
        break
      }
    }
    if agrees_on_ball {
      return true
    }
  }
  false
}

///|
///   2. UNIVERSAL QUOTIENT / EQUIVALENCE-CLASS MAP-GERM DESCENT (Theorem XII.4):
///      Given a quotient projection map-germ pi : (R^n, 0) -> (R^p, 0) defining the
///      local equivalence relation x ~ x' <=> pi(x) = pi(x'), tests whether a target
///      germ h : (R^n, 0) -> (R, 0) is strictly constant on the equivalence classes of pi
///      and constructs the UNIQUE mediating germ h_bar in O_p^{(k)} with h == h_bar o_k pi!
///      (e.g. symmetric germs h(x,y) = x^3 + y^3 factor uniquely through pi(x,y) = (x+y, xy)
///       as h_bar(s_1, s_2) = s_1^3 - 3 s_1 s_2, while x - y is rejected!)
pub fn factor_through_quotient_germ(
  pi : MapGerm,
  h : PolyGerm,
  quotient_deg : Int32,
  tol~ : Double = 1.0e-9,
) -> Result[PolyGerm, String] {
  let src_b = pi.basis
  let q_b = JetBasis::new(pi.target_dim(), quotient_deg)
  let m_cols = q_b.dim()
  let n_rows = src_b.dim()
  // Pullback operator pi^* : O_p^{(quotient_deg)} -> O_n^{(k)}, e_j |-> (y^{alpha_j}) o_k pi
  let a_mat = DenseMat::zeros(n_rows, m_cols)
  for j in 0..<m_cols {
    let pulled = PolyGerm::monomial(q_b, q_b.monoms[j], 1.0).compose(pi.comps)
    for i in 0..<n_rows {
      a_mat.set(i, j, pulled.coeffs[i])
    }
  }
  // Solve least-squares / exact linear system A * c = h via pivoted RREF on [A | h]
  let aug = DenseMat::from_fn(n_rows, m_cols + 1, (i, j) => {
    if j < m_cols {
      a_mat.get(i, j)
    } else {
      h.coeffs[i]
    }
  })
  let (rref, pivs) = aug.rref_with_pivots(tol~)
  // If last column m_cols is a pivot, h does NOT lie in im(pi^*) (breaks equivalence classes!)
  for pc in pivs {
    if pc == m_cols {
      return Err(
        "Germ is not invariant on equivalence classes of quotient map pi",
      )
    }
  }
  let coeffs = Array::make(m_cols, 0.0)
  for r in 0..<pivs.length() {
    coeffs[pivs[r]] = rref.get(r, m_cols)
  }
  let h_bar : PolyGerm = { basis: q_b, coeffs, }
  let residual = h_bar.compose(pi.comps).sub(h).jet_norm()
  if residual > 1.0e-8 {
    Err("Quotient factorization residual too large: \{residual}")
  } else {
    Ok(h_bar)
  }
}

///|
///   3. Mather K-Equivalence Class Classifier `[f]_K` assigning canonical Arnold ADE /
///      quasihomogeneity / ICIS normal-form labels strictly from K-invariant algebraic data.
#derive(Debug, Eq)
pub(all) struct GermEquivClass {
  label : String
  corank : Int32
  milnor : Int32
  tjurina : Int32
  strict_k_codim : Int32
  is_quasihomogeneous : Bool
}

///|
pub fn classify_contact_equiv_class(f : MapGerm) -> GermEquivClass {
  let p = f.target_dim()
  // For a scalar function germ the ADE corank is the Hessian corank, not the
  // differential corank min(n, 1) - rank(df(0)); the latter is always at most one.
  let crk = if p == 1 { scalar_function_hessian_corank(f) } else { f.corank() }
  let tau = f.tjurina_number()
  let dk = f.strict_k_codimension()
  let mu = if p == 1 { f.milnor_number() } else { tau }
  let qh = p == 1 && mu == tau
  let label = if tau == 0 {
    "A_0 (Submersion / Regular)"
  } else if p == 1 && crk == 1 {
    "A_\{tau}"
  } else if p == 1 && crk == 2 && qh {
    if tau == 4 {
      "D_4 (Umbilic)"
    } else if tau == 5 {
      "D_5 (Parabolic Umbilic)"
    } else if tau == 6 {
      "E_6 / D_6"
    } else {
      "Corank-2 QH (tau=\{tau})"
    }
  } else if p == 1 && !qh {
    "Non-QH Contact Class (tau=\{tau} < mu=\{mu})"
  } else {
    "Map-Germ K-Class (p=\{p}, crk=\{crk}, tau=\{tau})"
  }
  {
    label,
    corank: crk,
    milnor: mu,
    tjurina: tau,
    strict_k_codim: dk,
    is_quasihomogeneous: qh,
  }
}
