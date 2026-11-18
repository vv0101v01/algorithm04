///|
/// Module 9: Partial Differential Evolution Flows (偏微分演化流).
/// Implements three coupled geometric PDE flows on M^{m|n}_c:
///   1. Wasserstein-Fisher-Rao / Fokker-Planck-Beltrami-Berezin PDE flow
///        d_t rho = div_G(rho grad_G (V + D ln rho)) - alpha * rho * (V - <V>_rho)
///      preserving total Berezinian mass \int rho sqrt(Ber(G)) dx = 1, positivity rho > 0,
///      and strictly dissipating the variational free energy F[rho] (H-Theorem, dF/dt <= 0!),
///   2. Supersymmetric Witten-Hodge Heat PDE flow d_t Psi = -H Psi = -(1/2)(Q Q^+ + Q^+ Q) Psi
///      relaxing neuro-symbolic cochain fields onto topologically protected BPS ground states,
///   3. Adaptive Poincare-Ricci-Fisher Geometric Curvature Flow
///        d_t g_{ij} = -2 Ric_{ij}(g) + 2 kappa F_{ij} - 2 Lambda g_{ij}
///      evolving semantic hierarchy curvature c(t) toward a stable hyperbolic attractor c* > 0!

///|
/// 1D/Radial Finite-Volume Fokker-Planck-Beltrami-Berezin & Fisher-Rao PDE on M^{m|n}_c.
/// Discretizes r in (0, r_max) subset B_c^m weighted by the exact Berezinian geometric
/// volume measure w_i = sqrt(Ber(G(r_i))) * dx = (2 / (1 - c r_i^2))^{m - n} * dx
/// and inverse metric mobility g^{rr}(r) = ((1 - c r^2) / 2)^2.
/// Uses symmetric Chang-Cooper / Scharfetter-Gummel reversible flux. The long-time
/// `step_energy_monotone` integrator backtracks explicit trial steps and rescales mass,
/// certifying non-increasing discrete free energy while preserving strict positivity.
#derive(Debug, Eq)
pub(all) struct SuperBeltramiPDE {
  manifold : SuperManifold
  n_cells : Int32
  r_max : Double
  dr : Double
  diffusivity : Double
  fisher_rate : Double
  grid : Array[Double]
  vol_weights : Array[Double]
  potential : Array[Double]
  density : Array[Double]
}

///|
/// A time-local sample of the controllable exogenous WFR forcing sigma * Xi(t).
/// `xi` is an additive density-rate vector with one entry per finite-volume cell.
#derive(Debug, Eq)
pub(all) struct WFRExogenousPerturbation {
  sigma : Double
  xi : Array[Double]
}

///|
pub fn WFRExogenousPerturbation::new(
  sigma : Double,
  xi : Array[Double],
) -> WFRExogenousPerturbation {
  { sigma, xi, }
}

///|
/// Separate conservation and free-energy accounting for one perturbed WFR step.
/// `deterministic_dissipation = F_before - F_unperturbed_after`; `perturbation_work`
/// is the energy change from the unperturbed state to the perturbed state.
#derive(Debug, Eq)
pub(all) struct WFRFlowStepLedger {
  input_shape_valid : Bool
  input_values_valid : Bool
  mass_before : Double
  deterministic_mass_after : Double
  mass_after : Double
  mass_conservation_error : Double
  free_energy_before : Double
  deterministic_free_energy_after : Double
  free_energy_after : Double
  deterministic_dissipation : Double
  perturbation_work : Double
  total_free_energy_change : Double
}

///|
/// Result of an exogenously perturbed WFR step and its independent mass/energy ledger.
#derive(Debug, Eq)
pub(all) struct WFRPerturbedStep {
  state : SuperBeltramiPDE
  ledger : WFRFlowStepLedger
}

///|
/// One adaptive, energy-guarded deterministic WFR step.
#derive(Debug, Eq)
pub(all) struct WFRMonotoneStep {
  state : SuperBeltramiPDE
  accepted : Bool
  stationary_hold : Bool
  retries : Int32
  effective_dt : Double
  max_proposed_energy_increase : Double
}

