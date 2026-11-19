///|
/// Evidence from the M6 Flow -> Trop-Kan -> Germ-Micro -> Syn-Mem-Para feedback pass.
/// `role_absorption_times` is ordered as SGNE roles [Coordinator, Sensor, Planner, Executor].
#derive(Debug, Eq)
pub(all) struct M6ClosedLoopReport {
  input_valid : Bool
  converged : Bool
  empirical_fixed_point_certified : Bool
  iterations : Int32
  hurst_exponent : Double
  catastrophe_class : String
  role_coverage_count : Int32
  microlocal_quarantined : Bool
  microlocal_value : FourVal
  flow_mass_weights : Array[Double]
  trop_kan_weights : Array[Double]
  role_absorption_times : Array[Double]
  fixed_point_residual : Double
  empirical_contraction_factor : Double
  weight_normalization_defect : Double
  flow_free_energy : Double
  non_explosion_preserved : Bool
}

///|
fn m6_max_weight_defect(a : Array[Double], b : Array[Double]) -> Double {
  if a.length() != b.length() {
    return 1.0e300
  }
  let mut worst = 0.0
  for i in 0..<a.length() {
    worst = worst.max((a[i] - b[i]).abs())
  }
  worst
}

///|
fn m6_weight_sum_defect(weights : Array[Double]) -> Double {
  let mut sum = 0.0
  for weight in weights {
    sum = sum + weight
  }
  (sum - 1.0).abs()
}

///|
fn m6_blend_weights(
  current : Array[Double],
  target : Array[Double],
  relaxation : Double,
) -> Array[Double] {
  let mixed = Array::makei(4, role => {
    (1.0 - relaxation) * current[role] + relaxation * target[role]
  })
  let mut total = 0.0
  for weight in mixed {
    total = total + weight
  }
  mixed.map(weight => weight / total)
}

///|
/// Memory-derived controller targets. Profile index order is remapped to the SGNE order
/// before this helper is called; log1p keeps the response bounded as H approaches one.
fn m6_memory_target(
  absorption_times : Array[Double],
  gain : Double,
  class : CatastropheKind,
  quarantined : Bool,
) -> Array[Double] {
  let log_times = absorption_times.map(time => @math.ln(1.0 + time))
  let mut mean = 0.0
  for value in log_times {
    mean = mean + value / 4.0
  }
  let class_sign = match class {
    A3Cusp => -1.0
    D4Umbilic => 1.0
  }
  let scores = Array::makei(4, role => {
    let role_sign = if role == 0 || role == 2 { 1.0 } else { -1.0 }
    let catastrophe_bias = 0.04 * class_sign * role_sign
    let quarantine_bias = if quarantined {
      if role == 0 {
        0.02
      } else {
        -0.02 / 3.0
      }
    } else {
      0.0
    }
    gain * (log_times[role] - mean) + catastrophe_bias + quarantine_bias
  })
  softmax_vec(scores)
}

///|
fn invalid_m6_report() -> M6ClosedLoopReport {
  {
    input_valid: false,
    converged: false,
    empirical_fixed_point_certified: false,
    iterations: 0,
    hurst_exponent: 0.0,
    catastrophe_class: "invalid",
    role_coverage_count: 0,
    microlocal_quarantined: false,
    microlocal_value: Nv,
    flow_mass_weights: [],
    trop_kan_weights: [],
    role_absorption_times: [],
    fixed_point_residual: 0.0,
    empirical_contraction_factor: 0.0,
    weight_normalization_defect: 0.0,
    flow_free_energy: 0.0,
    non_explosion_preserved: false,
  }
}

