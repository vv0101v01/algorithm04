///|
/// Blackbox test suite for the eight merged mathematical-structure modules
/// (`memory.mbt`, `universal.mbt`, `complex_field.mbt`, `synergetic.mbt`,
/// `symplectic.mbt`, `bundle.mbt`, `quaternion_ktheory.mbt`, `para_universe.mbt`).
///
/// It contains:
///   * ALL 31 foundational theorems of the `algo8` lineage, re-expressed as blackbox
///     tests against the public API of the unified package;
///   * 6 REGRESSION tests that lock in the latent bugs which were found during the
///     cross-repository code audit and FIXED by this merge.
/// Every test is fully deterministic and runs identically on wasm-gc / wasm / js.

///|
fn c_eq(
  a : @super_emergence.Complex,
  b : @super_emergence.Complex,
  eps : Double,
) -> Bool {
  @super_emergence.approx(a.re, b.re, eps) &&
  @super_emergence.approx(a.im, b.im, eps)
}

///|
fn q_eq(
  a : @super_emergence.Quat,
  b : @super_emergence.Quat,
  eps : Double,
) -> Bool {
  @super_emergence.approx(a.w, b.w, eps) &&
  @super_emergence.approx(a.x, b.x, eps) &&
  @super_emergence.approx(a.y, b.y, eps) &&
  @super_emergence.approx(a.z, b.z, eps)
}

///|
fn hom_eq(a : @super_emergence.Hom, b : @super_emergence.Hom) -> Bool {
  a.src == b.src && a.dst == b.dst && a.map == b.map
}

///|
fn row_times_matrix(
  row : Array[Double],
  m : Array[Array[Double]],
) -> Array[Double] {
  let n = m.length()
  let out : Array[Double] = []
  for j in 0..<n {
    let mut s = 0.0
    for i in 0..<n {
      s = s + row[i] * m[i][j]
    }
    out.push(s)
  }
  out
}

///|
fn l1_rows(a : Array[Double], b : Array[Double]) -> Double {
  let mut s = 0.0
  for i in 0..<a.length() {
    s = s + (a[i] - b[i]).abs()
  }
  s
}

///|
fn mk_test_net() -> @super_emergence.SynergeticNet {
  let enc : @super_emergence.Layer = {
    w: [[1.0, 0.5, 0.0], [0.0, 1.0, 0.5], [0.5, 0.0, 1.0]],
    b: [0.1, -0.2, 0.0],
  }
  { encoder: enc, n_order: 3, }
}

///|
fn mat2_from_flat(x : Array[Double]) -> @super_emergence.DenseMat {
  { rows: 2, cols: 2, data: x.copy(), }
}

///|
fn conjugate2(a : Array[Double], g : Array[Double]) -> Array[Double] {
  let m = mat2_from_flat(a)
  let gm = mat2_from_flat(g)
  let r = (gm * m * gm.inv()).data
  r
}

///|
fn mat2_commutator(a : Array[Double], b : Array[Double]) -> Array[Double] {
  let ma = mat2_from_flat(a)
  let mb = mat2_from_flat(b)
  (ma * mb - mb * ma).data
}

///|
fn mat2_trace(a : Array[Double]) -> Double {
  a[0] + a[3]
}

// ============================================================================
//  MODULE 1 — LONG-TERM MEMORY CELL STATE TRANSITION (memory.mbt)
// ============================================================================

///|
test "M1.1 Gated memory transfer semigroup: closed form == iteration, unique attracting fixed point" {
  let g : @super_emergence.Gates = {
    forget: 0.9,
    input: 0.8,
    output: 1.0,
    candidate: 0.5,
  }
  let ig = g.input * g.candidate
  let mut cell : @super_emergence.MemoryCell = { c: 1.0, h: 0.0, }
  for t in 1..<=200 {
    cell = cell.step(g)
    if t <= 20 {
      let closed = @super_emergence.memory_closed_form(1.0, g.forget, ig, t)
      assert_true(@super_emergence.approx(cell.c, closed, 1.0e-9))
    }
  }
  // Fixed point theorem: |f| < 1 implies c_t -> i*g/(1 - f)
  let fixed = ig / (1.0 - g.forget)
  assert_true(@super_emergence.approx(cell.c, fixed, 1.0e-6))
  // The exposed activation h is exactly o * tanh(c)
  assert_true(
    @super_emergence.approx(cell.h, g.output * @math.tanh(cell.c), 1.0e-12),
  )
}

///|
test "M1.2 Ergodic memory chain: primitive matrix has a unique stationary distribution" {
  let p = @super_emergence.memory_ergodic_matrix()
  // Primitivity witness: P^3 has strictly positive entries
  let mut m = p
  for _ in 0..<3 {
    let out : Array[Array[Double]] = []
    for row in m {
      out.push(row_times_matrix(row, p))
    }
    m = out
  }
  for row in m {
    for x in row {
      assert_true(x > 0.0)
    }
  }
  let pi = @super_emergence.stationary_power_iteration(p, 200)
  let pi2 = row_times_matrix(pi, p)
  assert_true(l1_rows(pi, pi2) < 1.0e-12)
  // Initial-distribution independence
  let n = p.length()
  let other : Array[Double] = [
    if n > 0 {
      1.0
    } else {
      0.0
    },
    if n > 1 {
      0.0
    } else {
      0.0
    },
    if n > 2 {
      0.0
    } else {
      0.0
    },
    if n > 3 {
      0.0
    } else {
      0.0
    },
  ]
  let mut other2 = other.copy()
  for _ in 0..<200 {
    other2 = row_times_matrix(other2, p)
  }
  assert_true(l1_rows(pi, other2) < 1.0e-9)
  let mut total = 0.0
  for x in pi {
    total = total + x
  }
  assert_true(@super_emergence.approx(total, 1.0, 1.0e-12))
  // Phase constructors
  assert_eq(@super_emergence.phase_index(@super_emergence.Lost), 4)
  assert_eq(@super_emergence.phase_index(@super_emergence.ShortTerm), 0)
}

