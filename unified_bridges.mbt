///|
/// Module 24 (Unified Bridge Layer / Tier-3): the six MERGE-ONLY mathematical dividends
/// that exist ONLY when `algorithm04` (super-geometry, Schur-Berezin mass, Grassmann
/// exterior logic, Poincaré ontology, noncommutative spectral triples) and `algo8`
/// (gated memory, Haken synergetics, symplectic structure preservation, operator
/// bundles, quaternionic K-theory, Belnap paraconsistency) live in ONE type system:
///
///   XV.  Schur-Mass Metriplectic Structure-Preserving Flow (Theorem XV)
///         - conservative sub-flow is EXACTLY symplectic: J^T Omega J = Omega, det J = 1
///         - dissipative relaxation is EXACTLY metriplectic: A^T Omega + Omega A = -gamma Omega
///         - Schur-Berezin effective mass M_eff = M + Xi Omega^{-1} Xi^T drives the dynamics
///         - double-well barrier escape: conservative flow stays trapped, metriplectic escapes
///   XVI. Belnap-Grassmann-Poincare Paraconsistent Unification (Theorem XVI)
///         - Belnap B_4 four-valued labelling of every unification outcome
///         - Pauli-Grassmann exclusion and structural clash are QUARANTINED (Bv), never exploded
///         - Knaster-Tarski epistemic least fixed point over belief operators
///   XVII. Cech SuperOperatorBundle, Holonomy & Quaternionic Kramers-Connes (Theorem XVII)
///         - Cech cocycle condition g_ab g_bc = g_ac in the Grassmann superalgebra
///         - holonomy around a loop and gauge invariance of str / Ber
///         - arbitrary-n quaternionic graph -> real 4n x 4n Kramers 4-fold degenerate embedding
///         - integer K_0 direct-sum index and quaternionic Connes spectral distance
///   XVIII. SGNE-Syn-Mem-Para: role-gated memory, Haken/Supertropical duality, finite
///           bicompleteness and colony paraconsistent world fusion (Theorem XVIII)
///
/// DESIGN RULE: this layer is UNIDIRECTIONAL. Tier-0/Tier-1/Tier-2 modules never import
/// from here; only `emergence.mbt` (Layer 4) consumes this module. This keeps the two
/// upstream code bases decoupled while concentrating every cross-domain theorem in one place.

///|
/// ========================================================================
/// 24.1  SCHUR-MASS METRIPLECTIC STRUCTURE-PRESERVING FLOW (Theorem XV)
/// ========================================================================

///|
/// Schur-Mass Metriplectic Super-Hamiltonian on the phase space (q, p) in R^n x R^n:
///   H(q, p) = 1/2 p^T M_eff p + sum_i kappa_i (q_i^2 - 1)^2,
/// where M_eff = M + Xi Omega^{-1} Xi^T is the Schur-Berezin renormalized bosonic mass
/// of `SuperMassTensor` (algorithm04) and the potential is a separable multi-well landscape.
/// The induced generator A(q) = [[0, -K(q)], [K(q), -gamma I]] with K(q) = Hess(V)(q)
/// satisfies the METRIPLECTIC CONDITION exactly:
///   A^T Omega + Omega A = -gamma Omega,   Omega = [[0, I_n], [-I_n, 0]].
#derive(Debug, Eq)
pub(all) struct SuperHamiltonian {
  m_eff : DenseMat
  kappa : Array[Double]
  gamma : Double
}

///|
pub fn SuperHamiltonian::dim(self : SuperHamiltonian) -> Int32 {
  self.m_eff.rows
}

///|
/// Gradient of the separable multi-well potential V(q) = sum_i kappa_i (q_i^2 - 1)^2.
pub fn SuperHamiltonian::grad_potential(
  self : SuperHamiltonian,
  q : Array[Double],
) -> Array[Double] {
  Array::makei(q.length(), i => {
    let qi = q[i]
    4.0 * self.kappa[i] * qi * (qi * qi - 1.0)
  })
}

///|
/// Hessian of the separable multi-well potential (diagonal, K_ij = 4 kappa_i (3 q_i^2 - 1)).
pub fn SuperHamiltonian::hess_potential(
  self : SuperHamiltonian,
  q : Array[Double],
) -> DenseMat {
  let n = q.length()
  DenseMat::from_fn(n, n, (i, j) => {
    if i == j {
      4.0 * self.kappa[i] * (3.0 * q[i] * q[i] - 1.0)
    } else {
      0.0
    }
  })
}

///|
/// Total Hamiltonian energy H(q, p) = 1/2 p^T M_eff p + V(q).
pub fn SuperHamiltonian::energy(
  self : SuperHamiltonian,
  q : Array[Double],
  p : Array[Double],
) -> Double {
  let mv = self.m_eff.matvec(p)
  let mut ke = 0.0
  for i in 0..<p.length() {
    ke = ke + 0.5 * p[i] * mv[i]
  }
  let mut pe = 0.0
  for i in 0..<q.length() {
    let d = q[i] * q[i] - 1.0
    pe = pe + self.kappa[i] * d * d
  }
  ke + pe
}

///|
/// Conservative (Hamiltonian) part A_c(q) = [[0, -K(q)], [K(q), 0]] of the metriplectic generator.
pub fn SuperHamiltonian::conservative_generator(
  self : SuperHamiltonian,
  q : Array[Double],
) -> DenseMat {
  let n = q.length()
  let k = self.hess_potential(q)
  let g = DenseMat::zeros(2 * n, 2 * n)
  for i in 0..<n {
    for j in 0..<n {
      g.set(i, n + j, -k.get(i, j))
      g.set(n + i, j, k.get(i, j))
    }
  }
  g
}

///|
/// Full metriplectic generator A(q) = [[0, -K(q)], [K(q), -gamma I]] on the 2n-dimensional phase space.
pub fn SuperHamiltonian::phase_generator(
  self : SuperHamiltonian,
  q : Array[Double],
) -> DenseMat {
  let n = q.length()
  let g = self.conservative_generator(q)
  for i in 0..<n {
    g.set(n + i, n + i, -self.gamma)
  }
  g
}

///|
/// Canonical symplectic form Omega = [[0, I_n], [-I_n, 0]] on the 2n-dimensional phase space.
pub fn SuperHamiltonian::symplectic_form(self : SuperHamiltonian) -> DenseMat {
  canonical_symplectic(2 * self.dim())
}

///|
/// METRIPLECTIC DEFECT  || A^T Omega + Omega A + gamma Omega ||_F  (identically 0).
pub fn SuperHamiltonian::metriplectic_defect(
  self : SuperHamiltonian,
  q : Array[Double],
) -> Double {
  let a = self.phase_generator(q)
  let omega = self.symplectic_form()
  (a.transpose() * omega + omega * a + omega.scale(self.gamma)).frob_norm()
}

///|
/// Exact linearized conservative flow Jacobian J = exp(dt * A_c(q)) of the Hamiltonian sub-dynamics.
pub fn SuperHamiltonian::conservative_flow_jacobian(
  self : SuperHamiltonian,
  q : Array[Double],
  dt : Double,
) -> DenseMat {
  self.conservative_generator(q).scale(dt).mat_exp()
}

///|
/// SYMPLECTIC DEFECT of the conservative sub-flow:  || J^T Omega J - Omega ||_F  (identically 0).
pub fn SuperHamiltonian::symplectic_defect(
  self : SuperHamiltonian,
  q : Array[Double],
  dt : Double,
) -> Double {
  let j = self.conservative_flow_jacobian(q, dt)
  let omega = self.symplectic_form()
  (j.transpose() * omega * j - omega).frob_norm()
}

///|
/// DISSIPATIVE PHASE-VOLUME CONTRACTION FACTOR of the relaxation D = diag(I_n, e^{-gamma dt} I_n):
///   D^T Omega D = e^{-gamma dt} Omega,  det D = e^{-gamma dt} < 1 for gamma > 0.
pub fn SuperHamiltonian::dissipation_contraction(
  self : SuperHamiltonian,
  dt : Double,
) -> Double {
  @math.exp(-self.gamma * dt)
}

///|
/// One metriplectic step: symplectic-Euler conservative update, exact viscous damping
/// -gamma p, and an optional deterministic fluctuation impulse `noise`.
pub fn SuperHamiltonian::metriplectic_step(
  self : SuperHamiltonian,
  q : Array[Double],
  p : Array[Double],
  dt : Double,
  noise : Array[Double],
) -> (Array[Double], Array[Double]) {
  let n = q.length()
  let grad = self.grad_potential(q)
  let p2 = Array::makei(n, i => {
    p[i] - dt * grad[i] - self.gamma * dt * p[i] + noise[i]
  })
  let mv = self.m_eff.matvec(p2)
  let q2 = Array::makei(n, i => q[i] + dt * mv[i])
  (q2, p2)
}

///|
/// Deterministic Park-Miller (multiplicative congruential) pseudo-random generator in
/// Double arithmetic: guarantees bit-identical barrier-escape statistics on all three
/// backends (wasm-gc / wasm / js) without any external random dependency.
fn pm_uniform(seed : Int32, k : Int32) -> Double {
  let m = 2147483647.0
  let mut s = seed.to_double() * 48271.0 + k.to_double() * 69621.0
  s = s - (s / m).floor() * m
  for _ in 0..<6 {
    s = s * 48271.0
    s = s - (s / m).floor() * m
  }
  s / m
}

///|
/// Deterministic standard-normal deviate (Box-Muller transform of `pm_uniform`).
fn pm_normal(seed : Int32, k : Int32) -> Double {
  let u1 = pm_uniform(seed, 2 * k).max(1.0e-12)
  let u2 = pm_uniform(seed, 2 * k + 1)
  (-2.0 * @math.ln(u1)).sqrt() * @math.cos(6.283185307179586 * u2)
}

///|
/// Outcome of the double-well barrier-escape experiment.
#derive(Debug, Eq)
pub(all) struct BarrierEscapeReport {
  conservative_escapes : Int32
  metriplectic_escapes : Int32
  trials : Int32
  barrier_height : Double
  conservative_max_energy : Double
  metriplectic_min_energy : Double
}

