///|
test "Euler-Jacobi residue sums validate root support and finite arithmetic" {
  let roots = [
    @super_emergence.Complex::new(-1.2, 0.0),
    @super_emergence.Complex::new(-0.3, 0.4),
    @super_emergence.Complex::new(0.5, -0.3),
    @super_emergence.Complex::new(1.1, 0.2),
  ]
  match @super_emergence.euler_jacobi_residue_sum(roots, 0) {
    Ok(value) => assert_true(value.abs() < 1.0e-12)
    Err(_) => assert_true(false)
  }
  match @super_emergence.euler_jacobi_residue_sum(roots, 2) {
    Ok(value) => assert_true(value.abs() < 1.0e-12)
    Err(_) => assert_true(false)
  }
  match @super_emergence.euler_jacobi_residue_sum(roots, 3) {
    Ok(value) =>
      assert_true((value - @super_emergence.Complex::one()).abs() < 1.0e-12)
    Err(_) => assert_true(false)
  }

  assert_true(@super_emergence.euler_jacobi_residue_sum([], 0) is Err(_))
  assert_true(@super_emergence.euler_jacobi_residue_sum(roots, -1) is Err(_))
  assert_true(@super_emergence.euler_jacobi_residue_sum(roots, 4) is Err(_))
  assert_true(
    @super_emergence.euler_jacobi_residue_sum([roots[0], roots[0]], 0) is Err(_),
  )
  assert_true(
    @super_emergence.euler_jacobi_residue_sum(
      [@super_emergence.Complex::new(1.0 / 0.0, 0.0)],
      0,
    )
    is Err(_),
  )
  // Distinct roots can still underflow the derivative product; that must be reported
  // instead of letting Complex division's zero fallback return a plausible identity.
  assert_true(
    @super_emergence.euler_jacobi_residue_sum(
      [
        @super_emergence.Complex::zero(),
        @super_emergence.Complex::new(1.0e-200, 0.0),
        @super_emergence.Complex::new(2.0e-200, 0.0),
      ],
      0,
    )
    is Err(_),
  )
}