///|
/// Streaming certificate of a long deterministic WFR integration.
#derive(Debug, Eq)
pub(all) struct WFRLongTimeStabilityReport {
  input_valid : Bool
  requested_steps : Int32
  completed_steps : Int32
  stationary_holds : Int32
  failed_steps : Int32
  adaptive_retries : Int32
  simulated_time : Double
  initial_free_energy : Double
  final_free_energy : Double
  final_equilibrium_distance : Double
  max_free_energy_increase : Double
  max_proposed_energy_increase : Double
  max_mass_conservation_error : Double
  minimum_density : Double
  free_energy_monotone : Bool
  mass_conserved : Bool
  positivity_preserved : Bool
}

///|
pub fn SuperBeltramiPDE::new(
  manifold : SuperManifold,
  n_cells : Int32,
  r_max : Double,
  diffusivity : Double,
  fisher_rate : Double,
  potential_fn : (Double) -> Double,
  init_density_fn : (Double) -> Double,
) -> SuperBeltramiPDE {
  let dr = r_max / n_cells.to_double()
  let grid = Array::makei(n_cells, i => (i.to_double() + 0.5) * dr)
  let vol_weights = Array::makei(n_cells, i => {
    manifold.effective_volume_density_at_radius(grid[i]) * dr
  })
  let potential = grid.map(r => potential_fn(r))
  let raw_rho = grid.map(r => init_density_fn(r).max(1.0e-12))
  let mut mass = 0.0
  for i in 0..<n_cells {
    mass = mass + vol_weights[i] * raw_rho[i]
  }
  let density = raw_rho.map(x => x / mass)
  {
    manifold,
    n_cells,
    r_max,
    dr,
    diffusivity,
    fisher_rate,
    grid,
    vol_weights,
    potential,
    density,
  }
}

///|
/// Total Berezinian probability mass M[rho] = \int rho(x) sqrt(Ber(G(x))) dx.
pub fn SuperBeltramiPDE::total_mass(self : SuperBeltramiPDE) -> Double {
  let mut m = 0.0
  for i in 0..<self.n_cells {
    m = m + self.vol_weights[i] * self.density[i]
  }
  m
}

///|
/// Equilibrium Gibbs-Berezin density rho_eq(x) = Z^{-1} exp(-V(x) / D).
pub fn SuperBeltramiPDE::gibbs_equilibrium(
  self : SuperBeltramiPDE,
) -> Array[Double] {
  let mut min_v = self.potential[0]
  for v in self.potential {
    if v < min_v {
      min_v = v
    }
  }
  let raw = self.potential.map(v => @math.exp(-(v - min_v) / self.diffusivity))
  let mut z = 0.0
  for i in 0..<self.n_cells {
    z = z + self.vol_weights[i] * raw[i]
  }
  raw.map(x => x / z)
}

///|
/// Variational Free-Energy Lyapunov Functional on M^{m|n}_c:
///   F[rho] = \int rho(x) (V(x) + D ln rho(x)) sqrt(Ber(G(x))) dx
///          = D * D_KL^G(rho || rho_eq) - D ln Z.
/// Along the Wasserstein-Fisher-Rao Beltrami-Berezin PDE:
///   dF/dt = -\int rho ||grad_G mu||_G^2 dvol_G - alpha Var_rho(mu) <= 0!
pub fn SuperBeltramiPDE::free_energy(self : SuperBeltramiPDE) -> Double {
  let mut fe = 0.0
  for i in 0..<self.n_cells {
    let rho_i = self.density[i].max(1.0e-30)
    let mu_i = self.potential[i] + self.diffusivity * @math.ln(rho_i)
    fe = fe + self.vol_weights[i] * rho_i * mu_i
  }
  fe
}

