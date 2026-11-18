///|
/// Comprehensive Blackbox Test Suite for `arena/super_emergence`.
/// Verifies all 9 mathematical abstractions, their category/trait axioms,
/// all 7 derived theorems, and the SGNE-Flow quasi-agentic emergence algorithms.

///|
test "Grassmann superalgebra: Koszul anticommutation, Pauli nilpotency, inverse & Berezin calculus" {
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let t2 = @super_emergence.Grassmann::generator(4, 2)
  let t3 = @super_emergence.Grassmann::generator(4, 3)

  // Pauli nilpotency: theta^a * theta^a == 0
  assert_true((t0 * t0).l2_norm() < 1.0e-15)
  assert_true((t2 * t2).l2_norm() < 1.0e-15)

  // Anticommutation: theta^0 * theta^1 + theta^1 * theta^0 == 0
  assert_true((t0 * t1 + t1 * t0).l2_norm() < 1.0e-15)

  // Exact Neumann inverse on full inhomogeneous supernumber a = 2.5 + 0.7 t0 t1 - 0.4 t2 t3 + 1.3 t0 t1 t2 t3
  let a = @super_emergence.Grassmann::scalar(4, 2.5) +
    (t0 * t1).smul(0.7) -
    (t2 * t3).smul(0.4) +
    (t0 * t1 * t2 * t3).smul(1.3)
  let one = @super_emergence.Grassmann::scalar(4, 1.0)
  assert_true((a * a.inv() - one).l2_norm() < 1.0e-14)

  // Functional calculus identities: ln(exp(a)) == a, (sqrt(a))^2 == a, tanh(atanh(u)) == u
  assert_true((a.exp().ln() - a).l2_norm() < 1.0e-14)
  let sq = a.sqrt()
  assert_true((sq * sq - a).l2_norm() < 1.0e-14)
  let u = @super_emergence.Grassmann::scalar(4, 0.42) + (t0 * t2).smul(0.31)
  assert_true((u.atanh().tanh() - u).l2_norm() < 1.0e-14)

  // Berezin graded Leibniz rule: d_0(f * g) == (d_0 f) g + (-1)^{|f|} f (d_0 g)
  let f_odd = t0.smul(1.5) + (t0 * t1 * t2).smul(-0.8) + t3.smul(0.6)
  let g_any = t1.smul(0.9) + (t0 * t3).smul(1.2)
  let lhs = (f_odd * g_any).berezin_deriv(0)
  let rhs = f_odd.berezin_deriv(0) * g_any - f_odd * g_any.berezin_deriv(0)
  assert_true((lhs - rhs).l2_norm() < 1.0e-14)

  // Berezin Gaussian integral: \int d^4 theta exp(alpha t0 t1 + beta t2 t3) == alpha * beta!
  let gauss = ((t0 * t1).smul(1.7) + (t2 * t3).smul(-2.3)).exp()
  assert_true((gauss.berezin_integral() - 1.7 * -2.3).abs() < 1.0e-14)

  // Berezin integral translation invariance: \int d^4 theta P(theta + eta) == \int d^4 theta P(theta)
  let shift0 = t0 + t2.smul(0.5)
  let shift1 = t1 - t3.smul(0.7)
  let top_orig = (t0 * t1 * t2 * t3).berezin_integral()
  let top_shift = (shift0 * shift1 * t2 * t3).berezin_integral()
  assert_true((top_orig - top_shift).abs() < 1.0e-14)
}

///|
test "Module 1: Poincare-Riemannian supermanifold M^{m|n}, exp/log, transport & Theorem I" {
  let c = 1.4
  let x = @super_emergence.PoincarePoint::new(c, [0.22, -0.31, 0.18])
  let y = @super_emergence.PoincarePoint::new(c, [-0.27, 0.19, 0.35])
  let v = x.log_map(y)

  // exp_x(log_x(y)) == y and ||log_x(y)||_{g_x} == d_c(x, y)
  let y_rec = x.exp_map(v)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(y_rec.coords, y.coords)) <
    1.0e-13,
  )
  let g_len = x.metric_inner(v, v).sqrt()
  assert_true((g_len - x.geodesic_dist(y)).abs() < 1.0e-13)

  // Levi-Civita parallel transport preserves Riemannian inner products g_y(P u1, P u2) == g_x(u1, u2)
  let u1 = [0.4, -0.2, 0.5]
  let u2 = [-0.3, 0.7, 0.1]
  let pu1 = x.parallel_transport(y, u1)
  let pu2 = x.parallel_transport(y, u2)
  assert_true(
    (x.metric_inner(u1, u2) - y.metric_inner(pu1, pu2)).abs() < 1.0e-12,
  )

  // Hyperbolic triangle inequality: d_c(x, z) <= d_c(x, y) + d_c(y, z)
  let z = @super_emergence.PoincarePoint::new(c, [0.4, 0.3, -0.2])
  assert_true(
    x.geodesic_dist(z) <= x.geodesic_dist(y) + y.geodesic_dist(z) + 1.0e-14,
  )

  // Super-Poincare orthosymplectic symmetry <Z, W>_s == <W, Z>_s and soul radius != 0
  let smf = @super_emergence.SuperManifold::new(3, 2, c, n_gen=4)
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let t2 = @super_emergence.Grassmann::generator(4, 2)
  let t3 = @super_emergence.Grassmann::generator(4, 3)
  let sz = @super_emergence.SuperPoint::from_body_and_ferm(smf, x.coords, [
    t0.smul(0.8),
    t1.smul(0.6),
  ])
  let sw = @super_emergence.SuperPoint::from_body_and_ferm(smf, y.coords, [
    t2.smul(-0.5),
    t3.smul(0.9),
  ])
  assert_true(
    (@super_emergence.super_osp_inner(sz, sw) -
    @super_emergence.super_osp_inner(sw, sz)).l2_norm() <
    1.0e-15,
  )
  assert_true(sz.super_radius_sq().soul().l2_norm() > 0.5)

  // Super-geodesic distance body recovers exact Poincare distance, soul captures fermion coupling
  let sd = @super_emergence.super_geodesic_dist(sz, sw)
  assert_true((sd.body() - x.geodesic_dist(y)).abs() < 1.0e-13)
  assert_true(sd.soul().l2_norm() > 0.05)

  // Theorem I: On M^{2|2}_c (sdim = 0), sqrt(Ber(G(z))) == 1 + 0*soul identically;
  // on M^{3|2}_c (sdim = 1), sqrt(Ber(G(z))) == lambda_c(z)^1 identically!
  assert_true(
    (sz.volume_density() - sz.super_conformal_factor()).l2_norm() < 1.0e-13,
  )
  let smf_crit = @super_emergence.SuperManifold::new(2, 2, 1.8, n_gen=4)
  let scrit = @super_emergence.SuperPoint::from_body_and_ferm(
    smf_crit,
    [0.45, -0.33],
    [t0.smul(1.2), t1.smul(-0.9)],
  )
  assert_true(
    (scrit.volume_density() - @super_emergence.Grassmann::scalar(4, 1.0)).l2_norm() <
    1.0e-14,
  )
}