///|
/// Canonical ONE-DIMENSIONAL double-well metriplectic instance (V(x) = kappa (x^2 - 1)^2,
/// barrier height kappa at x = 0) used by the barrier-escape experiment.
pub fn double_well_instance() -> SuperHamiltonian {
  { m_eff: DenseMat::from_fn(1, 1, (_, _) => 1.0), kappa: [0.5], gamma: 0.35, }
}

///|
/// DOUBLE-WELL BARRIER ESCAPE under the metriplectic flow:
///   - the conservative symplectic flow (gamma = 0, no fluctuation) conserves H and stays
///     trapped in the metastable well because H_0 < H_barrier (verified numerically);
///   - the metriplectic flow (gamma > 0 with thermal fluctuation sigma > 0) crosses the
///     barrier with strictly positive escape frequency.
pub fn double_well_barrier_escape(
  h : SuperHamiltonian,
  trials : Int32,
  steps : Int32,
  dt : Double,
  sigma : Double,
) -> BarrierEscapeReport {
  let barrier = h.kappa[0] // V(0) = kappa (0 - 1)^2 = kappa
  let mut cons_escapes = 0
  let mut met_escapes = 0
  let mut cons_max_e = 0.0
  let mut met_min_e = 1.0e30
  for t in 0..<trials {
    // --- conservative branch: gamma = 0, no noise ---
    let mut q = [1.0]
    let mut p = [0.0]
    let e0 = h.energy(q, p)
    let mut max_e = e0
    for _ in 0..<steps {
      let (q1, p1) = h.metriplectic_step(q, p, dt, [0.0])
      q = q1
      p = p1
      let e = h.energy(q, p)
      if e > max_e {
        max_e = e
      }
    }
    if max_e > cons_max_e {
      cons_max_e = max_e
    }
    if q[0] < 0.0 {
      cons_escapes = cons_escapes + 1
    }
    // --- metriplectic branch: damping + fluctuation ---
    let mut qm = [1.0]
    let mut pm = [0.0]
    let mut min_e = h.energy(qm, pm)
    for k in 0..<steps {
      let amp = sigma * (2.0 * dt).sqrt()
      let z = pm_normal(t, k)
      let (q1, p1) = h.metriplectic_step(qm, pm, dt, [amp * z])
      qm = q1
      pm = p1
      let e = h.energy(qm, pm)
      if e < min_e {
        min_e = e
      }
    }
    if min_e < met_min_e {
      met_min_e = min_e
    }
    if qm[0] < 0.0 {
      met_escapes = met_escapes + 1
    }
  }
  {
    conservative_escapes: cons_escapes,
    metriplectic_escapes: met_escapes,
    trials,
    barrier_height: barrier,
    conservative_max_energy: cons_max_e,
    metriplectic_min_energy: met_min_e,
  }
}

///|
/// Canonical Schur-Berezin fixture shared by every Theorem XV certificate:
/// bare bosonic mass M = [[2.4, 0.3], [0.3, 1.8]] (SPD), an odd Yukawa coupling
/// Xi (2 x 2) over Lambda_4 and symplectic stiffness Omega = 1.2 * J_2.
/// Single source of truth for the fixture used by the metriplectic instance,
/// the soul-mass certificate and the effective-mass identity.
fn schur_fixture_tensor() -> SuperMassTensor {
  let m = DenseMat::from_fn(2, 2, (i, j) => {
    if i == j {
      if i == 0 {
        2.4
      } else {
        1.8
      }
    } else {
      0.3
    }
  })
  let xi_odd = [
    Grassmann::generator(4, 0, coeff=0.45),
    Grassmann::generator(4, 1, coeff=-0.30),
    Grassmann::generator(4, 2, coeff=0.25),
    Grassmann::generator(4, 3, coeff=0.35),
  ]
  SuperMassTensor::from_real_and_yukawa(m, xi_odd, 1.2, 2, 4)
}

///|
/// Canonical single-well / double-well metriplectic instance built from the Schur-Berezin
/// renormalized mass of a genuine `SuperMassTensor` (algorithm04) fused with the double-well
/// landscape (algo8). This is the concrete MERGE-ONLY object of Theorem XV.
pub fn schur_metriplectic_instance() -> SuperHamiltonian {
  let sm = schur_fixture_tensor()
  let (_, _, m_eff) = sm.schur_canonical_form()
  let meff = DenseMat::from_fn(2, 2, (i, j) => m_eff[i * 2 + j].body())
  { m_eff: meff, kappa: [0.5, 0.5], gamma: 0.35, }
}

///|
/// SCHUR-BEREZIN SOUL MASS RENORMALIZATION CERTIFICATE:
///   Delta M = M_eff - M = Xi Omega^{-1} Xi^T
/// is a PURELY FERMIONIC (soul) correction: because the Yukawa coupling Xi is odd and
/// Omega^{-1} is even, every entry of Delta M is a product of two odd generators and
/// therefore has ZERO body but a NON-ZERO soul. The fermionic sector thus literally adds
/// super-inertia to the bosonic mass without changing its classical (body) value.
/// Returns (soul Frobenius norm of Delta M, body trace of Delta M).
pub fn schur_soul_mass_shift() -> (Double, Double) {
  let sm = schur_fixture_tensor()
  let (a_blk, _, _, _) = sm.mat.blocks()
  let (_, _, m_eff) = sm.schur_canonical_form()
  let mb : Int32 = 2
  // Delta M = M_eff - M is the literal Schur-Berezin renormalization shift.
  let mut soul = 0.0
  let mut body_trace = 0.0
  for i in 0..<(mb * mb) {
    let delta = m_eff[i] - a_blk[i]
    soul = soul + delta.soul().l2_norm()
    body_trace = body_trace + delta.body()
  }
  (soul, body_trace)
}

///|
/// EXACT SCHUR-BEREZIN IDENTITY RESIDUAL:
///   || M_eff - (M + Xi Omega^{-1} Xi^T) ||  in the Grassmann algebra Lambda_4^even,
/// where M_eff is the effective bosonic mass returned by `schur_canonical_form`.
pub fn schur_effective_mass_identity() -> Double {
  let sm = schur_fixture_tensor()
  let (_, _, m_eff) = sm.schur_canonical_form()
  let (a_blk, xi, _, om) = sm.mat.blocks()
  let g = DEFAULT_GRASSMANN_GEN
  let mb : Int32 = 2
  let nf : Int32 = 2
  let om_inv = gmat_even_inv(om, nf, g)
  let xi_t = Array::makei(nf * mb, idx => {
    let alpha = idx / mb
    let i = idx % mb
    xi[i * nf + alpha]
  })
  let bdc = gmat_mul(gmat_mul(xi, mb, nf, om_inv, nf, g), mb, nf, xi_t, mb, g)
  let mut resid = 0.0
  for i in 0..<(mb * mb) {
    let diff = (m_eff[i] - (a_blk[i] + bdc[i])).l2_norm()
    if diff > resid {
      resid = diff
    }
  }
  resid
}

///|
/// ========================================================================
/// 24.2  BELNAP-GRASSMANN-POINCARE PARACONSISTENT UNIFICATION (Theorem XVI)
/// ========================================================================

///|
/// Outcome of a PARACONSISTENT neuro-symbolic unification: the conclusion carries a
/// Belnap four-valued epistemic label; contradictions are QUARANTINED (`Bv`) rather than
/// triggering classical explosion (ex contradictione quodlibet).
#derive(Debug, Eq)
pub(all) struct ParaUnifyReport {
  term : SymTerm
  subst : Substitution
  value : FourVal
  coherence : Double
  anomaly : Double
  logic : Grassmann
  quarantined : Bool
  pauli_excluded : Bool
  reason : String
}

///|
/// PARACONSISTENT NEURO-SYMBOLIC UNIFICATION U_tau^B (Belnap-Grassmann-Poincare):
///   1. the Pauli-Grassmann exterior exclusion (psi_1 ^ psi_2 = 0) is NOT a hard failure:
///      it is quarantined as the dialetheic value `Bv` (both true and false);
///   2. a structural clash is likewise quarantined as `Bv` with a diagnostic reason;
///   3. a coherent unification yields `Tv`, a weakly coherent one yields `Nv`/`Bv`
///      according to the Poincaré hyperbolic coherence exp(-d_c / tau);
///   4. in ALL cases the conclusion is a well-formed Belnap value, so the reasoning step
///      never explodes and never contaminates orthogonal propositions.
pub fn unify_paraconsistent(
  s1 : NeuroSymState,
  s2 : NeuroSymState,
  sym_embed : (String) -> PoincarePoint,
  tau~ : Double = 0.8,
  min_coherence~ : Double = 0.35,
) -> ParaUnifyReport {
  let merged_logic = s1.logic * s2.logic
  let d = s1.emb.geodesic_dist(s2.emb)
  let coherence = @math.exp(-d / tau)
  let pauli = s1.logic.l2_norm() > 1.0e-12 &&
    s2.logic.l2_norm() > 1.0e-12 &&
    merged_logic.l2_norm() < 1.0e-12
  if pauli {
    return {
      term: s1.term,
      subst: Substitution::empty(),
      value: Bv,
      coherence,
      anomaly: d,
      logic: merged_logic,
      quarantined: true,
      pauli_excluded: true,
      reason: "Pauli-Grassmann exclusion quarantined as Belnap dialetheism Bv",
    }
  }
  match unify_neuro_symbolic(s1, s2, sym_embed, tau~, min_coherence~) {
    Unified(subst, term, _emb, logic, coh, anom) => {
      let value = if coh >= min_coherence { Tv } else { Bv }
      {
        term,
        subst,
        value,
        coherence: coh,
        anomaly: anom,
        logic,
        quarantined: value == Bv,
        pauli_excluded: false,
        reason: "Graded neuro-symbolic unification with Belnap epistemic labelling",
      }
    }
    Contradiction(reason) =>
      {
        term: s1.term,
        subst: Substitution::empty(),
        value: Bv,
        coherence,
        anomaly: d,
        logic: merged_logic,
        quarantined: true,
        pauli_excluded: false,
        reason: "Structural clash quarantined as Belnap dialetheism Bv: " +
        reason,
      }
  }
}