///|
/// Advance the Wasserstein-Fisher-Rao Fokker-Planck-Beltrami-Berezin PDE by `dt`
/// using structure-preserving operator splitting:
///   Half-step 1 (Wasserstein-Beltrami-Berezin diffusion-drift with no-flux Neumann BC),
///   Half-step 2 (Exact exponential Fisher-Rao replicator-birth-death reaction step).
pub fn SuperBeltramiPDE::step(
  self : SuperBeltramiPDE,
  dt : Double,
) -> SuperBeltramiPDE {
  let n = self.n_cells
  let d_coef = self.diffusivity
  let eq = self.gibbs_equilibrium()
  // Relative density h_i = rho_i / rho_eq,i satisfies reversible detailed-balance flow:
  //   w_i rho_eq,i d_t h_i = sum_{j ~ i} K_{ij} (h_j - h_i)
  let pi_w = Array::makei(n, i => self.vol_weights[i] * eq[i])
  let h = Array::makei(n, i => self.density[i] / eq[i].max(1.0e-30))
  // Edge conductance K_{i+1/2} = D * sqrt(Ber(G)) * g^{rr} * rho_eq(r_{i+1/2}) / dr
  let flux = Array::make(n - 1, 0.0)
  for i in 0..<(n - 1) {
    let r_mid = 0.5 * (self.grid[i] + self.grid[i + 1])
    let lam = 2.0 / (1.0 - self.manifold.c * r_mid * r_mid)
    let sqrt_ber = self.manifold.effective_volume_density_at_radius(r_mid)
    let g_inv_rr = 1.0 / (lam * lam)
    // Logarithmic mean of eq[i], eq[i+1] preserves exact entropy dissipation!
    let eq_mid = if (eq[i] - eq[i + 1]).abs() < 1.0e-12 {
      0.5 * (eq[i] + eq[i + 1])
    } else {
      (eq[i] - eq[i + 1]) / (@math.ln(eq[i]) - @math.ln(eq[i + 1]))
    }
    let k_edge = d_coef * sqrt_ber * g_inv_rr * eq_mid / self.dr
    flux[i] = k_edge * (h[i + 1] - h[i])
  }
  let rho_wass = Array::makei(n, i => {
    let net = (if i < n - 1 { flux[i] } else { 0.0 }) -
      (if i > 0 { flux[i - 1] } else { 0.0 })
    let h_new = h[i] + dt * net / pi_w[i].max(1.0e-30)
    (h_new * eq[i]).max(1.0e-24)
  })
  // Fisher-Rao reaction step: d_t rho = -alpha * rho * (mu - <mu>_rho)
  let rho_next = if self.fisher_rate > 0.0 {
    let mu = Array::makei(n, i => {
      self.potential[i] + d_coef * @math.ln(rho_wass[i])
    })
    let mut mean_mu = 0.0
    for i in 0..<n {
      mean_mu = mean_mu + self.vol_weights[i] * rho_wass[i] * mu[i]
    }
    let reacted = Array::makei(n, i => {
      rho_wass[i] * @math.exp(-dt * self.fisher_rate * (mu[i] - mean_mu))
    })
    let mut z = 0.0
    for i in 0..<n {
      z = z + self.vol_weights[i] * reacted[i]
    }
    reacted.map(x => x / z)
  } else {
    rho_wass
  }
  self.wfr_state_with_density(rho_next)
}

///|
fn SuperBeltramiPDE::wfr_state_with_density(
  self : SuperBeltramiPDE,
  density : Array[Double],
) -> SuperBeltramiPDE {
  {
    manifold: self.manifold,
    n_cells: self.n_cells,
    r_max: self.r_max,
    dr: self.dr,
    diffusivity: self.diffusivity,
    fisher_rate: self.fisher_rate,
    grid: self.grid,
    vol_weights: self.vol_weights,
    potential: self.potential,
    density,
  }
}

///|
fn SuperBeltramiPDE::wfr_rescale_to_mass(
  self : SuperBeltramiPDE,
  target_mass : Double,
) -> SuperBeltramiPDE {
  let current_mass = self.total_mass()
  if !current_mass.is_finite() ||
    current_mass <= 0.0 ||
    !target_mass.is_finite() ||
    target_mass <= 0.0 {
    self
  } else {
    let density = self.density.map(rho => rho * target_mass / current_mass)
    let mut correction_index = 0
    for i in 1..<self.n_cells {
      if self.vol_weights[i] * density[i] >
        self.vol_weights[correction_index] * density[correction_index] {
        correction_index = i
      }
    }
    // Correct the remaining summation residual in the cell with largest weighted
    // mass so the relative adjustment is minimal; repeat once for rounding drift.
    for _ in 0..<2 {
      let mut actual_mass = 0.0
      for i in 0..<self.n_cells {
        actual_mass = actual_mass + self.vol_weights[i] * density[i]
      }
      density[correction_index] = density[correction_index] +
        (target_mass - actual_mass) / self.vol_weights[correction_index]
    }
    self.wfr_state_with_density(density)
  }
}

