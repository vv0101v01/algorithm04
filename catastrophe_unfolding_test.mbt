///|
test "M4 selects a versal A3 or D4 family by critical-branch demand" {
  let cusp = @super_emergence.learn_catastrophe_for_role_branches(3, 0.05)
  assert_true(cusp.input_valid && cusp.certified)
  assert_eq(cusp.selected_class, @super_emergence.A3Cusp)
  assert_eq(cusp.selected_label, "A_3")
  assert_eq(cusp.milnor_number, 3)
  assert_eq(cusp.unfolding_codimension, 3)
  assert_eq(cusp.parameters.length(), 3)
  assert_eq(cusp.unfolded_critical_points, 3)
  assert_eq(cusp.stable_minima, 2)
  assert_true(cusp.versal && cusp.target_matched)
  assert_true(cusp.reconstruction_residual < 1.0e-12)
  assert_true(cusp.stationary_residual < 1.0e-12)

  let umbilic = @super_emergence.learn_catastrophe_for_role_branches(4, 0.05)
  assert_true(umbilic.input_valid && umbilic.certified)
  assert_eq(umbilic.selected_class, @super_emergence.D4Umbilic)
  assert_eq(umbilic.selected_label, "D_4 (Umbilic)")
  assert_eq(umbilic.milnor_number, 4)
  assert_eq(umbilic.unfolding_codimension, 4)
  assert_eq(umbilic.parameters.length(), 4)
  assert_eq(umbilic.unfolded_critical_points, 4)
  assert_eq(umbilic.stable_minima, 1)
  assert_true(umbilic.versal && umbilic.target_matched)
  assert_true(umbilic.reconstruction_residual < 1.0e-12)
  assert_true(umbilic.stationary_residual < 1.0e-12)

  let basis = @super_emergence.JetBasis::new(2, 5)
  let d4_germ = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::from_terms(basis, [([3, 0], 1.0), ([1, 2], -3.0)]),
  ])
  let d4_class = @super_emergence.classify_contact_equiv_class(d4_germ)
  assert_eq(d4_class.corank, 2)
  assert_eq(d4_class.label, "D_4 (Umbilic)")

  let unsupported = @super_emergence.learn_catastrophe_for_role_branches(
    5, 0.05,
  )
  assert_true(!unsupported.input_valid && !unsupported.certified)
  let invalid_amplitude = @super_emergence.learn_catastrophe_for_role_branches(
    4, 0.0,
  )
  assert_true(!invalid_amplitude.input_valid)
  let non_finite_amplitude = @super_emergence.learn_catastrophe_for_role_branches(
    4,
    1.0 / 0.0,
  )
  assert_true(!non_finite_amplitude.input_valid)

  // At the smallest positive Double, amplitude / 2 underflows to zero, so the
  // three A3 critical branches collapse numerically despite a positive input.
  let unresolvable_amplitude = @super_emergence.learn_catastrophe_for_role_branches(
    3, 5.0e-324,
  )
  assert_true(!unresolvable_amplitude.input_valid)
}

///|
test "M4 checked unfolding fibers reject malformed controls" {
  let basis = @super_emergence.JetBasis::new(1, 5)
  let germ = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::monomial(basis, [3], 1.0),
  ])
  let unfolding = germ.universal_k_unfolding()
  assert_true(
    unfolding.fiber_at_checked(Array::make(unfolding.codim, 0.0)) is Ok(_),
  )
  assert_true(unfolding.fiber_at_checked([]) is Err(_))
  assert_true(
    unfolding.fiber_at_checked(
      Array::makei(unfolding.codim, i => if i == 0 { 1.0 / 0.0 } else { 0.0 }),
    )
    is Err(_),
  )
}