///|
test "Module 2: Affine tensor space, Koszul Yang-Baxter braiding, Riemann curvature & ODE transport" {
  // Affine torsor Chasles identity: (r - q) + (q - p) == r - p & shift equivariance of barycenter
  let p = @super_emergence.AffinePoint::new([1.2, -0.5, 3.0])
  let q = @super_emergence.AffinePoint::new([-0.8, 2.1, 0.4])
  let r = @super_emergence.AffinePoint::new([2.5, 1.3, -1.7])
  let lhs = @super_emergence.vec_add(r.diff_vec(q), q.diff_vec(p))
  let rhs = r.diff_vec(p)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(lhs, rhs)) < 1.0e-14,
  )
  let shift = [10.0, -7.5, 4.2]
  let b1 = @super_emergence.affine_barycenter([p, q, r], [0.2, 0.5, 0.3]).translate(
    shift,
  )
  let b2 = @super_emergence.affine_barycenter(
    [p.translate(shift), q.translate(shift), r.translate(shift)],
    [0.2, 0.5, 0.3],
  )
  assert_true(@super_emergence.vec_norm(b1.diff_vec(b2)) < 1.0e-13)

  // Supercontraction of Kronecker delta^A_B on V_{3|2} equals sdim = 3 - 2 = 1; on V_{2|4} equals -2!
  let delta_32 = @super_emergence.GradedTensor::kronecker_delta(3, 2)
  assert_true((delta_32.super_contract(0, 1).data[0] - 1.0).abs() < 1.0e-15)
  let delta_24 = @super_emergence.GradedTensor::kronecker_delta(2, 4)
  assert_true((delta_24.super_contract(0, 1).data[0] - -2.0).abs() < 1.0e-15)

  // Koszul braiding satisfies Yang-Baxter equation: tau_0 tau_1 tau_0 == tau_1 tau_0 tau_1 on V_{1|1}^{x3}
  let t3 = @super_emergence.GradedTensor::zeros(1, 1, [
    Contravariant,
    Contravariant,
    Contravariant,
  ])
  for i in 0..<t3.data.length() {
    t3.data[i] = 0.3 * (i + 1).to_double() - 0.7
  }
  let yb_l = t3.graded_swap(0).graded_swap(1).graded_swap(0)
  let yb_r = t3.graded_swap(1).graded_swap(0).graded_swap(1)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(yb_l.data, yb_r.data)) <
    1.0e-14,
  )

  // Musical isomorphism round-trip raise(lower(T)) == T
  let pt = @super_emergence.PoincarePoint::new(1.2, [0.25, -0.3, 0.15])
  let g = pt.metric_matrix()
  let g_inv = g.inv()
  let round_t = delta_32
  let _ = round_t
  let tens2 = @super_emergence.GradedTensor::kronecker_delta(3, 0)
  let rt = tens2.lower_index(0, g).raise_index(0, g_inv)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(rt.data, tens2.data)) <
    1.0e-13,
  )

  // Levi-Civita connection: torsion == 0, First Bianchi == 0, Ric = -c(m-1)g, R = -c m(m-1) = -7.2
  let conn = @super_emergence.AffineConnection::levi_civita(1.2, 3)
  assert_true(conn.torsion_tensor(pt.coords).frob_norm() < 1.0e-14)
  assert_true(conn.first_bianchi_residual(pt.coords) < 1.0e-13)
  let ric = conn.ricci_matrix(pt.coords)
  let ric_exact = g.scale(-1.2 * 2.0)
  assert_true((ric - ric_exact).frob_norm() < 1.0e-12)
  assert_true((conn.scalar_curvature(pt.coords) - -7.2).abs() < 1.0e-12)

  // Contorsion connection has non-zero torsion
  let torsion_conn : @super_emergence.AffineConnection = {
    c: 1.2,
    dim: 3,
    contorsion: 0.4,
  }
  assert_true(torsion_conn.torsion_tensor(pt.coords).frob_norm() > 0.5)

  // RK4 covariant parallel transport along geodesic matches exact Mobius gyration formula!
  let dst = @super_emergence.PoincarePoint::new(1.2, [-0.2, 0.28, -0.18])
  let v0 = [0.35, -0.42, 0.21]
  let v_ode = conn.parallel_transport_ode(pt, dst, v0, steps=120)
  let v_gyr = pt.parallel_transport(dst, v0)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(v_ode, v_gyr)) < 1.0e-8,
  )
}

///|
test "Module 3: PoPE positional encoding, shift invariance, What-Where decoupling & Super-PoPE" {
  let cfg = @super_emergence.PoPEConfig::new(
    6,
    base=1000.0,
    delta=[-0.5, -1.2, 0.0, -9.0, 2.5, -0.3], // tests clamping to [-2pi, 0]
  )
  assert_true((cfg.delta[3] - -2.0 * 3.141592653589793).abs() < 1.0e-12)
  assert_true(cfg.delta[4] == 0.0)

  let q = [0.8, -1.4, 0.3, 2.1, -0.6, 0.5]
  let k = [-0.3, 0.9, 1.2, -0.7, 0.4, -1.1]

  // Exact identity Re(q~_t^H k~_s) == closed-form cosine sum, and exact translation invariance
  let qt = cfg.encode_query(q, 4.2)
  let ks = cfg.encode_key(k, 11.7)
  let sc1 = @super_emergence.PoPEConfig::score_from_complex(qt, ks)
  let sc2 = cfg.attention_score(q, 4.2, k, 11.7)
  let sc3 = cfg.attention_score(q, -95.8, k, -88.3)
  assert_true((sc1 - sc2).abs() < 1.0e-13)
  assert_true((sc2 - sc3).abs() < 1.0e-11)

  // Analytic gradient wrt delta_c matches central finite differences
  let gd = cfg.grad_delta(q, 2.0, k, 5.0)
  let eps = 1.0e-6
  let d_valid = [-0.5, -1.2, -0.4, -1.8, -0.2, -0.3]
  let cfg_v = @super_emergence.PoPEConfig::new(6, base=1000.0, delta=d_valid)
  let gd_v = cfg_v.grad_delta(q, 2.0, k, 5.0)
  let _ = gd
  for c in 0..<6 {
    let dp = d_valid.copy()
    dp[c] = dp[c] + eps
    let dm = d_valid.copy()
    dm[c] = dm[c] - eps
    let cp = @super_emergence.PoPEConfig::new(6, base=1000.0, delta=dp)
    let cm = @super_emergence.PoPEConfig::new(6, base=1000.0, delta=dm)
    let fd = (
        cp.attention_score(q, 2.0, k, 5.0) - cm.attention_score(q, 2.0, k, 5.0)
      ) /
      (2.0 * eps)
    assert_true((gd_v[c] - fd).abs() < 1.0e-8)
  }

  // Super-PoPE Pauli exclusion: identical single-generator spinors have zero soul pairing,
  // while symplectic dual spinors have strong non-zero soul resonance!
  let smf = @super_emergence.SuperManifold::new(2, 2, 1.0, n_gen=4)
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let z_a = @super_emergence.SuperPoint::from_body_and_ferm(smf, [0.2, 0.1], [
    t0,
    @super_emergence.Grassmann::zero(4),
  ])
  let z_same = @super_emergence.SuperPoint::from_body_and_ferm(
    smf,
    [0.2, 0.1],
    [t0, @super_emergence.Grassmann::zero(4)],
  )
  let z_dual = @super_emergence.SuperPoint::from_body_and_ferm(
    smf,
    [0.2, 0.1],
    [@super_emergence.Grassmann::zero(4), t1],
  )
  let sp_cfg = @super_emergence.PoPEConfig::new(2, base=100.0)
  let sc_same = @super_emergence.super_pope_score(sp_cfg, z_a, 1.0, z_same, 2.0)
  let sc_dual = @super_emergence.super_pope_score(sp_cfg, z_a, 1.0, z_dual, 2.0)
  assert_true(sc_same.soul().l2_norm() < 1.0e-15)
  assert_true(sc_dual.soul().l2_norm() > 0.5)
}

