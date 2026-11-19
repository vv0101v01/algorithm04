///|
test "M6 applies normalized weights to Flow mass and Trop-Kan" {
  let (_, neutral_final) = @super_emergence.run_sgne_emergence_simulation(
    n_agents=8,
    n_steps=1,
    dt=0.12,
  )
  let initial_agents = @super_emergence.init_disordered_colony(8, 0.25)
  let neutral_weighted = @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
    8,
    1,
    0.12,
    [1.0, 1.0, 1.0, 1.0],
  )
  let neutral_feedback_final = match neutral_weighted {
    Ok((_, agents)) => agents
    Err(_) => []
  }
  assert_eq(neutral_feedback_final.length(), neutral_final.length())
  assert_true(
    (neutral_feedback_final[0].mass.mat.frob_norm() -
    neutral_final[0].mass.mat.frob_norm()).abs() <
    1.0e-12,
  )
  let biased = @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
    8,
    1,
    0.12,
    [0.7, 0.1, 0.1, 0.1],
  )
  let biased_final = match biased {
    Ok((_, agents)) => agents
    Err(_) => []
  }
  assert_eq(biased_final.length(), neutral_final.length())
  assert_true(
    (biased_final[0].mass.mat.frob_norm() -
    neutral_final[0].mass.mat.frob_norm()).abs() >
    1.0e-8,
  )
  assert_true(
    @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
      8,
      1,
      0.12,
      [0.0, 0.0, 0.0, 0.0],
    )
    is Err(_),
  )
  assert_true(
    @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
      8,
      0,
      0.12,
      [1.0e308, 1.0e308, 1.0e308, 1.0e308],
    )
    is Ok(_),
  )
  assert_true(
    @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
      8,
      0,
      0.12,
      [1.0e308, 1.0e-308, 1.0e-308, 1.0e-308],
    )
    is Err(_),
  )
  assert_true(
    @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
      8,
      0,
      0.12,
      [1.0, 1.0, 1.0],
    )
    is Err(_),
  )
  assert_true(
    @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
      8,
      0,
      0.12,
      [1.0, 1.0, 1.0, 1.0 / 0.0],
    )
    is Err(_),
  )
  let weighted = @super_emergence.distill_tropical_kan_macro_agent_with_weights(
    initial_agents,
    biased_final,
    [0.7, 0.1, 0.1, 0.1],
  )
  assert_true(weighted is Ok(_))
  let extreme_final : Array[@super_emergence.ProtoAgent] = biased_final.map(agent => {
    let modified : @super_emergence.ProtoAgent = {
      id: agent.id,
      pos_index: agent.pos_index,
      belief: agent.belief,
      ferm_spinor: agent.ferm_spinor,
      policy_eta: [-1000.0, 0.0, 0.0],
      mass: agent.mass,
      rule: agent.rule,
      logic_blade: agent.logic_blade,
    }
    modified
  })
  let stable_weighted = @super_emergence.distill_tropical_kan_macro_agent_with_weights(
    initial_agents,
    extreme_final,
    [1.0, 5.0e-324, 5.0e-324, 5.0e-324],
  )
  assert_true(stable_weighted is Ok(_))
  assert_true(
    @super_emergence.distill_tropical_kan_macro_agent_with_weights(
      initial_agents,
      biased_final,
      [0.0, 0.0, 0.0, 0.0],
    )
    is Err(_),
  )
  assert_true(
    @super_emergence.distill_tropical_kan_macro_agent_with_weights(
      initial_agents,
      biased_final,
      [1.0e308, 1.0e308, 1.0e308, 1.0e308],
    )
    is Ok(_),
  )
}

///|
test "M6 closes Flow-TropKan-GermMicro-SynMem feedback at a stable fixed point" {
  let report = @super_emergence.audit_four_layer_closed_loop(
    flow_steps=3,
    max_iterations=32,
    relaxation=0.35,
    tolerance=0.001,
  )
  assert_true(report.input_valid)
  assert_true(report.converged && report.empirical_fixed_point_certified)
  assert_true(report.iterations >= 2 && report.iterations <= 32)
  assert_true(report.fixed_point_residual <= 0.001)
  assert_true(report.empirical_contraction_factor < 1.0)
  assert_true(report.weight_normalization_defect < 1.0e-12)
  assert_eq(report.flow_mass_weights.length(), 4)
  assert_eq(report.trop_kan_weights.length(), 4)
  assert_eq(report.role_absorption_times.length(), 4)
  assert_true(
    report.role_coverage_count >= 1 && report.role_coverage_count <= 4,
  )
  assert_true(report.non_explosion_preserved)
  for weight in report.flow_mass_weights {
    assert_true(weight > 0.0)
  }
  for weight in report.trop_kan_weights {
    assert_true(weight > 0.0)
  }

  let default_report = @super_emergence.audit_four_layer_closed_loop()
  assert_true(default_report.input_valid)
  assert_true(
    default_report.converged && default_report.empirical_fixed_point_certified,
  )

  let invalid = @super_emergence.audit_four_layer_closed_loop(max_iterations=1)
  assert_true(!invalid.input_valid && !invalid.empirical_fixed_point_certified)

  // On budget exhaustion the report must return the weights used to produce its
  // final observables, not an additional unevaluated blended iterate.
  let capped = @super_emergence.audit_four_layer_closed_loop(
    flow_steps=3,
    max_iterations=2,
    tolerance=1.0e-15,
  )
  assert_true(capped.input_valid && !capped.converged)
  let replay = @super_emergence.run_sgne_emergence_simulation_with_mass_feedback(
    8,
    3,
    0.12,
    capped.flow_mass_weights,
  )
  match replay {
    Ok((snapshots, _)) =>
      assert_true(
        (snapshots[snapshots.length() - 1].free_energy - capped.flow_free_energy).abs() <
        1.0e-12,
      )
    Err(_) => assert_true(false)
  }
}