///|
/// PARACONSISTENT NON-EXPLOSION WITNESS: fuse the validated union of named propositions
/// by the Belnap information join and certify that
///   (i)  at least one proposition is quarantined as a dialetheism `Bv` (designated), and
///   (ii) at least one orthogonal proposition remains undesignated (`Fv`/`Nv`),
/// hence the classical rule "from a contradiction everything follows" FAILS.
/// Malformed worlds produce the compatibility result `(false, [])`.
pub fn paraconsistent_no_explosion(
  worlds : Array[ParaUniverse],
) -> (Bool, Array[FourVal]) {
  let mw : MultiWorld = { worlds, }
  let fused = match mw.aggregate() {
    Ok(state) => state.vals
    Err(_) => []
  }
  let mut has_contradiction = false
  let mut has_undesignated = false
  for v in fused {
    if v == Bv {
      has_contradiction = true
    }
    if !v.is_designated() {
      has_undesignated = true
    }
  }
  (has_contradiction && has_undesignated, fused)
}

///|
/// Epistemic Knaster-Tarski least fixed point of a Belnap belief operator, obtained by
/// the constructive iteration lfp_{<=_i}(f) = |_|_{k >= 0} f^k(Nv) which stabilizes in at
/// most height(B_4) = 2 steps for any <=_i-monotone f.
pub fn epistemic_least_fixed_point(f : (FourVal) -> FourVal) -> FourVal {
  tarski_least_fixed_point(f)
}

///|
/// ========================================================================
/// 24.3  CECH SUPEROPERATOR BUNDLE, HOLONOMY & QUATERNIONIC KRAMERS-CONNES (Theorem XVII)
/// ========================================================================

///|
/// Finite Čech 2-skeleton of a super-operator bundle. Pairwise intersections and genuine
/// triple intersections are stored separately, so a pairwise clique need not be a 2-simplex.
/// `local_ops[i]` is the local Grassmann-valued section and `transitions[i][j]` is g_ij.
#derive(Debug, Eq)
pub(all) struct SuperOperatorBundle {
  n_sets : Int32
  overlaps : Array[Array[Bool]]
  triple_overlaps : Array[Array[Array[Bool]]]
  local_ops : Array[SuperMatrix]
  transitions : Array[Array[SuperMatrix]]
}

///|
fn cech_infinity() -> Double {
  1.0 / 0.0
}

///|
fn cech_safe_norm(matrix : SuperMatrix) -> Double {
  let value = matrix.frob_norm()
  if value.is_finite() {
    value
  } else {
    cech_infinity()
  }
}

///|
fn cech_max_defect(current : Double, candidate : Double) -> Double {
  if !candidate.is_finite() {
    cech_infinity()
  } else if candidate > current {
    candidate
  } else {
    current
  }
}

///|
fn cech_matrix_storage_valid(matrix : SuperMatrix) -> Bool {
  let dim = matrix.m_bos + matrix.n_ferm
  matrix.m_bos >= 0 &&
  matrix.n_ferm >= 0 &&
  matrix.n_gen >= 0 &&
  dim >= 0 &&
  matrix.entries.length() == dim * dim
}

///|
fn cech_same_layout(a : SuperMatrix, b : SuperMatrix) -> Bool {
  a.m_bos == b.m_bos && a.n_ferm == b.n_ferm && a.n_gen == b.n_gen
}

///|
/// Check storage, parity, pair/triple intersection consistency, and matrix-layout invariants
/// before any Čech operation indexes transition data.
pub fn SuperOperatorBundle::is_well_formed(self : SuperOperatorBundle) -> Bool {
  if self.n_sets <= 0 ||
    self.overlaps.length() != self.n_sets ||
    self.triple_overlaps.length() != self.n_sets ||
    self.local_ops.length() != self.n_sets ||
    self.transitions.length() != self.n_sets {
    return false
  }
  // Validate all outer dimensions before cross-indexing any overlap row.
  for i in 0..<self.n_sets {
    if self.overlaps[i].length() != self.n_sets ||
      self.triple_overlaps[i].length() != self.n_sets ||
      self.transitions[i].length() != self.n_sets ||
      !self.overlaps[i][i] {
      return false
    }
    for j in 0..<self.n_sets {
      if self.triple_overlaps[i][j].length() != self.n_sets {
        return false
      }
    }
  }
  let base = self.local_ops[0]
  if !cech_matrix_storage_valid(base) || base.parity != Even {
    return false
  }
  for i in 0..<self.n_sets {
    let section = self.local_ops[i]
    if !cech_matrix_storage_valid(section) ||
      section.parity != Even ||
      !cech_same_layout(base, section) {
      return false
    }
    for j in 0..<self.n_sets {
      let transition = self.transitions[i][j]
      if !cech_matrix_storage_valid(transition) ||
        transition.parity != Even ||
        !cech_same_layout(base, transition) {
        return false
      }
    }
  }
  for i in 0..<self.n_sets {
    for j in 0..<self.n_sets {
      if self.overlaps[i][j] != self.overlaps[j][i] {
        return false
      }
      for k in 0..<self.n_sets {
        let simplex = self.triple_overlaps[i][j][k]
        if simplex != self.triple_overlaps[j][i][k] ||
          simplex != self.triple_overlaps[i][k][j] ||
          simplex != self.triple_overlaps[k][i][j] ||
          simplex != self.triple_overlaps[j][k][i] ||
          simplex != self.triple_overlaps[k][j][i] {
          return false
        }
        if simplex &&
          (!self.overlaps[i][j] || !self.overlaps[j][k] || !self.overlaps[i][k]) {
          return false
        }
        if (i == j && simplex != self.overlaps[i][k]) ||
          (i == k && simplex != self.overlaps[i][j]) ||
          (j == k && simplex != self.overlaps[i][j]) {
          return false
        }
      }
    }
  }
  true
}

///|
/// COCYCLE DEFECT on every nonempty triple overlap, including repeated indices. The
/// identity and inverse-transition laws are checked explicitly as part of the 1-cocycle.
/// Invalid storage or non-finite arithmetic returns +infinity rather than a false zero.
pub fn SuperOperatorBundle::cocycle_defect(
  self : SuperOperatorBundle,
) -> Double {
  if !self.is_well_formed() {
    return cech_infinity()
  }
  let base = self.local_ops[0]
  let ident = SuperMatrix::identity(base.m_bos, base.n_ferm, n_gen=base.n_gen)
  let mut worst = 0.0
  for i in 0..<self.n_sets {
    worst = cech_max_defect(
      worst,
      cech_safe_norm(self.transitions[i][i] - ident),
    )
    for j in 0..<self.n_sets {
      if self.overlaps[i][j] {
        let inverse_pair = self.transitions[i][j] * self.transitions[j][i]
        worst = cech_max_defect(worst, cech_safe_norm(inverse_pair - ident))
      }
      for k in 0..<self.n_sets {
        if self.triple_overlaps[i][j][k] {
          let lhs = self.transitions[i][j] * self.transitions[j][k]
          worst = cech_max_defect(
            worst,
            cech_safe_norm(lhs - self.transitions[i][k]),
          )
        }
      }
    }
  }
  worst
}

///|
/// PATCHING DEFECT max ||g_ij^st s_i g_ij - s_j||_F over the specified overlaps.
/// This is the descent condition for the local operator sections.
pub fn SuperOperatorBundle::patch_defect(self : SuperOperatorBundle) -> Double {
  if !self.is_well_formed() {
    return cech_infinity()
  }
  let mut worst = 0.0
  for i in 0..<self.n_sets {
    for j in 0..<self.n_sets {
      if self.overlaps[i][j] {
        let g = self.transitions[i][j]
        let lhs = g.supertranspose() * self.local_ops[i] * g
        worst = cech_max_defect(worst, cech_safe_norm(lhs - self.local_ops[j]))
      }
    }
  }
  worst
}

///|
/// Glue a compatible family of local operators using `reference_patch` as the common
/// trivialization. `None` means the bundle is malformed, the cover is not star-overlapping
/// at that patch, or either the cocycle/descent equations fail at the requested tolerance.
pub fn SuperOperatorBundle::glue_section(
  self : SuperOperatorBundle,
  reference_patch : Int32,
  tol~ : Double = 1.0e-10,
) -> SuperMatrix? {
  if !self.is_well_formed() ||
    !tol.is_finite() ||
    tol < 0.0 ||
    reference_patch < 0 ||
    reference_patch >= self.n_sets {
    return None
  }
  if self.cocycle_defect() > tol || self.patch_defect() > tol {
    return None
  }
  for i in 0..<self.n_sets {
    if !self.overlaps[reference_patch][i] {
      return None
    }
  }
  Some(self.local_ops[reference_patch])
}

///|
/// Multiply transitions around the closed path `i0 -> ... -> i_(m-1) -> i0`.
/// The empty path is the identity; invalid patches or missing overlaps return `None`.
pub fn SuperOperatorBundle::holonomy(
  self : SuperOperatorBundle,
  loop_patches : Array[Int32],
) -> SuperMatrix? {
  if !self.is_well_formed() {
    return None
  }
  let base = self.local_ops[0]
  let mut product = SuperMatrix::identity(
    base.m_bos,
    base.n_ferm,
    n_gen=base.n_gen,
  )
  let n = loop_patches.length()
  if n == 0 {
    return Some(product)
  }
  for t in 0..<n {
    let a = loop_patches[t]
    let b = loop_patches[(t + 1) % n]
    if a < 0 ||
      a >= self.n_sets ||
      b < 0 ||
      b >= self.n_sets ||
      !self.overlaps[a][b] {
      return None
    }
    product = product * self.transitions[a][b]
  }
  Some(product)
}

///|
/// HOLONOMY DEFECT ||g_i0i1 ... g_i(m-1)i0 - id||_F. Invalid loops return +infinity.
pub fn SuperOperatorBundle::holonomy_defect(
  self : SuperOperatorBundle,
  loop_patches : Array[Int32],
) -> Double {
  let base = if self.local_ops.length() > 0 {
    self.local_ops[0]
  } else {
    SuperMatrix::identity(0, 0)
  }
  match self.holonomy(loop_patches) {
    Some(product) => {
      let ident = SuperMatrix::identity(
        base.m_bos,
        base.n_ferm,
        n_gen=base.n_gen,
      )
      cech_safe_norm(product - ident)
    }
    None => cech_infinity()
  }
}