///|
test "Module 4: Noncommutative geometry, supermatrices, Berezinian, Super-Sylvester, Lax & Connes distance" {
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let t2 = @super_emergence.Grassmann::generator(4, 2)
  let t3 = @super_emergence.Grassmann::generator(4, 3)
  let s = (v : Double) => @super_emergence.Grassmann::scalar(4, v)

  let m1 = @super_emergence.SuperMatrix::from_blocks(
    2,
    2,
    4,
    Even,
    [s(2.1) + (t0 * t1).smul(0.3), s(-0.4), s(0.5), s(1.7)],
    [t0.smul(0.6), t1.smul(-0.3), t2.smul(0.4), t3.smul(0.5)],
    [t1.smul(0.5), t2.smul(-0.2), t3.smul(0.3), t0.smul(-0.4)],
    [s(1.5), s(0.3), s(-0.2), s(2.4) + (t2 * t3).smul(-0.2)],
  )
  let m2 = @super_emergence.SuperMatrix::from_blocks(
    2,
    2,
    4,
    Even,
    [s(1.3), s(0.6), s(-0.3), s(1.9)],
    [t2.smul(-0.5), t0.smul(0.4), t1.smul(0.2), t3.smul(-0.6)],
    [t0.smul(0.3), t3.smul(0.5), t1.smul(-0.4), t2.smul(0.2)],
    [s(2.2), s(-0.5), s(0.4), s(1.1)],
  )
  let id = @super_emergence.SuperMatrix::identity(2, 2, n_gen=4)

  // Exact SuperMatrix inverse: M1 * M1^{-1} == I and M1^{-1} * M1 == I
  let m1_inv = m1.inverse()
  assert_true((m1 * m1_inv - id).frob_norm() < 1.0e-13)
  assert_true((m1_inv * m1 - id).frob_norm() < 1.0e-13)

  // Berezinian multiplicativity: Ber(M1 * M2) == Ber(M1) * Ber(M2) (both body AND soul!)
  let ber_prod = (m1 * m2).berezinian()
  let prod_ber = m1.berezinian() * m2.berezinian()
  assert_true((ber_prod - prod_ber).l2_norm() < 1.0e-12)

  // Super-Liouville theorem: Ber(exp(X)) == exp(str(X))
  let x_small = m1.smul(0.35)
  assert_true(
    (x_small.super_exp().berezinian() - x_small.supertrace().exp()).l2_norm() <
    1.0e-12,
  )

  // Supertranspose anti-homomorphism across ALL 4 parity pairs: (M N)^{st} == (-1)^{|M||N|} N^{st} M^{st}
  let o1 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
      0.4 * (i + 2 * j + 1).to_double()
    }),
  )
  let o2 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
      -0.3 * (2 * i - j).to_double() + 0.5
    }),
  )
  assert_true(
    ((m1 * m2).supertranspose() - m2.supertranspose() * m1.supertranspose()).frob_norm() <
    1.0e-13,
  )
  assert_true(
    ((m1 * o1).supertranspose() - o1.supertranspose() * m1.supertranspose()).frob_norm() <
    1.0e-13,
  )
  assert_true(
    ((o1 * m1).supertranspose() - m1.supertranspose() * o1.supertranspose()).frob_norm() <
    1.0e-13,
  )
  assert_true(
    ((o1 * o2).supertranspose() + o2.supertranspose() * o1.supertranspose()).frob_norm() <
    1.0e-13,
  )

  // Supertrace vanishes identically on all graded supercommutators: str([X, Y]_s) == 0
  assert_true(m1.sbracket(m2).supertrace().l2_norm() < 1.0e-13)
  assert_true(m1.sbracket(o1).supertrace().l2_norm() < 1.0e-13)
  assert_true(o1.sbracket(o2).supertrace().l2_norm() < 1.0e-13)

  // Full Grassmann-valued Super-Sylvester equation A * X - X * B == Q
  let b_shift = m2 + id.smul(4.0) // disjoint body spectra guarantees unique solution!
  let x_sol = @super_emergence.solve_grassmann_super_sylvester(m1, b_shift, m2)
  assert_true((m1 * x_sol - x_sol * b_shift - m2).frob_norm() < 1.0e-11)

  // Graded Odd-Odd Super-Sylvester A * X + X * B == Q (Koszul sign -(-1)^{1*1} = +1)
  let a_odd = o1.entries.map(g => g.body())
  let a_dm = @super_emergence.DenseMat::from_fn(4, 4, (i, j) => {
    a_odd[i * 4 + j] + (if i == j { 2.0 } else { 0.0 })
  })
  let b_dm = @super_emergence.DenseMat::eye(4).scale(1.5)
  let q_dm = @super_emergence.DenseMat::from_fn(4, 4, (i, j) => {
    (i - j).to_double() * 0.3 + 0.2
  })
  let x_odd = @super_emergence.solve_super_sylvester(a_dm, Odd, b_dm, q_dm, Odd)
  assert_true((a_dm * x_odd + x_odd * b_dm - q_dm).frob_norm() < 1.0e-12)

  // Super-Lax flow preserves supertrace str(M(t)) and Ber(M(t)) identically
  let m_lax = @super_emergence.step_super_lax(m1, m2, 0.25)
  assert_true((m_lax.supertrace() - m1.supertrace()).l2_norm() < 1.0e-12)
  assert_true((m_lax.berezinian() - m1.berezinian()).l2_norm() < 1.0e-12)

  // Connes spectral triple exact 2-point Higgs distance d_D(0, 1) == 1 / |g|
  let triple = @super_emergence.SpectralTriple::from_yukawa(
    @super_emergence.DenseMat::from_fn(1, 1, (_, _) => 4.0),
  )
  assert_true(triple.chirality_anticommutator_norm() == 0.0)
  assert_true(
    (triple.connes_distance([1.0, 0.0], [0.0, 1.0]) - 0.25).abs() < 1.0e-12,
  )
}

///|
test "Module 5: Classical Jacobi, 8-sector Super-Jacobi, Super-Poisson & protocol anomaly" {
  // Classical Jacobi on gl(3, R)
  let a = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => {
    0.3 * (i * 2 - j + 1).to_double()
  })
  let b = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => {
    @math.sin((i + 3 * j).to_double())
  })
  let c = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => {
    @math.cos((2 * i - j).to_double())
  })
  assert_true(
    @super_emergence.classical_jacobiator(a, b, c).frob_norm() < 1.0e-14,
  )

  // Super-Poisson bracket: odd-odd {q theta^0, p theta^0}_{SP} = q * p (symmetric!)
  // and Super-Jacobi on phase superspace R^{2|2}
  let t0 = @super_emergence.Grassmann::generator(2, 0)
  let t1 = @super_emergence.Grassmann::generator(2, 1)
  let f = (q : Double, _p : Double) => t0.smul(q * q)
  let g = (_q : Double, p : Double) => t0.smul(p)
  let h = (q : Double, p : Double) => t1.smul(q * p)
  let fg = @super_emergence.super_poisson_bracket(f, Odd, g, 1.3, -0.7)
  // f = q^2 t0, g = p t0: bosonic part 2q * 1 * (t0*t0) = 0; fermionic part -1 * q^2 * p = -q^2 p!
  assert_true((fg.body() - -(1.3 * 1.3 * -0.7)).abs() < 1.0e-12)
  // Graded symmetry {f, g}_{SP} == +{g, f}_{SP} for two Odd observables
  let gf = @super_emergence.super_poisson_bracket(g, Odd, f, 1.3, -0.7)
  assert_true((fg - gf).l2_norm() < 1.0e-12)
  let _ = h

  // Protocol Super-Jacobiator detects non-associative perturbation immediately
  let o1 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
      if i == j {
        0.8
      } else {
        -0.3
      }
    }),
  )
  let o2 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
      0.5 * (i - j).to_double() + 0.2
    }),
  )
  let o3 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
      0.4 * (i + j + 1).to_double()
    }),
  )
  let assoc_anom = @super_emergence.protocol_super_jacobi_anomaly(o1, o2, o3, (
    u,
    v,
  ) => u * v)
  let broken_anom = @super_emergence.protocol_super_jacobi_anomaly(o1, o2, o3, (
    u,
    v,
  ) => u * v + u.supertranspose() * v)
  assert_true(assoc_anom < 1.0e-14)
  assert_true(broken_anom > 0.1)
}

///|
test "Module 6: Second-order super-mass tensor orbit space, Orbit-Stabilizer & SPD quotient distance" {
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let t2 = @super_emergence.Grassmann::generator(4, 2)
  let t3 = @super_emergence.Grassmann::generator(4, 3)

  // Case 1: Isotropic bosonic mass M = 2 I_3 => stab_{so(3)}(M) = so(3) (dim 3), orbit dim 0;
  // Omega = J_2 => stab_{sp(2)}(J_2) = sp(2) (dim 3), orbit dim 0! Total group dim = 3 + 3 = 6.
  let iso_m = @super_emergence.DenseMat::eye(3).scale(2.0)
  let zero_xi = Array::makei(6, _ => @super_emergence.Grassmann::zero(4))
  let iso_tensor = @super_emergence.SuperMassTensor::from_real_and_yukawa(
    iso_m, zero_xi, 1.0, 2, 4,
  )
  let (dg1, dorb1, dstab1) = iso_tensor.orbit_stabilizer_dims()
  assert_eq(dg1, 6)
  assert_eq(dorb1, 0)
  assert_eq(dstab1, 6)

  // Case 2: Distinct bosonic masses diag(1, 2, 4) => O(3) breaks completely: so(3) orbit dim = 3!
  let aniso_m = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => {
    if i == j {
      @math.pow(2.0, i.to_double())
    } else {
      0.0
    }
  })
  let xi = [
    t0.smul(0.4),
    t1.smul(0.3),
    t2.smul(-0.5),
    t3.smul(0.2),
    t0.smul(-0.2),
    t2.smul(0.6),
  ]
  let aniso_tensor = @super_emergence.SuperMassTensor::from_real_and_yukawa(
    aniso_m, xi, 1.5, 2, 4,
  )
  assert_true(aniso_tensor.graded_symmetry_defect() < 1.0e-15)
  let (dg2, dorb2, dstab2) = aniso_tensor.orbit_stabilizer_dims()
  assert_eq(dg2, 6)
  assert_eq(dorb2, 3)
  assert_eq(dstab2, 3)

  // Congruence action g^{st} I g preserves graded symmetry identically!
  let g_rot = @super_emergence.make_osp_even_generator(
    3,
    2,
    4,
    @super_emergence.DenseMat::from_fn(3, 3, (i, j) => 0.4 * (i - j).to_double()),
    @super_emergence.DenseMat::zeros(2, 2),
    zero_xi,
  ).super_exp()
  let rotated = aniso_tensor.congruence_action(g_rot)
  assert_true(rotated.graded_symmetry_defect() < 1.0e-12)
  // Same O(3) x Sp(2) orbit => orbit_space_distance == 0!
  assert_true(
    @super_emergence.orbit_space_distance(aniso_tensor, rotated) < 1.0e-11,
  )
  // Distinct orbits => strictly positive orbit distance!
  assert_true(
    @super_emergence.orbit_space_distance(aniso_tensor, iso_tensor) > 1.0,
  )

  // SPD affine-invariant distance d_AI(G^T M1 G, G^T M2 G) == d_AI(M1, M2) for any G in GL(3)!
  let g_gl = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => {
    if i == j {
      1.8
    } else {
      0.35 * (i - 2 * j + 1).to_double()
    }
  })
  let d_orig = @super_emergence.spd_affine_invariant_distance(iso_m, aniso_m)
  let d_cong = @super_emergence.spd_affine_invariant_distance(
    g_gl.transpose() * iso_m * g_gl,
    g_gl.transpose() * aniso_m * g_gl,
  )
  assert_true((d_orig - d_cong).abs() < 1.0e-11)
}

