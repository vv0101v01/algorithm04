///|
test "M9: the emergence metric separates structure from fake random search" {
  let r = @super_emergence.audit_m9_emergence_falsifiability()
  assert_true(r.input_valid)
  assert_eq(r.ensemble, 64)
  // The null model spreads the agents apart (variance grows), the coupled flow
  // collapses them (synchronisation order parameter -> 1).
  assert_true(r.null_mean < 0.0)
  assert_true(r.alt_mean > 0.8)
  assert_true(r.separates)
  // Both error rates are MEASURED, not assumed.
  assert_true(r.false_positive_rate <= 0.1)
  assert_true(r.power >= 0.9)
  assert_true(r.has_discriminating_power)
  // The claim is explicitly limited: this is evidence of discriminating power on
  // this model, not a proof that emergence exists anywhere.
  assert_true(r.caveat.contains("does not prove"))
}

///|
test "M9: order parameter behaves correctly at both extremes" {
  let flat = [1.0, 1.0, 1.0, 1.0]
  let spread = [0.0, 1.0, 2.0, 3.0]
  // Already synchronised and stays synchronised => r = 0 (no change in variance).
  assert_eq(@super_emergence.m9_sync_order_parameter(flat, flat), 0.0)
  // Collapsed onto a point => r = 1 (perfect synchronisation).
  let collapsed = [1.0, 1.0, 1.0, 1.0]
  assert_eq(@super_emergence.m9_sync_order_parameter(spread, collapsed), 1.0)
  // Spread out beyond the initial variance => r < 0.
  let wider = [0.0, 2.0, 4.0, 6.0]
  assert_true(@super_emergence.m9_sync_order_parameter(spread, wider) < 0.0)
}

///|
test "M9: LCG is deterministic across calls and seeds differ" {
  let a = @super_emergence.Pcg32::seeded(1L)
  let (u1, a2) = a.next_unit()
  let (u2, _) = a2.next_unit()
  assert_true(u1 >= 0.0 && u1 < 1.0)
  assert_true(u2 >= 0.0 && u2 < 1.0)
  assert_true(u1 != u2)
  // Same seed => same sequence (this is what makes the ensemble reproducible on
  // every backend).
  let b = @super_emergence.Pcg32::seeded(1L)
  let (v1, _) = b.next_unit()
  assert_eq(u1, v1)
}

///|
test "M10: the census is EXHAUSTIVE over all 256 configurations of B_4^4" {
  let r = @super_emergence.verify_m10_subcolony_consensus()
  assert_eq(r.n_subcolonies, 4)
  assert_true(r.exhaustive)
  // 4^4 = 256, enumerated exactly — no sampling, no hand-picked fixtures.
  assert_eq(r.naive_join.configurations, 256)
  assert_eq(r.bilattice.configurations, 256)
  assert_eq(r.weighted.configurations, 256)
}

///|
test "M10: lattice join explodes, quarantine is worse, scoping is not enough" {
  let r = @super_emergence.verify_m10_subcolony_consensus()
  // Every rule that answers with the raw join returns Bv on the many
  // configurations where the coordinates disagree or contradict.
  assert_true(r.naive_join.exploded > 0)
  assert_true(!r.naive_join.passes)
  // Quarantine-first is strictly worse: epistemic_quarantine_map sends Fv, Tv and
  // Bv all to Bv, so it manufactures contradictions out of agreement.
  assert_true(r.quarantine_first.exploded >= r.naive_join.exploded)
  assert_true(!r.quarantine_first.passes)
  // Scoping the explicit Bv coordinates still leaves join(Tv, Fv) = Bv.
  assert_true(r.scoped.exploded > 0)
  assert_true(!r.scoped.passes)
}

///|
test "M10: bilattice degradation never explodes and never loses the factor" {
  let r = @super_emergence.verify_m10_subcolony_consensus()
  assert_eq(r.bilattice.exploded, 0)
  assert_eq(r.bilattice.vacuous, 0)
  assert_eq(r.bilattice.lost_factor, 0)
  assert_true(r.bilattice.passes)
  // It must still CARRY the contradiction into the factor on some configurations;
  // a rule that reported a value while dropping the contradiction would pass the
  // explosion test trivially and be useless.
  assert_true(r.bilattice.carrying > 0)
  assert_true(r.non_explosive_consensus_exists)
  assert_eq(r.recommended_rule, "Bilattice")
}

///|
test "M10: Bv degrades into BOTH actionable branches, not into a veto" {
  // A single contradiction among agreeing truth: Tv, Tv, Tv, Bv.
  let colony : Array[@super_emergence.SubColonyVerdict] = [
    { name: "a", value: @super_emergence.FourVal::Tv, confidence: 1.0, },
    { name: "b", value: @super_emergence.FourVal::Tv, confidence: 1.0, },
    { name: "c", value: @super_emergence.FourVal::Tv, confidence: 1.0, },
    { name: "d", value: @super_emergence.FourVal::Bv, confidence: 1.0, },
  ]
  let factor = @super_emergence.colony_factor(colony)
  // The joint information is Bv — the colony KNOWS there is a contradiction.
  assert_eq(factor.information, @super_emergence.FourVal::Bv)
  assert_true(factor.carrying_contradiction)
  // But the available set keeps BOTH branches, so the colony can still finish.
  assert_eq(factor.available.length(), 2)
  // And it proceeds on the better-supported branch.
  let consensus = @super_emergence.consensus_bilattice(colony)
  assert_eq(consensus.agent_value, @super_emergence.FourVal::Tv)
  // The contradiction is still IN the factor after the decision.
  assert_eq(consensus.factor.information, @super_emergence.FourVal::Bv)
  assert_eq(consensus.contradicting, 1)
}

