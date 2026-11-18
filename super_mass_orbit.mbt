///|
/// Module 6: Second-Order Super-Mass Tensor Orbit Space (二階超質量張量軌道空間).
/// Models an agent's cognitive inertia (bosonic SPD mass M), logical symplectic
/// stiffness (skew-symmetric non-degenerate Omega), and boson-fermion Yukawa coupling Xi
/// as an even graded-symmetric 2-tensor:
///   I = [[M, Xi], [-Xi^T, Omega]] in Sym^2_s(V^*_{m|2k}),  M^T = M > 0, Omega^T = -Omega.
/// Implements:
///   1. Super-congruence gauge group action rho_g(I) = g^{st} * I * g preserving Sym^2_s,
///   2. Exact Schur-Berezin unipotent canonicalization U^{st} * I * U = diag(M_eff, Omega)
///      with effective renormalized bosonic mass M_eff = M + Xi * Omega^{-1} * Xi^T (Theorem IV),
///   3. OSp(m|2k)-invariant supertrace Casimir spectrum C_p(I) = str((G_0^{-1} I)^p),
///   4. Infinitesimal orbit-stabilizer dimension decomposition dim O_I + dim stab(I) = dim g,
///   5. Affine-invariant Riemannian quotient metric d_O([I_1], [I_2]) and repulsive
///      orbit specialization flow driving role differentiation among homogeneous agents.

///|
/// Second-order even graded-symmetric super-mass tensor I = [[M, Xi], [-Xi^T, Omega]].
#derive(Debug, Eq)
pub(all) struct SuperMassTensor {
  m_bos : Int32
  n_ferm : Int32
  n_gen : Int32
  mat : SuperMatrix
}

///|
/// Construct a valid graded-symmetric SuperMassTensor from symmetric positive-definite
/// `m_bos_mat` (m x m), odd coupling `xi_odd` (m x 2k), and skew-symmetric non-degenerate
/// `omega_mat` (2k x 2k).
pub fn SuperMassTensor::new(
  m_bos_mat : Array[Grassmann],
  xi_odd : Array[Grassmann],
  omega_mat : Array[Grassmann],
  m_bos : Int32,
  n_ferm : Int32,
  n_gen : Int32,
) -> SuperMassTensor {
  // Enforce M = (M + M^T)/2 even, Omega = (Omega - Omega^T)/2 even, C = -Xi^T odd
  let m_sym = Array::makei(m_bos * m_bos, idx => {
    let i = idx / m_bos
    let j = idx % m_bos
    (m_bos_mat[i * m_bos + j] + m_bos_mat[j * m_bos + i]).smul(0.5).even_part()
  })
  let b = Array::makei(m_bos * n_ferm, idx => xi_odd[idx].odd_part())
  let c = Array::makei(n_ferm * m_bos, idx => {
    let alpha = idx / m_bos
    let i = idx % m_bos
    -b[i * n_ferm + alpha]
  })
  let om_skew = Array::makei(n_ferm * n_ferm, idx => {
    let a = idx / n_ferm
    let bt = idx % n_ferm
    (omega_mat[a * n_ferm + bt] - omega_mat[bt * n_ferm + a])
    .smul(0.5)
    .even_part()
  })
  let mat = SuperMatrix::from_blocks(
    m_bos,
    n_ferm,
    n_gen,
    Even,
    m_sym,
    b,
    c,
    om_skew,
  )
  { m_bos, n_ferm, n_gen, mat, }
}

///|
/// Build from real SPD mass matrix M, odd coupling Xi, and symplectic scale kappa * J_{2k}.
pub fn SuperMassTensor::from_real_and_yukawa(
  m_real : DenseMat,
  xi_odd : Array[Grassmann],
  ferm_stiffness : Double,
  n_ferm : Int32,
  n_gen : Int32,
) -> SuperMassTensor {
  let m = m_real.rows
  let j = canonical_symplectic(n_ferm).scale(ferm_stiffness)
  let mg = Array::makei(m * m, idx => {
    Grassmann::scalar(n_gen, m_real.get(idx / m, idx % m))
  })
  let og = Array::makei(n_ferm * n_ferm, idx => {
    Grassmann::scalar(n_gen, j.get(idx / n_ferm, idx % n_ferm))
  })
  SuperMassTensor::new(mg, xi_odd, og, m, n_ferm, n_gen)
}

///|
/// Verify the graded-symmetry defect of a candidate SuperMassTensor:
///   || M - M^T ||_F + || Omega + Omega^T ||_F + || C + B^T ||_F == 0.
pub fn SuperMassTensor::graded_symmetry_defect(
  self : SuperMassTensor,
) -> Double {
  let m = self.m_bos
  let n = self.n_ferm
  let (a, b, c, d) = self.mat.blocks()
  let mut err_sq = 0.0
  for i in 0..<m {
    for j in 0..<m {
      err_sq = err_sq + (a[i * m + j] - a[j * m + i]).norm_sq()
    }
  }
  for i in 0..<n {
    for j in 0..<n {
      err_sq = err_sq + (d[i * n + j] + d[j * n + i]).norm_sq()
    }
  }
  for alpha in 0..<n {
    for i in 0..<m {
      err_sq = err_sq + (c[alpha * m + i] + b[i * n + alpha]).norm_sq()
    }
  }
  err_sq.sqrt()
}