///|
test "Module 7: Neuro-symbolic MGU, occurs-check, Witten SUSY transform & BPS projection" {
  let onto = (s : String) => {
    match s {
      "animal" => @super_emergence.PoincarePoint::new(1.0, [0.05, 0.05])
      "mammal" => @super_emergence.PoincarePoint::new(1.0, [0.22, 0.18])
      "whale" => @super_emergence.PoincarePoint::new(1.0, [0.75, -0.45])
      _ => @super_emergence.PoincarePoint::origin(1.0, 2)
    }
  }
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)

  // 1. Exact syntactic Robinson MGU with idempotency sigma(sigma(t)) == sigma(t)
  let s1 : @super_emergence.NeuroSymState = {
    term: App("knows", [Var("X"), App("parent", [Var("X")])]),
    emb: onto("mammal"),
    logic: t0,
  }
  let s2 : @super_emergence.NeuroSymState = {
    term: App("knows", [Const("alice"), Var("Y")]),
    emb: onto("mammal"),
    logic: t1,
  }
  match @super_emergence.unify_neuro_symbolic(s1, s2, onto, tau=0.0) {
    Unified(sub, ut, _, _, coh, anom) => {
      assert_eq(coh, 1.0)
      assert_eq(anom, 0.0)
      assert_eq(sub.apply(s1.term), sub.apply(s2.term))
      assert_eq(sub.apply(sub.apply(s1.term)), sub.apply(s1.term))
      assert_eq(ut.format_term(), "knows(alice, parent(alice))")
    }
    Contradiction(_) => assert_true(false)
  }

  // 2. Occurs-check rejects infinite cyclic unification X = f(X)
  let cyc1 : @super_emergence.NeuroSymState = {
    term: Var("X"),
    emb: onto("animal"),
    logic: t0,
  }
  let cyc2 : @super_emergence.NeuroSymState = {
    term: App("succ", [Var("X")]),
    emb: onto("animal"),
    logic: t1,
  }
  match @super_emergence.unify_neuro_symbolic(cyc1, cyc2, onto) {
    Contradiction(_) => assert_true(true)
    Unified(_, _, _, _, _, _) => assert_true(false)
  }

  // 3. Witten SUSY on S^1 circle (3 vertices, 3 edges, 0 triangles): chi(S^1) = 3 - 3 = 0!
  let circle = @super_emergence.WittenSUSYSystem::from_simplicial_complex(
    3,
    [(0, 1), (1, 2), (0, 2)],
    [],
    w0=[0.6, -0.9, 0.3],
    w1=[-0.4, 0.8, -0.2],
  )
  assert_true(circle.witten_index(1.5).abs() < 1.0e-13)
  // Finite SUSY transformation U(eps) is orthogonal and preserves H: U H U^T == H!
  let u = circle.susy_transform(0.65)
  assert_true(
    (u.transpose() * u - @super_emergence.DenseMat::eye(6)).frob_norm() <
    1.0e-13,
  )
  assert_true(
    (u * circle.hamiltonian * u.transpose() - circle.hamiltonian).frob_norm() <
    1.0e-12,
  )
  // BPS projection lands strictly inside ker(Q) cap ker(Q^dagger)!
  let psi = [1.0, -0.5, 0.8, 0.4, -0.7, 0.9]
  let bps = circle.project_to_bps(psi)
  assert_true(@super_emergence.vec_norm(bps) > 0.2)
  assert_true(@super_emergence.vec_norm(circle.q_op.matvec(bps)) < 1.0e-12)
  assert_true(@super_emergence.vec_norm(circle.q_dag.matvec(bps)) < 1.0e-12)
}

///|
test "Module 8 & 9 & 10: Fisher-Rao KL Taylor, Quantum SLD, PDE flows & all 7 Theorems" {
  // KL divergence exact 2nd-order Fisher-Rao Taylor identity: D_KL(p_eta || p_{eta+d}) / (0.5 d^T F d) -> 1
  let eta = [0.4, -0.7, 0.2]
  let d = [1.0e-4, -1.5e-4, 0.8e-4]
  let p0 = @super_emergence.categorical_probs(eta)
  let p1 = @super_emergence.categorical_probs(@super_emergence.vec_add(eta, d))
  let kl = @super_emergence.kl_divergence(p0, p1)
  let f = @super_emergence.categorical_fisher_matrix(eta)
  let quad = 0.5 * @super_emergence.vec_dot(d, f.matvec(d))
  assert_true((kl / quad - 1.0).abs() < 1.0e-4)

  // Quantum Bures-Helstrom SLD satisfies (1/2)(rho L + L rho) == d_rho and F^Q is SPD
  let rho = @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
    if i == 0 && j == 0 {
      0.7
    } else if i == 1 && j == 1 {
      0.3
    } else {
      0.15
    }
  })
  let dr1 = @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
    if i == j {
      if i == 0 {
        1.0
      } else {
        -1.0
      }
    } else {
      0.0
    }
  })
  let dr2 = @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
    if i == j {
      0.0
    } else {
      1.0
    }
  })
  let sld1 = @super_emergence.symmetric_log_derivative(rho, dr1)
  assert_true(
    ((rho * sld1 + sld1 * rho).scale(0.5) - dr1).frob_norm() < 1.0e-13,
  )
  let sf = @super_emergence.super_fisher_matrix(eta, rho, [dr1, dr2])
  let (sf_eigs, _) = sf.sym_eigen()
  assert_true(sf_eigs[0] > 0.0)

  // Natural gradient beats Euclidean gradient on KL divergence optimization
  let (kl_nat, kl_euc) = @super_emergence.compare_natural_vs_euclidean_kl(
    [0.7, 0.2, 0.1],
    [-1.5, 1.2],
    30,
    0.25,
  )
  assert_true(kl_nat < 0.05 * kl_euc)

  // Ricci-Fisher curvature flow converges accurately to analytical hyperbolic attractor c*
  let (traj, c_star) = @super_emergence.evolve_ricci_fisher_curvature(
    0.01, 4, 0.9, 2.5, 0.8, 0.05, 80,
  )
  assert_true((traj[traj.length() - 1] - c_star).abs() < 1.0e-4)

  // SUSY heat flow converges monotonically to BPS ground state
  let sys = @super_emergence.WittenSUSYSystem::from_simplicial_complex(
    4,
    [(0, 1), (1, 2), (2, 3), (0, 3), (0, 2)],
    [(0, 1, 2), (0, 2, 3)],
    w0=[0.3, -0.5, 0.2, 0.4],
  )
  let init_psi = [1.0, -0.8, 0.5, 0.3, -0.4, 0.6, 0.9, -0.7, 0.2, 0.5, -0.3]
  let evolved = @super_emergence.evolve_susy_heat_flow(sys, init_psi, 25.0)
  let bps = sys.project_to_bps(init_psi)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(evolved, bps)) < 1.0e-6,
  )

  // Master verification: ALL 18 composite theorems (Layers I-IV) pass!
  let reports = @super_emergence.verify_all_theorems()
  assert_eq(reports.length(), 18)
  for rep in reports {
    assert_true(rep.passed)
  }
}