///|
fn wfr_weighted_density_distance(
  a : SuperBeltramiPDE,
  b : SuperBeltramiPDE,
) -> Double {
  let mut distance = 0.0
  for i in 0..<a.n_cells {
    distance = distance + a.vol_weights[i] * (a.density[i] - b.density[i]).abs()
  }
  distance
}

///|
/// Backtrack the explicit WFR step until its discrete free energy does not increase.
/// At machine-precision equilibrium, a density change below 1e-8 with only roundoff
/// energy variation is treated as a stationary hold over the attempted time interval.
pub fn SuperBeltramiPDE::step_energy_monotone(
  self : SuperBeltramiPDE,
  dt : Double,
) -> WFRMonotoneStep {
  let shape_valid = self.n_cells > 1 &&
    self.density.length() == self.n_cells &&
    self.vol_weights.length() == self.n_cells &&
    self.potential.length() == self.n_cells &&
    self.grid.length() == self.n_cells
  if !shape_valid {
    return {
      state: self,
      accepted: false,
      stationary_hold: false,
      retries: 0,
      effective_dt: 0.0,
      max_proposed_energy_increase: 0.0,
    }
  }
  let initial_energy = self.free_energy()
  let target_mass = self.total_mass()
  let mut state_values_valid = initial_energy.is_finite() &&
    target_mass.is_finite() &&
    target_mass > 0.0 &&
    self.diffusivity.is_finite() &&
    self.diffusivity > 0.0 &&
    self.fisher_rate.is_finite() &&
    self.fisher_rate >= 0.0
  for i in 0..<self.n_cells {
    if !self.density[i].is_finite() ||
      self.density[i] <= 0.0 ||
      !self.vol_weights[i].is_finite() ||
      self.vol_weights[i] <= 0.0 ||
      !self.potential[i].is_finite() ||
      !self.grid[i].is_finite() {
      state_values_valid = false
    }
  }
  let input_valid = dt.is_finite() && dt > 0.0 && state_values_valid
  if !input_valid {
    return {
      state: self,
      accepted: false,
      stationary_hold: false,
      retries: 0,
      effective_dt: 0.0,
      max_proposed_energy_increase: 0.0,
    }
  }

  let mut trial_dt = dt
  let mut max_proposed_increase = 0.0
  for retry in 0..<25 {
    let candidate = self.step(trial_dt).wfr_rescale_to_mass(target_mass)
    let candidate_energy = candidate.free_energy()
    let proposed_increase = if candidate_energy.is_finite() {
      (candidate_energy - initial_energy).max(0.0)
    } else {
      1.0e300
    }
    if proposed_increase > max_proposed_increase {
      max_proposed_increase = proposed_increase
    }
    if candidate_energy.is_finite() && candidate_energy <= initial_energy {
      return {
        state: candidate,
        accepted: true,
        stationary_hold: false,
        retries: retry,
        effective_dt: trial_dt,
        max_proposed_energy_increase: max_proposed_increase,
      }
    }
    let density_change = wfr_weighted_density_distance(self, candidate)
    let energy_roundoff_tolerance = 1.0e-13 * (1.0 + initial_energy.abs())
    if candidate_energy.is_finite() &&
      proposed_increase <= energy_roundoff_tolerance &&
      density_change <= 1.0e-8 {
      return {
        state: self,
        accepted: true,
        stationary_hold: true,
        retries: retry,
        effective_dt: trial_dt,
        max_proposed_energy_increase: max_proposed_increase,
      }
    }
    trial_dt = trial_dt * 0.5
  }
  {
    state: self,
    accepted: false,
    stationary_hold: false,
    retries: 25,
    effective_dt: 0.0,
    max_proposed_energy_increase: max_proposed_increase,
  }
}

