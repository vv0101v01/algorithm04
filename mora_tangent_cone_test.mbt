///|
test "Mora NF terminates on the classic non-well-ordered example x - x^2" {
  // NegDegRevLex makes x the initial term of x - x^2, so <x - x^2> is not a
  // standard basis: plain division by x - x^2 diverges (x -> x^2 -> x^3 ...).
  // Mora's ecart insertion must make the reduction terminate with NF = 0.
  let x = @super_emergence.mora_var_poly(1, 6, 0)
  let g = x.sub_poly(@super_emergence.mora_monomial_poly(1, 6, [2], 1.0))
  let nf = @super_emergence.mora_normal_form(x, [g])
  assert_true(nf.input_valid)
  assert_true(nf.remainder_is_zero)
  assert_true(nf.inserted_reducers > 0)

  // A unit generator reduces everything: <1 + x> = O_1.
  let unit = @super_emergence.mora_const_poly(1, 6, 1.0).add_poly(x)
  let nf2 = @super_emergence.mora_normal_form(
    @super_emergence.mora_monomial_poly(1, 6, [3], 2.0),
    [unit],
  )
  assert_true(nf2.input_valid && nf2.remainder_is_zero)
}

///|
test "Mora monomial ordering laws: total, antisymmetric, translation-invariant" {
  let gens : Array[Array[Int32]] = []
  for a in 0..<=3 {
    for b in 0..<=3 {
      gens.push([a, b])
    }
  }
  for
    ordering in [
      @super_emergence.NegDegRevLex,
      @super_emergence.NegDegLex,
      @super_emergence.NegLexLastSmall,
    ] {
    for i in 0..<gens.length() {
      for j in 0..<gens.length() {
        let c = @super_emergence.mora_compare_monomials(
          ordering,
          gens[i],
          gens[j],
        )
        let d = @super_emergence.mora_compare_monomials(
          ordering,
          gens[j],
          gens[i],
        )
        assert_eq(c, -d)
        if i != j {
          assert_true(c != 0)
        }
      }
    }
  }
  // Degree-compatible orders must order monomials by degree first.
  assert_eq(
    @super_emergence.mora_compare_monomials(
      @super_emergence.NegDegRevLex,
      [2, 0],
      [0, 3],
    ),
    -1,
  )
  // The local lex order with the last variable smallest is NOT degree-first:
  // x_1^2 = [0,2] < x_0^3 = [3,0] because x_0 > x_1.
  assert_eq(
    @super_emergence.mora_compare_monomials(
      @super_emergence.NegLexLastSmall,
      [0, 2],
      [3, 0],
    ),
    -1,
  )
}

///|
test "Buchberger–Mora produces a genuine local standard basis" {
  // I = <x + y^2, y + x^2> = m_2 : the maximal ideal.
  let g1 = @super_emergence.mora_var_poly(2, 4, 0).add_poly(
    @super_emergence.mora_monomial_poly(2, 4, [0, 2], 1.0),
  )
  let g2 = @super_emergence.mora_var_poly(2, 4, 1).add_poly(
    @super_emergence.mora_monomial_poly(2, 4, [2, 0], 1.0),
  )
  let sb = @super_emergence.mora_standard_basis([g1, g2])
  assert_true(sb.input_valid && sb.standard && !sb.budget_exhausted)
  let tc = @super_emergence.tangent_cone_report([g1, g2])
  assert_true(tc.input_valid)
  assert_eq(tc.dimension, 0)
  assert_eq(tc.multiplicity, 1)
  assert_eq(tc.colength, 1)
  assert_true(tc.conical)

  // I = <xy, x^2 - y^3>. The standard basis is {xy, x^2 - y^3, y^4}, and the
  // initial ideal <xy, x^2, y^4> has the 5 standard monomials 1, x, y, y^2,
  // y^3, so V(I) = {0} with multiplicity 5 (an embedded component at the
  // origin that the naive cone <xy, x^2> would have missed by declaring a line).
  let h1 = @super_emergence.mora_monomial_poly(2, 6, [1, 1], 1.0)
  let h2 = @super_emergence.mora_monomial_poly(2, 6, [2, 0], 1.0).sub_poly(
    @super_emergence.mora_monomial_poly(2, 6, [0, 3], 1.0),
  )
  let tc2 = @super_emergence.tangent_cone_report([h1, h2])
  assert_true(tc2.input_valid)
  assert_eq(tc2.dimension, 0)
  assert_eq(tc2.multiplicity, 5)
  assert_eq(tc2.colength, 5)
  assert_eq(tc2.hilbert_function, [1, 2, 1, 1, 0, 0, 0])
  assert_true(!tc2.lineality)
}