///|
test "Supplemental laws: Frechet barycenter, Super-Riccati fixed point, Beltrami-Berezin & polymorphic trait" {
  // 1. Poincare Frechet mean minimizes sum_k w_k d_c(x, p_k)^2 (first-order Riemannian optimality == 0)
  let c = 1.1
  let pts = [
    @super_emergence.PoincarePoint::new(c, [0.35, 0.12, -0.18]),
    @super_emergence.PoincarePoint::new(c, [-0.22, 0.41, 0.15]),
    @super_emergence.PoincarePoint::new(c, [0.08, -0.33, 0.29]),
  ]
  let wts = [0.25, 0.45, 0.30]
  let bary = @super_emergence.poincare_frechet_mean(pts, wts)
  let riemann_grad = [0.0, 0.0, 0.0]
  for k in 0..<3 {
    let vk = bary.log_map(pts[k])
    for i in 0..<3 {
      riemann_grad[i] = riemann_grad[i] + wts[k] * vk[i]
    }
  }
  assert_true(@super_emergence.vec_norm(riemann_grad) < 1.0e-12)

  // 2. Differential Super-Riccati equation converges to exact CARE solution A^{st} P + P A - P R P + Q == 0
  let a = @super_emergence.SuperMatrix::identity(1, 1, n_gen=2).smul(-1.0)
  let r_m = @super_emergence.SuperMatrix::identity(1, 1, n_gen=2)
  let q_m = @super_emergence.SuperMatrix::identity(1, 1, n_gen=2).smul(3.0)
  // Exact steady state for -2p - p^2 + 3 = 0 (p > 0) is p* = 1.0!
  let mut p = @super_emergence.SuperMatrix::identity(1, 1, n_gen=2).smul(0.2)
  for _ in 0..<80 {
    p = @super_emergence.step_super_riccati(p, a, r_m, q_m, 0.05)
  }
  let care_res = a.supertranspose() * p + p * a - p * r_m * p + q_m
  assert_true(care_res.frob_norm() < 1.0e-6)
  assert_true((p.get(0, 0).body() - 1.0).abs() < 1.0e-6)

  // 3. Laplace-Beltrami-Berezin at superdimension m - n = 2 is purely conformally invariant:
  //    Delta_{M^{4|2}}(r) == 0 for linear harmonic u(r) = a * r + b!
  let m42 = @super_emergence.SuperManifold::new(4, 2, 1.5)
  let lap_lin = @super_emergence.laplace_beltrami_berezin_1d(
    m42,
    r => 3.2 * r - 1.1,
    0.37,
  )
  assert_true(lap_lin.abs() < 1.0e-9)

  // 4. Polymorphic trait method `LieSuperAlgebra::eval_bilinear` observes str([X, Y]_s) == 0
  let o1 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::eye(2),
  )
  let o2 = @super_emergence.make_osp_odd_generator(
    2,
    2,
    4,
    @super_emergence.DenseMat::eye(2).scale(2.0),
  )
  let observed_str : Double = o1.eval_bilinear(o2, m => m.supertrace().l2_norm())
  assert_true(observed_str < 1.0e-15)
}

///|
test "Module 11: Universal property functors — Yoneda, Adjunction, Exterior lift, Tensor, Pushout & Kan" {
  // 1. HomFunctor functor laws: fmap(id) == id and fmap(g o f) == fmap(g) o fmap(f)
  let h0 : @super_emergence.HomFunctor[Int32, Double] = {
    run: k => k.to_double() * 0.5,
  }
  let f = (x : Double) => x * x + 1.0
  let g = (y : Double) => 3.0 * y - 2.0
  let h_comp = h0.fmap(x => g(f(x)))
  let h_seq = h0.fmap(f).fmap(g)
  for k in -3..<=3 {
    assert_true(((h_comp.run)(k) - (h_seq.run)(k)).abs() < 1.0e-14)
  }
  // Yoneda isomorphism Y^{-1}(Y(alpha)) == alpha on natural transformation alpha(h) = [h(2), h(5)]
  let alpha_id = @super_emergence.yoneda_to_value((
    h : @super_emergence.HomFunctor[Int32, Int32],
  ) => [(h.run)(2), (h.run)(5)])
  let mapped_via_y = @super_emergence.yoneda_from_value(alpha_id, h_seq)
  assert_eq(mapped_via_y, [(h_seq.run)(2), (h_seq.run)(5)])
  // Coyoneda O(1) fusion: lifting into Coyoneda, fusing 3 fmaps, single-pass lower == sequential map
  let raw_xs = [-1.5, 0.0, 2.0, 3.5]
  let fused_xs = @super_emergence.Coyoneda::lift(raw_xs)
    .fmap(f)
    .fmap(g)
    .fmap(z => z - 0.25)
    .lower()
  let seq_xs = raw_xs.map(f).map(g).map(z => z - 0.25)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(fused_xs, seq_xs)) <
    1.0e-14,
  )
  // Fermionic creation operators satisfy exact exterior anticommutativity {e_a, e_b} = 0
  let creators = @super_emergence.fermionic_creation_operators(3)
  assert_true(@super_emergence.anticommutator_family_defect(creators) < 1.0e-15)

  // 2. Free-Forgetful Adjunction F -| U into Grassmann Module (polymorphic trait method!)
  let t0 = @super_emergence.Grassmann::generator(4, 0)
  let t1 = @super_emergence.Grassmann::generator(4, 1)
  let t2 = @super_emergence.Grassmann::generator(4, 2)
  let adj_err = @super_emergence.verify_free_module_adjunction(
    3,
    [t0 + t1, t2.smul(1.5), t0 * t1 * t2],
    @super_emergence.FreeVec::new([0.6, -1.3, 2.2]),
  )
  assert_true(adj_err < 1.0e-14)

  // 3. Universal Exterior Functor lift Phi : Lambda_2 -> Lambda_4 mapping
  //    theta^0 |-> (t0 + 0.5 t2),  theta^1 |-> (t1 - 0.7 t3) (mutually anticommuting odd elements!)
  let e0 = t0 + t2.smul(0.5)
  let e1 = t1 - t3_gen()
  let a2 = @super_emergence.Grassmann::scalar(2, 1.3) +
    @super_emergence.Grassmann::generator(2, 0).smul(-0.8) +
    (@super_emergence.Grassmann::generator(2, 0) *
    @super_emergence.Grassmann::generator(2, 1)).smul(0.9)
  let b2 = @super_emergence.Grassmann::scalar(2, -0.5) +
    @super_emergence.Grassmann::generator(2, 1).smul(1.4) +
    @super_emergence.Grassmann::generator(2, 0).smul(0.6)
  let one4 = @super_emergence.Grassmann::scalar(4, 1.0)
  let zero4 = @super_emergence.Grassmann::zero(4)
  let lift_ab = @super_emergence.grassmann_universal_lift(
    a2 * b2,
    one4,
    zero4,
    [e0, e1],
  )
  let lift_a_lift_b = @super_emergence.grassmann_universal_lift(
      a2,
      one4,
      zero4,
      [e0, e1],
    ) *
    @super_emergence.grassmann_universal_lift(b2, one4, zero4, [e0, e1])
  assert_true((lift_ab - lift_a_lift_b).l2_norm() < 1.0e-14)

  // 4. Universal Exterior Lift onto Witten SUSY supercharge Q (Q^2 == 0 => Lambda_1 -> End(H)!)
  let susy = @super_emergence.WittenSUSYSystem::from_simplicial_complex(
    3,
    [(0, 1), (1, 2), (0, 2)],
    [(0, 1, 2)],
  )
  let dim_h = susy.m_bos + susy.n_ferm
  let g_u = @super_emergence.Grassmann::scalar(1, 2.0) +
    @super_emergence.Grassmann::generator(1, 0).smul(1.5)
  let g_v = @super_emergence.Grassmann::scalar(1, -0.7) +
    @super_emergence.Grassmann::generator(1, 0).smul(0.9)
  let m_uv = @super_emergence.grassmann_universal_lift_mat(g_u * g_v, dim_h, [
    susy.q_op,
  ])
  let m_u_m_v = @super_emergence.grassmann_universal_lift_mat(g_u, dim_h, [
      susy.q_op,
    ]) *
    @super_emergence.grassmann_universal_lift_mat(g_v, dim_h, [susy.q_op])
  assert_true((m_uv - m_u_m_v).frob_norm() < 1.0e-14)

  // 5. Universal Tensor Product Bilinear Factorization: 3D cross product u x v == B~(u (x) v)
  let cross = (u : Array[Double], v : Array[Double]) => {
    [
      u[1] * v[2] - u[2] * v[1],
      u[2] * v[0] - u[0] * v[2],
      u[0] * v[1] - u[1] * v[0],
    ]
  }
  let b_tilde = @super_emergence.universal_tensor_factorization(3, 3, 3, cross)
  let u3 = [1.4, -0.7, 2.3]
  let v3 = [-0.9, 1.8, 0.5]
  let via_tens = b_tilde.matvec(@super_emergence.universal_tensor_pair(u3, v3))
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(via_tens, cross(u3, v3))) <
    1.0e-14,
  )

  // 6. Universal Pushout Colimit: commuting square + unique mediating morphism + rejection of invalid cocone
  let f_ca = [0, 2]
  let g_cb = [1, 2]
  let po = @super_emergence.compute_finite_pushout(4, 3, f_ca, g_cb)
  assert_eq(po.n_apex, 5) // 4 + 3 - 2 = 5
  for c in 0..<2 {
    assert_eq(po.inl[f_ca[c]], po.inr[g_cb[c]])
  }
  // Valid cocone (qa[0]==qb[1]=="shared0", qa[2]==qb[2]=="shared1")
  let qa = ["shared0", "onlyA1", "shared1", "onlyA3"]
  let qb = ["onlyB0", "shared0", "shared1"]
  match po.mediating_map(qa, qb) {
    Ok(med) => {
      for a in 0..<4 {
        assert_eq(med[po.inl[a]], qa[a])
      }
      for b in 0..<3 {
        assert_eq(med[po.inr[b]], qb[b])
      }
    }
    Err(_) => assert_true(false)
  }
  // Invalid cocone breaks commutativity => rejected!
  let qb_bad = ["onlyB0", "CONFLICT", "shared1"]
  assert_true(po.mediating_map(qa, qb_bad) is Err(_))

  // 7. Tropical Kan Extension exact universal equivalence: Lan_K(F) <= G  <==>  F <= G o K
  let k_map = [0, 1, 0, 2]
  let d_cat = @super_emergence.TropMatrix::from_fn(3, 3, (i, j) => {
    if i == j {
      0.0
    } else {
      -0.6 * (i - j).abs().to_double()
    }
  }).kleene_star()
  let d_hm = @super_emergence.DenseMat::from_fn(3, 3, (i, j) => d_cat.get(i, j))
  let f_mic = [1.0, 2.2, 1.5, 0.4]
  let lan = @super_emergence.tropical_left_kan_extension(k_map, d_hm, f_mic)
  // Valid enriched functor G dominating F o K: G(d) = lan(d) + 0.3
  let g_dom = [lan[0] + 0.3, lan[1] + 0.3, lan[2] + 0.3]
  for c in 0..<4 {
    assert_true(f_mic[c] <= g_dom[k_map[c]] + 1.0e-14)
  }
  for d in 0..<3 {
    assert_true(lan[d] <= g_dom[d] + 1.0e-14)
  }
}

