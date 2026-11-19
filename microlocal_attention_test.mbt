///|
test "M5 quarantines only same-point antipodal wavefront collisions" {
  let plus = @super_emergence.HyperfunctionGerm::cauchy_plus(0.0).sp()
  let minus = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0).sp()
  let collision = @super_emergence.microlocal_attention_event(
    plus,
    minus,
    @super_emergence.Tv,
  )
  assert_true(collision.input_valid && collision.same_base_point)
  assert_true(collision.antipodal_collision && collision.quarantined)
  assert_eq(collision.value_after, @super_emergence.Bv)
  assert_true(collision.non_explosion_preserved)

  let cooriented = @super_emergence.microlocal_attention_event(
    plus,
    plus,
    @super_emergence.Fv,
  )
  assert_true(cooriented.input_valid && !cooriented.quarantined)
  assert_eq(cooriented.value_after, @super_emergence.Fv)

  let other_point = @super_emergence.HyperfunctionGerm::cauchy_minus(1.0e-4).sp()
  let separated = @super_emergence.microlocal_attention_event(
    plus,
    other_point,
    @super_emergence.Tv,
  )
  assert_true(separated.input_valid && !separated.same_base_point)
  assert_true(!separated.antipodal_collision && !separated.quarantined)

  let invalid_tolerance = @super_emergence.microlocal_attention_event(
    plus,
    minus,
    @super_emergence.Tv,
    base_tol=-1.0,
  )
  assert_true(!invalid_tolerance.input_valid)
}

///|
test "Microfunction products reject different stalks and unsupported logarithms" {
  let plus0 = @super_emergence.HyperfunctionGerm::cauchy_plus(0.0).sp()
  let plus1 = @super_emergence.HyperfunctionGerm::cauchy_plus(1.0).sp()
  let minus0 = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0).sp()
  assert_true(@super_emergence.MicrofunctionGerm::dist(plus0, plus1) > 0.9)
  assert_true(@super_emergence.micro_product(plus0, plus1) is Err(_))
  assert_true(@super_emergence.micro_product(plus0, minus0) is Err(_))

  let zero : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(@super_emergence.micro_product(zero, zero) is Ok(_))

  let log_germ = @super_emergence.HyperfunctionGerm::heaviside(0.0).sp()
  assert_true(@super_emergence.micro_product(log_germ, log_germ) is Err(_))
}

///|
test "M5 rejects malformed germs and validates the standalone collision predicate" {
  let plus = @super_emergence.HyperfunctionGerm::cauchy_plus(0.0).sp()
  let minus = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0).sp()
  let separated = @super_emergence.HyperfunctionGerm::cauchy_minus(1.0e-4).sp()
  assert_true(plus.antipodal_collision(minus))
  assert_true(!plus.antipodal_collision(separated))
  assert_true(!plus.antipodal_collision(minus, base_tol=-1.0))
  assert_true(!plus.antipodal_collision(minus, spectrum_tol=1.0 / 0.0))

  let invalid_base : @super_emergence.MicrofunctionGerm = {
    x0: 1.0 / 0.0,
    plus_poles: [],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  let invalid_pole : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [@super_emergence.Complex::new(1.0 / 0.0, 0.0)],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  let invalid_minus_pole : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [@super_emergence.Complex::new(0.0, 1.0 / 0.0)],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(!invalid_base.is_well_formed())
  assert_true(!invalid_pole.is_well_formed())
  assert_true(!invalid_minus_pole.is_well_formed())
  assert_true(!invalid_base.antipodal_collision(minus))
  assert_true(!invalid_pole.antipodal_collision(minus))
  assert_true(@super_emergence.micro_product(invalid_base, plus) is Err(_))
  let invalid_attention = @super_emergence.microlocal_attention_event(
    invalid_minus_pole,
    minus,
    @super_emergence.Tv,
  )
  assert_true(!invalid_attention.input_valid && !invalid_attention.quarantined)

  // Public-field fixtures may contain noncanonical all-zero pole arrays. They must
  // not create a phantom wavefront or an antipodal product collision.
  let padded_zero : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [@super_emergence.Complex::zero()],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [@super_emergence.Complex::zero()],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(padded_zero.singular_spectrum() == (false, false))
  assert_true(padded_zero.singular_spectrum(tol=-1.0) == (false, false))
  assert_true(!padded_zero.antipodal_collision(minus))
  assert_true(@super_emergence.micro_product(padded_zero, minus) is Ok(_))

  let tiny_pole : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [@super_emergence.Complex::new(1.0e-200, 0.0)],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(tiny_pole.singular_spectrum() == (true, false))
}

///|
test "Microlocal integration rejects unsupported existing logarithms" {
  let delta = @super_emergence.HyperfunctionGerm::dirac_delta(0.0).sp()
  let heaviside = @super_emergence.HyperfunctionGerm::heaviside(0.0).sp()
  match delta.integrate_microlocal() {
    Ok(primitive) =>
      assert_true(
        @super_emergence.MicrofunctionGerm::dist(primitive, heaviside) < 1.0e-12,
      )
    Err(_) => assert_true(false)
  }
  // Integrating a logarithmic germ requires z*log(z), which is not represented here.
  assert_true(heaviside.integrate_microlocal() is Err(_))
  let tiny_log : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [],
    plus_log: @super_emergence.Complex::new(1.0e-200, 0.0),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(tiny_log.integrate_microlocal() is Err(_))
  assert_true(@super_emergence.micro_product(tiny_log, delta) is Err(_))
  assert_true(tiny_log.singular_spectrum(tol=0.0) == (true, false))
  assert_true(heaviside.singular_spectrum() == (true, true))

  let third_order = @super_emergence.HyperfunctionGerm::cauchy_plus(
    0.0,
    order=3,
  ).sp()
  let expected_primitive : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [
      @super_emergence.Complex::zero(),
      @super_emergence.Complex::new(-0.5, 0.0),
    ],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  match third_order.integrate_microlocal() {
    Ok(primitive) =>
      assert_true(
        @super_emergence.MicrofunctionGerm::dist(primitive, expected_primitive) <
        1.0e-12,
      )
    Err(_) => assert_true(false)
  }

  let malformed : @super_emergence.MicrofunctionGerm = {
    x0: 0.0,
    plus_poles: [@super_emergence.Complex::new(1.0 / 0.0, 0.0)],
    plus_log: @super_emergence.Complex::zero(),
    minus_poles: [],
    minus_log: @super_emergence.Complex::zero(),
  }
  assert_true(malformed.integrate_microlocal() is Err(_))
}