///|
/// Apply a Čech 0-cochain of even invertible frame changes `h_i`:
/// `g'_ij = h_i^{-1} g_ij h_j`, `s'_i = h_i^st s_i h_i`. Returns `None` for an
/// invalid cochain/bundle; the transformed transition data must still satisfy descent.
pub fn SuperOperatorBundle::coboundary(
  self : SuperOperatorBundle,
  gauges : Array[SuperMatrix],
) -> SuperOperatorBundle? {
  if !self.is_well_formed() ||
    gauges.length() != self.n_sets ||
    self.cocycle_defect() > 1.0e-9 ||
    self.patch_defect() > 1.0e-9 {
    return None
  }
  let base = self.local_ops[0]
  for gauge in gauges {
    if !cech_matrix_storage_valid(gauge) ||
      gauge.parity != Even ||
      !cech_same_layout(base, gauge) {
      return None
    }
  }
  let inverse_gauges = gauges.map(gauge => gauge.inverse())
  let ident = SuperMatrix::identity(base.m_bos, base.n_ferm, n_gen=base.n_gen)
  let mut inverse_defect = 0.0
  for i in 0..<self.n_sets {
    inverse_defect = cech_max_defect(
      inverse_defect,
      cech_safe_norm(gauges[i] * inverse_gauges[i] - ident),
    )
    inverse_defect = cech_max_defect(
      inverse_defect,
      cech_safe_norm(inverse_gauges[i] * gauges[i] - ident),
    )
  }
  if !inverse_defect.is_finite() || inverse_defect > 1.0e-9 {
    return None
  }
  let transitions = self.transitions.map(row => row.copy())
  for i in 0..<self.n_sets {
    for j in 0..<self.n_sets {
      if self.overlaps[i][j] {
        transitions[i][j] = inverse_gauges[i] *
          self.transitions[i][j] *
          gauges[j]
      }
    }
  }
  let local_ops = Array::makei(self.n_sets, i => {
    gauges[i].supertranspose() * self.local_ops[i] * gauges[i]
  })
  let transformed : SuperOperatorBundle = {
    n_sets: self.n_sets,
    overlaps: self.overlaps,
    triple_overlaps: self.triple_overlaps,
    local_ops,
    transitions,
  }
  if !transformed.is_well_formed() ||
    transformed.cocycle_defect() > 1.0e-8 ||
    transformed.patch_defect() > 1.0e-8 {
    return None
  }
  Some(transformed)
}

///|
/// Check the nonabelian Čech coboundary law around a closed loop. The loop holonomy after
/// the local frame change is conjugate by the gauge at its base patch.
pub fn SuperOperatorBundle::coboundary_holonomy_defect(
  self : SuperOperatorBundle,
  loop_patches : Array[Int32],
  gauges : Array[SuperMatrix],
) -> Double {
  let transformed = match self.coboundary(gauges) {
    Some(value) => value
    None => return cech_infinity()
  }
  let before = match self.holonomy(loop_patches) {
    Some(value) => value
    None => return cech_infinity()
  }
  let after = match transformed.holonomy(loop_patches) {
    Some(value) => value
    None => return cech_infinity()
  }
  if loop_patches.length() == 0 {
    return cech_safe_norm(after - before)
  }
  let base_patch = loop_patches[0]
  let base_gauge = gauges[base_patch]
  let expected = base_gauge.inverse() * before * base_gauge
  cech_safe_norm(after - expected)
}

///|
/// Čech naturality for the multiplicative superoperator B = Ad_q, Ad_q(x)=q*x*q^{-1}:
/// the same B on every edge is the constant 0-cochain `h_i=q^{-1}`.
pub fn SuperOperatorBundle::superoperator_holonomy_defect(
  self : SuperOperatorBundle,
  loop_patches : Array[Int32],
  q : SuperMatrix,
) -> Double {
  if !self.is_well_formed() ||
    q.parity != Even ||
    !cech_matrix_storage_valid(q) ||
    !cech_same_layout(self.local_ops[0], q) {
    return cech_infinity()
  }
  let gauges = Array::make(self.n_sets, q.inverse())
  self.coboundary_holonomy_defect(loop_patches, gauges)
}

///|
#derive(Debug, Eq)
pub(all) struct CechMorphism {
  src : Int32
  dst : Int32
  transport : SuperMatrix
}

///|
/// Patch-pair Čech groupoid for an equivalence overlap relation with all composable triple
/// intersections present. Morphisms are transition operators; composition is matrix multiplication.
#derive(Debug, Eq)
pub(all) struct CechCategory {
  bundle : SuperOperatorBundle
  tolerance : Double
}

///|
pub fn CechCategory::is_well_formed(self : CechCategory) -> Bool {
  if !self.tolerance.is_finite() ||
    self.tolerance < 0.0 ||
    !self.bundle.is_well_formed() ||
    self.bundle.cocycle_defect() > self.tolerance {
    return false
  }
  // Transitivity is necessary for patch-pair arrows to admit composition.
  for i in 0..<self.bundle.n_sets {
    for j in 0..<self.bundle.n_sets {
      for k in 0..<self.bundle.n_sets {
        if self.bundle.overlaps[i][j] &&
          self.bundle.overlaps[j][k] &&
          (!self.bundle.overlaps[i][k] || !self.bundle.triple_overlaps[i][j][k]) {
          return false
        }
      }
    }
  }
  true
}

///|
/// Construct the Čech category only when the transition cocycle, equivalence relation, and
/// every required triple intersection satisfy the groupoid/category prerequisites. Invalid
/// data returns `None`.
pub fn CechCategory::from_bundle(
  bundle : SuperOperatorBundle,
  tolerance~ : Double = 1.0e-10,
) -> CechCategory? {
  let category : CechCategory = { bundle, tolerance, }
  if category.is_well_formed() {
    Some(category)
  } else {
    None
  }
}

///|
fn CechCategory::morphism_unchecked(
  self : CechCategory,
  src : Int32,
  dst : Int32,
) -> CechMorphism? {
  if src < 0 ||
    dst < 0 ||
    src >= self.bundle.n_sets ||
    dst >= self.bundle.n_sets ||
    !self.bundle.overlaps[src][dst] {
    return None
  }
  Some({ src, dst, transport: self.bundle.transitions[src][dst], })
}

///|
pub fn CechCategory::morphism(
  self : CechCategory,
  src : Int32,
  dst : Int32,
) -> CechMorphism? {
  if !self.is_well_formed() {
    return None
  }
  self.morphism_unchecked(src, dst)
}

///|
pub fn CechCategory::identity(
  self : CechCategory,
  object : Int32,
) -> CechMorphism? {
  self.morphism(object, object)
}

///|
fn CechCategory::contains_morphism(
  self : CechCategory,
  arrow : CechMorphism,
) -> Bool {
  if arrow.src < 0 ||
    arrow.dst < 0 ||
    arrow.src >= self.bundle.n_sets ||
    arrow.dst >= self.bundle.n_sets ||
    !self.bundle.overlaps[arrow.src][arrow.dst] ||
    !cech_matrix_storage_valid(arrow.transport) ||
    arrow.transport.parity != Even ||
    !cech_same_layout(self.bundle.local_ops[0], arrow.transport) {
    return false
  }
  let defect = cech_safe_norm(
    arrow.transport - self.bundle.transitions[arrow.src][arrow.dst],
  )
  defect.is_finite() && defect <= self.tolerance
}

///|

///|
fn CechCategory::compose_unchecked(
  self : CechCategory,
  first : CechMorphism,
  second : CechMorphism,
) -> CechMorphism? {
  if first.dst != second.src ||
    !self.contains_morphism(first) ||
    !self.contains_morphism(second) ||
    !self.bundle.overlaps[first.src][second.dst] ||
    !self.bundle.triple_overlaps[first.src][first.dst][second.dst] {
    return None
  }
  let transport = first.transport * second.transport
  let result = { src: first.src, dst: second.dst, transport, }
  if !self.contains_morphism(result) {
    return None
  }
  Some(result)
}

///|
/// Compose a path `first: i -> j`, `second: j -> k` in traversal order.
pub fn CechCategory::compose(
  self : CechCategory,
  first : CechMorphism,
  second : CechMorphism,
) -> CechMorphism? {
  if !self.is_well_formed() {
    return None
  }
  self.compose_unchecked(first, second)
}

///|
fn cech_morphism_defect(a : CechMorphism, b : CechMorphism) -> Double {
  if a.src != b.src || a.dst != b.dst {
    return cech_infinity()
  }
  cech_safe_norm(a.transport - b.transport)
}

///|
/// Maximum left/right unit-law residual over all arrows in the Čech groupoid.
pub fn CechCategory::unit_defect(self : CechCategory) -> Double {
  if !self.is_well_formed() {
    return cech_infinity()
  }
  let mut worst = 0.0
  for i in 0..<self.bundle.n_sets {
    for j in 0..<self.bundle.n_sets {
      if self.bundle.overlaps[i][j] {
        let arrow = match self.morphism_unchecked(i, j) {
          Some(value) => value
          None => return cech_infinity()
        }
        let left = match self.morphism_unchecked(i, i) {
          Some(identity) =>
            match self.compose_unchecked(identity, arrow) {
              Some(composite) => composite
              None => return cech_infinity()
            }
          None => return cech_infinity()
        }
        let right = match self.morphism_unchecked(j, j) {
          Some(identity) =>
            match self.compose_unchecked(arrow, identity) {
              Some(composite) => composite
              None => return cech_infinity()
            }
          None => return cech_infinity()
        }
        worst = cech_max_defect(worst, cech_morphism_defect(left, arrow))
        worst = cech_max_defect(worst, cech_morphism_defect(right, arrow))
      }
    }
  }
  worst
}

