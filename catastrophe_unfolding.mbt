///|
/// Finite set of catastrophe normal forms currently supported by the M4 controller.
/// The selector is intentionally explicit: it does not claim to classify all ADE germs.
#derive(Debug, Eq)
pub(all) enum CatastropheKind {
  A3Cusp
  D4Umbilic
}

///|
/// Machine-checkable result of active finite-catalogue catastrophe selection and unfolding.
#derive(Debug, Eq)
pub(all) struct M4LearningReport {
  input_valid : Bool
  certified : Bool
  target_role_branches : Int32
  candidate_classes_tested : Int32
  selected_class : CatastropheKind
  selected_label : String
  milnor_number : Int32
  unfolding_codimension : Int32
  parameters : Array[Double]
  parameter_norm : Double
  base_critical_points : Int32
  unfolded_critical_points : Int32
  stable_minima : Int32
  versal : Bool
  target_matched : Bool
  reconstruction_residual : Double
  stationary_residual : Double
}

///|
priv struct M4Candidate {
  kind : CatastropheKind
  label : String
  milnor_number : Int32
  codimension : Int32
  parameters : Array[Double]
  parameter_norm : Double
  critical_points : Int32
  stable_minima : Int32
  versal : Bool
  reconstruction_residual : Double
  stationary_residual : Double
}

///|
fn m4_jet_basis(kind : CatastropheKind) -> JetBasis {
  match kind {
    A3Cusp => JetBasis::new(1, 6)
    D4Umbilic => JetBasis::new(2, 5)
  }
}

///|
fn m4_normal_form(kind : CatastropheKind) -> MapGerm {
  let basis = m4_jet_basis(kind)
  match kind {
    A3Cusp => MapGerm::new([PolyGerm::monomial(basis, [4], 1.0)])
    D4Umbilic =>
      MapGerm::new([
        PolyGerm::from_terms(basis, [([3, 0], 1.0), ([1, 2], -3.0)]),
      ])
  }
}

///|
fn m4_requested_perturbation(
  kind : CatastropheKind,
  amplitude : Double,
) -> MapGerm {
  let basis = m4_jet_basis(kind)
  match kind {
    A3Cusp => MapGerm::new([PolyGerm::monomial(basis, [2], -amplitude)])
    D4Umbilic =>
      MapGerm::new([
        PolyGerm::from_terms(basis, [([2, 0], amplitude), ([0, 2], amplitude)]),
      ])
  }
}

///|
/// Verify the analytic critical-point branches without letting tiny/huge amplitude powers
/// underflow or overflow the residual. The residual is normalized by the natural scale of
/// each gradient equation, while branch coordinates must remain representably distinct.
fn m4_stationary_residual(kind : CatastropheKind, amplitude : Double) -> Double {
  let mut worst = 0.0
  match kind {
    A3Cusp => {
      let root = (amplitude / 2.0).sqrt()
      if root == 0.0 || !root.is_finite() {
        return 1.0
      }
      let roots = [-root, 0.0, root]
      for x in roots {
        let t = x / root
        worst = worst.max((t * t * t - t).abs())
      }
    }
    D4Umbilic => {
      let saddle_x = -(2.0 / 3.0) * amplitude
      let branch_y = amplitude / 3.0.sqrt()
      if saddle_x == 0.0 ||
        branch_y == 0.0 ||
        !saddle_x.is_finite() ||
        !branch_y.is_finite() {
        return 1.0
      }
      // Normalize coordinates by a, so grad(f)/a^2 is evaluated without forming a^2.
      let points = [
        (0.0, 0.0),
        (-2.0 / 3.0, 0.0),
        (1.0 / 3.0, 1.0 / 3.0.sqrt()),
        (1.0 / 3.0, -1.0 / 3.0.sqrt()),
      ]
      for (u, v) in points {
        let dx = 3.0 * u * u - 3.0 * v * v + 2.0 * u
        let dy = -6.0 * u * v + 2.0 * v
        worst = worst.max((dx * dx + dy * dy).sqrt())
      }
    }
  }
  worst
}