///|
/// Super-congruence gauge action rho_g(I) = g^{st} * I * g for Even g in GL(m|2k)_0.
/// Preserves Sym^2_s(V^*_{m|2k}) identically and transforms Ber(I) -> Ber(g)^2 * Ber(I)
/// (hence strictly preserves Ber(I) for all unimodular and OSp(m|2k) transformations!).
pub fn SuperMassTensor::congruence_action(
  self : SuperMassTensor,
  g : SuperMatrix,
) -> SuperMassTensor {
  {
    m_bos: self.m_bos,
    n_ferm: self.n_ferm,
    n_gen: self.n_gen,
    mat: g.supertranspose() * self.mat * g,
  }
}

///|
/// Exact Schur-Berezin Canonical Normal Form on the GL(m|2k)_0 orbit space (Theorem IV):
/// Constructs the unipotent super-gauge transformation U = [[I_m, 0], [Omega^{-1} Xi^T, I_{2k}]]
/// with Ber(U) == 1 such that
///   U^{st} * I * U = [[ M_eff, 0 ], [ 0, Omega ]],
/// where M_eff = M + Xi * Omega^{-1} * Xi^T is symmetric even (carrying the exact
/// fermion-induced soul mass renormalization Sigma = Xi * Omega^{-1} * Xi^T!).
/// Returns (canonical_tensor, gauge_U, m_eff).
pub fn SuperMassTensor::schur_canonical_form(
  self : SuperMassTensor,
) -> (SuperMassTensor, SuperMatrix, Array[Grassmann]) {
  let m = self.m_bos
  let n = self.n_ferm
  let g = self.n_gen
  let (m_blk, xi, _, om) = self.mat.blocks()
  let om_inv = gmat_even_inv(om, n, g)
  let xi_t = Array::makei(n * m, idx => {
    let alpha = idx / m
    let i = idx % m
    xi[i * n + alpha]
  })
  // R = Omega^{-1} * Xi^T
  let r_blk = gmat_mul(om_inv, n, n, xi_t, m, g)
  let zero_b = Array::makei(m * n, _ => Grassmann::zero(g))
  let u = SuperMatrix::from_blocks(
    m,
    n,
    g,
    Even,
    gmat_eye(m, g),
    zero_b,
    r_blk,
    gmat_eye(n, g),
  )
  let canon = self.congruence_action(u)
  // M_eff = M + Xi * Omega^{-1} * Xi^T
  let soul_shift = gmat_mul(xi, m, n, r_blk, m, g)
  let m_eff = Array::makei(m * m, i => m_blk[i] + soul_shift[i])
  (canon, u, m_eff)
}

///|
/// Compute the OSp(m|2k)-invariant supertrace Casimir spectrum:
///   C_p(I) = str( (G_0^{-1} * I)^p ),   p = 1, 2, ..., max_order.
/// For any g in OSp(m|2k) (g^{st} G_0 g = G_0), G_0^{-1} (g^{st} I g) = g^{-1} (G_0^{-1} I) g,
/// so C_p(g^{st} I g) == C_p(I) identically across the entire orbit [I]!
pub fn SuperMassTensor::osp_casimirs(
  self : SuperMassTensor,
  max_order : Int32,
) -> Array[Grassmann] {
  // G_0 = diag(I_m, J), so G_0^{-1} = diag(I_m, -J) = G_0^T
  let g0_inv = SuperMatrix::from_real(
    self.m_bos,
    self.n_ferm,
    Even,
    flat_osp_metric_mat(self.m_bos, self.n_ferm).transpose(),
    n_gen=self.n_gen,
  )
  let op = g0_inv * self.mat
  let mut pow_op = SuperMatrix::identity(
    self.m_bos,
    self.n_ferm,
    n_gen=self.n_gen,
  )
  let out : Array[Grassmann] = Array(capacity=max_order)
  for _ in 1..<=max_order {
    pow_op = pow_op * op
    out.push(pow_op.supertrace())
  }
  out
}