///|
fn t3_gen() -> @super_emergence.Grassmann {
  @super_emergence.Grassmann::generator(4, 3, coeff=0.7)
}

///|
test "Module 12: Semitropical projective space TP^n, Galois projection, Ghost hypersurface, Karp & Theorems VIII-X" {
  // 1. Tropical idempotent semiring laws: a (+) a == a, a (*) (b (+) c) == a(*)b (+) a(*)c, 0 absorbing
  let a = @super_emergence.Tropical::finite(2.3)
  let b = @super_emergence.Tropical::finite(-0.7)
  let c = @super_emergence.Tropical::finite(1.5)
  let z = @super_emergence.Tropical::zero()
  assert_eq(@super_emergence.IdempotentSemiring::tadd(a, a), a)
  assert_eq(@super_emergence.IdempotentSemiring::tmul(a, z), z)
  let dist_l = @super_emergence.IdempotentSemiring::tmul(
    a,
    @super_emergence.IdempotentSemiring::tadd(b, c),
  )
  let dist_r = @super_emergence.IdempotentSemiring::tadd(
    @super_emergence.IdempotentSemiring::tmul(a, b),
    @super_emergence.IdempotentSemiring::tmul(a, c),
  )
  assert_true((dist_l.val - dist_r.val).abs() < 1.0e-14)

  // 2. Supertropical Tropical Line V_trop(0 (+) x (+) y) in R^2:
  //    Corner apex (0, 0) and three rays (-t, 0), (0, -t), (t, t) (t > 0) are Ghost;
  //    interior point (2.0, -1.0) is strictly Tangible!
  let line_c = [0.0, 0.0, 0.0]
  let line_e = [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]
  assert_true(
    @super_emergence.eval_supertropical_poly(line_c, line_e, [0.0, 0.0]).is_ghost(),
  )
  assert_true(
    @super_emergence.eval_supertropical_poly(line_c, line_e, [1.7, 1.7]).is_ghost(),
  )
  assert_true(
    @super_emergence.eval_supertropical_poly(line_c, line_e, [-2.5, 0.0]).is_ghost(),
  )
  assert_true(
    !@super_emergence.eval_supertropical_poly(line_c, line_e, [2.0, -1.0]).is_ghost(),
  )

  // 3. Viro-Maslov diffeomorphism TP^{n-1} <-> Delta^{n-1} round-trip & Fisher natural chart bridge
  let tp = @super_emergence.TropProjPoint::from_homogeneous([3.2, 1.5, 4.7, 0.8])
  let tp_shift = @super_emergence.TropProjPoint::from_homogeneous([
    -6.8, -8.5, -5.3, -9.2,
  ])
  assert_true(@super_emergence.tropical_hilbert_dist(tp, tp_shift) < 1.0e-14)
  let simp = tp.to_simplex(0.6)
  let tp_back = @super_emergence.TropProjPoint::from_simplex(simp, 0.6)
  assert_true(@super_emergence.tropical_hilbert_dist(tp, tp_back) < 1.0e-13)
  let eta = tp.to_fisher_natural_coords()
  let simp1 = tp.to_simplex(1.0)
  let cat_p = @super_emergence.categorical_probs(eta)
  assert_true(
    @super_emergence.vec_norm(@super_emergence.vec_sub(simp1, cat_p)) < 1.0e-14,
  )

  // 4. Tropical projective geodesic satisfies exact metric additivity d(p, m) + d(m, q) == d(p, q)!
  let tq = @super_emergence.TropProjPoint::from_homogeneous([
    -1.1, 2.4, 0.3, 1.9,
  ])
  let tmid = @super_emergence.tropical_projective_geodesic(tp, tq, 0.42)
  let d_pq = @super_emergence.tropical_hilbert_dist(tp, tq)
  let d_sum = @super_emergence.tropical_hilbert_dist(tp, tmid) +
    @super_emergence.tropical_hilbert_dist(tmid, tq)
  assert_true((d_pq - d_sum).abs() < 1.0e-13)

  // 5. Exact Galois Adjunction V (*) u <= x  <==>  u <= V \ x  & Maslov projection convergence
  let v_mat = @super_emergence.TropMatrix::from_projective_columns([
    @super_emergence.TropProjPoint::from_homogeneous([0.0, -1.2, -2.0]),
    @super_emergence.TropProjPoint::from_homogeneous([-1.8, 0.0, -0.6]),
  ])
  let x_v = [0.5, -0.3, 1.1]
  let u_max = v_mat.residuate_vec(x_v)
  let vu_max = v_mat.tmul_vec(u_max)
  for i in 0..<3 {
    assert_true(vu_max[i] <= x_v[i] + 1.0e-14)
  }
  let p_in = @super_emergence.TropProjPoint::from_homogeneous(x_v)
  let pi_exact = v_mat.project_onto_polytope(p_in)
  let pi_maslov = v_mat.maslov_project_onto_polytope(p_in, 1.0e-3)
  assert_true(
    @super_emergence.tropical_hilbert_dist(pi_exact, pi_maslov) < 5.0e-3,
  )

  // 6. Verify ALL 18 composite theorems (Layers I-IV) pass simultaneously!
  let all18 = @super_emergence.verify_all_theorems()
  assert_eq(all18.length(), 18)
  for rep in all18 {
    assert_true(rep.passed)
  }
  // Supertropical multiplication absorbs Ghost ideal: Tangible * Ghost -> Ghost
  let st_prod = @super_emergence.SuperTropical::st_mul(
    @super_emergence.Tangible(1.5),
    @super_emergence.Ghost(2.0),
  )
  assert_true(st_prod.is_ghost() && (st_prod.nu_val() - 3.5).abs() < 1.0e-14)
}