///|
/// Stream a long deterministic WFR integration without storing its trajectory.
/// Each step backtracks to preserve non-increasing free energy; mass is rescaled to
/// its initial value and the report records failures, stationary holds, retries,
/// finite-precision proposal violations, and the actual integrated time.
pub fn SuperBeltramiPDE::audit_long_time_stability(
  self : SuperBeltramiPDE,
  dt : Double,
  steps : Int32,
) -> WFRLongTimeStabilityReport {
  let shape_valid = self.n_cells > 1 &&
    self.density.length() == self.n_cells &&
    self.vol_weights.length() == self.n_cells &&
    self.potential.length() == self.n_cells &&
    self.grid.length() == self.n_cells
  let initial_mass = if shape_valid { self.total_mass() } else { 0.0 }
  let initial_energy = if shape_valid { self.free_energy() } else { 0.0 }
  let mut values_valid = initial_mass.is_finite() &&
    initial_mass > 0.0 &&
    initial_energy.is_finite() &&
    self.diffusivity.is_finite() &&
    self.diffusivity > 0.0 &&
    self.fisher_rate.is_finite() &&
    self.fisher_rate >= 0.0
  let mut min_density = 1.0e300
  if shape_valid {
    for i in 0..<self.n_cells {
      let rho = self.density[i]
      if !rho.is_finite() ||
        rho <= 0.0 ||
        !self.vol_weights[i].is_finite() ||
        self.vol_weights[i] <= 0.0 ||
        !self.potential[i].is_finite() ||
        !self.grid[i].is_finite() {
        values_valid = false
      }
      if rho < min_density {
        min_density = rho
      }
    }
  } else {
    values_valid = false
    min_density = 0.0
  }
  let input_valid = dt.is_finite() &&
    dt > 0.0 &&
    steps >= 0 &&
    shape_valid &&
    values_valid
  if !input_valid {
    return {
      input_valid: false,
      requested_steps: steps,
      completed_steps: 0,
      stationary_holds: 0,
      failed_steps: 0,
      adaptive_retries: 0,
      simulated_time: 0.0,
      initial_free_energy: initial_energy,
      final_free_energy: initial_energy,
      final_equilibrium_distance: 1.0e300,
      max_free_energy_increase: 0.0,
      max_proposed_energy_increase: 0.0,
      max_mass_conservation_error: 0.0,
      minimum_density: min_density,
      free_energy_monotone: false,
      mass_conserved: false,
      positivity_preserved: false,
    }
  }

  let mut state = self
  let mut previous_energy = initial_energy
  let mut completed_steps = 0
  let mut stationary_holds = 0
  let mut failed_steps = 0
  let mut adaptive_retries = 0
  let mut simulated_time = 0.0
  let mut max_increase = 0.0
  let mut max_proposed_increase = 0.0
  let mut max_mass_error = 0.0
  let mut free_energy_monotone = true
  for _ in 0..<steps {
    let guarded = state.step_energy_monotone(dt)
    adaptive_retries = adaptive_retries + guarded.retries
    if guarded.max_proposed_energy_increase > max_proposed_increase {
      max_proposed_increase = guarded.max_proposed_energy_increase
    }
    if !guarded.accepted {
      failed_steps = failed_steps + 1
      break
    }
    let next_energy = guarded.state.free_energy()
    let observed_increase = next_energy - previous_energy
    if observed_increase > max_increase {
      max_increase = observed_increase
    }
    if observed_increase > 0.0 {
      free_energy_monotone = false
    }
    state = guarded.state
    previous_energy = next_energy
    completed_steps = completed_steps + 1
    if guarded.stationary_hold {
      stationary_holds = stationary_holds + 1
    }
    simulated_time = simulated_time + guarded.effective_dt
    let mass_error = (state.total_mass() - initial_mass).abs()
    if mass_error > max_mass_error {
      max_mass_error = mass_error
    }
    for rho in state.density {
      if rho < min_density {
        min_density = rho
      }
    }
  }
  let equilibrium = state.gibbs_equilibrium()
  let mut equilibrium_distance = 0.0
  for i in 0..<state.n_cells {
    equilibrium_distance = equilibrium_distance +
      state.vol_weights[i] *
      (state.density[i] - initial_mass * equilibrium[i]).abs()
  }
  {
    input_valid: true,
    requested_steps: steps,
    completed_steps,
    stationary_holds,
    failed_steps,
    adaptive_retries,
    simulated_time,
    initial_free_energy: initial_energy,
    final_free_energy: state.free_energy(),
    final_equilibrium_distance: equilibrium_distance,
    max_free_energy_increase: max_increase,
    max_proposed_energy_increase: max_proposed_increase,
    max_mass_conservation_error: max_mass_error,
    minimum_density: min_density,
    free_energy_monotone,
    mass_conserved: max_mass_error < 1.0e-12,
    positivity_preserved: min_density > 0.0,
  }
}