///|
fn build_m4_candidate(
  kind : CatastropheKind,
  amplitude : Double,
) -> Result[M4Candidate, String] {
  let branch_residual = m4_stationary_residual(kind, amplitude)
  if !branch_residual.is_finite() || branch_residual >= 1.0e-10 {
    return Err("critical branches are not representable at this amplitude")
  }
  let base = m4_normal_form(kind)
  let germ_class = classify_contact_equiv_class(base)
  let expected_label = match kind {
    A3Cusp => "A_3"
    D4Umbilic => "D_4 (Umbilic)"
  }
  let expected_codimension = match kind {
    A3Cusp => 3
    D4Umbilic => 4
  }
  if germ_class.label != expected_label ||
    germ_class.tjurina != expected_codimension {
    return Err("normal-form classifier/codimension mismatch")
  }
  let unfolding = base.universal_k_unfolding()
  let versal = unfolding.codim == expected_codimension &&
    is_k_versal_unfolding(base, unfolding.directions)
  if !versal {
    return Err("universal unfolding failed the infinitesimal K-versality check")
  }
  let perturbation = m4_requested_perturbation(kind, amplitude)
  let parameters = unfolding.induce_perturbation_params(perturbation)
  let fiber = match unfolding.fiber_at_checked(parameters) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  // The selected complement need not reproduce the same polynomial representative:
  // it must reproduce the same class modulo T K_e(f). Audit the quotient residual,
  // not coefficient equality (units/coordinate changes can alter stationary points).
  let remainder = fiber.comps[0].sub(base.comps[0]).sub(perturbation.comps[0])
  let remainder_map = MapGerm::new([remainder])
  let reconstruction_residual = vec_norm(
    unfolding.induce_perturbation_params(remainder_map),
  )
  let (critical_points, stable_minima) = match kind {
    A3Cusp => (3, 2)
    D4Umbilic => (4, 1)
  }
  Ok({
    kind,
    label: germ_class.label,
    milnor_number: germ_class.milnor,
    codimension: unfolding.codim,
    parameter_norm: vec_norm(parameters),
    parameters,
    critical_points,
    stable_minima,
    versal,
    reconstruction_residual,
    stationary_residual: branch_residual,
  })
}

///|
fn invalid_m4_report(target_role_branches : Int32) -> M4LearningReport {
  {
    input_valid: false,
    certified: false,
    target_role_branches,
    candidate_classes_tested: 0,
    selected_class: A3Cusp,
    selected_label: "invalid",
    milnor_number: 0,
    unfolding_codimension: 0,
    parameters: [],
    parameter_norm: 0.0,
    base_critical_points: 0,
    unfolded_critical_points: 0,
    stable_minima: 0,
    versal: false,
    target_matched: false,
    reconstruction_residual: 0.0,
    stationary_residual: 0.0,
  }
}

///|
/// M4 active selector. It compares the A3 cusp and D4 umbilic miniversal families,
/// introduces a finite nonzero control, and selects the least-codimension family whose
/// analytically counted real critical branches match the requested role-branch count.
/// The reported branches are equilibrium candidates, not a claim that every branch is
/// a stable attractor: `stable_minima` records that distinction explicitly.
pub fn learn_catastrophe_for_role_branches(
  target_role_branches : Int32,
  amplitude : Double,
) -> M4LearningReport {
  if (target_role_branches != 3 && target_role_branches != 4) ||
    !amplitude.is_finite() ||
    amplitude <= 0.0 {
    return invalid_m4_report(target_role_branches)
  }
  let a3 = match build_m4_candidate(A3Cusp, amplitude) {
    Ok(candidate) => candidate
    Err(_) => return invalid_m4_report(target_role_branches)
  }
  let d4 = match build_m4_candidate(D4Umbilic, amplitude) {
    Ok(candidate) => candidate
    Err(_) => return invalid_m4_report(target_role_branches)
  }
  let a3_diff = a3.critical_points - target_role_branches
  let d4_diff = d4.critical_points - target_role_branches
  let a3_gap = if a3_diff < 0 { -a3_diff } else { a3_diff }
  let d4_gap = if d4_diff < 0 { -d4_diff } else { d4_diff }
  let chosen = if a3_gap < d4_gap ||
    (a3_gap == d4_gap && a3.codimension <= d4.codimension) {
    a3
  } else {
    d4
  }
  let target_matched = chosen.critical_points == target_role_branches
  let certified = target_matched &&
    chosen.versal &&
    chosen.reconstruction_residual < 1.0e-10 &&
    chosen.stationary_residual < 1.0e-10
  {
    input_valid: true,
    certified,
    target_role_branches,
    candidate_classes_tested: 2,
    selected_class: chosen.kind,
    selected_label: chosen.label,
    milnor_number: chosen.milnor_number,
    unfolding_codimension: chosen.codimension,
    parameters: chosen.parameters,
    parameter_norm: chosen.parameter_norm,
    base_critical_points: 1,
    unfolded_critical_points: chosen.critical_points,
    stable_minima: chosen.stable_minima,
    versal: chosen.versal,
    target_matched,
    reconstruction_residual: chosen.reconstruction_residual,
    stationary_residual: chosen.stationary_residual,
  }
}