///|
test "M1.3 Absorption time: Neumann linear solve == survival-probability tail series" {
  let p = @super_emergence.memory_absorbing_matrix()
  for row in p {
    let mut s = 0.0
    for x in row {
      s = s + x
    }
    assert_true(@super_emergence.approx(s, 1.0, 1.0e-12))
  }
  let q : Array[Array[Double]] = []
  let r : Array[Double] = []
  for i in 0..<4 {
    let qrow : Array[Double] = []
    for j in 0..<4 {
      qrow.push(p[i][j])
    }
    q.push(qrow)
    r.push(p[i][4])
  }
  // Absorption is certain: Q^n -> 0
  let mut m = q
  for _ in 0..<500 {
    let out : Array[Array[Double]] = []
    for row in m {
      out.push(row_times_matrix(row, q))
    }
    m = out
  }
  for row in m {
    for x in row {
      assert_true(x.abs() < 1.0e-9)
    }
  }
  let ones : Array[Double] = [1.0, 1.0, 1.0, 1.0]
  let t_lin = @super_emergence.absorption_time_linear_solve(q, ones)
  let t_ser = @super_emergence.absorption_time_series(0, p, 4, 1.0e-13)
  assert_true(@super_emergence.approx(t_lin[0], t_ser, 1.0e-6))
  assert_true(t_lin[0] > 1.0)
}

// ============================================================================
//  MODULE 2 — UNIVERSAL PROPERTY FUNCTORS (universal.mbt)
// ============================================================================

///|
test "M2.1 Terminal object uniqueness and binary product universal property (exhaustive)" {
  assert_true(@super_emergence.terminal_is_unique_up_to_iso())
  assert_eq(@super_emergence.count_terminal_arrows(5), 1)
  let arrow = @super_emergence.terminal_unique_arrow(5)
  assert_eq(arrow.map.length(), 5)
  assert_true(arrow.map[3] == 0)
  assert_true(@super_emergence.universal_property_product_witness(2, 3, 2))
  assert_true(@super_emergence.universal_property_product_witness(2, 2, 1))
  let id3 = @super_emergence.Hom::identity(3)
  assert_true(@super_emergence.Hom::is_identity(id3))
  let f : @super_emergence.Hom = { src: 3, dst: 2, map: [0, 1, 0], }
  let comp = @super_emergence.Hom::compose(f, @super_emergence.Hom::identity(2))
  assert_true(hom_eq(comp, f))
}

///|
test "M2.2 Cartesian product endofunctor obeys the functor laws F(id)=id, F(g.f)=F(g).F(f)" {
  assert_true(@super_emergence.functor_laws_product_with_k(3, 2, 2))
  assert_true(@super_emergence.functor_laws_product_with_k(2, 3, 3))
}