///|
/// Advance one deterministic WFR step, then apply the mass-zero additive forcing
/// `sigma * Xi(t)` in density space. The forcing is projected to zero total
/// Berezinian mass, positivity is preserved by a weighted-simplex retraction, and
/// the ledger reports deterministic dissipation separately from perturbation work.
/// If `xi.length() != n_cells` or any forcing value is non-finite, the deterministic
/// step is returned and the ledger marks the corresponding input-validity flag false.
pub fn SuperBeltramiPDE::step_with_exogenous_perturbation(
  self : SuperBeltramiPDE,
  dt : Double,
  perturbation : WFRExogenousPerturbation,
) -> WFRPerturbedStep {
  let mass_before = self.total_mass()
  let free_energy_before = self.free_energy()
  let deterministic = self.step(dt)
  let deterministic_mass_after = deterministic.total_mass()
  let deterministic_free_energy_after = deterministic.free_energy()
  let input_shape_valid = perturbation.xi.length() == self.n_cells
  let mut input_values_valid = perturbation.sigma.is_finite()
  for value in perturbation.xi {
    if !value.is_finite() {
      input_values_valid = false
    }
  }
  let density = if input_shape_valid && input_values_valid {
    let mut total_volume = 0.0
    let mut forcing_mass = 0.0
    for i in 0..<self.n_cells {
      total_volume = total_volume + self.vol_weights[i]
      forcing_mass = forcing_mass + self.vol_weights[i] * perturbation.xi[i]
    }
    let xi_mean = if total_volume > 0.0 {
      forcing_mass / total_volume
    } else {
      0.0
    }
    // The weighted mean subtraction makes the additive source tangent to the
    // fixed-mass simplex; the final retraction handles large forcing safely.
    let trial = Array::makei(self.n_cells, i => {
      (deterministic.density[i] +
      dt * perturbation.sigma * (perturbation.xi[i] - xi_mean)).max(1.0e-24)
    })
    let mut trial_mass = 0.0
    for i in 0..<self.n_cells {
      trial_mass = trial_mass + self.vol_weights[i] * trial[i]
    }
    trial.map(rho => rho * deterministic_mass_after / trial_mass)
  } else {
    deterministic.density
  }
  let state = deterministic.wfr_state_with_density(density)
  let mass_after = state.total_mass()
  let free_energy_after = state.free_energy()
  {
    state,
    ledger: {
      input_shape_valid,
      input_values_valid,
      mass_before,
      deterministic_mass_after,
      mass_after,
      mass_conservation_error: (mass_after - mass_before).abs(),
      free_energy_before,
      deterministic_free_energy_after,
      free_energy_after,
      deterministic_dissipation: free_energy_before -
      deterministic_free_energy_after,
      perturbation_work: free_energy_after - deterministic_free_energy_after,
      total_free_energy_change: free_energy_after - free_energy_before,
    },
  }
}