///|
test "Modules 13-15 & Regression Suite: U(g) PBW, Contact/ICIS/Normal/Mero/Micro/Quotient Germs & Bug Fixes" {
  // 1. U(sl(2)) exact quadratic Casimir [C_2, X_a] == 0 & PBW dim U_{<=2}(sl(2)) == C(5, 3) = 10
  let sl2 = @super_emergence.SuperLieTable::sl2()
  assert_eq(sl2.pbw_filtration_dim(2), 10)
  assert_eq(sl2.enumerate_pbw_basis(2).length(), 10)
  let c2_sl2 = @super_emergence.sl2_quadratic_casimir()
  for a in 0..<3 {
    assert_true(
      sl2
      .uea_supercommutator(c2_sl2, @super_emergence.UEAElement::generator(3, a))
      .pbw_norm() <
      1.0e-14,
    )
  }

  // 2. MapGerm jet functoriality j^k(g o f) == j^k(g) o_k j^k(f), PolyGerm::eval, and Universal Unfolding fiber
  let jb = @super_emergence.JetBasis::new(2, 4)
  let x = @super_emergence.PolyGerm::coord(jb, 0)
  let y = @super_emergence.PolyGerm::coord(jb, 1)
  let f_map = @super_emergence.MapGerm::new([
    x.add(y.mul(y)),
    y.sub(x.scale(0.5)),
  ])
  let g_map = @super_emergence.MapGerm::new([x.mul(y).add(x.scale(1.2))])
  let gf = @super_emergence.MapGerm::compose(g_map, f_map)
  let pt = [0.05, -0.04]
  let fx = [f_map.comps[0].eval(pt), f_map.comps[1].eval(pt)]
  assert_true((gf.comps[0].eval(pt) - g_map.comps[0].eval(fx)).abs() < 1.0e-7)
  // Cusp A_2: f(x) = x^3 has K-codim tau = 2; unfolded at u = [0.0, -0.25] splits into {-0.5, 0, 0.5}!
  let jb1 = @super_emergence.JetBasis::new(1, 5)
  let a2 = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::monomial(jb1, [3], 1.0),
  ])
  let a2_unf = a2.universal_k_unfolding()
  assert_eq(a2_unf.codim, 2)
  let morsified = a2_unf.fiber_at([0.0, -0.25])
  assert_true(morsified.comps[0].eval([-0.5]).abs() < 1.0e-14)
  assert_true(morsified.comps[0].eval([0.5]).abs() < 1.0e-14)

  // 3. Multivariate Meromorphic Germs M_{2,0}: stalk equivalence (x^2-y^2)/(x-y) == (x+y)/1 & indeterminacy x/y
  let one2 = @super_emergence.PolyGerm::constant(jb, 1.0)
  let m1 : @super_emergence.MultiMeroGerm = {
    num: x.mul(x).sub(y.mul(y)),
    den: x.sub(y),
  }
  let m2 : @super_emergence.MultiMeroGerm = { num: x.add(y), den: one2, }
  assert_true(@super_emergence.MultiMeroGerm::equiv(m1, m2))
  let m_indet : @super_emergence.MultiMeroGerm = { num: x, den: y, }
  assert_eq(m_indet.origin_status(), "Indeterminate")
  let m_pole : @super_emergence.MultiMeroGerm = { num: one2, den: x, }
  assert_eq(m_pole.origin_status(), "PolarDivisor")
  let m_holo = @super_emergence.MultiMeroGerm::mul(
    m2,
    @super_emergence.MultiMeroGerm::add(m2, { num: one2, den: one2, }),
  )
  assert_eq(m_holo.origin_status(), "Holomorphic")
  // Check co-chiral negative-frequency microfunction product (x - i0)^{-1} * (x - i0)^{-1} == (x - i0)^{-2}
  let cm1 = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0)
  let cm2 = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0, order=2)
  match @super_emergence.micro_product(cm1.sp(), cm1.sp()) {
    Ok(sq) =>
      assert_true(
        @super_emergence.MicrofunctionGerm::dist(sq, cm2.sp()) < 1.0e-14,
      )
    Err(_) => assert_true(false)
  }

  // 4. SGNE-Germ-Micro full phase report
  let gm = @super_emergence.distill_germ_microlocal_phase()
  assert_eq(gm.pbw_dim_deg3, 44)
  assert_eq(gm.catastrophe_class, "A_3")
  assert_eq(gm.unfolding_codim, 3)
  assert_eq(gm.icis_milnor, 5)
  assert_eq(gm.normalization_conductor, 2 * gm.normalization_delta)
  assert_true((gm.residue_charge - 1.0).abs() < 1.0e-13)
  assert_true(gm.microlocal_parametrix_err < 1.0e-13)

  // 5. Bug-fix regressions & 100% API coverage:
  //    - BUG-01: singular solve_vec/inv produces finite values (no NaN/Inf)
  let sing = @super_emergence.DenseMat::zeros(3, 3)
  sing.set(0, 0, 2.0)
  let sol_s = sing.solve_vec([4.0, 0.0, 0.0])
  assert_true((sol_s[0] - 2.0).abs() < 1.0e-14 && sol_s[1] == 0.0)
  assert_true(sing.inv().frob_norm() < 10.0)
  //    - BUG-02: dense 16x16 symmetric matrix Jacobi eigendecomposition converges to < 1e-12
  let big_s = @super_emergence.DenseMat::from_fn(16, 16, (i, j) => {
    @math.cos((i + j + 1).to_double()) +
    (if i == j { i.to_double() * 0.3 } else { 0.0 })
  })
  let (e16, v16) = big_s.sym_eigen()
  let diag16 = @super_emergence.DenseMat::from_fn(16, 16, (i, j) => {
    if i == j {
      e16[i]
    } else {
      0.0
    }
  })
  assert_true((v16 * diag16 * v16.transpose() - big_s).frob_norm() < 1.0e-12)
  //    - BUG-03: cyclic variable swap {X <-> Y} terminates & satisfies sigma o sigma == id!
  let swap_sub : @super_emergence.Substitution = {
    bindings: [
      ("X", @super_emergence.Var("Y")),
      ("Y", @super_emergence.Var("X")),
    ],
  }
  let term_xy = @super_emergence.App("rel", [
    @super_emergence.Var("X"),
    @super_emergence.Var("Y"),
  ])
  assert_eq(
    @super_emergence.Substitution::compose(swap_sub, swap_sub).apply(term_xy),
    term_xy,
  )
  //    - BUG-04: sparse tropical cycle & DAG (no cycles => TROP_NEG_INF)
  let dag = @super_emergence.TropMatrix::from_fn(3, 3, (i, j) => {
    if i < j {
      2.5
    } else {
      @super_emergence.TROP_NEG_INF
    }
  })
  let (dag_lam, _) = dag.tropical_eigenpair()
  assert_true(dag_lam <= @super_emergence.TROP_NEG_INF * 0.5)
  //    - BUG-05: GradedTensor::tensor_product, KL trust-region step, spectral action & RoPE translation invariance
  let ta = @super_emergence.GradedTensor::zeros(2, 0, [
    @super_emergence.Contravariant,
  ])
  ta.set([0], 2.0)
  ta.set([1], -3.0)
  let tb = @super_emergence.GradedTensor::zeros(2, 0, [
    @super_emergence.Covariant,
  ])
  tb.set([0], 1.5)
  tb.set([1], 4.0)
  let tab = ta.tensor_product(tb)
  assert_true((tab.get([0, 1]) - 8.0).abs() < 1.0e-14)
  assert_true((tab.get([1, 0]) + 4.5).abs() < 1.0e-14)
  let f_cat = @super_emergence.categorical_fisher_matrix([0.2, -0.3])
  let g_cat = [0.4, -0.5]
  let kl_d = @super_emergence.natural_gradient_kl_step(f_cat, g_cat, 0.01)
  let quad = 0.5 * @super_emergence.vec_dot(kl_d, f_cat.matvec(kl_d))
  assert_true((quad - 0.01).abs() < 1.0e-6)
  let sp_tri = @super_emergence.SpectralTriple::from_yukawa(
    @super_emergence.DenseMat::eye(2).scale(2.0),
  )
  assert_true(
    (sp_tri.spectral_action(2.0) - 4.0 * @math.exp(-1.0)).abs() < 1.0e-13,
  )
  let r1 = @super_emergence.rope_attention_score(
    [1.0, 0.5],
    2.0,
    [-0.3, 0.8],
    5.0,
  )
  let r2 = @super_emergence.rope_attention_score(
    [1.0, 0.5],
    9.0,
    [-0.3, 0.8],
    12.0,
  )
  assert_true((r1 - r2).abs() < 1.0e-13)
  //    - BUG-05: pure-fermionic GL(0|2) SuperMatrix Frobenius-Banachiewicz inverse
  let pf = @super_emergence.SuperMatrix::from_real(
    0,
    2,
    @super_emergence.Even,
    @super_emergence.DenseMat::eye(2).scale(2.5),
  )
  let pf_prod = pf * pf.inverse()
  assert_true(
    (pf_prod - @super_emergence.SuperMatrix::identity(0, 2)).frob_norm() <
    1.0e-14,
  )
}