///|
test "Tangent cone of a homogeneous cone ideal is itself (conical certificate)" {
  // Cone ideal <xz, yz>: union of two planes in A^3, conical with mult 2.
  let g1 = @super_emergence.mora_monomial_poly(3, 6, [1, 0, 1], 1.0)
  let g2 = @super_emergence.mora_monomial_poly(3, 6, [0, 1, 1], 1.0)
  let tc = @super_emergence.tangent_cone_report([g1, g2])
  assert_true(tc.input_valid)
  assert_true(tc.conical)
  assert_eq(tc.dimension, 2)
  // Hilbert function of k[x,y,z]/<xz, yz>: 1, 3, 4, 5, 6, 7, 8 (the eventual
  // slope, hence the multiplicity, is 1; per-degree counts keep rising by one).
  assert_eq(tc.hilbert_function, [1, 3, 4, 5, 6, 7, 8])
  assert_eq(tc.multiplicity, 1)
  // Neither the x- nor the y-axis is contained (xz in I kills the y-axis,
  // yz kills the x-axis), but the z-axis is: 0 = yz(0,0,1) and 0 = xz(0,0,1).
  assert_true(tc.lineality)
  // Non-conical ideal <x^2 - y^3>: cone is V(x^2), multiplicity 2, not conical.
  let cusp = @super_emergence.mora_monomial_poly(2, 6, [2, 0], 1.0).sub_poly(
    @super_emergence.mora_monomial_poly(2, 6, [0, 3], 1.0),
  )
  let tc2 = @super_emergence.tangent_cone_report([cusp])
  assert_true(tc2.input_valid)
  assert_true(!tc2.conical)
  assert_eq(tc2.dimension, 1)
  assert_eq(tc2.multiplicity, 2)
  // The tangent cone of the cusp is its tangent line: the y-axis, so the
  // lineality check must fire (0 = x^2 on x = 0, y = t).
  assert_true(tc2.lineality)
  // A non-degree-compatible ordering cannot define the tangent cone.
  let bad = @super_emergence.tangent_cone_report(
    [cusp],
    ordering=@super_emergence.NegLexLastSmall,
  )
  assert_true(!bad.input_valid)
}