///|
test "M10: agreement with no contradiction needs no vote" {
  let colony : Array[@super_emergence.SubColonyVerdict] = [
    { name: "a", value: @super_emergence.FourVal::Fv, confidence: 1.0, },
    { name: "b", value: @super_emergence.FourVal::Fv, confidence: 1.0, },
  ]
  let result = @super_emergence.consensus_bilattice(colony)
  assert_eq(result.agent_value, @super_emergence.FourVal::Fv)
  assert_eq(result.factor.information, @super_emergence.FourVal::Fv)
  assert_eq(result.factor.available.length(), 1)
  assert_true(!result.factor.carrying_contradiction)
}

///|
test "M10: silence stays silent rather than becoming a decision" {
  // All Nv: the colony has no information, and that must not be dressed up as
  // either an answer (explosion) or a vote.
  let colony : Array[@super_emergence.SubColonyVerdict] = [
    { name: "a", value: @super_emergence.FourVal::Nv, confidence: 1.0, },
    { name: "b", value: @super_emergence.FourVal::Nv, confidence: 1.0, },
  ]
  let result = @super_emergence.consensus_bilattice(colony)
  assert_eq(result.agent_value, @super_emergence.FourVal::Nv)
  assert_eq(result.factor.available, [@super_emergence.FourVal::Nv])
  assert_true(!result.factor.carrying_contradiction)
}

///|
test "M10: true_available is exactly the <=_t projection" {
  assert_eq(@super_emergence.truth_available(@super_emergence.FourVal::Tv), [
    @super_emergence.FourVal::Tv,
  ])
  assert_eq(@super_emergence.truth_available(@super_emergence.FourVal::Fv), [
    @super_emergence.FourVal::Fv,
  ])
  assert_eq(@super_emergence.truth_available(@super_emergence.FourVal::Nv), [
    @super_emergence.FourVal::Nv,
  ])
  // The degradation: Bv is not a veto, it is the pair of branches.
  assert_eq(@super_emergence.truth_available(@super_emergence.FourVal::Bv), [
    @super_emergence.FourVal::Tv,
    @super_emergence.FourVal::Fv,
  ])
}

///|
test "M10: carried vs manufactured contradictions are distinguished" {
  let r = @super_emergence.verify_m10_subcolony_consensus()
  // Both mechanisms exist in B_4^4 and the census separates them.
  assert_true(r.bilattice.carrying > 0)
  assert_true(r.bilattice.manufactured > 0)
  // They are genuinely different states of the factor.
  let carried : Array[@super_emergence.SubColonyVerdict] = [
    { name: "a", value: @super_emergence.FourVal::Tv, confidence: 1.0, },
    { name: "b", value: @super_emergence.FourVal::Bv, confidence: 1.0, },
  ]
  let manufactured : Array[@super_emergence.SubColonyVerdict] = [
    { name: "a", value: @super_emergence.FourVal::Tv, confidence: 1.0, },
    { name: "b", value: @super_emergence.FourVal::Fv, confidence: 1.0, },
  ]
  let f_carried = @super_emergence.colony_factor(carried)
  let f_manufactured = @super_emergence.colony_factor(manufactured)
  assert_eq(f_carried.information, @super_emergence.FourVal::Bv)
  assert_eq(f_manufactured.information, @super_emergence.FourVal::Bv)
  assert_true(f_carried.carrying_contradiction)
  assert_true(!f_carried.manufactured_contradiction)
  assert_true(f_manufactured.manufactured_contradiction)
  assert_true(!f_manufactured.carrying_contradiction)
  // BOTH still degrade into two actionable branches, so neither is a veto.
  assert_eq(f_carried.available.length(), 2)
  assert_eq(f_manufactured.available.length(), 2)
}

///|
test "M6: the four layers are four sub-colonies, not one scalar" {
  let report = @super_emergence.audit_four_layer_closed_loop()
  assert_true(report.input_valid)
  // The factor carries one coordinate per layer.
  assert_eq(report.colony_factor.coordinates.length(), 4)
  // In the default run Flow and Trop-Kan disagree, so the joint information is Bv
  // — and the loop still finishes with a certified fixed point. That is the
  // property under test: a contradiction does not stop the work.
  assert_true(report.empirical_fixed_point_certified)
  assert_true(report.fixed_point_residual <= 1.0e-3)
  // The old boolean is a derived view; it must agree with the factor's
  // contradiction inventory rather than being a separate independent flag.
  let factor_has_contradiction = report.colony_factor.carrying_contradiction ||
    report.colony_factor.local_contradictions > 0
  assert_eq(report.microlocal_quarantined, factor_has_contradiction)
}
