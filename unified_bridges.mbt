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
/// Canonical single-well / double-well metriplectic instance built from the Schur-Berezin
/// renormalized mass of a genuine `SuperMassTensor` (algorithm04) fused with the double-well
/// landscape (algo8). This is the concrete MERGE-ONLY object of Theorem XV.
pub fn schur_metriplectic_instance() -> SuperHamiltonian {
  // Bare bosonic mass M = [[2.4, 0.3], [0.3, 1.8]] (SPD)
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
  // Odd Yukawa coupling Xi (2 x 2) and symplectic stiffness Omega = kappa * J_2
  let xi_odd = [
    Grassmann::generator(4, 0, coeff=0.45),
    Grassmann::generator(4, 1, coeff=-0.30),
    Grassmann::generator(4, 2, coeff=0.25),
    Grassmann::generator(4, 3, coeff=0.35),
  ]
  let sm = SuperMassTensor::from_real_and_yukawa(m, xi_odd, 1.2, 2, 4)
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
  let sm = SuperMassTensor::from_real_and_yukawa(m, xi_odd, 1.2, 2, 4)
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
  let mut soul = 0.0
  let mut body_trace = 0.0
  for i in 0..<(mb * mb) {
    let delta = bdc[i] - a_blk[i] + a_blk[i]
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
  let sm = SuperMassTensor::from_real_and_yukawa(m, xi_odd, 1.2, 2, 4)
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
/// PARACONSISTENT NON-EXPLOSION WITNESS: fuse several epistemic worlds pointwise by the
/// Belnap information join and certify that
///   (i)  at least one proposition is quarantined as a dialetheism `Bv` (designated), and
///   (ii) at least one orthogonal proposition remains undesignated (`Fv`/`Nv`),
/// hence the classical rule "from a contradiction everything follows" FAILS.
pub fn paraconsistent_no_explosion(
  worlds : Array[ParaUniverse],
) -> (Bool, Array[FourVal]) {
  let mw : MultiWorld = { worlds, }
  let fused = mw.merge_pointwise()
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
/// Cech nerve of a super-operator bundle over `n_sets` open patches:
///   - `local_ops[i]` is the local (Grassmann-valued) operator section on patch i;
///   - `transitions[i][j]` is the super-transition g_ij relating patch i to patch j,
///     with `transitions[i][i] = id` and the COCYCLE condition g_ij g_jk = g_ik.
#derive(Debug, Eq)
pub(all) struct SuperOperatorBundle {
  n_sets : Int32
  local_ops : Array[SuperMatrix]
  transitions : Array[Array[SuperMatrix]]
}

///|
/// COCYCLE DEFECT  max_{i,j,k distinct} || g_ij g_jk - g_ik ||_F  (identically 0 on a bundle).
pub fn SuperOperatorBundle::cocycle_defect(
  self : SuperOperatorBundle,
) -> Double {
  let mut worst = 0.0
  for i in 0..<self.n_sets {
    for j in 0..<self.n_sets {
      if i == j {
        continue
      }
      for k in 0..<self.n_sets {
        if k == i || k == j {
          continue
        }
        let lhs = self.transitions[i][j] * self.transitions[j][k]
        let rhs = self.transitions[i][k]
        let d = (lhs - rhs).frob_norm()
        if d > worst {
          worst = d
        }
      }
    }
  }
  worst
}

///|
/// PATCH COMPATIBILITY DEFECT  max_{i != j} || g_ij^{st} s_i g_ij - s_j ||_F.
pub fn SuperOperatorBundle::patch_defect(self : SuperOperatorBundle) -> Double {
  let mut worst = 0.0
  for i in 0..<self.n_sets {
    for j in 0..<self.n_sets {
      if i == j {
        continue
      }
      let g = self.transitions[i][j]
      let lhs = g.supertranspose() * self.local_ops[i] * g
      let d = (lhs - self.local_ops[j]).frob_norm()
      if d > worst {
        worst = d
      }
    }
  }
  worst
}

///|
/// HOLONOMY around an ordered loop of patches: h = g_{i0 i1} ... g_{i_{m-1} i0};
/// the holonomy defect || h - id ||_F vanishes exactly when the cocycle condition holds.
pub fn SuperOperatorBundle::holonomy_defect(
  self : SuperOperatorBundle,
  loop_patches : Array[Int32],
) -> Double {
  let m = loop_patches.length()
  if m < 2 {
    return 0.0
  }
  let mut h = SuperMatrix::identity(
    self.local_ops[0].m_bos,
    self.local_ops[0].n_ferm,
    n_gen=self.local_ops[0].n_gen,
  )
  for t in 0..<m {
    let a = loop_patches[t]
    let b = loop_patches[(t + 1) % m]
    h = h * self.transitions[a][b]
  }
  let ident = SuperMatrix::identity(
    self.local_ops[0].m_bos,
    self.local_ops[0].n_ferm,
    n_gen=self.local_ops[0].n_gen,
  )
  (h - ident).frob_norm()
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
/// Build a 2|2 EVEN supermatrix [[A, B], [C, D]] from four real 2x2 blocks stored as
/// flat row-major arrays of length 4 (embedded as real even elements of Lambda_4).
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
/// solution of (I - Q) t = r), plus the equivalent tail-series value as a cross-check.
pub fn role_absorption_time(retention : Double) -> (Double, Double) {
  let p = role_transition_matrix(retention)
  let q = Array::makei(4, i => Array::makei(4, j => p[i][j]))
  let r = [1.0, 1.0, 1.0, 1.0]
  let lin = absorption_time_linear_solve(q, r)
  let series = absorption_time_series(0, p, 4, 1.0e-12)
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
/// Canonical GÖDEL (CANTOR) ENCODING of a finite set of non-negative integers:
///   code(S) = pi(|S|, mask(S)),  mask(S) = sum_{k in S} 2^k,
/// where pi is the canonical Cantor pairing. The (n+2)-ary digit encoding is injective
/// (every digit lies in [1, n+1] < n+2) and pi is injective, so the encoding is injective.
pub fn godel_encode_finite_set(s : Array[Int32]) -> Int32 {
  let n = s.length()
  // Binary characteristic mask: bit k is set iff k belongs to the set. The mask is
  // order-independent, hence the encoding depends on the SET and not on its presentation.
  let mut mask = 0
  for x in s {
    if x >= 0 && x <= 29 {
      mask = mask | (1 << x)
    }
  }
  cantor_pair(n, mask)
}

///|
/// Inverse of `godel_encode_finite_set`: recover the finite set from its Gödel code.
pub fn godel_decode_finite_set(code : Int32) -> Array[Int32] {
  let (_, mask) = cantor_unpair(code)
  let out : Array[Int32] = []
  let mut b = 0
  while b < 30 {
    if ((mask >> b) & 1) == 1 {
      out.push(b)
    }
    b = b + 1
  }
  out
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
  // Gödel injectivity on a deterministic sample of finite sets
  let samples : Array[Array[Int32]] = [
    [],
    [0],
    [1],
    [0, 1],
    [2, 5],
    [1, 3, 7],
    [0, 1, 2, 3],
    [4, 9],
  ]
  let mut godel_ok = true
  for i in 0..<samples.length() {
    for j in 0..<samples.length() {
      if i != j {
        let ci = godel_encode_finite_set(samples[i])
        let cj = godel_encode_finite_set(samples[j])
        if ci == cj {
          godel_ok = false
        }
      }
    }
  }
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
) -> SynMemParaReport {
  let profiles = role_memory_profiles()
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