///|
test "Newton polyhedron and the toric/Koszul dichotomy" {
  // Cusp x^2 - y^3: support degrees 2 and 3, so the total-degree (1,1)
  // minimiser is the single monomial x^2 and the total-degree initial form is
  // monomial (Newton-degenerate in the total-degree direction).
  let cusp = @super_emergence.mora_monomial_poly(2, 6, [2, 0], 1.0).sub_poly(
    @super_emergence.mora_monomial_poly(2, 6, [0, 3], 1.0),
  )
  let np = @super_emergence.newton_polyhedron_report(cusp)
  assert_true(np.input_valid)
  assert_eq(np.dimension, 1)
  assert_eq(np.vertices.length(), 2)
  assert_true(np.total_degree_facet)
  // x^2 - y^2: both terms have total degree 2, so (1,1) exposes the whole edge
  // and the initial form is the genuine BINOMIAL x^2 - y^2 — the compact-face /
  // toric side of the dichotomy.
  let conic = @super_emergence.mora_monomial_poly(2, 4, [2, 0], 1.0).sub_poly(
    @super_emergence.mora_monomial_poly(2, 4, [0, 2], 1.0),
  )
  let np_conic = @super_emergence.newton_polyhedron_report(conic)
  assert_true(np_conic.input_valid)
  assert_true(!np_conic.total_degree_facet)

  // x + y^2: vertices (1,0), (0,2); total degree minimiser is x alone, so the
  // total-degree initial form is monomial: Newton-degenerate / Koszul side.
  let deg = @super_emergence.mora_var_poly(2, 4, 0).add_poly(
    @super_emergence.mora_monomial_poly(2, 4, [0, 2], 1.0),
  )
  let np2 = @super_emergence.newton_polyhedron_report(deg)
  assert_true(np2.input_valid)
  assert_true(np2.total_degree_facet)

  let prof = @super_emergence.newton_cone_profile(cusp)
  assert_true(prof.input_valid)
  assert_true(!prof.mixed_toric_face)
  assert_true(prof.monomial_cone)
  assert_true(prof.matches_mora_cone)

  let prof_conic = @super_emergence.newton_cone_profile(conic)
  assert_true(prof_conic.input_valid)
  assert_true(prof_conic.mixed_toric_face)
  assert_true(!prof_conic.monomial_cone)
  assert_eq(prof_conic.semigroup_rank, 2)
  assert_eq(prof_conic.total_degree, 2)
  assert_true(prof_conic.matches_mora_cone)

  let prof2 = @super_emergence.newton_cone_profile(deg)
  assert_true(prof2.monomial_cone && prof2.matches_mora_cone)
}

///|
test "M4 v2: the tangent cone of the critical variety selects A3 vs D4" {
  let a3 = @super_emergence.learn_catastrophe_from_tangent_cone(3, 0.05)
  assert_true(a3.input_valid && a3.certified)
  assert_eq(a3.selected_class, @super_emergence.A3Cusp)
  assert_eq(a3.a3_cone_multiplicity, 2)
  assert_eq(a3.a3_cone_dimension, 1)
  assert_true(!a3.a3_conical)
  assert_eq(a3.a3_real_critical_points, 3)
  assert_eq(a3.milnor_number, 3)
  assert_eq(a3.unfolding_codimension, 3)

  let d4 = @super_emergence.learn_catastrophe_from_tangent_cone(4, 0.05)
  assert_true(d4.input_valid && d4.certified)
  assert_eq(d4.selected_class, @super_emergence.D4Umbilic)
  assert_eq(d4.d4_cone_multiplicity, 4)
  assert_eq(d4.d4_cone_dimension, 1)
  assert_true(d4.d4_conical)
  assert_eq(d4.d4_real_critical_points, 4)
  assert_eq(d4.milnor_number, 4)
  assert_eq(d4.unfolding_codimension, 4)

  // Invalid branch demands and non-positive amplitudes are rejected.
  let bad = @super_emergence.learn_catastrophe_from_tangent_cone(5, 0.05)
  assert_true(!bad.input_valid && !bad.certified)
  let bad2 = @super_emergence.learn_catastrophe_from_tangent_cone(3, 0.0)
  assert_true(!bad2.input_valid)
}

///|
test "M6 v2: tangent-cone certified four-layer closed loop" {
  let report = @super_emergence.audit_four_layer_tangent_cone_loop(
    flow_steps=3,
    max_iterations=32,
    relaxation=0.35,
    tolerance=1.0e-3,
  )
  assert_true(report.input_valid)
  assert_true(report.converged && report.empirical_fixed_point_certified)
  assert_true(report.fixed_point_residual <= 1.0e-3)
  assert_true(report.empirical_contraction_factor < 1.0)
  assert_true(report.weight_normalization_defect < 1.0e-12)
  // The cone certificate must be a real one, chosen from the tangent cone.
  assert_true(report.cone_multiplicity == 2 || report.cone_multiplicity == 4)
  assert_eq(report.cone_dimension, 1)
  assert_true(report.band_cycle_reversible)
  assert_eq(report.role_assignment.length(), 8)
  assert_eq(report.cluster_sizes.length(), 4)

  let default_report = @super_emergence.audit_four_layer_tangent_cone_loop()
  assert_true(default_report.input_valid && default_report.converged)

  let invalid = @super_emergence.audit_four_layer_tangent_cone_loop(
    max_iterations=1,
  )
  assert_true(!invalid.input_valid)
  let invalid2 = @super_emergence.audit_four_layer_tangent_cone_loop(
    tolerance=1.0,
  )
  assert_true(!invalid2.input_valid)
}