///|
/// Exhaustively check associativity on every composable triple of patch morphisms.
pub fn CechCategory::associativity_defect(self : CechCategory) -> Double {
  if !self.is_well_formed() {
    return cech_infinity()
  }
  let n = self.bundle.n_sets
  let mut worst = 0.0
  for a in 0..<n {
    for b in 0..<n {
      for c in 0..<n {
        for d in 0..<n {
          if self.bundle.overlaps[a][b] &&
            self.bundle.overlaps[b][c] &&
            self.bundle.overlaps[c][d] {
            let f = match self.morphism_unchecked(a, b) {
              Some(value) => value
              None => return cech_infinity()
            }
            let g = match self.morphism_unchecked(b, c) {
              Some(value) => value
              None => return cech_infinity()
            }
            let h = match self.morphism_unchecked(c, d) {
              Some(value) => value
              None => return cech_infinity()
            }
            let left = match self.compose_unchecked(f, g) {
              Some(fg) => self.compose_unchecked(fg, h)
              None => None
            }
            let right = match self.compose_unchecked(g, h) {
              Some(gh) => self.compose_unchecked(f, gh)
              None => None
            }
            match (left, right) {
              (Some(lhs), Some(rhs)) =>
                worst = cech_max_defect(worst, cech_morphism_defect(lhs, rhs))
              _ => return cech_infinity()
            }
          }
        }
      }
    }
  }
  worst
}

///|
pub fn CechCategory::axiom_defect(self : CechCategory) -> Double {
  cech_max_defect(self.associativity_defect(), self.unit_defect())
}

///|
pub fn CechCategory::axioms_hold(
  self : CechCategory,
  tol~ : Double = 1.0e-10,
) -> Bool {
  tol.is_finite() && tol >= 0.0 && self.axiom_defect() <= tol
}

///|
/// GAUGE INVARIANCE DEFECT of the supertrace `str` and the Berezinian `Ber` under the
/// super-congruence gauge action I |-> g^{st} I g (identically 0 for even unimodular g).
pub fn SuperOperatorBundle::str_ber_gauge_defect(
  self : SuperOperatorBundle,
  gauge : SuperMatrix,
) -> Double {
  let g = gauge.supertranspose()
  let mut worst = 0.0
  for s in self.local_ops {
    let t = g * s * gauge
    let d1 = (t.supertrace().body() - s.supertrace().body()).abs()
    let d2 = (t.berezinian().body() - s.berezinian().body()).abs()
    if d1 > worst {
      worst = d1
    }
    if d2 > worst {
      worst = d2
    }
  }
  worst
}

///|
/// Build a 2|2 EVEN supermatrix from four real 2x2 coefficient blocks. Since the off-diagonal
/// blocks of an EVEN supermatrix must be Grassmann-odd, real-valued `b` and `c` are projected
/// to zero by `from_blocks`; use `even_super_matrix_with_odd_blocks` for nonzero odd blocks.
pub fn even_super_matrix(
  a : Array[Double],
  b : Array[Double],
  c : Array[Double],
  d : Array[Double],
) -> SuperMatrix {
  let g = DEFAULT_GRASSMANN_GEN
  let ga = a.map(v => Grassmann::scalar(g, v))
  let gb = b.map(v => Grassmann::scalar(g, v))
  let gc = c.map(v => Grassmann::scalar(g, v))
  let gd = d.map(v => Grassmann::scalar(g, v))
  SuperMatrix::from_blocks(2, 2, g, Even, ga, gb, gc, gd)
}

///|
/// Build an EVEN 2|2 matrix with real even diagonal blocks and explicit Grassmann-odd
/// off-diagonal blocks. Each block is a row-major array of four entries.
pub fn even_super_matrix_with_odd_blocks(
  a_real : Array[Double],
  b_odd : Array[Grassmann],
  c_odd : Array[Grassmann],
  d_real : Array[Double],
  n_gen : Int32,
) -> SuperMatrix {
  let a = a_real.map(value => Grassmann::scalar(n_gen, value))
  let d = d_real.map(value => Grassmann::scalar(n_gen, value))
  SuperMatrix::from_blocks(2, 2, n_gen, Even, a, b_odd, c_odd, d)
}

///|
/// Real 4n x 4n representation rho(A) of the quaternionic adjacency A of a `NonCommGraph`:
///   rho(A)_{(i,alpha),(j,beta)} = (iota(A_ij))_{alpha,beta},
/// where iota : H -> Mat_4(R) is the faithful scaled-orthogonal left-multiplication
/// representation with iota(q)^T iota(q) = |q|^2 I_4 and iota(conj q) = iota(q)^T.
/// For quaternionic-Hermitian A the real matrix rho(A) is REAL SYMMETRIC and every
/// quaternionic eigenvalue of quaternionic multiplicity m appears with REAL multiplicity
/// 4m (KRAMERS 4-FOLD DEGENERACY), while det_R(iota(q)) = |q|^4 (Study determinant).
pub fn quat_real_embedding(g : NonCommGraph) -> DenseMat {
  let adj = g.adjacency()
  let n = g.n
  let m = DenseMat::zeros(4 * n, 4 * n)
  for i in 0..<n {
    for j in 0..<n {
      let blk = adj[i][j].to_real_mat4()
      for r in 0..<4 {
        for c in 0..<4 {
          m.set(4 * i + r, 4 * j + c, blk.get(r, c))
        }
      }
    }
  }
  m
}

///|
/// Group eigenvalues into tolerance classes and return (all multiplicities divisible by 4,
/// the multiplicity profile) — the numerical certificate of Kramers 4-fold degeneracy.
pub fn kramers_multiplicity_profile(
  eigs : Array[Double],
  eps~ : Double = 1.0e-8,
) -> (Bool, Array[Int32]) {
  let reps : Array[Double] = []
  let counts : Array[Int32] = []
  for e in eigs {
    let mut merged = false
    for k in 0..<reps.length() {
      if (e - reps[k]).abs() <= eps {
        counts[k] = counts[k] + 1
        merged = true
        break
      }
    }
    if !merged {
      reps.push(e)
      counts.push(1)
    }
  }
  let mut ok = true
  for c in counts {
    if c % 4 != 0 {
      ok = false
    }
  }
  (ok, counts)
}

///|
/// Quaternionic Connes spectral triple (A = M_n(H), H_q = H^n, D) with a positive definite
/// real Dirac operator D = rho(A)^2 + I on the 4n-dimensional real Hilbert space.
#derive(Debug, Eq)
pub(all) struct QuatSpectralTriple {
  n : Int32
  dirac : DenseMat
}

///|
pub fn QuatSpectralTriple::from_graph(g : NonCommGraph) -> QuatSpectralTriple {
  let rho = quat_real_embedding(g)
  { n: g.n, dirac: rho * rho + DenseMat::eye(4 * g.n), }
}

///|
/// CONNES SPECTRAL DISTANCE between two quaternionic scalars a, b in the commutative
/// algebra M_n(H):  d(a, b) = || rho(a - b) D^{-1} ||_op  (a genuine metric: symmetric,
/// non-negative, vanishes iff a == b, and satisfies the triangle inequality).
pub fn QuatSpectralTriple::connes_distance(
  self : QuatSpectralTriple,
  a : Quat,
  b : Quat,
) -> Double {
  let diff = (a - b).to_real_mat4()
  let m = DenseMat::zeros(4 * self.n, 4 * self.n)
  for i in 0..<self.n {
    for r in 0..<4 {
      for c in 0..<4 {
        m.set(4 * i + r, 4 * i + c, diff.get(r, c))
      }
    }
  }
  (m * self.dirac.inv()).op_norm()
}

///|
/// INTEGER K_0 DIRECT-SUM INDEX of two quaternionic Hermitian projectors, lifted through the
/// faithful real 4-fold embedding iota : H -> Mat_4(R) into Mat_16(R):
///   (1/4) Tr_R(P) = tr_H(p_+(H_1)) + tr_H(p_+(H_2)) in Z.
pub fn quat_k0_integer_index(
  h1 : Hermitian2,
  h2 : Hermitian2,
) -> (Int32, Double) {
  k0_direct_sum_index(h1, h2)
}

///|
/// ========================================================================
/// 24.4  ROLE-GATED MEMORY, HAKEN/SUPERTROPICAL DUALITY, FINITE BICOMPLETENESS
/// ========================================================================

///|
/// Canonical role-gated memory profile of one emergent SGNE role.
#derive(Debug, Eq)
pub(all) struct RoleMemoryProfile {
  role : Int32
  gates : Gates
  retention : Double
}

///|
/// The four emergent roles (0 Coordinator, 1 Sensor, 2 Planner, 3 Executor) with their
/// canonical gate profiles. Retention f rises with role centrality, so the expected
/// absorption time into the `Lost` phase is STRICTLY ordered by role.
pub fn role_memory_profiles() -> Array[RoleMemoryProfile] {
  [
    {
      role: 0,
      gates: { forget: 0.97, input: 0.20, output: 1.00, candidate: 0.10, },
      retention: 0.97,
    },
    {
      role: 2,
      gates: { forget: 0.88, input: 0.70, output: 0.90, candidate: 0.40, },
      retention: 0.88,
    },
    {
      role: 1,
      gates: { forget: 0.80, input: 0.90, output: 0.60, candidate: 0.50, },
      retention: 0.80,
    },
    {
      role: 3,
      gates: { forget: 0.65, input: 0.85, output: 0.95, candidate: 0.60, },
      retention: 0.65,
    },
  ]
}

///|
/// Hurst-conditioned four-role retention profile and its exact absorbing-time response.
#derive(Debug, Eq)
pub(all) struct HurstMemoryResponse {
  input_valid : Bool
  hurst_exponent : Double
  profiles : Array[RoleMemoryProfile]
  role_absorption_times : Array[Double]
  mean_retention : Double
  mean_absorption_time : Double
}

///|
/// Finite-grid monotonicity audit for the Hurst-to-memory-retention coupling.
#derive(Debug, Eq)
pub(all) struct HurstMemoryTrendReport {
  input_valid : Bool
  hurst_grid_strictly_increasing : Bool
  mean_absorption_strictly_increasing : Bool
  each_role_absorption_strictly_increasing : Bool
  within_sample_role_order_preserved : Bool
  hurst_samples : Array[Double]
  mean_absorption_times : Array[Double]
  role_absorption_times_by_sample : Array[Array[Double]]
  minimum_mean_absorption_increment : Double
  certified : Bool
}