///|
/// M6 deterministic damped fixed-point iteration. Each iterate runs the four layers from
/// a common initial colony: mass weights parameterize SGNE-Flow; the weighted colony is
/// distilled by Trop-Kan; role occupancy selects an M4 unfolding and M5 antipodal event;
/// the resulting Hurst-conditioned Syn-Mem absorption times update both weight vectors.
/// Convergence is reported from the actual residual sequence, not asserted as a global
/// theorem about the full nonlinear SGNE simulator.
pub fn audit_four_layer_closed_loop(
  flow_steps~ : Int32 = 4,
  max_iterations~ : Int32 = 24,
  relaxation~ : Double = 0.35,
  tolerance~ : Double = 1.0e-3,
) -> M6ClosedLoopReport {
  if flow_steps < 1 ||
    max_iterations < 2 ||
    max_iterations > 64 ||
    !relaxation.is_finite() ||
    relaxation <= 0.0 ||
    relaxation > 1.0 ||
    !tolerance.is_finite() ||
    tolerance <= 0.0 ||
    tolerance > 0.1 {
    return invalid_m6_report()
  }
  let n_agents = 8
  let dt = 0.12
  let initial_agents = init_disordered_colony(n_agents, 0.25)
  let mut flow_weights = [0.25, 0.25, 0.25, 0.25]
  let mut trop_weights = [0.25, 0.25, 0.25, 0.25]
  let mut previous_residual = 1.0e300
  let mut empirical_contraction = 0.0
  let mut contraction_evidence = false
  let mut residual_sequence_contracting = true
  let mut residual = 1.0e300
  let mut final_hurst = 0.5
  let mut final_class = "invalid"
  let mut final_role_coverage = 0
  let mut final_quarantined = false
  let mut final_microlocal_value = Nv
  let mut final_absorption_times : Array[Double] = []
  let mut final_free_energy = 0.0
  let mut final_non_explosion = false
  let mut iterations = 0
  let mut converged = false

  for iteration in 0..<max_iterations {
    let (snapshots, final_agents) = match
      run_sgne_emergence_simulation_with_mass_feedback(
        n_agents, flow_steps, dt, flow_weights,
      ) {
      Ok(result) => result
      Err(_) => return invalid_m6_report()
    }
    if snapshots.length() == 0 {
      return invalid_m6_report()
    }
    let macro_agent = match
      distill_tropical_kan_macro_agent_with_weights(
        initial_agents, final_agents, trop_weights,
      ) {
      Ok(report) => report
      Err(_) => return invalid_m6_report()
    }
    let occupied = Array::make(4, false)
    for role in macro_agent.role_assignment {
      if role < 0 || role >= 4 {
        return invalid_m6_report()
      }
      occupied[role] = true
    }
    let mut role_coverage = 0
    for is_occupied in occupied {
      if is_occupied {
        role_coverage = role_coverage + 1
      }
    }
    let target_branches = if role_coverage >= 4 { 4 } else { 3 }
    let catastrophe = learn_catastrophe_for_role_branches(target_branches, 0.05)
    if !catastrophe.certified {
      return invalid_m6_report()
    }

    let last_snapshot = snapshots[snapshots.length() - 1]
    let signal = HyperfunctionGerm::cauchy_plus(last_snapshot.policy_entropy).sp()
    let belief_spectrum = match catastrophe.selected_class {
      A3Cusp =>
        HyperfunctionGerm::cauchy_plus(last_snapshot.policy_entropy).sp()
      D4Umbilic =>
        HyperfunctionGerm::cauchy_minus(last_snapshot.policy_entropy).sp()
    }
    let attention = microlocal_attention_event(signal, belief_spectrum, Tv)
    if !attention.input_valid {
      return invalid_m6_report()
    }
    let entropy_fraction = (last_snapshot.policy_entropy / @math.ln(4.0)).clamp(
      min=0.0,
      max=1.0,
    )
    let role_fraction = role_coverage.to_double() / 4.0
    let ghost_fraction = macro_agent.final_ghost_agents.to_double() /
      n_agents.to_double()
    let quarantine_memory_bonus = if attention.quarantined { 0.06 } else { 0.0 }
    let hurst = (0.20 +
    0.32 * entropy_fraction +
    0.18 * role_fraction +
    0.12 * (1.0 - ghost_fraction) +
    quarantine_memory_bonus).clamp(min=0.05, max=0.95)
    let synmem = distill_synergetic_memory_para_agent(
      final_agents,
      last_snapshot.curvature_c,
      hurst~,
    )
    if !synmem.hurst_profile_valid || synmem.role_absorption_times.length() != 4 {
      return invalid_m6_report()
    }
    // Memory reports [Coordinator, Planner, Sensor, Executor]; SGNE/Trop-Kan index
    // order is [Coordinator, Sensor, Planner, Executor]. Reorder at the boundary once.
    let absorption_by_sgne_role = [
      synmem.role_absorption_times[0],
      synmem.role_absorption_times[2],
      synmem.role_absorption_times[1],
      synmem.role_absorption_times[3],
    ]
    let target_flow = m6_memory_target(
      absorption_by_sgne_role,
      0.45,
      catastrophe.selected_class,
      attention.quarantined,
    )
    let target_trop = m6_memory_target(
      absorption_by_sgne_role,
      -0.32,
      catastrophe.selected_class,
      attention.quarantined,
    )
    residual = m6_max_weight_defect(flow_weights, target_flow).max(
      m6_max_weight_defect(trop_weights, target_trop),
    )
    iterations = iteration + 1
    final_hurst = hurst
    final_class = catastrophe.selected_label
    final_role_coverage = role_coverage
    final_quarantined = attention.quarantined
    final_microlocal_value = attention.value_after
    final_absorption_times = absorption_by_sgne_role
    final_free_energy = last_snapshot.free_energy
    final_non_explosion = synmem.no_explosion &&
      attention.non_explosion_preserved

    if previous_residual < 1.0e299 && previous_residual > 0.0 {
      let ratio = residual / previous_residual
      empirical_contraction = empirical_contraction.max(ratio)
      contraction_evidence = true
      if ratio >= 1.0 {
        residual_sequence_contracting = false
      }
    }
    if residual <= tolerance && iteration > 0 {
      converged = true
      break
    }
    previous_residual = residual
    // Keep the report's residual and observables paired with the weights that produced
    // them. Do not advance one unused iterate after the final allowed audit pass.
    if iteration + 1 < max_iterations {
      flow_weights = m6_blend_weights(flow_weights, target_flow, relaxation)
      trop_weights = m6_blend_weights(trop_weights, target_trop, relaxation)
    }
  }

  let normalization_defect = m6_weight_sum_defect(flow_weights).max(
    m6_weight_sum_defect(trop_weights),
  )
  let empirical_fixed_point_certified = converged &&
    residual <= tolerance &&
    contraction_evidence &&
    residual_sequence_contracting &&
    empirical_contraction < 1.0 &&
    normalization_defect < 1.0e-12 &&
    final_non_explosion
  {
    input_valid: true,
    converged,
    empirical_fixed_point_certified,
    iterations,
    hurst_exponent: final_hurst,
    catastrophe_class: final_class,
    role_coverage_count: final_role_coverage,
    microlocal_quarantined: final_quarantined,
    microlocal_value: final_microlocal_value,
    flow_mass_weights: flow_weights,
    trop_kan_weights: trop_weights,
    role_absorption_times: final_absorption_times,
    fixed_point_residual: residual,
    empirical_contraction_factor: if contraction_evidence {
      empirical_contraction
    } else {
      1.0
    },
    weight_normalization_defect: normalization_defect,
    flow_free_energy: final_free_energy,
    non_explosion_preserved: final_non_explosion,
  }
}