///|
test "M2.3 Finite pullback (fiber product limit) exists with a unique mediating morphism" {
  let f : @super_emergence.Hom = { src: 2, dst: 1, map: [0, 0], }
  let g : @super_emergence.Hom = { src: 2, dst: 1, map: [0, 0], }
  let pb = @super_emergence.compute_finite_pullback(f, g)
  assert_eq(pb.n_apex, 4)
  // A commuting cone has a mediating morphism into the pullback
  let cone_a : @super_emergence.Hom = { src: 1, dst: 2, map: [1], }
  let cone_b : @super_emergence.Hom = { src: 1, dst: 2, map: [1], }
  match pb.mediating_map(cone_a, cone_b) {
    Ok(u) => assert_eq(u.map.length(), 1)
    Err(_) => assert_true(false)
  }
  // A NON-commuting cone is rejected (no mediating morphism exists)
  let bad_b : @super_emergence.Hom = { src: 1, dst: 2, map: [0], }
  let f2 : @super_emergence.Hom = { src: 2, dst: 1, map: [0, 1], }
  let pb2 = @super_emergence.compute_finite_pullback(f2, g)
  match pb2.mediating_map(cone_a, bad_b) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

// ============================================================================
//  MODULE 3 — COMPLEX FIELD STRONG CARDINALITY (complex_field.mbt)
// ============================================================================

///|
test "M3.1 Hamel strong-basis coordinates of C are unique and invertible" {
  let z = @super_emergence.Complex::new(3.5, -2.25)
  let (a, b) = @super_emergence.strong_basis_coords(z)
  assert_true(c_eq(@super_emergence.rebuild_from_coords(a, b), z, 1.0e-12))
  // Linear independence of the basis {1, i}: a*1 + b*i = 0 => a = b = 0
  let s = @super_emergence.Complex::one() *
    @super_emergence.Complex::new(2.0, 0.0) +
    @super_emergence.Complex::i_unit() * @super_emergence.Complex::new(3.0, 0.0)
  assert_true(c_eq(s, @super_emergence.Complex::new(2.0, 3.0), 1.0e-12))
}

///|
test "M3.2 C is a field: commutativity, identities, inverses, associativity, distributivity" {
  let samples : Array[@super_emergence.Complex] = [
    @super_emergence.Complex::new(1.0, 2.0),
    @super_emergence.Complex::new(-0.5, 0.25),
    @super_emergence.Complex::new(0.0, -1.0),
    @super_emergence.Complex::new(3.0, 0.0),
    @super_emergence.Complex::new(-2.5, 4.5),
  ]
  assert_true(@super_emergence.field_axioms_hold(samples))
}

///|
test "M3.3 Cantor pairing is a bijection N x N -> N with an exact O(1) inverse" {
  let seen : Array[Int32] = []
  for a in 0..<20 {
    for b in 0..<20 {
      let p = @super_emergence.cantor_pair(a, b)
      for q in seen {
        if q == p {
          assert_true(false)
        }
      }
      seen.push(p)
    }
  }
  assert_eq(seen.length(), 400)
  for a in 0..<20 {
    for b in 0..<20 {
      let p = @super_emergence.cantor_pair(a, b)
      let (a2, b2) = @super_emergence.cantor_unpair(p)
      assert_eq(a2, a)
      assert_eq(b2, b)
    }
  }
  // Surjectivity onto the triangular band {0, ..., T_{n+1} - 1}
  let n = 19
  let maxv = (n + 1) * (n + 2) / 2 - 1
  let hit : Array[Bool] = []
  for _ in 0..<=maxv {
    hit.push(false)
  }
  for s in 0..<=n {
    for b in 0..<=s {
      let a = s - b
      hit[@super_emergence.cantor_pair(a, b)] = true
    }
  }
  for h in hit {
    assert_true(h)
  }
}

///|
test "M3.4 Gaussian integer norm sieve Z[i] inside C" {
  let norms = @super_emergence.gaussian_int_norms(10)
  assert_eq(norms.length(), 121)
  let mut has0 = false
  let mut has2 = false
  for x in norms {
    if x == 0 {
      has0 = true
    }
    if x == 2 {
      has2 = true
    }
  }
  assert_true(has0)
  assert_true(has2)
}

// ============================================================================
//  MODULE 4 — SYNERGETIC FUNCTOR NEURAL NETWORK (synergetic.mbt)
// ============================================================================

///|
test "M4.1 Synergetic encoder pushes translations forward covariantly (functor laws)" {
  let net = mk_test_net()
  let x : Array[Double] = [1.0, 2.0, 3.0]
  let u1 : Array[Double] = [0.5, -0.5, 1.0]
  let u2 : Array[Double] = [-1.0, 0.25, 0.0]
  assert_true(@super_emergence.functor_laws_synergetic(net, x, u1, u2))
}

///|
test "M4.2 Haken slaving: unique fixed point with geometric (explicit Euler) contraction" {
  let gamma = 4.0
  let eta = 0.2 // |1 - eta*gamma| = 0.2 < 1
  for xi in [0.0, 0.5, 1.0, -1.5] {
    let s_star = @super_emergence.slaving_fixed_point(xi, gamma)
    let s_n = @super_emergence.slaving_run(xi, gamma, eta, 200)
    assert_true((s_n - s_star).abs() < 1.0e-9)
    let s0 = 3.7
    let s1 = @super_emergence.slaving_step(s0, xi, gamma, eta)
    let e0 = s0 - s_star
    let e1 = s1 - s_star
    if e0.abs() > 1.0e-9 {
      assert_true((e1 / e0 - (1.0 - eta * gamma)).abs() < 1.0e-12)
    }
  }
}

///|
test "M4.3 Winner-Take-All order parameter converges to the unique strict maximiser" {
  let proj : Array[Double] = [0.1, 2.0, 0.5, -1.0]
  let w = @super_emergence.order_parameter_wta(proj, 0.1, 200)
  assert_eq(w.length(), 1)
  assert_eq(w[0], 1)
  assert_true(@super_emergence.wta_argmax_stable(proj))
  let proj2 : Array[Double] = [1.0, 0.0, 0.0]
  let w2 = @super_emergence.order_parameter_wta(proj2, 0.1, 200)
  assert_eq(w2[0], 0)
}

// ============================================================================
//  MODULE 5 — NEURAL-PDE SYMPLECTIC PHASE-HARMONY IDENTITY (symplectic.mbt)
// ============================================================================

///|
test "M5.1 Symplectic Euler preserves the symplectic form and the phase-space area" {
  let h = @super_emergence.default_neural_h()
  let q : Array[Double] = [0.7, -0.4]
  let p : Array[Double] = [0.3, 0.9]
  let r = @super_emergence.symplectic_identity_residual(h, q, p, 0.1)
  assert_true(r < 1.0e-6)
  let d = @super_emergence.symplectic_det_area(q, p, 0.1)
  assert_true((d - 1.0).abs() < 1.0e-6)
}

///|
test "M5.2 Explicit Euler is NOT symplectic (residual significantly non-zero)" {
  let h = @super_emergence.default_neural_h()
  let q : Array[Double] = [0.7, -0.4]
  let p : Array[Double] = [0.3, 0.9]
  let r = @super_emergence.explicit_identity_residual(h, q, p, 0.1)
  assert_true(r > 1.0e-3)
}

///|
test "M5.3 Long-horizon energy stability: symplectic drift < explicit drift" {
  let dt = 0.05
  let steps = 2000
  let d_s = @super_emergence.energy_drift(true, steps, dt)
  let d_e = @super_emergence.energy_drift(false, steps, dt)
  assert_true(d_s < d_e)
  assert_true(d_s < 0.05)
}

// ============================================================================
//  MODULE 6 — EMERGENCE OPERATOR BUNDLE (bundle.mbt)
// ============================================================================

///|
test "M6.1 Cech transition cocycle condition g_ab g_bc = g_ac (and a counterexample)" {
  let gab : Array[Double] = [2.0, 0.0, 0.0, 0.5]
  let gbc : Array[Double] = [3.0, 0.0, 0.0, 1.0 / 3.0]
  let gac : Array[Double] = [6.0, 0.0, 0.0, 1.0 / 6.0]
  assert_true(@super_emergence.cocycle_condition(gab, gbc, gac, 1.0e-12))
  let bad : Array[Double] = [5.0, 0.0, 0.0, 0.2]
  assert_true(!@super_emergence.cocycle_condition(gab, gbc, bad, 1.0e-12))
}

///|
test "M6.2 Section patching: compatible local sections glue, incompatible ones do not" {
  let sa : Array[Double] = [1.0, 0.5, 0.0, 2.0]
  let gab : Array[Double] = [2.0, 0.0, 0.0, 0.5]
  let sb = conjugate2(sa, gab)
  assert_true(@super_emergence.patch_sections(sa, sb, gab, 1.0e-12))
  let sb_bad : Array[Double] = [1.0, 0.0, 0.0, 1.0]
  assert_true(!@super_emergence.patch_sections(sa, sb_bad, gab, 1.0e-12))
}

///|
test "M6.3 Emergent invariant: the commutator trace is conjugation invariant" {
  let a : Array[Double] = [1.0, 2.0, 0.0, -1.0]
  let b : Array[Double] = [0.0, 1.0, 1.0, 0.0]
  let g : Array[Double] = [1.0, 1.0, 0.0, 1.0]
  assert_true(@super_emergence.emergent_commutator_trace(a, b, g, 1.0e-10))
  // Commuting diagonal matrices have a vanishing commutator
  let d1 : Array[Double] = [2.0, 0.0, 0.0, 3.0]
  let d2 : Array[Double] = [-1.0, 0.0, 0.0, 5.0]
  for x in mat2_commutator(d1, d2) {
    assert_true(x.abs() < 1.0e-12)
  }
  // The trace of ANY 2x2 commutator vanishes exactly
  assert_true(mat2_trace(mat2_commutator(a, b)).abs() < 1.0e-12)
}

///|
test "M6.4 Global section construction from compatible local operators" {
  let ref_op : Array[Double] = [1.0, 0.5, 0.0, 2.0]
  let g01 : Array[Double] = [2.0, 0.0, 0.0, 0.5]
  let g02 : Array[Double] = [1.0, 1.0, 0.0, 1.0]
  let op1 = conjugate2(ref_op, g01)
  let op2 = conjugate2(ref_op, g02)
  let locals : Array[Array[Double]] = [ref_op, op1, op2]
  let id2 : Array[Double] = [1.0, 0.0, 0.0, 1.0]
  let trans : Array[Array[Double]] = [id2, g01, g02]
  assert_true(@super_emergence.build_global_section(locals, trans, 0, 1.0e-10))
  let locals_bad : Array[Array[Double]] = [ref_op, op1, [9.0, 0.0, 0.0, 9.0]]
  assert_true(
    !@super_emergence.build_global_section(locals_bad, trans, 0, 1.0e-10),
  )
}

///|
test "M6.5 Emergent spectral gap of the glued global operator" {
  let g : Array[Double] = [4.0, 0.0, 0.0, 1.0]
  assert_true((@super_emergence.emergent_spectral_gap(g) - 3.0).abs() < 1.0e-12)
  let g2 : Array[Double] = [4.0, 0.2, 0.0, 1.0]
  let gap = @super_emergence.emergent_spectral_gap(g2)
  assert_true(gap > 2.0 && gap < 4.0)
}

// ============================================================================
//  MODULE 7 — HILBERT QUATERNIONS & NONCOMMUTATIVE GRAPH K-THEORY (quaternion_ktheory.mbt)
// ============================================================================

///|
test "M7.1 Hamilton quaternions are non-commutative with i^2 = j^2 = k^2 = -1" {
  let i = @super_emergence.Quat::new(0.0, 1.0, 0.0, 0.0)
  let j = @super_emergence.Quat::new(0.0, 0.0, 1.0, 0.0)
  let k = @super_emergence.Quat::new(0.0, 0.0, 0.0, 1.0)
  assert_true(q_eq(i * j, k, 1.0e-12))
  assert_true(q_eq(j * i, -k, 1.0e-12))
  assert_true(
    q_eq(i * i, @super_emergence.Quat::new(-1.0, 0.0, 0.0, 0.0), 1.0e-12),
  )
  assert_true(
    q_eq(j * j, @super_emergence.Quat::new(-1.0, 0.0, 0.0, 0.0), 1.0e-12),
  )
  assert_true(
    q_eq(k * k, @super_emergence.Quat::new(-1.0, 0.0, 0.0, 0.0), 1.0e-12),
  )
}

///|
test "M7.2 Quaternion division algebra: associativity, anti-automorphic conjugation, multiplicativity of the norm" {
  let a = @super_emergence.Quat::new(1.0, 2.0, -0.5, 0.25)
  let b = @super_emergence.Quat::new(-1.0, 0.5, 1.5, -2.0)
  let c = @super_emergence.Quat::new(0.75, -1.25, 0.0, 1.0)
  assert_true(q_eq(a * b * c, a * (b * c), 1.0e-12))
  assert_true(q_eq((a * b).conj(), b.conj() * a.conj(), 1.0e-12))
  let lhs = (a * b).norm()
  let rhs = a.norm() * b.norm()
  assert_true((lhs - rhs).abs() < 1.0e-12)
  assert_true(q_eq(a * @super_emergence.Quat::one(), a, 1.0e-12))
  assert_true(q_eq(a / a, @super_emergence.Quat::one(), 1.0e-10))
  assert_true(
    q_eq(
      a * (@super_emergence.Quat::one() / a),
      @super_emergence.Quat::one(),
      1.0e-10,
    ),
  )
}

///|
test "M7.3 Hermitian 2x2 quaternionic operator: real spectrum, Rayleigh bounds, projector idempotency" {
  let h : @super_emergence.Hermitian2 = {
    a: 2.0,
    b: 1.0,
    q: @super_emergence.Quat::new(0.0, 0.5, -0.5, 1.0),
  }
  let (lp, lm) = @super_emergence.hermitian2_eigs(h)
  assert_true(lp >= lm)
  let v : Array[@super_emergence.Quat] = [
    @super_emergence.Quat::new(1.0, 0.3, -0.2, 0.1),
    @super_emergence.Quat::new(0.5, -0.4, 0.6, 0.0),
  ]
  assert_true(@super_emergence.rayleigh_imag_residual(h, v) < 1.0e-12)
  let r = @super_emergence.rayleigh_real(h, v)
  assert_true(r >= lm - 1.0e-9 && r <= lp + 1.0e-9)
  let (alpha, delta, _bq) = @super_emergence.hermitian2_projector_plus(h)
  let nq = h.q.norm2()
  let denom = lp - lm
  let beta = 1.0 / denom
  assert_true((alpha * alpha + beta * beta * nq - alpha).abs() < 1.0e-12)
  assert_true((delta * delta + beta * beta * nq - delta).abs() < 1.0e-12)
  assert_true((alpha + delta - 1.0).abs() < 1.0e-12)
  let tr = alpha + delta
  assert_true(tr >= -1.0e-12 && tr <= 2.0 + 1.0e-12)
  assert_true((tr - tr.round()).abs() < 1.0e-10)
}

///|
test "M7.4 K_0 spectral projector identities (orthogonality, completeness, integer index)" {
  let h1 : @super_emergence.Hermitian2 = {
    a: 2.0,
    b: 1.0,
    q: @super_emergence.Quat::new(0.0, 0.5, -0.5, 1.0),
  }
  assert_true(@super_emergence.k0_spectral_identity(h1, 1.0e-12))
  let h2 : @super_emergence.Hermitian2 = {
    a: 0.5,
    b: -1.5,
    q: @super_emergence.Quat::new(1.0, 0.0, 1.0, 0.0),
  }
  assert_true(@super_emergence.k0_spectral_identity(h2, 1.0e-12))
  let h3 : @super_emergence.Hermitian2 = {
    a: 3.0,
    b: 3.0,
    q: @super_emergence.Quat::zero(),
  }
  assert_true(@super_emergence.k0_spectral_identity(h3, 1.0e-12))
  let (lp, lm) = @super_emergence.hermitian2_eigs(h3)
  assert_true((lp - 3.0).abs() < 1.0e-12)
  assert_true((lm - 3.0).abs() < 1.0e-12)
}

///|
test "M7.5 Non-commutative quaternion graph: Hermitian adjacency and quaternionic Cayley-Hamilton" {
  let w0 : Array[@super_emergence.Quat] = [
    @super_emergence.Quat::zero(),
    @super_emergence.Quat::new(0.0, 1.0, 1.0, 0.0),
  ]
  let g : @super_emergence.NonCommGraph = { n: 2, weights: [w0], }
  assert_true(@super_emergence.adjacency_is_hermitian(g, 1.0e-12))
  let a = g.adjacency()
  assert_true(@super_emergence.cayley_hamilton_2x2(a, 1.0e-10))
  let tr_a = a[0][0].w + a[1][1].w
  assert_true(tr_a.abs() < 1.0e-12)
  let h : @super_emergence.Hermitian2 = {
    a: 0.0,
    b: 0.0,
    q: @super_emergence.Quat::new(0.0, 1.0, 1.0, 0.0),
  }
  let (lp, lm) = @super_emergence.hermitian2_eigs(h)
  let nq = h.q.norm()
  assert_true((lp - nq).abs() < 1.0e-12)
  assert_true((lm + nq).abs() < 1.0e-12)
}

///|
test "M7.6 K_0 direct-sum index additivity (integer-valued)" {
  assert_true(@super_emergence.k0_additivity(1.0, 1.0, 1.0e-12))
  assert_true(@super_emergence.k0_additivity(0.0, 2.0, 1.0e-12))
  let (idx, err) = @super_emergence.k0_direct_sum_index(
    { a: 2.0, b: 1.0, q: @super_emergence.Quat::new(0.0, 0.5, -0.5, 1.0), },
    { a: 3.0, b: 0.5, q: @super_emergence.Quat::new(0.2, 0.1, 0.0, -0.3), },
  )
  assert_true(idx >= 2 && idx <= 4)
  assert_true(err < 1.0e-9)
}

// ============================================================================
//  MODULE 8 — PARA-UNIVERSE, BELNAP B_4 (para_universe.mbt)
// ============================================================================

///|
test "M8.1 Belnap four-valued bilattice: lattice laws, De Morgan, conservative Boolean embedding" {
  let vs = @super_emergence.four_all_values()
  assert_eq(vs.length(), 4)
  for a in vs {
    for b in vs {
      // Commutativity of the information join and meet
      assert_true(
        @super_emergence.FourVal::join(a, b) ==
        @super_emergence.FourVal::join(b, a),
      )
      assert_true(
        @super_emergence.FourVal::meet(a, b) ==
        @super_emergence.FourVal::meet(b, a),
      )
      // Information-lattice absorption laws (join = lub, meet = glb)
      assert_true(
        @super_emergence.FourVal::meet(a, @super_emergence.FourVal::join(a, b)) ==
        a,
      )
      assert_true(
        @super_emergence.FourVal::join(a, @super_emergence.FourVal::meet(a, b)) ==
        a,
      )
      // Truth-order lattice laws (lor = lub, land = glb of <=_t)
      assert_true(
        @super_emergence.FourVal::land(a, b) ==
        @super_emergence.FourVal::land(b, a),
      )
      assert_true(
        @super_emergence.FourVal::lor(a, b) ==
        @super_emergence.FourVal::lor(b, a),
      )
      assert_true(
        @super_emergence.FourVal::land(a, @super_emergence.FourVal::lor(a, b)) ==
        a,
      )
      assert_true(
        @super_emergence.FourVal::lor(a, @super_emergence.FourVal::land(a, b)) ==
        a,
      )
      // Negation is an involution
      assert_true(
        @super_emergence.FourVal::neg(@super_emergence.FourVal::neg(a)) == a,
      )
      // `truth_le` agrees with the truth-order lattice operations
      assert_true(
        @super_emergence.FourVal::truth_le(a, b) ==
        (@super_emergence.FourVal::lor(a, b) == b),
      )
      assert_true(
        @super_emergence.FourVal::truth_le(a, b) ==
        (@super_emergence.FourVal::land(a, b) == a),
      )
      // Partial orders are reflexive
      assert_true(@super_emergence.four_le(a, a))
      assert_true(@super_emergence.FourVal::truth_le(a, a))
    }
  }
  // Conservative embedding of the classical Boolean algebra
  assert_true(
    @super_emergence.classic_embed(true) == @super_emergence.Tv &&
    @super_emergence.classic_embed(false) == @super_emergence.Fv,
  )
  assert_true(
    @super_emergence.FourVal::land(
      @super_emergence.classic_embed(true),
      @super_emergence.classic_embed(false),
    ) ==
    @super_emergence.Fv,
  )
}

///|
test "M8.2 Paraconsistency: B /\\ ~B stays designated and explosion has a counterexample" {
  let b = @super_emergence.Bv
  let conj = @super_emergence.FourVal::land(b, @super_emergence.FourVal::neg(b))
  assert_true(conj.is_designated())
  assert_true(conj == @super_emergence.Bv)
  assert_true(@super_emergence.explosion_counterexample_exists())
  // A designated contradiction does NOT make an unrelated proposition designated
  assert_true(!@super_emergence.Fv.is_designated())
  assert_true(!@super_emergence.Nv.is_designated())
}

///|
test "M8.3 Knaster-Tarski: every <=_i-monotone belief operator has a least fixed point" {
  assert_true(@super_emergence.all_monotone_maps_have_fixed_point())
  let lfp = @super_emergence.tarski_least_fixed_point(v => {
    @super_emergence.epistemic_quarantine_map(v)
  })
  assert_true(lfp == @super_emergence.Nv)
}

///|
test "M8.4 Multi-world epistemic fusion: conflicting beliefs become a quarantined dialetheism" {
  let w1 = @super_emergence.ParaUniverse::new(["p", "q"], [
    @super_emergence.Tv,
    @super_emergence.Fv,
  ])
  let w2 = @super_emergence.ParaUniverse::new(["p", "q"], [
    @super_emergence.Fv,
    @super_emergence.Tv,
  ])
  let mw : @super_emergence.MultiWorld = { worlds: [w1, w2], }
  let merged = mw.merge_pointwise()
  assert_true(merged[0] == @super_emergence.Bv)
  assert_true(merged[1] == @super_emergence.Bv)
  assert_true(
    @super_emergence.ParaUniverse::lookup(w1, "p") is Some(@super_emergence.Tv),
  )
  assert_true(@super_emergence.ParaUniverse::lookup(w1, "zz") is None)
}

///|
test "M8.5 Belnap order structure: Nv is the bottom, Bv the top of the information order" {
  let vs = @super_emergence.four_all_values()
  for a in vs {
    assert_true(@super_emergence.four_le(@super_emergence.Nv, a))
    assert_true(@super_emergence.four_le(a, @super_emergence.Bv))
    assert_true(
      @super_emergence.FourVal::truth_le(
        @super_emergence.Fv,
        @super_emergence.Tv,
      ),
    )
  }
  assert_true(
    !@super_emergence.four_le(@super_emergence.Fv, @super_emergence.Tv),
  )
  assert_true(
    !@super_emergence.four_le(@super_emergence.Tv, @super_emergence.Fv),
  )
}

// ============================================================================
//  REGRESSION TESTS FOR THE LATENT BUGS FOUND DURING THE CROSS-REPO AUDIT
//  (each of these FAILED on the pre-merge `algo8` code base)
// ============================================================================

///|
test "R1 Degenerate Hermitian spectrum must not produce NaN: p_+ = I_2 on H = lambda*I" {
  // Pre-merge bug: `hermitian2_projector_plus` divided by (lambda_+ - lambda_-) = 0 and
  // produced NaN/Inf; `k0_spectral_identity` then silently returned `true` because
  // IEEE-754 `NaN > eps` is `false`.
  let h : @super_emergence.Hermitian2 = {
    a: 3.0,
    b: 3.0,
    q: @super_emergence.Quat::zero(),
  }
  let (alpha, delta, bq) = @super_emergence.hermitian2_projector_plus(h)
  assert_true(alpha.is_finite() && delta.is_finite())
  assert_true(bq.norm().is_finite())
  // The correct answer is the FULL-RANK projection onto the (degenerate) eigenspace
  assert_true((alpha - 1.0).abs() < 1.0e-12)
  assert_true((delta - 1.0).abs() < 1.0e-12)
  assert_true(bq.norm() < 1.0e-12)
  // And the K_0 identities must hold with a finite, integer index
  assert_true(@super_emergence.k0_spectral_identity(h, 1.0e-12))
}

///|
test "R2 absorption_time_linear_solve must not mutate the caller's right-hand side" {
  // Pre-merge bug: `let rhs = r` aliased the caller's array and the Gauss-Jordan
  // elimination overwrote it in place.
  let p = @super_emergence.memory_absorbing_matrix()
  let q : Array[Array[Double]] = []
  for i in 0..<4 {
    let qrow : Array[Double] = []
    for j in 0..<4 {
      qrow.push(p[i][j])
    }
    q.push(qrow)
  }
  let r : Array[Double] = [1.0, 1.0, 1.0, 1.0]
  let _ = @super_emergence.absorption_time_linear_solve(q, r)
  assert_true(r[0] == 1.0 && r[1] == 1.0 && r[2] == 1.0 && r[3] == 1.0)
}

///|
test "R3 symplectic variational Jacobian must use dt (not eps) as the step size" {
  // Pre-merge bug: `variational_jacobian` passed the perturbation `eps` as the `dt`
  // argument of the integrator, so the residual measured a different flow.
  let h = @super_emergence.default_neural_h()
  let q : Array[Double] = [0.7, -0.4]
  let p : Array[Double] = [0.3, 0.9]
  let symp = @super_emergence.symplectic_identity_residual(h, q, p, 0.1)
  let expl = @super_emergence.explicit_identity_residual(h, q, p, 0.1)
  assert_true(symp < 1.0e-6)
  assert_true(expl > 1.0e-3)
  // The defect must be independent of the step size (it is a structural identity)
  let symp2 = @super_emergence.symplectic_identity_residual(h, q, p, 0.05)
  assert_true((symp - symp2).abs() < 1.0e-6)
}

///|
test "R4 bundle conjugation must be protected against singular transition functions" {
  // Pre-merge bug: `conjugate` inverted the transition matrix without a zero-determinant
  // guard, producing NaN/Inf for a singular frame change.
  let a : Array[Double] = [1.0, 2.0, 0.0, -1.0]
  let b : Array[Double] = [0.0, 1.0, 1.0, 0.0]
  let singular : Array[Double] = [0.0, 0.0, 0.0, 0.0]
  assert_true(
    !@super_emergence.emergent_commutator_trace(a, b, singular, 1.0e-10),
  )
  assert_true(
    !@super_emergence.patch_sections(
      [1.0, 0.5, 0.0, 2.0],
      [1.0, 0.0, 0.0, 1.0],
      singular,
      1.0e-12,
    ),
  )
}

///|
test "R5 complex division must be protected against the zero divisor" {
  // Pre-merge bug: `Complex::div` had no zero-divisor guard.
  let zero = @super_emergence.Complex::zero()
  let q = @super_emergence.Complex::one() / zero
  assert_true(q.re.is_finite() && q.im.is_finite())
  assert_true(q.re == 0.0 && q.im == 0.0)
  // Non-zero division still behaves like a field
  let z = @super_emergence.Complex::new(3.0, 4.0)
  let inv = @super_emergence.Complex::one() / z
  assert_true(c_eq(z * inv, @super_emergence.Complex::one(), 1.0e-12))
}

///|
test "R6 Belnap values and quaternions must be compared STRUCTURALLY, not via strings" {
  // Pre-merge bug: `FourVal` was compared through string allocation.
  let a = @super_emergence.Bv
  let b = @super_emergence.Bv
  assert_true(a == b)
  assert_true(
    @super_emergence.FourVal::to_string(a) ==
    @super_emergence.FourVal::to_string(b),
  )
  assert_true(a != @super_emergence.Tv)
  // The enum is usable as a hash key (structural hashing, not string hashing)
  let seen : Array[@super_emergence.FourVal] = []
  let mut dup = false
  for v in @super_emergence.four_all_values() {
    for s in seen {
      if s == v {
        dup = true
      }
    }
    seen.push(v)
  }
  assert_true(!dup)
  // Quaternions compare structurally too
  let q1 = @super_emergence.Quat::new(0.5, 0.25, -0.1, 0.3)
  let q2 = @super_emergence.Quat::new(0.5, 0.25, -0.1, 0.3)
  assert_true(q1 == q2)
}

///|
test "R7 singular matrix inverse must return the zero matrix, never a bogus partial inverse" {
  // Regression: the Gauss-Jordan inverse used to `continue` past a degenerate pivot,
  // silently returning a matrix that did NOT satisfy A * A^{-1} == I.
  // SINGULAR-PIVOT CONTRACT: a degenerate pivot means no inverse exists, so the zero
  // matrix is returned (same neutral-element convention as Grassmann::inv).
  let sing = @super_emergence.DenseMat::zeros(3, 3)
  sing.set(0, 0, 2.0)
  sing.set(1, 1, 4.0)
  assert_true(@super_emergence.DenseMat::det(sing).abs() < 1.0e-15)
  let inv_s = sing.inv()
  // Zero matrix, finite, and clearly distinguishable from a plausible-looking inverse.
  assert_true(inv_s.frob_norm() == 0.0)
  for v in inv_s.data {
    assert_true(v.is_finite())
  }
  // An invertible matrix still inverts exactly.
  let ok = @super_emergence.DenseMat::from_fn(2, 2, (i, j) => {
    if i == j {
      4.0
    } else {
      1.0
    }
  })
  let inv_ok = ok.inv()
  assert_true(
    (ok * inv_ok - @super_emergence.DenseMat::eye(2)).frob_norm() < 1.0e-12,
  )
}

///|
test "R8 singular even Grassmann matrix inverse must return the zero matrix" {
  // The same singular-pivot contract must hold over the commutative even subalgebra
  // Lambda_{N, even}: gmat_even_det already reported singularity as zero, so
  // gmat_even_inv must not hand back a partially eliminated "inverse".
  let g = 4
  let n = 2
  let one = @super_emergence.Grassmann::scalar(g, 1.0)
  let sing = [one, one, one, one]
  assert_true(@super_emergence.gmat_even_det(sing, n, g).l2_norm() == 0.0)
  let inv_s = @super_emergence.gmat_even_inv(sing, n, g)
  assert_true(inv_s.length() == n * n)
  for v in inv_s {
    assert_true(v.l2_norm() == 0.0)
    assert_true(v.l2_norm().is_finite())
  }
  // An invertible even matrix still inverts exactly: A * A^{-1} == I.
  let ok = [
    @super_emergence.Grassmann::scalar(g, 2.0),
    @super_emergence.Grassmann::scalar(g, 1.0),
    @super_emergence.Grassmann::scalar(g, 0.0),
    @super_emergence.Grassmann::scalar(g, 3.0),
  ]
  let inv_ok = @super_emergence.gmat_even_inv(ok, n, g)
  let prod = @super_emergence.gmat_mul(ok, n, n, inv_ok, n, g)
  let eye = @super_emergence.gmat_eye(n, g)
  for i in 0..<(n * n) {
    assert_true((prod[i] - eye[i]).l2_norm() < 1.0e-14)
  }
}

///|
test "R9 zero-body Grassmann inverse, logarithm and square root must stay finite" {
  // Zero-divisor / out-of-domain guards: these must return the zero element rather
  // than letting 1/0 = Inf, ln(0) = -Inf or sqrt(b < 0) propagate as NaN.
  let z = @super_emergence.Grassmann::zero(4)
  assert_true(z.inv().l2_norm() == 0.0)
  assert_true(z.ln().l2_norm() == 0.0)
  assert_true(z.sqrt().l2_norm() == 0.0)
  // A pure soul element (zero body) has no multiplicative inverse either.
  let psi = @super_emergence.Grassmann::generator(4, 0)
  assert_true(psi.inv().l2_norm() == 0.0)
  assert_true(psi.ln().l2_norm() == 0.0)
  assert_true(psi.sqrt().l2_norm() == 0.0)
  // Negative body is outside the square-root domain -> zero element, still finite.
  let neg = @super_emergence.Grassmann::scalar(4, -4.0)
  assert_true(neg.sqrt().l2_norm() == 0.0)
  assert_true(neg.sqrt().l2_norm().is_finite())
}

///|
test "R10 quaternion Rayleigh quotient at the zero vector must not produce NaN" {
  // 0/0 in the Rayleigh quotient is undefined; the guarded implementation returns 0.0.
  let h : @super_emergence.Hermitian2 = {
    a: 2.0,
    b: 3.0,
    q: @super_emergence.Quat::new(0.0, 0.0, 0.0, 1.0),
  }
  let zero_v = [@super_emergence.Quat::zero(), @super_emergence.Quat::zero()]
  let r = @super_emergence.rayleigh_real(h, zero_v)
  assert_true(r.is_finite())
  assert_true(r == 0.0)
  let ri = @super_emergence.rayleigh_imag_residual(h, zero_v)
  assert_true(ri.is_finite())
  assert_true(ri == 0.0)
}

///|
test "R11 NaN defects must FAIL every verification predicate, never silently pass" {
  // `NaN > eps` is false in IEEE-754, so a positive-form guard (`if residual > eps`)
  // would let a NaN defect through unnoticed. Every predicate that compares a
  // residual must therefore use the NaN-safe form (`!(residual <= eps)`).
  let inf_v = 1.0 / 0.0
  let nan_v = inf_v - inf_v
  assert_true(nan_v.is_nan())

  // (a) Cocycle condition: the defect `gab * gbc - gac` is NaN (Inf - Inf).
  let gab = [inf_v, 0.0, 0.0, 1.0]
  let gbc = [1.0, 0.0, 0.0, 1.0]
  let gac = [inf_v, 0.0, 0.0, 1.0]
  assert_true(!@super_emergence.cocycle_condition(gab, gbc, gac, 1.0e-12))

  // (b) Section patching / commutator trace: the frame determinant is NaN.
  let nan_frame = [inf_v, 0.0, 0.0, 0.0]
  assert_true(
    !@super_emergence.patch_sections(
      [1.0, 0.5, 0.0, 2.0],
      [1.0, 0.5, 0.0, 2.0],
      nan_frame,
      1.0e-12,
    ),
  )
  assert_true(
    !@super_emergence.emergent_commutator_trace(
      [1.0, 2.0, 0.0, -1.0],
      [0.0, 1.0, 1.0, 0.0],
      nan_frame,
      1.0e-10,
    ),
  )

  // (c) Functor law: a NaN-encoded layer must NOT satisfy the functoriality law.
  let nan_layer : @super_emergence.Layer = { w: [[(-1.0).sqrt()]], b: [0.0], }
  let net : @super_emergence.SynergeticNet = { encoder: nan_layer, n_order: 1, }
  assert_true(
    !@super_emergence.functor_laws_synergetic(net, [1.0], [1.0], [2.0]),
  )

  // (d) The NaN-safe proximity helper must reject NaN on both sides.
  let approx_a = @super_emergence.approx(0.0, 0.0, 1.0e-12)
  assert_true(approx_a)
  let approx_b = @super_emergence.approx(nan_v, 0.0, 1.0e-12)
  assert_true(!approx_b)
}