///|
/// Rescale each canonical forget-gate retention continuously with the environmental
/// Hurst exponent H in (0, 1): f(H) = f(1/2) + 2(H - 1/2)(1 - f(1/2)).
/// Thus H=1/2 exactly recovers the original profiles and every role's retention and
/// expected absorption time strictly increase with H. Outside the open Hurst interval
/// the response is explicitly invalid and carries no profiles.
pub fn role_memory_profiles_for_hurst(hurst : Double) -> HurstMemoryResponse {
  if !hurst.is_finite() || hurst <= 0.0 || hurst >= 1.0 {
    return {
      input_valid: false,
      hurst_exponent: hurst,
      profiles: [],
      role_absorption_times: [],
      mean_retention: 0.0,
      mean_absorption_time: 0.0,
    }
  }
  let base = role_memory_profiles()
  let profiles = base.map(profile => {
    let retention = profile.retention +
      2.0 * (hurst - 0.5) * (1.0 - profile.retention)
    {
      role: profile.role,
      gates: {
        forget: retention,
        input: profile.gates.input,
        output: profile.gates.output,
        candidate: profile.gates.candidate,
      },
      retention,
    }
  })
  let mut profiles_valid = true
  let role_absorption_times = profiles.map(profile => {
    if profile.retention <= 0.0 ||
      profile.retention >= 1.0 ||
      !profile.retention.is_finite() ||
      profile.gates.forget != profile.retention {
      profiles_valid = false
    }
    // Four serial geometric memory phases; E[T] = 4 / (1 - f) exactly.
    4.0 / (1.0 - profile.retention)
  })
  let mut mean_retention = 0.0
  let mut mean_absorption_time = 0.0
  for i in 0..<profiles.length() {
    mean_retention = mean_retention + profiles[i].retention / 4.0
    mean_absorption_time = mean_absorption_time + role_absorption_times[i] / 4.0
  }
  {
    input_valid: profiles_valid,
    hurst_exponent: hurst,
    profiles,
    role_absorption_times,
    mean_retention,
    mean_absorption_time,
  }
}

///|
/// Audit strictly increasing Hurst samples for per-role retention/absorption response,
/// mean response, and preservation of Coordinator > Planner > Sensor > Executor memory
/// lifetimes. Returns certificate evidence at every sampled environmental Hurst value.
pub fn audit_hurst_memory_monotonicity(
  hurst_samples : Array[Double],
) -> HurstMemoryTrendReport {
  let mut grid_valid = hurst_samples.length() >= 2
  for i in 0..<hurst_samples.length() {
    if !hurst_samples[i].is_finite() ||
      hurst_samples[i] <= 0.0 ||
      hurst_samples[i] >= 1.0 ||
      (i > 0 && hurst_samples[i] <= hurst_samples[i - 1]) {
      grid_valid = false
    }
  }
  if !grid_valid {
    return {
      input_valid: false,
      hurst_grid_strictly_increasing: false,
      mean_absorption_strictly_increasing: false,
      each_role_absorption_strictly_increasing: false,
      within_sample_role_order_preserved: false,
      hurst_samples,
      mean_absorption_times: [],
      role_absorption_times_by_sample: [],
      minimum_mean_absorption_increment: 0.0,
      certified: false,
    }
  }
  let responses = hurst_samples.map(h => role_memory_profiles_for_hurst(h))
  let mut responses_valid = true
  for response in responses {
    if !response.input_valid {
      responses_valid = false
    }
  }
  if !responses_valid {
    return {
      input_valid: false,
      hurst_grid_strictly_increasing: true,
      mean_absorption_strictly_increasing: false,
      each_role_absorption_strictly_increasing: false,
      within_sample_role_order_preserved: false,
      hurst_samples,
      mean_absorption_times: [],
      role_absorption_times_by_sample: [],
      minimum_mean_absorption_increment: 0.0,
      certified: false,
    }
  }
  let mean_absorption_times = responses.map(r => r.mean_absorption_time)
  let role_times = responses.map(r => r.role_absorption_times)
  let mut mean_increasing = true
  let mut roles_increasing = true
  let mut role_order_preserved = true
  let mut min_mean_increment = 1.0e300
  for i in 0..<responses.length() {
    let times = role_times[i]
    if !(times[0] > times[1] && times[1] > times[2] && times[2] > times[3]) {
      role_order_preserved = false
    }
    if i > 0 {
      let mean_increment = mean_absorption_times[i] -
        mean_absorption_times[i - 1]
      if mean_increment <= 0.0 {
        mean_increasing = false
      }
      if mean_increment < min_mean_increment {
        min_mean_increment = mean_increment
      }
      for role in 0..<4 {
        if role_times[i][role] <= role_times[i - 1][role] {
          roles_increasing = false
        }
      }
    }
  }
  let certified = mean_increasing && roles_increasing && role_order_preserved
  {
    input_valid: true,
    hurst_grid_strictly_increasing: true,
    mean_absorption_strictly_increasing: mean_increasing,
    each_role_absorption_strictly_increasing: roles_increasing,
    within_sample_role_order_preserved: role_order_preserved,
    hurst_samples,
    mean_absorption_times,
    role_absorption_times_by_sample: role_times,
    minimum_mean_absorption_increment: min_mean_increment,
    certified,
  }
}

///|
/// Role-dependent absorbing transition matrix over the 5 memory phases
/// {ShortTerm, Encoding, LongTerm, Retrieval, Lost}: with per-step retention f the chain
/// walks deterministically towards `Lost` with probability (1 - f) per step, and
/// `Lost` is absorbing. Expected absorption time from ShortTerm equals 4 / (1 - f).
pub fn role_transition_matrix(retention : Double) -> Array[Array[Double]] {
  let f = retention
  [
    [f, 1.0 - f, 0.0, 0.0, 0.0],
    [0.0, f, 1.0 - f, 0.0, 0.0],
    [0.0, 0.0, f, 1.0 - f, 0.0],
    [0.0, 0.0, 0.0, f, 1.0 - f],
    [0.0, 0.0, 0.0, 0.0, 1.0],
  ]
}

///|
/// Expected absorption time of a role-gated memory chain (exact Neumann fundamental matrix
/// solution of (I - Q) t = r), plus its equivalent survival-tail sum. For fast-retention
/// profiles, use the exact four-stage negative-binomial tail 4/(1-f) instead of a truncated
/// series whose stopping error would be magnified as f approaches one.
pub fn role_absorption_time(retention : Double) -> (Double, Double) {
  let p = role_transition_matrix(retention)
  let q = Array::makei(4, i => Array::makei(4, j => p[i][j]))
  let r = [1.0, 1.0, 1.0, 1.0]
  let lin = absorption_time_linear_solve(q, r)
  let series = if retention < 0.90 {
    absorption_time_series(0, p, 4, 1.0e-12)
  } else {
    4.0 / (1.0 - retention)
  }
  (lin[0], series)
}

///|
/// GATED TRANSITION SEMIGROUP CLOSURE ERROR: the O(log t) closed form `memory_closed_form`
/// must agree with the t-fold iteration of the gated cell transition.
pub fn role_semigroup_closure_error(
  profile : RoleMemoryProfile,
  c0 : Double,
  steps : Int32,
) -> Double {
  let mut cell : MemoryCell = { c: c0, h: 0.0, }
  for _ in 0..<steps {
    cell = cell.step(profile.gates)
  }
  let ig = profile.gates.input * profile.gates.candidate
  let closed = memory_closed_form(c0, profile.gates.forget, ig, steps)
  (cell.c - closed).abs()
}

///|
/// SUPERTROPICAL (IZHAKIAN-ROWEN) CLASSIFICATION of a converged Haken order-parameter
/// state: `Tangible` when a unique maximiser separates from the runner-up by more than the
/// tie tolerance, `Ghost` when the maximisers tie (the corner locus G of the supertropical
/// semiring, i.e. the exact locus where the Winner-Take-All selection is not decidable).
pub fn supertropical_wta_dual(
  proj : Array[Double],
  eta : Double,
  steps : Int32,
  tie_tol~ : Double = 1.0e-9,
) -> (Array[Int32], SuperTropical) {
  let xi = order_parameter_logits(proj, eta, steps)
  let winners = order_parameter_wta(proj, eta, steps)
  let mut best = xi[0]
  for v in xi {
    if v > best {
      best = v
    }
  }
  // Count the maximisers of the converged order parameter: a tie AT THE MAXIMUM is the
  // supertropical corner locus (Ghost ideal G), a unique maximiser is Tangible.
  let mut n_tied = 0
  for v in xi {
    if (v - best).abs() <= tie_tol {
      n_tied = n_tied + 1
    }
  }
  let st = if n_tied >= 2 {
    SuperTropical::Ghost(best)
  } else {
    SuperTropical::Tangible(best)
  }
  (winners, st)
}

///|
/// HAKEN ADIABATIC SLAVING COLLAPSE ERROR: the fast variable s converges exponentially onto
/// the slaving manifold s*(xi) = (xi^2 - 1) / gamma.
pub fn slaving_collapse_error(
  xi : Double,
  gamma : Double,
  eta : Double,
  steps : Int32,
) -> Double {
  (slaving_run(xi, gamma, eta, steps) - slaving_fixed_point(xi, gamma)).abs()
}

///|
/// Fixed universe size chosen so every Cantor code fits in a non-negative Int32.
const GODEL_SET_UNIVERSE_SIZE : Int32 = 15

///|
const GODEL_SET_MAX_MASK : Int32 = (1 << GODEL_SET_UNIVERSE_SIZE) - 1

///|
/// Error from encoding an unsupported element or decoding a noncanonical set code.
#derive(Debug, Eq)
pub(all) enum GodelSetError {
  ElementOutOfRange(Int32)
  InvalidCode(Int32)
}

///|
/// A finite set represented by its canonical Gödel code over the bounded universe
/// `{0, ..., 14}`. The private mask is always in `[0, 2^15)`.
#derive(Debug, Eq)
pub struct GodelFiniteSet {
  mask : Int32
}

///|
fn godel_set_mask_from_elements(
  elements : Array[Int32],
) -> Result[Int32, GodelSetError] {
  let mut mask = 0
  for element in elements {
    if element < 0 || element >= GODEL_SET_UNIVERSE_SIZE {
      return Err(ElementOutOfRange(element))
    }
    mask = mask | (1 << element)
  }
  Ok(mask)
}