///|
test "ADE classifier separates E6 from D6 and names A1/E7/E8/T" {
  // A1: a nondegenerate critical point is the corank-0 case that the old
  // classifier silently dumped into the generic map-germ bucket.
  let b1 = @super_emergence.JetBasis::new(1, 6)
  let a1 = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::from_terms(b1, [([2], 1.0)]),
  ])
  let ra1 = @super_emergence.classify_contact_equiv_class(a1)
  assert_eq(ra1.corank, 0)
  assert_eq(ra1.label, "A_1 (Nondegenerate)")

  let b2 = @super_emergence.JetBasis::new(2, 8)
  let g = (t : Array[(Array[Int32], Double)]) => {
    @super_emergence.MapGerm::new([@super_emergence.PolyGerm::from_terms(b2, t)])
  }
  // E6 = x^3 + y^4 and D6 = x^2 y + y^5 share (mu, tau, corank) = (6, 6, 2);
  // only the Tjurina Hilbert function separates them (socle degrees 3 vs 4).
  let e6 = @super_emergence.classify_contact_equiv_class(
    g([([3, 0], 1.0), ([0, 4], 1.0)]),
  )
  let d6 = @super_emergence.classify_contact_equiv_class(
    g([([2, 1], 1.0), ([0, 5], 1.0)]),
  )
  assert_eq(e6.milnor, 6)
  assert_eq(d6.milnor, 6)
  assert_eq(e6.tjurina, d6.tjurina)
  assert_true(e6.label != d6.label)
  assert_eq(e6.label, "E_6 (x^3 + y^4)")
  assert_eq(d6.label, "D_6 (x^2 y + y^5)")

  // E7 and E8 previously fell through to "Corank-2 QH (tau=k)".
  let e7 = @super_emergence.classify_contact_equiv_class(
    g([([3, 0], 1.0), ([1, 3], 1.0)]),
  )
  let e8 = @super_emergence.classify_contact_equiv_class(
    g([([3, 0], 1.0), ([0, 5], 1.0)]),
  )
  assert_eq(e7.label, "E_7 (x^3 + x y^3)")
  assert_eq(e7.milnor, 7)
  assert_eq(e8.label, "E_8 (x^3 + y^5)")
  assert_eq(e8.milnor, 8)

  // T_{3,3,3}: mu = 2^3 = 8 with corank 3 (three variables).
  let b3 = @super_emergence.JetBasis::new(3, 6)
  let t333 = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::from_terms(b3, [
      ([3, 0, 0], 1.0),
      ([0, 3, 0], 1.0),
      ([0, 0, 3], 1.0),
    ]),
  ])
  let rt = @super_emergence.classify_contact_equiv_class(t333)
  assert_eq(rt.corank, 3)
  assert_eq(rt.milnor, 8)
  assert_eq(rt.label, "T_{3,3,3} (Triangle)")
}

///|
test "truncation adequacy audit catches an under-resolved Milnor number" {
  // E8 = x^3 + y^5 needs max_deg >= 5: at max_deg = 4 the truncated computation
  // inflates mu to 9, so any label derived from it would be wrong.
  let b4 = @super_emergence.JetBasis::new(2, 4)
  let e8_short = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::from_terms(b4, [([3, 0], 1.0), ([0, 5], 1.0)]),
  ])
  let audit_short = @super_emergence.audit_truncation_adequacy(e8_short)
  assert_true(audit_short.input_valid)
  assert_eq(audit_short.mu_at_max_deg, 9)
  assert_true(!audit_short.stable)

  let b8 = @super_emergence.JetBasis::new(2, 8)
  let e8_ok = @super_emergence.MapGerm::new([
    @super_emergence.PolyGerm::from_terms(b8, [([3, 0], 1.0), ([0, 5], 1.0)]),
  ])
  let audit_ok = @super_emergence.audit_truncation_adequacy(e8_ok)
  assert_eq(audit_ok.mu_at_max_deg, 8)
  assert_true(audit_ok.stable)
}