///|
/// Compute the discrete Laplace-Beltrami-Berezin operator on M^{m|n}_c:
///   (Delta_{M^{m|n}} u)(r) = (1 / sqrt(Ber(G))) d_r ( sqrt(Ber(G)) g^{rr} d_r u )
///                          = lambda(r)^{-2} [ u''(r) + 2c (m - n - 2) r / (1 - c r^2) u'(r) ]
/// showing explicitly how superdimension sdim = m - n modulates geometric drift!
pub fn laplace_beltrami_berezin_1d(
  manifold : SuperManifold,
  u : (Double) -> Double,
  r : Double,
  eps~ : Double = 1.0e-5,
) -> Double {
  let c = manifold.c
  let sdim = manifold.super_dim().to_double()
  let lam = 2.0 / (1.0 - c * r * r)
  let u_r = (u(r + eps) - u(r - eps)) / (2.0 * eps)
  let u_rr = (u(r + eps) - 2.0 * u(r) + u(r - eps)) / (eps * eps)
  let drift = 2.0 * c * (sdim - 2.0) * r / (1.0 - c * r * r)
  (u_rr + drift * u_r) / (lam * lam)
}

///|
/// Supersymmetric Witten-Hodge Heat PDE Flow:
///   d Psi / dt = -H Psi = -(1/2) (Q Q^dagger + Q^dagger Q) Psi.
/// Solved exactly by semigroup propagator exp(-t H): damps all excited non-BPS
/// boson-fermion pairs at identical rate exp(-t E_k), converging exponentially
/// onto the topologically protected harmonic BPS ground state P_BPS(Psi_0)!
pub fn evolve_susy_heat_flow(
  sys : WittenSUSYSystem,
  psi0 : Array[Double],
  t : Double,
) -> Array[Double] {
  let tot = sys.m_bos + sys.n_ferm
  let (eigs, v) = sys.hamiltonian.sym_eigen()
  let out = Array::make(tot, 0.0)
  for k in 0..<tot {
    let mut coeff = 0.0
    for i in 0..<tot {
      coeff = coeff + v.get(i, k) * psi0[i]
    }
    let damped = coeff * @math.exp(-t * eigs[k].max(0.0))
    for i in 0..<tot {
      out[i] = out[i] + damped * v.get(i, k)
    }
  }
  out
}

///|
/// Adaptive Poincare-Ricci-Fisher Metric Curvature Flow:
/// Derived from projecting d_t g_{ij} = -2 Ric_{ij}(g) + 2 kappa F_{ij} - 2 Lambda g_{ij}
/// onto constant negative curvature slices K(t) = -c(t) (where Ric = -c(m-1)g):
///   dc / dt = -2 (m - 1) c^2 + 2 Lambda c + kappa * I_Fisher,
/// which possesses a unique globally asymptotically stable hyperbolic fixed point
///   c* = (Lambda + sqrt(Lambda^2 + 2 (m - 1) kappa I_Fisher)) / (2 (m - 1)) > 0!
/// Even starting from flat space c(0) -> 0+, non-zero Fisher information I_Fisher > 0
/// spontaneously generates negative curvature (emergent semantic hierarchy)!
pub fn evolve_ricci_fisher_curvature(
  c0 : Double,
  m_bos : Int32,
  cosmological_lambda : Double,
  kappa : Double,
  fisher_trace : Double,
  dt : Double,
  steps : Int32,
) -> (Array[Double], Double) {
  let m1 = (m_bos - 1).to_double().max(1.0)
  let rhs = (c : Double) => {
    -2.0 * m1 * c * c + 2.0 * cosmological_lambda * c + kappa * fisher_trace
  }
  let c_star = (
      cosmological_lambda +
      (cosmological_lambda * cosmological_lambda +
      2.0 * m1 * kappa * fisher_trace).sqrt()
    ) /
    (2.0 * m1)
  let traj : Array[Double] = Array(capacity=steps + 1)
  let mut c = c0
  traj.push(c)
  for _ in 0..<steps {
    let k1 = rhs(c)
    let k2 = rhs(c + 0.5 * dt * k1)
    let k3 = rhs(c + 0.5 * dt * k2)
    let k4 = rhs(c + dt * k3)
    c = (c + dt / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4)).max(1.0e-9)
    traj.push(c)
  }
  (traj, c_star)
}
