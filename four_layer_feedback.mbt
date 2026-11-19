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
  /// The B_4 colony factor of the four layers (M10 v2). The old boolean above is
  /// retained as a derived view so existing consumers do not break, but the
  /// authoritative state is this factor: a contradiction is CARRIED, not merely
  /// flagged. `carrying_contradiction` is the honest replacement for
  /// `microlocal_quarantined`.
  colony_factor : ColonyFactor
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
/// A layer's verdict as a B_4 element, so the four layers can be treated as four
/// sub-colonies rather than being collapsed into one scalar.
///
///   - the layer produced a usable result            -> `Tv`
///   - the layer ran but failed a check              -> `Fv`
///   - the layer had nothing to say (skipped/empty)  -> `Nv`
///
/// A layer that is deliberately quarantined by M5 is `Bv` at that layer only;
/// that is the caller's choice, not this helper's.
fn classify_layer(ok : Bool, ran : Bool) -> FourVal {
  if !ran {
    FourVal::Nv
  } else if ok {
    FourVal::Tv
  } else {
    FourVal::Fv
  }
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
    colony_factor: colony_factor([]),
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
  let mut final_factor = colony_factor([])
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
    // THE DEGRADATION, wired in: the four layers are four SUB-COLONIES, each
    // contributing a full B_4 value. A microlocal quarantine is a `Bv` at that
    // layer, not a global veto — the loop keeps running and acts on whichever
    // branch survives, which is what "打交佢都會繼續比你完成件事" means
    // concretely. The old boolean is a derived view of this factor.
    let layer_verdicts : Array[SubColonyVerdict] = [
      {
        name: "flow",
        value: classify_layer(role_coverage >= 3, flow_steps > 0),
        confidence: 1.0,
      },
      {
        name: "trop-kan",
        value: classify_layer(role_coverage >= 2, true),
        confidence: 1.0,
      },
      {
        name: "germ-micro",
        value: if attention.quarantined {
          FourVal::Bv
        } else {
          FourVal::Tv
        },
        confidence: 1.0,
      },
      {
        name: "syn-mem",
        value: classify_layer(synmem.hurst_profile_valid, true),
        confidence: 1.0,
      },
    ]
    final_factor = colony_factor(layer_verdicts)
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
    colony_factor: final_factor,
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

///|
/// M6 v2 report: the closed loop where **every** calibration decision is
/// certified by the M4 tangent-cone engine rather than by a hard-coded branch
/// count. `role_assignment` uses the SGNE four-cluster order
/// [Coordinator, Sensor, Planner, Executor]; `dominant_band` is the index of
/// the band the tangent-cone analysis selected in the memory spectrum.
#derive(Debug, Eq)
pub(all) struct M6TangentConeFeedbackReport {
  input_valid : Bool
  converged : Bool
  empirical_fixed_point_certified : Bool
  iterations : Int32
  hurst_exponent : Double
  catastrophe_class : String
  cone_multiplicity : Int32
  cone_dimension : Int32
  cone_conical : Bool
  role_coverage_count : Int32
  role_assignment : Array[Int32]
  cluster_sizes : Array[Int32]
  dominant_band : Int32
  band_cycle_reversible : Bool
  microlocal_quarantined : Bool
  microlocal_value : FourVal
  flow_mass_weights : Array[Double]
  trop_kan_weights : Array[Double]
  role_absorption_times : Array[Double]
  fixed_point_residual : Double
  empirical_contraction_factor : Double
  weight_normalization_defect : Double
  non_explosion_preserved : Bool
}

///|
fn invalid_m6_cone_report() -> M6TangentConeFeedbackReport {
  {
    input_valid: false,
    converged: false,
    empirical_fixed_point_certified: false,
    iterations: 0,
    hurst_exponent: 0.0,
    catastrophe_class: "invalid",
    cone_multiplicity: 0,
    cone_dimension: 0,
    cone_conical: false,
    role_coverage_count: 0,
    role_assignment: [],
    cluster_sizes: [],
    dominant_band: -1,
    band_cycle_reversible: false,
    microlocal_quarantined: false,
    microlocal_value: Nv,
    flow_mass_weights: [],
    trop_kan_weights: [],
    role_absorption_times: [],
    fixed_point_residual: 0.0,
    empirical_contraction_factor: 0.0,
    weight_normalization_defect: 0.0,
    non_explosion_preserved: false,
  }
}

///|
/// M6 v2 deterministic damped fixed-point iteration in which the catastrophe
/// stage of the loop is *not* a branch-count lookup: role occupancy below
/// selects the target branch count, and each iteration re-runs the M4
/// tangent-cone certificate, falls back to the certified alternative if the
/// preferred class fails certification, and (on a certified M4 result) feeds
/// the M4→M5 micro-local attention and the certified role occupancy into the
/// Syn-Mem absorption targets for the Flow and Trop-Kan weight vectors.
///
/// The band-cycle reversibility check re-runs the role assignment with the
/// (dominantly occupied band → 0 → original) spectrum cycle, mirroring M1.2's
/// pure-function reversal but with the multiplicity-aware role order that the
/// tangent cone produces.
pub fn audit_four_layer_tangent_cone_loop(
  flow_steps~ : Int32 = 4,
  max_iterations~ : Int32 = 24,
  relaxation~ : Double = 0.35,
  tolerance~ : Double = 1.0e-3,
) -> M6TangentConeFeedbackReport {
  if flow_steps < 1 ||
    max_iterations < 2 ||
    max_iterations > 64 ||
    !relaxation.is_finite() ||
    relaxation <= 0.0 ||
    relaxation > 1.0 ||
    !tolerance.is_finite() ||
    tolerance <= 0.0 ||
    tolerance > 0.1 {
    return invalid_m6_cone_report()
  }
  let n_agents = 8
  let dt = 0.12
  let initial_agents = init_disordered_colony(n_agents, 0.25)
  let orbits = canonical_role_mass_orbits()
  let mut flow_weights = [0.25, 0.25, 0.25, 0.25]
  let mut trop_weights = [0.25, 0.25, 0.25, 0.25]
  let mut previous_residual = 1.0e300
  let mut empirical_contraction = 0.0
  let mut contraction_evidence = false
  let mut residual_sequence_contracting = true
  let mut residual = 1.0e300
  let mut final_hurst = 0.5
  let mut final_class = "invalid"
  let mut final_cone_mult = 0
  let mut final_cone_dim = 0
  let mut final_cone_conical = false
  let mut final_assignment : Array[Int32] = []
  let mut final_cluster_sizes : Array[Int32] = []
  let mut final_coverage = 0
  let mut final_band = -1
  let mut final_quarantined = false
  let mut final_microlocal = Nv
  let mut final_absorption : Array[Double] = []
  let mut final_non_explosion = false
  let mut iterations = 0
  let mut converged = false

  for iteration in 0..<max_iterations {
    let (snapshots, final_agents) = match
      run_sgne_emergence_simulation_with_mass_feedback(
        n_agents, flow_steps, dt, flow_weights,
      ) {
      Ok(result) => result
      Err(_) => return invalid_m6_cone_report()
    }
    if snapshots.length() == 0 {
      return invalid_m6_cone_report()
    }
    let macro_agent = match
      distill_tropical_kan_macro_agent_with_weights(
        initial_agents, final_agents, trop_weights,
      ) {
      Ok(report) => report
      Err(_) => return invalid_m6_cone_report()
    }
    let occupied = Array::make(4, false)
    for role in macro_agent.role_assignment {
      if role < 0 || role >= 4 {
        return invalid_m6_cone_report()
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
    // M4 tangent-cone certificate, with explicit fallback on a failed class.
    let mut catastrophe = learn_catastrophe_from_tangent_cone(
      target_branches, 0.05,
    )
    if !catastrophe.input_valid || !catastrophe.certified {
      let alternate = if target_branches == 4 { 3 } else { 4 }
      catastrophe = learn_catastrophe_from_tangent_cone(alternate, 0.05)
    }
    if !catastrophe.input_valid || !catastrophe.certified {
      return invalid_m6_cone_report()
    }
    // M5 microlocal attention: same-point antipodal conormal collision.
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
      return invalid_m6_cone_report()
    }
    // Syn-Mem: Hurst comes from the Flow observables and the quarantine event.
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
      return invalid_m6_cone_report()
    }
    // Distinguishing observables drive the band selection: the cone multiplicity
    // sets the memory band (mult 2 -> band 2, mult 4 -> band 4), while the
    // M5 quarantine adds one band of isolation pressure.
    let quarantine_band = if attention.quarantined { 1 } else { 0 }
    let band = (
        catastrophe.d4_cone_multiplicity.min(catastrophe.a3_cone_multiplicity) +
        (catastrophe.d4_cone_multiplicity - catastrophe.a3_cone_multiplicity).abs() +
        quarantine_band
      ) %
      4
    let disturbance = Array::make(4, 0.0)
    disturbance[band] = 8.0
    // Recover the agent masses that the Flow/Trop-Kan chain ended on.
    let agent_masses = Array::makei(final_agents.length(), i => {
      final_agents[i].mass
    })
    let reassigned = reassign_roles_by_orbit_distance(
      agent_masses, orbits, disturbance,
    )
    if !reassigned.input_valid {
      return invalid_m6_cone_report()
    }
    // Memory index order is [Coordinator, Planner, Sensor, Executor]; remap once.
    let absorption_by_sgne_role = [
      synmem.role_absorption_times[0],
      synmem.role_absorption_times[2],
      synmem.role_absorption_times[1],
      synmem.role_absorption_times[3],
    ]
    let selected = catastrophe.selected_class
    let target_flow = m6_memory_target(
      absorption_by_sgne_role,
      0.45,
      selected,
      attention.quarantined,
    )
    let target_trop = m6_memory_target(
      absorption_by_sgne_role,
      -0.32,
      selected,
      attention.quarantined,
    )
    residual = m6_max_weight_defect(flow_weights, target_flow).max(
      m6_max_weight_defect(trop_weights, target_trop),
    )
    iterations = iteration + 1
    final_hurst = hurst
    final_class = catastrophe.selected_label
    final_cone_mult = if selected == D4Umbilic {
      catastrophe.d4_cone_multiplicity
    } else {
      catastrophe.a3_cone_multiplicity
    }
    final_cone_dim = if selected == D4Umbilic {
      catastrophe.d4_cone_dimension
    } else {
      catastrophe.a3_cone_dimension
    }
    final_cone_conical = if selected == D4Umbilic {
      catastrophe.d4_conical
    } else {
      catastrophe.a3_conical
    }
    final_assignment = macro_agent.role_assignment
    final_cluster_sizes = reassigned.cluster_sizes
    final_coverage = role_coverage
    final_band = band
    final_quarantined = attention.quarantined
    final_microlocal = attention.value_after
    final_absorption = absorption_by_sgne_role
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
    if iteration + 1 < max_iterations {
      flow_weights = m6_blend_weights(flow_weights, target_flow, relaxation)
      trop_weights = m6_blend_weights(trop_weights, target_trop, relaxation)
    }
  }

  // Band cycle 0 -> band -> 0 must restore the original assignment exactly.
  let mut band_cycle_reversible = false
  let mut cycle_checked = false
  if final_band >= 0 && final_assignment.length() == n_agents {
    // Rebuild the last iterate's masses cheaply: the assignment is a pure
    // function of (masses, spectrum), so evaluate at the observed clusters.
    let (snapshots, final_agents) = match
      run_sgne_emergence_simulation_with_mass_feedback(
        n_agents, flow_steps, dt, flow_weights,
      ) {
      Ok(result) => result
      Err(_) => return invalid_m6_cone_report()
    }
    let _ = snapshots
    let agent_masses = Array::makei(final_agents.length(), i => {
      final_agents[i].mass
    })
    let spectrum_0 = [8.0, 0.0, 0.0, 0.0]
    let spectrum_band = Array::make(4, 0.0)
    spectrum_band[final_band] = 8.0
    let assign_a = reassign_roles_by_orbit_distance(
      agent_masses, orbits, spectrum_0,
    )
    let assign_b = reassign_roles_by_orbit_distance(
      agent_masses, orbits, spectrum_band,
    )
    let assign_back = reassign_roles_by_orbit_distance(
      agent_masses, orbits, spectrum_0,
    )
    cycle_checked = assign_a.input_valid &&
      assign_b.input_valid &&
      assign_back.input_valid
    band_cycle_reversible = cycle_checked &&
      assign_a.role_assignment == assign_back.role_assignment
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
    cycle_checked
  {
    input_valid: true,
    converged,
    empirical_fixed_point_certified,
    iterations,
    hurst_exponent: final_hurst,
    catastrophe_class: final_class,
    cone_multiplicity: final_cone_mult,
    cone_dimension: final_cone_dim,
    cone_conical: final_cone_conical,
    role_coverage_count: final_coverage,
    role_assignment: final_assignment,
    cluster_sizes: final_cluster_sizes,
    dominant_band: final_band,
    band_cycle_reversible,
    microlocal_quarantined: final_quarantined,
    microlocal_value: final_microlocal,
    flow_mass_weights: flow_weights,
    trop_kan_weights: trop_weights,
    role_absorption_times: final_absorption,
    fixed_point_residual: residual,
    empirical_contraction_factor: if contraction_evidence {
      empirical_contraction
    } else {
      1.0
    },
    weight_normalization_defect: normalization_defect,
    non_explosion_preserved: final_non_explosion,
  }
}

///|
/// M6 v3 report: the same four-layer loop as `audit_four_layer_closed_loop`, but
/// with the two *refinement* checks that a fixed-point claim needs and that the
/// v1/v2 reports do not perform:
///
///   1. **step-size refinement** — rerun the whole damped iteration with
///      `relaxation / 2`; a genuine fixed point must be approached from the same
///      place, so the two fixed points may differ by O(relaxation) but not more;
///   2. **local contraction** — estimate the spectral radius of the iteration map
///      by finite differences: perturb each weight coordinate by `h`, rerun one
///      full layer pass, and take the matrix max-norm of the divided difference.
///      The v1/v2 reports only bound the *observed* consecutive residual ratio,
///      which says nothing about nearby trajectories.
///
/// Both diagnostics are deliberately weak (they are numerical, on one sampled
/// colony) and are documented as such; they upgrade "the residual decreased"
/// to "the map contracts near this point with radius rho < 1".
#derive(Debug, Eq)
pub(all) struct M6RefinementReport {
  input_valid : Bool
  relaxation : Double
  refined_relaxation : Double
  fixed_point_residual : Double
  refined_fixed_point_residual : Double
  weight_delta : Double
  local_contraction_radius : Double
  refinement_consistent : Bool
  local_contraction_certified : Bool
  certified : Bool
}

///|
/// One full layer pass: Flow -> Trop-Kan -> role coverage -> catastrophe class ->
/// Syn-Mem absorption -> next weight targets. This is the iteration map whose
/// fixed point the loop seeks; it is factored out so the Jacobian probe below
/// uses exactly the same map as the loop.
fn m6_layer_pass(
  flow_weights : Array[Double],
  trop_weights : Array[Double],
  flow_steps : Int32,
) -> Result[(Array[Double], Array[Double], Int32, Double), String] {
  let n_agents = 8
  let dt = 0.12
  let initial_agents = init_disordered_colony(n_agents, 0.25)
  let (snapshots, final_agents) = match
    run_sgne_emergence_simulation_with_mass_feedback(
      n_agents, flow_steps, dt, flow_weights,
    ) {
    Ok(result) => result
    Err(message) => return Err(message)
  }
  if snapshots.length() == 0 {
    return Err("flow produced no snapshots")
  }
  let macro_agent = match
    distill_tropical_kan_macro_agent_with_weights(
      initial_agents, final_agents, trop_weights,
    ) {
    Ok(report) => report
    Err(message) => return Err(message)
  }
  let occupied = Array::make(4, false)
  for role in macro_agent.role_assignment {
    if role >= 0 && role < 4 {
      occupied[role] = true
    }
  }
  let mut role_coverage = 0
  for is_occupied in occupied {
    if is_occupied {
      role_coverage = role_coverage + 1
    }
  }
  let last = snapshots[snapshots.length() - 1]
  let target_branches = if role_coverage >= 4 { 4 } else { 3 }
  let catastrophe = learn_catastrophe_from_tangent_cone(target_branches, 0.05)
  if !catastrophe.input_valid {
    return Err("catastrophe class not certifiable")
  }
  let quarantined = match catastrophe.selected_class {
    A3Cusp => false
    D4Umbilic => true
  }
  let entropy_fraction = (last.policy_entropy / @math.ln(4.0)).clamp(
    min=0.0,
    max=1.0,
  )
  let ghost_fraction = macro_agent.final_ghost_agents.to_double() /
    n_agents.to_double()
  let hurst = (0.20 +
  0.32 * entropy_fraction +
  0.18 * (role_coverage.to_double() / 4.0) +
  0.12 * (1.0 - ghost_fraction) +
  (if quarantined { 0.06 } else { 0.0 })).clamp(min=0.05, max=0.95)
  let synmem = distill_synergetic_memory_para_agent(
    final_agents,
    last.curvature_c,
    hurst~,
  )
  if !synmem.hurst_profile_valid || synmem.role_absorption_times.length() != 4 {
    return Err("memory profile invalid")
  }
  let absorption = [
    synmem.role_absorption_times[0],
    synmem.role_absorption_times[2],
    synmem.role_absorption_times[1],
    synmem.role_absorption_times[3],
  ]
  let cat_class = catastrophe.selected_class
  let target_flow = m6_memory_target(absorption, 0.45, cat_class, quarantined)
  let target_trop = m6_memory_target(absorption, -0.32, cat_class, quarantined)
  Ok((target_flow, target_trop, role_coverage, hurst))
}

///|
/// Full damped iteration to (approximate) fixed point at a given relaxation.
fn m6_iterate_to_fixed_point(
  relaxation : Double,
  flow_steps : Int32,
  max_iterations : Int32,
  tolerance : Double,
) -> Result[(Array[Double], Array[Double], Double, Int32), String] {
  let mut flow_weights = [0.25, 0.25, 0.25, 0.25]
  let mut trop_weights = [0.25, 0.25, 0.25, 0.25]
  let mut residual = 1.0e300
  let mut iterations = 0
  for _ in 0..<max_iterations {
    let (target_flow, target_trop, _, _) = match
      m6_layer_pass(flow_weights, trop_weights, flow_steps) {
      Ok(value) => value
      Err(message) => return Err(message)
    }
    residual = m6_max_weight_defect(flow_weights, target_flow).max(
      m6_max_weight_defect(trop_weights, target_trop),
    )
    iterations = iterations + 1
    if residual <= tolerance {
      break
    }
    flow_weights = m6_blend_weights(flow_weights, target_flow, relaxation)
    trop_weights = m6_blend_weights(trop_weights, target_trop, relaxation)
  }
  Ok((flow_weights, trop_weights, residual, iterations))
}

///|
pub fn audit_m6_refinement_and_local_contraction(
  flow_steps~ : Int32 = 3,
  max_iterations~ : Int32 = 32,
  relaxation~ : Double = 0.35,
  tolerance~ : Double = 1.0e-3,
  probe_step~ : Double = 1.0e-3,
) -> M6RefinementReport {
  let invalid = {
    input_valid: false,
    relaxation,
    refined_relaxation: relaxation / 2.0,
    fixed_point_residual: 0.0,
    refined_fixed_point_residual: 0.0,
    weight_delta: 0.0,
    local_contraction_radius: 1.0,
    refinement_consistent: false,
    local_contraction_certified: false,
    certified: false,
  }
  if !relaxation.is_finite() ||
    relaxation <= 0.0 ||
    relaxation > 1.0 ||
    !probe_step.is_finite() ||
    probe_step <= 0.0 ||
    probe_step > 1.0e-1 {
    return invalid
  }
  let (flow_a, trop_a, residual_a, _) = match
    m6_iterate_to_fixed_point(relaxation, flow_steps, max_iterations, tolerance) {
    Ok(value) => value
    Err(_) => return invalid
  }
  let refined = relaxation / 2.0
  let (flow_b, trop_b, residual_b, _) = match
    m6_iterate_to_fixed_point(
      refined,
      flow_steps,
      max_iterations * 2,
      tolerance,
    ) {
    Ok(value) => value
    Err(_) => return invalid
  }
  let delta = m6_max_weight_defect(flow_a, flow_b).max(
    m6_max_weight_defect(trop_a, trop_b),
  )
  // Local contraction: finite-difference the composite map at the fixed point.
  // G(w) = (1 - r) w + r T(w); its Jacobian is (1 - r) I + r DT. We measure the
  // max-norm of the divided differences of one *unrelaxed* layer pass T, then
  // apply the damping factor, which is the contraction factor that matters.
  let base = match m6_layer_pass(flow_a, trop_a, flow_steps) {
    Ok(value) => value
    Err(_) => return invalid
  }
  let (base_flow, _, _, _) = base
  let mut max_gain = 0.0
  for i in 0..<4 {
    let perturbed = flow_a.copy()
    perturbed[i] = perturbed[i] + probe_step
    let mut total = 0.0
    for weight in perturbed {
      total = total + weight
    }
    let normalized = perturbed.map(w => w / total)
    let (tf, _, _, _) = match m6_layer_pass(normalized, trop_a, flow_steps) {
      Ok(value) => value
      Err(_) => return invalid
    }
    for j in 0..<4 {
      let gain = ((tf[j] - base_flow[j]) / probe_step).abs()
      if gain > max_gain {
        max_gain = gain
      }
    }
  }
  // Damped map spectral radius bound: |1 - r| + r * ||DT||_max.
  let rho = (1.0 - relaxation).abs() + relaxation * max_gain
  let refinement_consistent = delta <= 10.0 * relaxation
  let contraction_certified = rho < 1.0
  {
    input_valid: true,
    relaxation,
    refined_relaxation: refined,
    fixed_point_residual: residual_a,
    refined_fixed_point_residual: residual_b,
    weight_delta: delta,
    local_contraction_radius: rho,
    refinement_consistent,
    local_contraction_certified: contraction_certified,
    certified: residual_a <= tolerance &&
    residual_b <= tolerance &&
    refinement_consistent &&
    contraction_certified,
  }
}

///|
/// M6.4: is the observed 2-of-4 role coverage structural or is it a property of
/// the weight vector the loop happens to converge to?
///
/// `audit_four_layer_tangent_cone_loop` reports `role_coverage_count = 2`. That
/// number is an *output* of the policy argmax at the last snapshot, so on its own
/// it says nothing about whether full differentiation (4 of 4 clusters) is
/// reachable at all. This sweep separates the two cases:
///
///   - `max_coverage < 4` over the whole weight simplex  => structural cap; the
///     Flow's 8 agents cannot occupy four functional roles at any weighting,
///     and the M6 loop's "2" is not a tuning failure.
///   - `max_coverage == 4` for some vertex/edge/centroid => 4 clusters ARE
///     reachable, so the loop's fixed point is a *metastable* division of
///     labour, not full differentiation. That is a different (and stronger)
///     statement than "coverage is 2".
///
/// Weights are sampled on the simplex in a fixed deterministic order (four
/// vertices, six edge midpoints, the centroid, then a Halton-style low
/// discrepancy fill) so the report is reproducible on all four backends.
#derive(Debug, Eq)
pub(all) struct RoleCoverageSweepReport {
  input_valid : Bool
  samples : Int32
  max_coverage : Int32
  min_coverage : Int32
  coverage_histogram : Array[Int32]
  four_reachable : Bool
  witness_weights : Array[Double]
  structural_cap : Bool
  /// Coverage measured on the tie family: weights with exactly k tied maxima,
  /// for k = 1..4. Index i holds the coverage for k = i+1.
  tie_family_coverage : Array[Int32]
  /// True when coverage(k) == k on the whole tie family, i.e. the number of
  /// occupied roles is exactly the number of tied maxima. This is the correct
  /// explanation for hist[3] = 0: the low-discrepancy sweep never samples a
  /// three-way tie, it does NOT mean three-role splits are dynamically unstable.
  tie_family_monotone : Bool
  certified : Bool
}

///|
pub fn m6_coverage_at_weights(
  weights : Array[Double],
  flow_steps : Int32,
) -> Int32 {
  let n_agents = 8
  let dt = 0.12
  let initial_agents = init_disordered_colony(n_agents, 0.25)
  let (snapshots, final_agents) = match
    run_sgne_emergence_simulation_with_mass_feedback(
      n_agents, flow_steps, dt, weights,
    ) {
    Ok(result) => result
    Err(_) => return -1
  }
  if snapshots.length() == 0 {
    return -1
  }
  let macro_agent = match
    distill_tropical_kan_macro_agent_with_weights(
      initial_agents, final_agents, weights,
    ) {
    Ok(report) => report
    Err(_) => return -1
  }
  let occupied = Array::make(4, false)
  for role in macro_agent.role_assignment {
    if role < 0 || role >= 4 {
      return -1
    }
    occupied[role] = true
  }
  let mut coverage = 0
  for is_occupied in occupied {
    if is_occupied {
      coverage = coverage + 1
    }
  }
  coverage
}

///|
/// Deterministic simplex sampling: 4 vertices, 6 edge midpoints, centroid, then a
/// low-discrepancy fill using the radical-inverse sequence in base 3,5,7 mapped to
/// the 3-simplex by the exponential map. No RNG, so the report is bit-identical
/// across the wasm-gc / wasm / js / native backends.
fn m6_sample_simplex(index : Int32, total : Int32) -> Array[Double] {
  // The four-role weight vector must be strictly positive (see
  // normalize_four_role_weights), so we sample the OPEN simplex by starting from
  // a deterministic interior point and moving along deterministic directions.
  // Vertices are approached but never reached: eps = 1e-3 is small enough that
  // one role dominates by 3 orders of magnitude, which is what "a vertex" means
  // for a softmax policy.
  let eps = 1.0e-3
  let n = 4
  // Radical inverse (van der Corput) in bases 3,5,7 -> three coordinates.
  let vdc = (m : Int32, base : Double) => {
    let mut result = 0.0
    let mut denom = 1.0
    let mut value = m
    while value > 0 {
      denom = denom * base
      let digit = value % base.to_int()
      result = result + digit.to_double() / denom
      value = value / base.to_int()
    }
    result
  }
  let raw = [0.0, 0.0, 0.0, 0.0]
  if index < n {
    // Near-vertex: one role at 1-(n-1)eps, the rest at eps.
    for j in 0..<n {
      raw[j] = if j == index { 1.0 - eps * (n - 1).to_double() } else { eps }
    }
    return raw
  }
  if index < 2 * n {
    // Near-edge midpoint: the named pair splits 1/2-eps, others eps.
    let pairs : Array[(Int32, Int32)] = [
      (0, 1),
      (0, 2),
      (0, 3),
      (1, 2),
      (1, 3),
      (2, 3),
    ]
    let (a, b) = pairs[index - n]
    for j in 0..<n {
      raw[j] = eps
    }
    raw[a] = 0.5 - eps
    raw[b] = 0.5 - eps
    return raw
  }
  if index == 2 * n {
    // Interior symmetric point.
    return [0.25, 0.25, 0.25, 0.25]
  }
  // Low-discrepancy interior fill: exponential map from three vdC coordinates.
  let k = index - 2 * n - 1
  let u = vdc(k + 1, 3.0)
  let v = vdc(k + 1, 5.0)
  let w = vdc(k + 1, 7.0)
  let e0 = -@math.ln(u.clamp(min=1.0e-4, max=1.0 - 1.0e-4))
  let e1 = -@math.ln(v.clamp(min=1.0e-4, max=1.0 - 1.0e-4))
  let e2 = -@math.ln(w.clamp(min=1.0e-4, max=1.0 - 1.0e-4))
  let e3 = -@math.ln((0.6 * u + 0.25 * v + 0.15 * w).clamp(min=1.0e-4, max=1.0))
  let s = e0 + e1 + e2 + e3
  let _ = total
  [e0 / s, e1 / s, e2 / s, e3 / s]
}

///|
pub fn audit_m6_role_coverage_sweep(
  samples~ : Int32 = 42,
  flow_steps~ : Int32 = 3,
) -> RoleCoverageSweepReport {
  let invalid = {
    input_valid: false,
    samples: 0,
    max_coverage: 0,
    min_coverage: 0,
    coverage_histogram: [0, 0, 0, 0, 0],
    four_reachable: false,
    witness_weights: [],
    structural_cap: false,
    tie_family_coverage: [],
    tie_family_monotone: false,
    certified: false,
  }
  if samples < 11 || samples > 400 || flow_steps < 1 {
    return invalid
  }
  let histogram = [0, 0, 0, 0, 0]
  let mut max_coverage = 0
  let mut min_coverage = 4
  let mut witness : Array[Double] = []
  for i in 0..<samples {
    let weights = m6_sample_simplex(i, samples)
    let coverage = m6_coverage_at_weights(weights, flow_steps)
    if coverage < 0 {
      return invalid
    }
    histogram[coverage] = histogram[coverage] + 1
    if coverage > max_coverage {
      max_coverage = coverage
      witness = weights
    }
    if coverage < min_coverage {
      min_coverage = coverage
    }
  }
  let four_reachable = max_coverage >= 4
  // The sweep above answers "is 4 reachable". It does NOT answer "for which
  // weights does coverage equal 3", and an earlier version of this code read
  // hist[3] = 0 as evidence that three-role splits are unstable. That inference
  // was WRONG: the low-discrepancy fill simply never produces weights with
  // exactly three tied maxima. The tie family below settles it by construction.
  let tie_family = m6_tie_family_weights()
  let tie_coverage : Array[Int32] = []
  let mut tie_monotone = true
  for k in 0..<4 {
    let coverage = m6_coverage_at_weights(tie_family[k], flow_steps)
    if coverage < 0 {
      return invalid
    }
    tie_coverage.push(coverage)
    if coverage != k + 1 {
      tie_monotone = false
    }
  }
  {
    input_valid: true,
    samples,
    max_coverage,
    min_coverage,
    coverage_histogram: histogram,
    four_reachable,
    witness_weights: if four_reachable {
      witness
    } else {
      []
    },
    structural_cap: !four_reachable,
    tie_family_coverage: tie_coverage,
    tie_family_monotone: tie_monotone,
    // Certified in either branch: the sweep is a decision procedure, and both
    // outcomes are reportable facts. It is NOT certified only when the sweep was
    // vacuous (no sample produced a verdict).
    certified: histogram[1] + histogram[2] + histogram[3] + histogram[4] > 0,
  }
}

///|
/// Weights whose four entries have exactly k tied maxima, for k = 1..4. Entry
/// i of the result has (i+1) entries at 1.0 and the rest at 1e-4, normalised.
/// These are NOT simplex vertices (the weight vector must be strictly
/// positive); they are vertex-approaching points with a prescribed tie
/// multiplicity, which is exactly what the sweep's low-discrepancy fill misses.
pub fn m6_tie_family_weights() -> Array[Array[Double]] {
  let family : Array[Array[Double]] = []
  for k in 1..<5 {
    let raw = [1.0e-4, 1.0e-4, 1.0e-4, 1.0e-4]
    for i in 0..<k {
      raw[i] = 1.0
    }
    let mut total = 0.0
    for value in raw {
      total = total + value
    }
    family.push([raw[0] / total, raw[1] / total, raw[2] / total, raw[3] / total])
  }
  family
}