///|
test "Hörmander Σ-condition decides microlocal products, not just collisions" {
  let plus = @super_emergence.HyperfunctionGerm::cauchy_plus(0.0).sp()
  let minus = @super_emergence.HyperfunctionGerm::cauchy_minus(0.0).sp()
  // Opposite chirality at a common base point: (x+i0)^-1 * (x-i0)^-1 collides.
  let bad = @super_emergence.hormander_sigma_condition(plus, minus)
  assert_true(bad.input_valid)
  assert_eq(bad.sigma_hits, 1)
  assert_true(!bad.product_admissible)
  assert_true(!bad.leibniz_safe)
  assert_eq(bad.forbidden_pairs, [("+i dx", "-i dx")])
  // Co-chiral: the product exists and Leibniz applies.
  let good = @super_emergence.hormander_sigma_condition(plus, plus)
  assert_eq(good.sigma_hits, 0)
  assert_true(good.product_admissible && good.leibniz_safe)
  // Different base points never collide.
  let shifted = @super_emergence.HyperfunctionGerm::cauchy_minus(0.5).sp()
  let far = @super_emergence.hormander_sigma_condition(plus, shifted)
  assert_true(!far.input_valid)

  // Generalised auditor over multi-direction conormal bundles. Angles use the
  // library constant: the auditor's default angle tolerance is 1e-9 and a
  // truncated literal for pi would itself exceed it.
  let half_pi = @math.PI / 2.0
  let cu = @super_emergence.ConormalBundle::new(0.0, [
    (0.0, 1.0),
    (half_pi, 1.0),
  ])
  // (pi, +1) is antipodal to the 0 direction => collision => NOT admissible.
  let cv_hit = @super_emergence.ConormalBundle::new(0.0, [(@math.PI, 1.0)])
  assert_true(!@super_emergence.hormander_sigma_conormal(cu, cv_hit))
  // (pi, -1) folds to 2pi = 0, meeting the 0 direction with the SAME effective
  // direction: the covectors are +dx and +dx, which do not cancel.
  let cv_no_hit = @super_emergence.ConormalBundle::new(0.0, [(@math.PI, -1.0)])
  assert_true(@super_emergence.hormander_sigma_conormal(cu, cv_no_hit))
}

///|
test "Leibniz consistency audit ties Σ-condition to the product implementation" {
  let audit = @super_emergence.audit_microlocal_leibniz_consistency()
  assert_true(audit.input_valid)
  assert_eq(audit.fixtures, 36)
  assert_true(audit.admissible > 0 && audit.rejected > 0)
  // Every admissible pair multiplied, every inadmissible pair was rejected, and
  // the pole orders satisfied ord(u*v) = ord u + ord v on the pure-pole pairs.
  assert_true(audit.sigma_agrees_with_product)
  assert_true(audit.order_additivity_defect < 1.0e-12)
  assert_true(audit.certified)
}

///|
test "M6 v3 refinement and local contraction certificate" {
  let report = @super_emergence.audit_m6_refinement_and_local_contraction()
  assert_true(report.input_valid)
  assert_true(report.fixed_point_residual <= 1.0e-3)
  assert_true(report.refined_fixed_point_residual <= 1.0e-3)
  // Halving the relaxation must not move the fixed point by more than O(r).
  assert_true(report.refinement_consistent)
  assert_true(report.local_contraction_radius < 1.0)
  assert_true(report.local_contraction_certified)
  assert_true(report.certified)
}