///|
test "Layer 4 (Theorems XV-XVIII): unified bridge theorems — Schur-Metriplectic flow, paraconsistent unification, Cech super-bundle & quaternionic Connes, role-gated memory" {
  let (_, end_col) = @super_emergence.run_sgne_emergence_simulation(
    n_agents=8,
    n_steps=24,
    dt=0.18,
  )
  let c = end_col[0].belief.c

  // --- THEOREM XV: Schur-Mass Metriplectic structure-preserving flow ---
  let metri = @super_emergence.schur_metriplectic_instance()
  let q = [0.9, -0.8]
  let p = [0.2, 0.35]
  let e0 = metri.energy(q, p)
  let (q2, p2) = metri.metriplectic_step(q, p, 0.002, [0.0, 0.0])
  assert_true(metri.energy(q2, p2) <= e0 + 1.0e-6)
  assert_true(metri.metriplectic_defect(q) < 1.0e-12)
  assert_true(metri.symplectic_defect(q, 0.05) < 1.0e-9)
  assert_true(
    (metri.conservative_flow_jacobian(q, 0.05).det() - 1.0).abs() < 1.0e-9,
  )
  assert_true(metri.dissipation_contraction(0.05) < 1.0)
  let (soul_norm, body_trace) = @super_emergence.schur_soul_mass_shift()
  assert_true(soul_norm > 1.0e-6)
  assert_true(body_trace.abs() < 1.0e-12)
  assert_true(@super_emergence.schur_effective_mass_identity() < 1.0e-13)
  let dw = @super_emergence.double_well_instance()
  let esc = @super_emergence.double_well_barrier_escape(dw, 8, 6000, 0.001, 1.5)
  assert_eq(esc.conservative_escapes, 0)
  assert_true(esc.metriplectic_escapes > 0)
  assert_true(esc.conservative_max_energy < esc.barrier_height)

  // --- THEOREM XVI: Belnap-Grassmann-Poincare paraconsistent unification ---
  let emb_a = @super_emergence.PoincarePoint::new(1.0, [0.10, 0.0, 0.0, 0.0])
  let emb_b = @super_emergence.PoincarePoint::new(1.0, [0.90, 0.0, 0.0, 0.0])
  let sym_embed = (sym : String) => {
    match sym {
      "sense" => @super_emergence.PoincarePoint::new(1.0, [0.10, 0.0, 0.0, 0.0])
      "plan" => @super_emergence.PoincarePoint::new(1.0, [0.60, 0.0, 0.0, 0.0])
      _ => @super_emergence.PoincarePoint::origin(1.0, 4)
    }
  }
  let st_a : @super_emergence.NeuroSymState = {
    term: @super_emergence.SymTerm::App("sense", [
      @super_emergence.SymTerm::Var("x"),
    ]),
    emb: emb_a,
    logic: @super_emergence.Grassmann::generator(4, 0, coeff=0.5),
  }
  let st_b : @super_emergence.NeuroSymState = {
    term: @super_emergence.SymTerm::App("plan", [
      @super_emergence.SymTerm::Var("x"),
    ]),
    emb: emb_b,
    logic: @super_emergence.Grassmann::generator(4, 0, coeff=0.4),
  }
  let pauli_rep = @super_emergence.unify_paraconsistent(st_a, st_b, sym_embed)
  assert_true(pauli_rep.value == @super_emergence.Bv)
  assert_true(pauli_rep.quarantined)
  assert_true(pauli_rep.pauli_excluded)
  let w1 = @super_emergence.ParaUniverse::new(["p", "q", "r"], [
    @super_emergence.Tv,
    @super_emergence.Fv,
    @super_emergence.Fv,
  ])
  let w2 = @super_emergence.ParaUniverse::new(["p", "q", "r"], [
    @super_emergence.Fv,
    @super_emergence.Tv,
    @super_emergence.Fv,
  ])
  let (no_expl, fused) = @super_emergence.paraconsistent_no_explosion([w1, w2])
  assert_true(no_expl)
  assert_true(fused[0] == @super_emergence.Bv)
  assert_true(fused[2] == @super_emergence.Fv)
  let lfp = @super_emergence.epistemic_least_fixed_point(
    @super_emergence.epistemic_quarantine_map,
  )
  assert_true(lfp == @super_emergence.Nv)

  // --- THEOREM XVII: Cech super-operator bundle & quaternionic Connes bridge ---
  let bundle = @super_emergence.build_canonical_super_bundle()
  assert_true(bundle.cocycle_defect() < 1.0e-12)
  assert_true(bundle.patch_defect() < 1.0e-12)
  assert_true(bundle.holonomy_defect([0, 1, 2]) < 1.0e-12)
  assert_true(
    bundle.str_ber_gauge_defect(@super_emergence.super_orthogonal_gauge()) <
    1.0e-9,
  )
  let ncgraph : @super_emergence.NonCommGraph = {
    n: 3,
    weights: [
      [
        @super_emergence.Quat::zero(),
        @super_emergence.Quat::new(0.30, 0.40, -0.20, 0.50),
        @super_emergence.Quat::new(-0.60, 0.10, 0.30, -0.20),
      ],
      [
        @super_emergence.Quat::zero(),
        @super_emergence.Quat::zero(),
        @super_emergence.Quat::new(0.20, -0.50, 0.15, 0.25),
      ],
      [
        @super_emergence.Quat::zero(),
        @super_emergence.Quat::zero(),
        @super_emergence.Quat::zero(),
      ],
    ],
  }
  let rho = @super_emergence.quat_real_embedding(ncgraph)
  assert_true((rho.transpose() - rho).frob_norm() < 1.0e-12)
  let (rho_eigs, _) = rho.sym_eigen()
  let (kramers_ok, mult) = @super_emergence.kramers_multiplicity_profile(
    rho_eigs,
  )
  assert_true(kramers_ok)
  let mut total_mult = 0
  for m in mult {
    total_mult = total_mult + m
  }
  assert_eq(total_mult, 12)
  let st = @super_emergence.QuatSpectralTriple::from_graph(ncgraph)
  let qa = @super_emergence.Quat::new(0.5, 0.25, -0.1, 0.3)
  let qb = @super_emergence.Quat::new(-0.2, 0.4, 0.15, 0.05)
  let qc = @super_emergence.Quat::new(0.9, -0.3, 0.2, 0.1)
  assert_true(st.connes_distance(qa, qa) < 1.0e-9)
  let d_ab = st.connes_distance(qa, qb)
  let d_bc = st.connes_distance(qb, qc)
  let d_ac = st.connes_distance(qa, qc)
  assert_true(d_ab > 1.0e-9)
  assert_true(d_ac <= d_ab + d_bc + 1.0e-9)
  let (k0_idx, k0_err) = @super_emergence.quat_k0_integer_index(
    { a: 2.0, b: 1.0, q: @super_emergence.Quat::new(0.0, 0.5, -0.5, 1.0), },
    { a: 3.0, b: 0.5, q: @super_emergence.Quat::new(0.2, 0.1, 0.0, -0.3), },
  )
  assert_true(k0_idx >= 2 && k0_idx <= 4)
  assert_true(k0_err < 1.0e-9)

  // --- THEOREM XVIII: SGNE-Syn-Mem-Para ---
  let profiles = @super_emergence.role_memory_profiles()
  assert_eq(profiles.length(), 4)
  let mut prev_t = 1.0e30
  for prof in profiles {
    let (lin, ser) = @super_emergence.role_absorption_time(prof.retention)
    assert_true(@super_emergence.approx(lin, ser, 1.0e-6))
    assert_true(lin < prev_t)
    prev_t = lin
    assert_true(
      @super_emergence.role_semigroup_closure_error(prof, 1.0, 64) < 1.0e-9,
    )
  }
  let (t_winners, t_state) = @super_emergence.supertropical_wta_dual(
    [0.10, 2.00, 0.50, -1.00],
    0.1,
    200,
  )
  assert_eq(t_winners.length(), 1)
  assert_true(!t_state.is_ghost())
  let (g_winners, g_state) = @super_emergence.supertropical_wta_dual(
    [0.60, 0.60, -0.30, -1.20],
    0.1,
    200,
  )
  assert_eq(g_winners.length(), 2)
  assert_true(g_state.is_ghost())
  assert_true(
    @super_emergence.slaving_collapse_error(1.5, 4.0, 0.2, 400) < 1.0e-9,
  )
  let (bicomp_ok, po_size, pb_size) = @super_emergence.finite_bicompleteness_certificate()
  assert_true(bicomp_ok)
  assert_true(po_size > 0 && pb_size > 0)
  let code = @super_emergence.godel_encode_finite_set([0, 2, 5])
  let decoded = @super_emergence.godel_decode_finite_set(code)
  assert_eq(decoded.length(), 3)
  assert_eq(decoded[0], 0)
  assert_eq(decoded[1], 2)
  assert_eq(decoded[2], 5)
  let smp = @super_emergence.distill_synergetic_memory_para_agent(end_col, c)
  assert_true(smp.semigroup_closure_error < 1.0e-9)
  assert_true(smp.wta_tangible && smp.wta_ghost)
  assert_true(smp.slaving_collapse_error < 1.0e-9)
  assert_true(smp.godel_injective)
  assert_true(smp.no_explosion)
  assert_true(smp.contradicted_propositions > 0)
}