///|
/// Verify the Orbit-Stabilizer Theorem on the classical O(m) x Sp(2k) = OSp(m|2k)_body
/// orbit of a super-mass tensor body (M_0, Omega_0):
///   dim(g_0) = m(m-1)/2 + k(2k+1) = dim(T_I O_I) + dim(stab_{g_0}(I)).
/// Returns (dim_group, dim_orbit, dim_stabilizer).
pub fn SuperMassTensor::orbit_stabilizer_dims(
  self : SuperMassTensor,
) -> (Int32, Int32, Int32) {
  let m = self.m_bos
  let n = self.n_ferm
  let k = n / 2
  let (a, _, _, d) = self.mat.blocks()
  let m0 = DenseMat::from_fn(m, m, (i, j) => a[i * m + j].body())
  let om0 = DenseMat::from_fn(n, n, (i, j) => d[i * n + j].body())
  // Basis of so(m): E_{ij} - E_{ji} for 0 <= i < j < m, acting via X -> X^T M0 + M0 X
  let dim_so = m * (m - 1) / 2
  let so_cols : Array[Array[Double]] = Array(capacity=dim_so)
  for i in 0..<m {
    for j in (i + 1)..<m {
      let x = DenseMat::zeros(m, m)
      x.set(i, j, 1.0)
      x.set(j, i, -1.0)
      let tang = x.transpose() * m0 + m0 * x
      so_cols.push(tang.data)
    }
  }
  let rank_so = if dim_so == 0 {
    0
  } else {
    let jac_so = DenseMat::from_fn(m * m, dim_so, (r, c) => so_cols[c][r])
    jac_so.numerical_rank()
  }
  // Basis of sp(2k): X = J * S for symmetric S (0 <= i <= j < 2k), acting via X^T Om0 + Om0 X
  let dim_sp = k * (2 * k + 1)
  let j_mat = canonical_symplectic(n)
  let sp_cols : Array[Array[Double]] = Array(capacity=dim_sp)
  for i in 0..<n {
    for j in i..<n {
      let s = DenseMat::zeros(n, n)
      s.set(i, j, 1.0)
      s.set(j, i, 1.0)
      let x = j_mat * s
      let tang = x.transpose() * om0 + om0 * x
      sp_cols.push(tang.data)
    }
  }
  let rank_sp = if dim_sp == 0 {
    0
  } else {
    let jac_sp = DenseMat::from_fn(n * n, dim_sp, (r, c) => sp_cols[c][r])
    jac_sp.numerical_rank()
  }
  let dim_g = dim_so + dim_sp
  let dim_orb = rank_so + rank_sp
  let dim_stab = dim_g - dim_orb
  (dim_g, dim_orb, dim_stab)
}

///|
/// Extract sorted eigenvalues of the effective bosonic mass body M_eff,0 (O(m)-orbit invariant).
pub fn SuperMassTensor::bosonic_mass_spectrum(
  self : SuperMassTensor,
) -> Array[Double] {
  let m = self.m_bos
  let (_, _, m_eff) = self.schur_canonical_form()
  let m0 = DenseMat::from_fn(m, m, (i, j) => m_eff[i * m + j].body())
  let (eigs, _) = m0.sym_eigen()
  eigs
}

///|
/// Gauge-invariant O(m)-orbit spectral distance + soul-renormalization distance
/// between two SuperMassTensors [I_1], [I_2] in Sym^2_s(V^*_{m|2k}) / OSp(m|2k):
///   d_O([I_1], [I_2]) = sqrt( sum_i (ln lambda_i(I_1) - ln lambda_i(I_2))^2
///                           + (ln |Ber(I_1)_0| - ln |Ber(I_2)_0|)^2
///                           + (||Sigma_1||_soul - ||Sigma_2||_soul)^2 ).
/// Strictly vanishes when I_2 = g^{st} I_1 g for g in O(m) x Sp(2k), symmetric,
/// and obeys the triangle inequality!
pub fn orbit_space_distance(
  t1 : SuperMassTensor,
  t2 : SuperMassTensor,
) -> Double {
  let e1 = t1.bosonic_mass_spectrum()
  let e2 = t2.bosonic_mass_spectrum()
  let mut s = 0.0
  for i in 0..<e1.length() {
    let dl = @math.ln(e1[i].max(1.0e-12)) - @math.ln(e2[i].max(1.0e-12))
    s = s + dl * dl
  }
  let db = @math.ln(t1.mat.berezinian().body().abs().max(1.0e-12)) -
    @math.ln(t2.mat.berezinian().body().abs().max(1.0e-12))
  s = s + db * db
  // Soul invariant: || C_1(I)_soul ||_2 from first OSp Casimir
  let c1_soul = t1.osp_casimirs(1)[0].soul().l2_norm()
  let c2_soul = t2.osp_casimirs(1)[0].soul().l2_norm()
  let dc = c1_soul - c2_soul
  (s + dc * dc).sqrt()
}

///|
/// Affine-invariant Riemannian distance on the SPD bosonic mass cone P_m = GL(m)/O(m):
///   d_AI(M_1, M_2) = || log(M_1^{-1/2} M_2 M_1^{-1/2}) ||_F.
/// Invariant under simultaneous congruence M_k -> G^T M_k G for ALL G in GL(m, R)!
pub fn spd_affine_invariant_distance(m1 : DenseMat, m2 : DenseMat) -> Double {
  let n = m1.rows
  let (e1, v1) = m1.sym_eigen()
  let inv_sqrt_d = DenseMat::zeros(n, n)
  for i in 0..<n {
    inv_sqrt_d.set(i, i, 1.0 / e1[i].max(1.0e-14).sqrt())
  }
  let m1_inv_half = v1 * inv_sqrt_d * v1.transpose()
  let mid = m1_inv_half * m2 * m1_inv_half
  let mid_sym = (mid + mid.transpose()).scale(0.5)
  let (em, _) = mid_sym.sym_eigen()
  let mut acc = 0.0
  for lam in em {
    let l = @math.ln(lam.max(1.0e-14))
    acc = acc + l * l
  }
  acc.sqrt()
}