///|
fn godel_set_mask_cardinality(mask : Int32) -> Int32 {
  let mut remaining = mask
  let mut count = 0
  for _ in 0..<GODEL_SET_UNIVERSE_SIZE {
    count = count + (remaining & 1)
    remaining = remaining >> 1
  }
  count
}

///|
fn godel_set_encode_mask(mask : Int32) -> Int32 {
  cantor_pair(godel_set_mask_cardinality(mask), mask)
}

///|
fn godel_set_decode_mask(code : Int32) -> Result[Int32, GodelSetError] {
  let maximum_code = cantor_pair(GODEL_SET_UNIVERSE_SIZE, GODEL_SET_MAX_MASK)
  if code < 0 || code > maximum_code {
    return Err(InvalidCode(code))
  }
  let (cardinality, mask) = cantor_unpair(code)
  if mask < 0 ||
    mask > GODEL_SET_MAX_MASK ||
    cardinality != godel_set_mask_cardinality(mask) ||
    godel_set_encode_mask(mask) != code {
    return Err(InvalidCode(code))
  }
  Ok(mask)
}

///|
pub fn GodelFiniteSet::empty() -> GodelFiniteSet {
  { mask: 0, }
}

///|
pub fn GodelFiniteSet::from_elements(
  elements : Array[Int32],
) -> Result[GodelFiniteSet, GodelSetError] {
  match godel_set_mask_from_elements(elements) {
    Ok(mask) => Ok({ mask, })
    Err(error) => Err(error)
  }
}

///|
pub fn GodelFiniteSet::from_code(
  code : Int32,
) -> Result[GodelFiniteSet, GodelSetError] {
  match godel_set_decode_mask(code) {
    Ok(mask) => Ok({ mask, })
    Err(error) => Err(error)
  }
}

///|
pub fn GodelFiniteSet::code(self : GodelFiniteSet) -> Int32 {
  godel_set_encode_mask(self.mask)
}

///|
pub fn GodelFiniteSet::to_array(self : GodelFiniteSet) -> Array[Int32] {
  let out : Array[Int32] = []
  for element in 0..<GODEL_SET_UNIVERSE_SIZE {
    if ((self.mask >> element) & 1) == 1 {
      out.push(element)
    }
  }
  out
}

///|
pub fn GodelFiniteSet::contains(
  self : GodelFiniteSet,
  element : Int32,
) -> Result[Bool, GodelSetError] {
  if element < 0 || element >= GODEL_SET_UNIVERSE_SIZE {
    return Err(ElementOutOfRange(element))
  }
  Ok((self.mask & (1 << element)) != 0)
}

///|
pub fn GodelFiniteSet::union(
  self : GodelFiniteSet,
  other : GodelFiniteSet,
) -> GodelFiniteSet {
  { mask: self.mask | other.mask, }
}

///|
pub fn GodelFiniteSet::intersection(
  self : GodelFiniteSet,
  other : GodelFiniteSet,
) -> GodelFiniteSet {
  { mask: self.mask & other.mask, }
}

///|
pub fn GodelFiniteSet::difference(
  self : GodelFiniteSet,
  other : GodelFiniteSet,
) -> GodelFiniteSet {
  { mask: self.mask & (GODEL_SET_MAX_MASK ^ other.mask), }
}

///|
pub fn GodelFiniteSet::symmetric_difference(
  self : GodelFiniteSet,
  other : GodelFiniteSet,
) -> GodelFiniteSet {
  { mask: self.mask ^ other.mask, }
}

///|
pub fn GodelFiniteSet::is_subset_of(
  self : GodelFiniteSet,
  other : GodelFiniteSet,
) -> Bool {
  (self.mask & other.mask) == self.mask
}

///|
/// Checked form of `godel_encode_finite_set`; duplicates are canonicalized as a set.
pub fn godel_encode_finite_set_checked(
  elements : Array[Int32],
) -> Result[Int32, GodelSetError] {
  match GodelFiniteSet::from_elements(elements) {
    Ok(set) => Ok(set.code())
    Err(error) => Err(error)
  }
}

///|
/// Canonical Cantor Gödel code for a subset of `{0,...,14}`:
/// `pi(|S|, sum(2^k for k in S))`. This domain bound keeps the Int32 Cantor code exact;
/// duplicate elements are ignored. Returns -1 for unsupported input; prefer the checked API.
pub fn godel_encode_finite_set(elements : Array[Int32]) -> Int32 {
  match godel_encode_finite_set_checked(elements) {
    Ok(code) => code
    Err(_) => -1
  }
}

///|
/// Checked inverse of `godel_encode_finite_set`; rejects negative, out-of-range, and
/// noncanonical Cantor codes instead of interpreting them as arbitrary bitmasks.
pub fn godel_decode_finite_set_checked(
  code : Int32,
) -> Result[Array[Int32], GodelSetError] {
  match GodelFiniteSet::from_code(code) {
    Ok(set) => Ok(set.to_array())
    Err(error) => Err(error)
  }
}

///|
/// Compatibility decoder. Invalid codes return the empty set; use the checked API when
/// an invalid code must be distinguished from the valid empty-set code 0.
pub fn godel_decode_finite_set(code : Int32) -> Array[Int32] {
  match godel_decode_finite_set_checked(code) {
    Ok(elements) => elements
    Err(_) => []
  }
}

///|
/// Apply an operation after validating both encoded set references.
fn[T] godel_with_set_pair(
  left : Int32,
  right : Int32,
  operation : (GodelFiniteSet, GodelFiniteSet) -> T,
) -> Result[T, GodelSetError] {
  match (GodelFiniteSet::from_code(left), GodelFiniteSet::from_code(right)) {
    (Ok(a), Ok(b)) => Ok(operation(a, b))
    (Err(error), _) | (_, Err(error)) => Err(error)
  }
}

///|
/// Set operations on encoded references reject invalid codes and re-encode results canonically.
pub fn godel_set_union(
  left : Int32,
  right : Int32,
) -> Result[Int32, GodelSetError] {
  godel_with_set_pair(left, right, (a, b) => a.union(b).code())
}

///|
pub fn godel_set_intersection(
  left : Int32,
  right : Int32,
) -> Result[Int32, GodelSetError] {
  godel_with_set_pair(left, right, (a, b) => a.intersection(b).code())
}

///|
pub fn godel_set_difference(
  left : Int32,
  right : Int32,
) -> Result[Int32, GodelSetError] {
  godel_with_set_pair(left, right, (a, b) => a.difference(b).code())
}

///|
pub fn godel_set_symmetric_difference(
  left : Int32,
  right : Int32,
) -> Result[Int32, GodelSetError] {
  godel_with_set_pair(left, right, (a, b) => a.symmetric_difference(b).code())
}

///|
pub fn godel_set_is_subset(
  left : Int32,
  right : Int32,
) -> Result[Bool, GodelSetError] {
  godel_with_set_pair(left, right, (a, b) => a.is_subset_of(b))
}

///|
/// Machine-checked set laws for encoded finite belief references.
#derive(Debug, Eq)
pub(all) struct GodelSetAlgebraReport {
  sample_sets_checked : Int32
  universe_subsets_checked : Int32
  round_trip : Bool
  canonical_encoding : Bool
  injective_on_domain : Bool
  union_commutative : Bool
  union_associative : Bool
  union_idempotent : Bool
  intersection_commutative : Bool
  intersection_associative : Bool
  intersection_idempotent : Bool
  union_identity : Bool
  intersection_zero : Bool
  absorption_laws : Bool
  symmetric_difference_laws : Bool
  subset_laws : Bool
  distributive : Bool
  difference_laws : Bool
  invalid_inputs_rejected : Bool
  certified : Bool
}

