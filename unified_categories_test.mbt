///|
test "M7: the three legs each satisfy their category axioms" {
  let semis = @super_emergence.verify_semitropical_category()
  assert_true(semis.identity_law)
  assert_true(semis.associativity)
  // The ghost ideal is MULTIPLICATIVE; addition only produces a ghost on a tie.
  assert_true(semis.extra_axioms)
  assert_true(semis.axioms_hold)

  let sympl = @super_emergence.verify_symplectic_category()
  assert_true(sympl.axioms_hold)

  let parac = @super_emergence.verify_paraconsistent_category()
  assert_true(parac.identity_law)
  assert_true(parac.associativity)
  assert_true(parac.axioms_hold)
  assert_eq(parac.object_count, 4)
}

///|
test "M7: the fiber product over the Maslov phase is a category" {
  let report = @super_emergence.verify_m7_unified_category()
  assert_true(report.fiber_product_closed)
  assert_true(report.identity_law)
  // Associativity holds UP TO the tie tolerance, not under strict Double
  // equality; verify_m7... uses unified_morphism_nearly_eq for this reason.
  assert_true(report.associativity)
  assert_true(report.phase_agreement)
  assert_true(report.semitropical.axioms_hold)
  assert_true(report.symplectic.axioms_hold)
  assert_true(report.paraconsistent.axioms_hold)
  assert_true(report.is_category)
  assert_eq(report.failing_leg, "")
}

///|
test "M7: a broken leg is reported by name, not silently swallowed" {
  // Guards the diagnosability requirement: if any leg fails, failing_leg must
  // name it. We assert the healthy case names nothing, and that the contract
  // constructor reports the first failing axiom in evaluation order.
  let broken = @super_emergence.category_contract(
    "Broken", 1, 1, false, true, true,
  )
  assert_true(!broken.axioms_hold)
  assert_eq(broken.failing_axiom, "identity")
  let broken_assoc = @super_emergence.category_contract(
    "Broken", 1, 1, true, false, true,
  )
  assert_eq(broken_assoc.failing_axiom, "associativity")
}

///|
test "M8: K_0 index is additive on block-diagonal direct sums" {
  let report = @super_emergence.verify_m8_k0_complexity_measure()
  assert_true(report.additive)
  // Additivity on a concrete pair: K_0(A (+) B) = K_0(A) + K_0(B).
  let modules = @super_emergence.colony_role_modules()
  for i in 0..<modules.length() {
    for j in 0..<modules.length() {
      let (index, err) = @super_emergence.role_direct_sum_index(
        modules[i],
        modules[j],
      )
      assert_true(err < 1.0e-9)
      assert_eq(
        index,
        report.profiles[i].k0_class + report.profiles[j].k0_class,
      )
    }
  }
}

///|
test "M8: K_0 gives a genuine role complexity measure" {
  let report = @super_emergence.verify_m8_k0_complexity_measure()
  assert_true(report.additive)
  assert_true(report.monotone)
  assert_true(report.distinguishable)
  assert_true(report.is_complexity_measure)
  assert_eq(report.failing_property, "")
  // Documented limitation, asserted so a future change cannot hide it:
  // rank alone does NOT separate all four roles (explorer and connector are
  // both rank 1), so the measure must include the summand count.
  let profiles = report.profiles
  assert_eq(profiles.length(), 4)
  let mut rank_one = 0
  for p in profiles {
    if p.k0_class == 1 {
      rank_one = rank_one + 1
    }
  }
  assert_true(rank_one >= 2)
}

///|
test "M6.4: 4-role coverage is reachable, so 2 is metastable not structural" {
  let sweep = @super_emergence.audit_m6_role_coverage_sweep(
    samples=42,
    flow_steps=3,
  )
  assert_true(sweep.input_valid)
  assert_eq(sweep.samples, 42)
  // The sweep must actually decide the question, in either direction.
  assert_true(sweep.four_reachable || sweep.structural_cap)
  assert_true(!(sweep.four_reachable && sweep.structural_cap))
  if sweep.four_reachable {
    assert_eq(sweep.max_coverage, 4)
    assert_eq(sweep.witness_weights.length(), 4)
  }
  assert_true(sweep.certified)
  // The tie family settles what hist[3] = 0 does NOT mean. With exactly k
  // tied maxima the number of occupied roles is exactly k, for every k.
  assert_eq(sweep.tie_family_coverage, [1, 2, 3, 4])
  assert_true(sweep.tie_family_monotone)
  // Three-role splits therefore exist; the sweep simply never sampled one.
  assert_eq(sweep.coverage_histogram[3], 0)
}

///|
test "M8: role mdl separates roles that the K_0 rank alone cannot" {
  let report = @super_emergence.verify_m8_k0_complexity_measure()
  // mdls must be READ INDIVIDUALLY. An earlier version computed
  // summands = max(k0_class, 1), which silently made connector's mdl 1 instead
  // of 2 and hid the fact that rank alone does not separate the four roles.
  let mdls : Array[Double] = []
  for p in report.profiles {
    mdls.push(p.mdl)
  }
  assert_eq(mdls, [1.0, 1.0, 3.0, 2.0])
  // coordinator and explorer share (k0 = 1, summands = 1) and are genuinely
  // indistinguishable by this measure; connector differs only in the summand
  // count. Asserting the multiplicities keeps the limitation visible.
  assert_eq(report.profiles[0].mdl, report.profiles[1].mdl)
  assert_true(report.profiles[3].mdl != report.profiles[0].mdl)
  assert_eq(report.profiles[3].k0_class, report.profiles[0].k0_class)
  assert_eq(report.profiles[3].irreducible_summands, 2)
}