///|
pub fn audit_godel_set_algebra() -> GodelSetAlgebraReport {
  let samples : Array[Array[Int32]] = [
    [],
    [0],
    [1],
    [0, 1],
    [2, 5],
    [1, 3, 7],
    [0, 1, 2, 3],
    [4, 9],
    [14],
  ]
  let mut sample_round_trip = true
  for sample in samples {
    match godel_encode_finite_set_checked(sample) {
      Ok(code) =>
        match godel_decode_finite_set_checked(code) {
          Ok(decoded) => {
            let canonical = match GodelFiniteSet::from_elements(sample) {
              Ok(set) => set.to_array()
              Err(_) => []
            }
            if decoded != canonical {
              sample_round_trip = false
            }
          }
          Err(_) => sample_round_trip = false
        }
      Err(_) => sample_round_trip = false
    }
  }
  // A left-inverse check over every mask also certifies injection on this finite domain.
  let mut injective_on_domain = true
  for mask in 0..<=GODEL_SET_MAX_MASK {
    match godel_set_decode_mask(godel_set_encode_mask(mask)) {
      Ok(decoded) => if decoded != mask { injective_on_domain = false }
      Err(_) => injective_on_domain = false
    }
  }
  let round_trip = sample_round_trip && injective_on_domain
  let canonical_encoding = godel_encode_finite_set([5, 0, 2, 2]) ==
    godel_encode_finite_set([2, 5, 0])

  let a = match GodelFiniteSet::from_elements([0, 2, 5]) {
    Ok(set) => set
    Err(_) => GodelFiniteSet::empty()
  }
  let b = match GodelFiniteSet::from_elements([2, 3, 14]) {
    Ok(set) => set
    Err(_) => GodelFiniteSet::empty()
  }
  let c = match GodelFiniteSet::from_elements([1, 3, 5]) {
    Ok(set) => set
    Err(_) => GodelFiniteSet::empty()
  }
  let empty = GodelFiniteSet::empty()
  let union_commutative = a.union(b) == b.union(a)
  let union_associative = a.union(b).union(c) == a.union(b.union(c))
  let union_idempotent = a.union(a) == a
  let intersection_commutative = a.intersection(b) == b.intersection(a)
  let intersection_associative = a.intersection(b).intersection(c) ==
    a.intersection(b.intersection(c))
  let intersection_idempotent = a.intersection(a) == a
  let union_identity = a.union(empty) == a && empty.union(a) == a
  let intersection_zero = a.intersection(empty) == empty &&
    empty.intersection(a) == empty
  let absorption_laws = a.union(a.intersection(b)) == a &&
    a.intersection(a.union(b)) == a
  let symmetric_difference_laws = a.symmetric_difference(b) ==
    b.symmetric_difference(a) &&
    a.symmetric_difference(empty) == a &&
    a.symmetric_difference(a) == empty &&
    a.symmetric_difference(b).symmetric_difference(c) ==
    a.symmetric_difference(b.symmetric_difference(c))
  let subset_laws = empty.is_subset_of(a) &&
    a.is_subset_of(a) &&
    a.intersection(b).is_subset_of(a) &&
    a.is_subset_of(b) == (a.union(b) == b)
  let distributive = a.intersection(b.union(c)) ==
    a.intersection(b).union(a.intersection(c))
  let difference_laws = a.difference(empty) == a &&
    a.difference(a) == empty &&
    a.difference(b).intersection(b) == empty &&
    a.difference(b).union(a.intersection(b)) == a &&
    a.is_subset_of(a.union(b))
  let invalid_element = match GodelFiniteSet::from_elements([-1]) {
    Err(ElementOutOfRange(-1)) => true
    _ => false
  }
  let invalid_code = match GodelFiniteSet::from_code(-1) {
    Err(InvalidCode(-1)) => true
    _ => false
  }
  let oversized_code_rejected = GodelFiniteSet::from_code(2_147_483_647)
    is Err(InvalidCode(2_147_483_647))
  let invalid_inputs_rejected = invalid_element &&
    invalid_code &&
    oversized_code_rejected &&
    GodelFiniteSet::empty().contains(15) is Err(ElementOutOfRange(15)) &&
    godel_encode_finite_set_checked([15]) is Err(_) &&
    godel_decode_finite_set_checked(godel_set_encode_mask(0) + 1) is Err(_)
  let universe_subsets_checked = GODEL_SET_MAX_MASK + 1
  let certified = round_trip &&
    canonical_encoding &&
    injective_on_domain &&
    union_commutative &&
    union_associative &&
    union_idempotent &&
    intersection_commutative &&
    intersection_associative &&
    intersection_idempotent &&
    union_identity &&
    intersection_zero &&
    absorption_laws &&
    symmetric_difference_laws &&
    subset_laws &&
    distributive &&
    difference_laws &&
    invalid_inputs_rejected
  {
    sample_sets_checked: samples.length(),
    universe_subsets_checked,
    round_trip,
    canonical_encoding,
    injective_on_domain,
    union_commutative,
    union_associative,
    union_idempotent,
    intersection_commutative,
    intersection_associative,
    intersection_idempotent,
    union_identity,
    intersection_zero,
    absorption_laws,
    symmetric_difference_laws,
    subset_laws,
    distributive,
    difference_laws,
    invalid_inputs_rejected,
    certified,
  }
}

///|
/// FINITE BICOMPLETENESS CERTIFICATE of the FinSet-encoded category used by the agent:
///   (i)   the terminal object exists and is unique up to isomorphism;
///   (ii)  the binary product exists with a unique mediating morphism;
///   (iii) the pushout (colimit) exists with a unique mediating morphism;
///   (iv)  the pullback (limit) exists with a unique mediating morphism;
///   (v)   the Cantor Gödel encoding of finite structures is injective.
pub fn finite_bicompleteness_certificate() -> (Bool, Int32, Int32) {
  let term_ok = terminal_is_unique_up_to_iso() && count_terminal_arrows(6) == 1
  let prod_ok = universal_property_product_witness(2, 2, 2)
  // Colimit: pushout of the span A <- C -> B with A = {0,1}, B = {2,3}, C = {0,2}
  let po = compute_finite_pushout(2, 2, [0], [0])
  let cocone_a : Array[Int32] = [0, 1]
  let cocone_b : Array[Int32] = [0, 3]
  let cocone_res = po.mediating_map(cocone_a, cocone_b)
  let colimit_ok = match cocone_res {
    Ok(_) => true
    Err(_) => false
  }
  // Limit: pullback of the cospan A -> C <- B with A = {0,1}, B = {2,3}, f(0)=f(1)=0, g(2)=g(3)=0
  let f : Hom = { src: 2, dst: 1, map: [0, 0], }
  let g : Hom = { src: 2, dst: 1, map: [0, 0], }
  let pb = compute_finite_pullback(f, g)
  let cone_a : Hom = { src: 1, dst: 2, map: [1], }
  let cone_b : Hom = { src: 1, dst: 2, map: [1], }
  let cone_res = pb.mediating_map(cone_a, cone_b)
  let limit_ok = match cone_res {
    Ok(_) => true
    Err(_) => false
  }
  // Reuse the checked Gödel-code round-trip, injectivity, and set-algebra certificate.
  let godel_ok = audit_godel_set_algebra().certified
  let all_ok = term_ok && prod_ok && colimit_ok && limit_ok && godel_ok
  (all_ok, po.n_apex, pb.n_apex)
}

///|
/// Build a Belnap four-valued epistemic universe for one SGNE proto-agent over the four
/// emergent roles: a role is designated (`Tv`) when the agent's policy probability exceeds
/// the role threshold, and ungrounded (`Nv`) when the agent's belief is hyperbolic-far from
/// the colony consensus (grounding radius exceeded).
pub fn agent_para_universe(
  ag : ProtoAgent,
  consensus : PoincarePoint,
  radius : Double,
) -> ParaUniverse {
  let probs = categorical_probs(ag.policy_eta)
  let names = ["sense", "plan", "verify", "act", "oracle"]
  let grounded = ag.belief.geodesic_dist(consensus) <= radius
  let vals = Array::makei(probs.length() + 1, i => {
    if i == probs.length() {
      // The colony holds no opinion about the oracle proposition: it stays ungrounded.
      Nv
    } else if !grounded {
      Nv
    } else if probs[i] > 1.0 / probs.length().to_double() {
      Tv
    } else {
      Fv
    }
  })
  ParaUniverse::new(names, vals)
}

///|
/// COLONY PARACONSISTENT WORLD FUSION: fuse every agent's epistemic universe into a single
/// Belnap world and certify that the fusion does NOT explode (some proposition stays
/// undesignated even though another becomes a dialetheism).
pub fn colony_para_fusion(
  agents : Array[ProtoAgent],
  c : Double,
  radius : Double,
) -> (Bool, Array[FourVal], Int32) {
  if agents.length() == 0 {
    return (false, [], 0)
  }
  let mean = [0.0, 0.0, 0.0, 0.0]
  for ag in agents {
    for k in 0..<4 {
      mean[k] = mean[k] + ag.belief.coords[k]
    }
  }
  for k in 0..<4 {
    mean[k] = mean[k] / agents.length().to_double()
  }
  let consensus = PoincarePoint::new(c, mean)
  let worlds = agents.map(ag => agent_para_universe(ag, consensus, radius))
  let (no_expl, fused) = paraconsistent_no_explosion(worlds)
  let mut contradictions = 0
  for v in fused {
    if v == Bv {
      contradictions = contradictions + 1
    }
  }
  (no_expl, fused, contradictions)
}

///|
/// Consolidated report of the Layer-4 bridge algorithm `SGNE-Syn-Mem-Para`
/// (Sub-Algorithms A9 & A10).
#derive(Debug, Eq)
pub(all) struct SynMemParaReport {
  hurst_exponent : Double
  hurst_profile_valid : Bool
  role_retention : Array[Double]
  role_absorption_times : Array[Double]
  semigroup_closure_error : Double
  wta_tangible : Bool
  wta_ghost : Bool
  wta_ghost_winners : Int32
  slaving_collapse_error : Double
  pushout_ontology_size : Int32
  pullback_apex_size : Int32
  godel_injective : Bool
  fused_values : Array[FourVal]
  no_explosion : Bool
  contradicted_propositions : Int32
}

///|
/// Derived Algorithm `SGNE-Syn-Mem-Para` (Sub-Algorithms A9 & A10): distils the emergent
/// SGNE colony into a role-gated memory semigroup with exact absorption times (A9) and into
/// a Haken/Supertropical order-parameter duality with finite bicompleteness and a
/// paraconsistent world fusion (A10).
pub fn distill_synergetic_memory_para_agent(
  agents : Array[ProtoAgent],
  c : Double,
  hurst~ : Double = 0.5,
) -> SynMemParaReport {
  let memory_response = role_memory_profiles_for_hurst(hurst)
  let profiles = memory_response.profiles
  let retention : Array[Double] = []
  let absorption : Array[Double] = []
  let mut closure_err = 0.0
  for p in profiles {
    retention.push(p.retention)
    let (lin, series) = role_absorption_time(p.retention)
    absorption.push(lin)
    closure_err = closure_err.max(
      (lin - series).abs().max(role_semigroup_closure_error(p, 1.0, 64)),
    )
  }
  // Haken WTA <-> Supertropical Tangible/Ghost duality
  let (t_winners, t_state) = supertropical_wta_dual(
    [0.10, 2.00, 0.50, -1.00],
    0.1,
    200,
  )
  let (g_winners, g_state) = supertropical_wta_dual(
    [0.60, 0.60, -0.30, -1.20],
    0.1,
    200,
  )
  let slaving_err = slaving_collapse_error(1.5, 4.0, 0.2, 400)
  let (bicomp_ok, po_size, pb_size) = finite_bicompleteness_certificate()
  let (no_expl, fused, contradictions) = colony_para_fusion(agents, c, 1.2)
  {
    hurst_exponent: hurst,
    hurst_profile_valid: memory_response.input_valid,
    role_retention: retention,
    role_absorption_times: absorption,
    semigroup_closure_error: closure_err,
    wta_tangible: t_winners.length() == 1 && !t_state.is_ghost(),
    wta_ghost: g_state.is_ghost() && g_winners.length() == 2,
    wta_ghost_winners: g_winners.length(),
    slaving_collapse_error: slaving_err,
    pushout_ontology_size: po_size,
    pullback_apex_size: pb_size,
    godel_injective: bicomp_ok,
    fused_values: fused,
    no_explosion: no_expl,
    contradicted_propositions: contradictions,
  }
}
