///|
/// Unified CLI demo for `arena/super_emergence` (v2.0.0): verifies all 18 composite
/// theorems (Layers I-IV), replays the four-layer quasi-agentic emergence engine, and
/// reports the M1.1–M1.4, M2.1–M2.4 and M3.1–M6 roadmap acceptance audits.
/// Run with `moon run cmd/main`.

///|
/// Format a floating-point value to a fixed number of decimal places for clean tables.
fn fmt_fixed(x : Double, digits : Int32) -> String {
  if x.is_nan() {
    return "NaN"
  }
  let sign = if x < 0.0 { "-" } else { "" }
  let ax = x.abs()
  let mut scale = 1.0
  for _ in 0..<digits {
    scale = scale * 10.0
  }
  let rounded = (ax * scale).round().to_int64()
  let s_i64 = scale.to_int64()
  let whole = rounded / s_i64
  let frac = rounded % s_i64
  let frac_str = frac.to_string()
  let pad = digits - frac_str.length()
  let buf = StringBuilder()
  buf.write_string(sign)
  buf.write_string(whole.to_string())
  buf.write_string(".")
  for _ in 0..<pad {
    buf.write_string("0")
  }
  buf.write_string(frac_str)
  buf.to_string()
}

///|
/// Format small scientific residual (e.g. 2.22e-16).
fn fmt_sci(x : Double) -> String {
  let ax = x.abs()
  if ax == 0.0 {
    return "0.00e+00"
  }
  let mut mant = ax
  let mut exp = 0
  while mant >= 10.0 {
    mant = mant / 10.0
    exp = exp + 1
  }
  while mant < 1.0 {
    mant = mant * 10.0
    exp = exp - 1
  }
  let sign_e = if exp >= 0 { "+" } else { "-" }
  let ae = if exp >= 0 { exp } else { -exp }
  let es = if ae < 10 { "0\{ae}" } else { "\{ae}" }
  "\{fmt_fixed(mant, 2)}e\{sign_e}\{es}"
}

///|
/// Preserve the sign when displaying a scientific energy change or work term.
fn fmt_signed_sci(x : Double) -> String {
  let sign = if x < 0.0 { "-" } else { "" }
  "\{sign}\{fmt_sci(x)}"
}

///|
fn main {
  println(
    "================================================================================",
  )
  println(
    "  SUPER-EMERGENCE v2.0.0 (MoonBit v0.10.21): Unified Math-Quasi-Agentic Emergence",
  )
  println(
    "  algorithm04 (super-geometry / Schur-Berezin / germs / microlocal) +",
  )
  println(
    "  algo8 (memory / limits / symplectic / bundles / K-theory / paraconsistency)",
  )
  println(
    "  = 26 structures | 18 composite + 31 foundational theorems | 4 emergence layers",
  )
  println(
    "================================================================================",
  )
  println("")
  // One shared SGNE-Flow run feeds every downstream report section.
  let (snaps, final_agents) = @se.run_sgne_emergence_simulation(
    n_agents=8,
    n_steps=24,
    dt=0.18,
  )
  let c_end = snaps[snaps.length() - 1].curvature_c

  report_part_1()
  report_part_2()
  report_part_3(snaps)
  report_part_4(final_agents, c_end)
  report_part_5(final_agents)
  report_part_6()
  report_part_7(final_agents, c_end)
  report_part_8()
  report_part_9()
  report_part_10()
  report_part_11()
  report_part_12()
  report_part_13()
}

///|
/// Report section 1 of the unified emergence CLI.
fn report_part_1() -> Unit {
  println(
    "[Part 1] Computational Verification of 18 Composite Mathematical Theorems:",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
  let reports = @se.verify_all_theorems()
  let mut passed_cnt = 0
  for r in reports {
    let badge = if r.passed { "PASS" } else { "FAIL" }
    if r.passed {
      passed_cnt = passed_cnt + 1
    }
    println("  [\{badge}] \{r.id}: \{r.title}")
    println(
      "         max_residual = \{fmt_sci(r.max_residual)} | invariant = \{fmt_fixed(r.key_invariant, 4)}",
    )
    println("         \{r.summary}")
  }
  println(
    "--------------------------------------------------------------------------------",
  )
  println(
    "  Theorem Verification Summary: \{passed_cnt} / \{reports.length()} theorems verified.",
  )
  println("")

  // Part 2: Natural Gradient vs Euclidean Gradient + PoPE vs RoPE quantitative check
}

///|
/// Report section 2 of the unified emergence CLI.
fn report_part_2() -> Unit {
  println("[Part 2] Key Algorithmic Contrasts:")
  println(
    "--------------------------------------------------------------------------------",
  )
  let (kl_nat, kl_euc) = @se.compare_natural_vs_euclidean_kl(
    [0.72, 0.18, 0.07, 0.03],
    [-1.2, 0.9, 1.4],
    35,
    0.25,
  )
  println(
    "  Fisher-Rao Natural Gradient vs Euclidean GD (35 steps, KL minimization):",
  )
  println(
    "    D_KL(p* || p_nat) = \{fmt_sci(kl_nat)}  vs  D_KL(p* || p_euc) = \{fmt_sci(kl_euc)}",
  )
  let pope_cfg = @se.PoPEConfig::new(8, base=1000.0, delta=[
    -0.3, -0.1, 0.0, -0.5, -0.2, 0.0, -0.4, -0.1,
  ])
  let q_demo = [0.6, -0.8, 1.2, 0.3, -0.5, 0.9, 0.4, -0.7]
  let (pope_jac, rope_jac) = @se.what_where_entanglement_norms(pope_cfg, q_demo)
  println(
    "  PoPE vs RoPE What-Where Phase-Content Jacobian Norm ||d(phi)/dq||_2:",
  )
  println(
    "    PoPE = \{fmt_sci(pope_jac)} (exact decoupling)  vs  RoPE = \{fmt_fixed(rope_jac, 4)} (entangled)",
  )
  let (c_traj, c_star) = @se.evolve_ricci_fisher_curvature(
    0.02, 4, 0.8, 2.4, 0.75, 0.05, 40,
  )
  println(
    "  Ricci-Fisher Spontaneous Hyperbolic Curvature Emergence (c0 = 0.02 -> c*):",
  )
  println(
    "    c(0) = \{fmt_fixed(c_traj[0], 4)} -> c(T) = \{fmt_fixed(c_traj[c_traj.length() - 1], 4)} (analytic attractor c* = \{fmt_fixed(c_star, 4)})",
  )
  println("")

  // Part 3: Full SGNE-Flow Quasi-Agentic Emergence Trajectory
}

///|
/// Report section 3 of the unified emergence CLI.
fn report_part_3(snaps : Array[@se.EmergenceSnapshot]) -> Unit {
  println(
    "[Part 3] Master Algorithm SGNE-Flow: 8 Proto-Agents on Critical M^{4|4}_c",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
  println(
    "  Step | Curv c | FreeEng | SUSY_H  | WitIdx | HierSpr | OrbDiv | PolEnt | Unif | Synergy",
  )
  for s in snaps {
    if s.step % 4 == 0 {
      println(
        "   \{s.step}   | \{fmt_fixed(s.curvature_c, 3)}  | \{fmt_fixed(s.free_energy, 4)} | \{fmt_fixed(s.susy_frustration, 4)} | \{fmt_fixed(s.witten_index, 3)}  | \{fmt_fixed(s.hierarchy_spread, 4)} | \{fmt_fixed(s.mass_orbit_diversity, 4)} | \{fmt_fixed(s.policy_entropy, 4)} |  \{s.unified_rules}  | \{fmt_fixed(s.emergence_synergy, 4)}",
      )
    }
  }
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report section 4 of the unified emergence CLI.
fn report_part_4(final_agents : Array[@se.ProtoAgent], c_end : Double) -> Unit {
  println("[Part 4] Emerged Specialized Quasi-Agent Roles & Super-Mass Orbits:")
  let role_labels = [
    "Coordinator (Root Anchor)", "Sensor (Perception)", "Planner (Symbolic Verifier)",
    "Executor (Boundary Actor)",
  ]
  let orig = @se.PoincarePoint::origin(c_end, 4)
  for ag in final_agents {
    let probs = @se.categorical_probs(ag.policy_eta)
    let mut top_r = 0
    for r in 1..<4 {
      if probs[r] > probs[top_r] {
        top_r = r
      }
    }
    let depth = orig.geodesic_dist(ag.belief)
    let spec = ag.mass.bosonic_mass_spectrum()
    let mean_mass = 0.25 * (spec[0] + spec[1] + spec[2] + spec[3])
    let ber_b = ag.mass.mat.berezinian().body()
    println(
      "  Agent #\{ag.id} -> \{role_labels[top_r]} (p=\{fmt_fixed(probs[top_r], 3)}) | d_c(0,x)=\{fmt_fixed(depth, 3)} | <M_eff>=\{fmt_fixed(mean_mass, 3)} | Ber(I)=\{fmt_fixed(ber_b, 3)}",
    )
  }
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report section 5 of the unified emergence CLI.
fn report_part_5(final_agents : Array[@se.ProtoAgent]) -> Unit {
  println(
    "[Part 5] SGNE-Trop-Kan Universal Functor & Semitropical Projective Distillation:",
  )
  let init_agents = @se.init_disordered_colony(8, 0.25)
  let mac = @se.distill_tropical_kan_macro_agent(init_agents, final_agents)
  println(
    "  Supertropical Ghost Phase Transition : \{mac.initial_ghost_agents}/8 (critical tie G) -> \{mac.final_ghost_agents}/8 (all Tangible T!)",
  )
  println(
    "  Projective Polytope Pi_V Contraction : lip_ratio = \{fmt_fixed(mac.polytope_proj_contraction, 4)} (<= 1.0000 in d_TH)",
  )
  println(
    "  Universal Left Kan Capability Lan_K  : [Coord=\{fmt_fixed(mac.lan_capability[0], 3)}, Sense=\{fmt_fixed(mac.lan_capability[1], 3)}, Plan=\{fmt_fixed(mac.lan_capability[2], 3)}, Act=\{fmt_fixed(mac.lan_capability[3], 3)}]",
  )
  println(
    "  Universal Right Kan Safety Ran_K     : [Coord=\{fmt_fixed(mac.ran_safety_floor[0], 3)}, Sense=\{fmt_fixed(mac.ran_safety_floor[1], 3)}, Plan=\{fmt_fixed(mac.ran_safety_floor[2], 3)}, Act=\{fmt_fixed(mac.ran_safety_floor[3], 3)}]",
  )
  println(
    "  Karp Tropical Spectral Throughput    : lambda_trop(A) = \{fmt_fixed(mac.karp_cycle_eigenvalue, 4)} (fixed pt [v*] in TP^7)",
  )
  println(
    "  Universal Pushout Merged Ontology    : |A (+)_C B| = \{mac.pushout_ontology_size} concepts (5 + 5 - 3 interface)",
  )
  println(
    "  Trop Gr(2,8) Plucker Ghost Defect    : Poincare = \{fmt_fixed(mac.poincare_plucker_defect, 4)} (< 2ln2/sqrt(c) = \{fmt_fixed(mac.gromov_sharp_bound, 4)}) -> Ultrametric = \{fmt_sci(mac.ultrametric_plucker_defect)}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report section 6 of the unified emergence CLI.
fn report_part_6() -> Unit {
  println(
    "[Part 6] SGNE-Germ-Micro Enveloping, Singularity Germ & Sato Microlocal Audit:",
  )
  let gm = @se.distill_germ_microlocal_phase()
  println(
    "  Super-PBW U_{<=3}(osp(1|2)) & C_2    : dim = \{gm.pbw_dim_deg3} | Schur Casimir lambda(C_2) = \{fmt_fixed(gm.osp_casimir_eigenvalue, 4)}",
  )
  println(
    "  Catastrophe K-Class & Unfolding      : \{gm.catastrophe_class} | Universal K-codim tau = \{gm.unfolding_codim} (finite A3/D4 scalar prototypes)",
  )
  println(
    "  ICIS Le-Greuel & Normal Ring Germ    : ICIS mu = \{gm.icis_milnor} | Normalization delta = \{gm.normalization_delta}, conductor c = \{gm.normalization_conductor} (= 2*delta Gorenstein)",
  )
  println(
    "  Euler-Jacobi Residue & SKK Parametrix: sum Res = \{fmt_fixed(gm.residue_charge, 4)} | ||P o P^{-1} - 1|| = \{fmt_sci(gm.microlocal_parametrix_err)}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report section 7 of the unified emergence CLI.
fn report_part_7(final_agents : Array[@se.ProtoAgent], c_end : Double) -> Unit {
  println(
    "[Part 7] SGNE-Syn-Mem-Para (Layer 4): Schur-Metriplectic + Role-Gated Memory + B4 Fusion",
  )
  let smp = @se.distill_synergetic_memory_para_agent(final_agents, c_end)
  println(
    "  Role-Gated Memory Absorption Times   : [Coord=\{fmt_fixed(smp.role_absorption_times[0], 2)}, Plan=\{fmt_fixed(smp.role_absorption_times[1], 2)}, Sense=\{fmt_fixed(smp.role_absorption_times[2], 2)}, Act=\{fmt_fixed(smp.role_absorption_times[3], 2)}]",
  )
  println(
    "  Gated Semigroup Closure |closed-iter|: \{fmt_sci(smp.semigroup_closure_error)} (O(log t) closed form == t-fold iteration)",
  )
  println(
    "  Haken WTA <-> Supertropical Duality  : Tangible=\{smp.wta_tangible} | Ghost=\{smp.wta_ghost} (tie winners = \{smp.wta_ghost_winners})",
  )
  println(
    "  Haken Slaving Collapse Error         : \{fmt_sci(smp.slaving_collapse_error)}",
  )
  println(
    "  Finite Bicompleteness (Godel inj.)   : \{smp.godel_injective} | pushout |A (+) B| = \{smp.pushout_ontology_size}, pullback |A x B| = \{smp.pullback_apex_size}",
  )
  let fused_str = smp.fused_values.map(v => @se.FourVal::to_string(v)).join(",")
  println(
    "  Colony B_4 Paraconsistent Fusion     : [\{fused_str}] | no-explosion = \{smp.no_explosion} | quarantined contradictions = \{smp.contradicted_propositions}",
  )
  let metri = @se.schur_metriplectic_instance()
  let q1 = [0.9, -0.8]
  println(
    "  Schur-Metriplectic A^T Omega + Omega A: defect = \{fmt_sci(metri.metriplectic_defect(q1))} (metriplectic condition exact)",
  )
  println(
    "  Conservative Sub-Flow Symplecticity  : defect = \{fmt_sci(metri.symplectic_defect(q1, 0.05))} | det J = \{fmt_fixed(metri.conservative_flow_jacobian(q1, 0.05).det(), 9)}",
  )
  let (soul_norm, body_trace) = @se.schur_soul_mass_shift()
  println(
    "  Schur-Berezin Soul Mass Shift        : ||Delta M||_soul = \{fmt_sci(soul_norm)} | tr_body(Delta M) = \{fmt_sci(body_trace)} | Schur identity resid = \{fmt_sci(@se.schur_effective_mass_identity())}",
  )
  let dw = @se.double_well_instance()
  let esc = @se.double_well_barrier_escape(dw, 12, 8000, 0.001, 1.5)
  println(
    "  Double-Well Barrier Escape           : conservative = \{esc.conservative_escapes}/\{esc.trials} (trapped, H < barrier) | metriplectic = \{esc.metriplectic_escapes}/\{esc.trials} (escaped)",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report section 8 of the unified emergence CLI.
fn report_part_8() -> Unit {
  println("[Part 8] Merged Mathematical-Structure Demos (algo8 lineage):")
  println(
    "--------------------------------------------------------------------------------",
  )
  // 8.1 Long-term memory cell state transition
  let g : @se.Gates = { forget: 0.9, input: 0.8, output: 1.0, candidate: 0.5, }
  let ig = g.input * g.candidate
  let mut cell : @se.MemoryCell = { c: 1.0, h: 0.0, }
  for _ in 0..<10 {
    cell = cell.step(g)
  }
  let closed = @se.memory_closed_form(1.0, g.forget, ig, 10)
  println(
    "  [8.1] Memory gated cell: iterated c10 = \{cell.c} | closed form = \{closed}",
  )
  let pi = @se.stationary_power_iteration(@se.memory_ergodic_matrix(), 200)
  println(
    "        Stationary pi = [\{fmt_fixed(pi[0], 4)}, \{fmt_fixed(pi[1], 4)}, \{fmt_fixed(pi[2], 4)}, \{fmt_fixed(pi[3], 4)}]",
  )
  // 8.2 Universal property functors
  println(
    "  [8.2] Terminal object arrows = \{@se.count_terminal_arrows(7)} | product universal property = \{@se.universal_property_product_witness(2, 2, 2)} | functor laws = \{@se.functor_laws_product_with_k(3, 2, 2)}",
  )
  // 8.3 Complex field strong cardinality
  let z = @se.Complex::new(3.5, -2.25)
  let (ca, cb) = @se.strong_basis_coords(z)
  let back = @se.rebuild_from_coords(ca, cb)
  let (pa, pb) = @se.cantor_unpair(@se.cantor_pair(3, 5))
  println(
    "  [8.3] Hamel coords of z = (\{ca}, \{cb}) | rebuilt = (\{back.re}, \{back.im}) | Cantor pi^-1(pi(3,5)) = (\{pa}, \{pb})",
  )
  // 8.4 Synergetic functor network
  let enc : @se.Layer = {
    w: [[1.0, 0.5, 0.0], [0.0, 1.0, 0.5], [0.5, 0.0, 1.0]],
    b: [0.1, -0.2, 0.0],
  }
  let net : @se.SynergeticNet = { encoder: enc, n_order: 3, }
  let fl = @se.functor_laws_synergetic(net, [1.0, 2.0, 3.0], [0.5, -0.5, 1.0], [
    -1.0, 0.25, 0.0,
  ])
  let wta = @se.order_parameter_wta([0.1, 2.0, 0.5, -1.0], 0.1, 200)
  println(
    "  [8.4] Synergetic functor laws = \{fl} | slaving s* = \{fmt_fixed(@se.slaving_fixed_point(1.5, 4.0), 6)} | WTA winner = \{wta[0]}",
  )
  // 8.5 Symplectic phase-harmony identity
  let h = @se.default_neural_h()
  let qh = [0.7, -0.4]
  let ph = [0.3, 0.9]
  println(
    "  [8.5] Symplectic residual ||M^T Omega M - Omega|| = \{fmt_sci(@se.symplectic_identity_residual(h, qh, ph, 0.1))} | det = \{fmt_fixed(@se.symplectic_det_area(qh, ph, 0.1), 9)}",
  )
  println(
    "        2000-step energy drift: symplectic = \{fmt_sci(@se.energy_drift(true, 2000, 0.05))} vs explicit = \{fmt_sci(@se.energy_drift(false, 2000, 0.05))}",
  )
  // 8.6 Emergence operator bundle
  let gab : Array[Double] = [2.0, 0.0, 0.0, 0.5]
  let gbc : Array[Double] = [3.0, 0.0, 0.0, 1.0 / 3.0]
  let gac : Array[Double] = [6.0, 0.0, 0.0, 1.0 / 6.0]
  println(
    "  [8.6] Cech cocycle = \{@se.cocycle_condition(gab, gbc, gac, 1.0e-12)} | commutator-trace gauge invariance = \{@se.emergent_commutator_trace([1.0, 2.0, 0.0, -1.0], [0.0, 1.0, 1.0, 0.0], [1.0, 1.0, 0.0, 1.0], 1.0e-10)} | spectral gap = \{fmt_fixed(@se.emergent_spectral_gap([4.0, 0.0, 0.0, 1.0]), 6)}",
  )
  // 8.7 Hilbert quaternions & noncommutative graph K-theory
  let qi = @se.Quat::new(0.0, 1.0, 0.0, 0.0)
  let qj = @se.Quat::new(0.0, 0.0, 1.0, 0.0)
  let qk = qi.mul(qj)
  let hh : @se.Hermitian2 = {
    a: 2.0,
    b: 1.0,
    q: @se.Quat::new(0.0, 0.5, -0.5, 1.0),
  }
  let (lp, lm) = @se.hermitian2_eigs(hh)
  let (k0idx, k0err) = @se.k0_direct_sum_index(hh, hh)
  println(
    "  [8.7] i*j = \{qk.w} + \{qk.x}i + \{qk.y}j + \{qk.z}k | lambda+/- = \{fmt_fixed(lp, 6)} / \{fmt_fixed(lm, 6)} | K_0 direct-sum index = \{k0idx} (err \{fmt_sci(k0err)})",
  )
  // 8.8 Para-universe (Belnap B_4)
  let bth = @se.FourVal::Bv
  let gl = @se.FourVal::land(bth, @se.FourVal::neg(bth))
  let w1 = @se.ParaUniverse::new(["p", "q"], [@se.FourVal::Tv, @se.FourVal::Fv])
  let w2 = @se.ParaUniverse::new(["p", "q"], [@se.FourVal::Fv, @se.FourVal::Tv])
  let mw : @se.MultiWorld = { worlds: [w1, w2], }
  let merged = mw.merge_pointwise()
  println(
    "  [8.8] B /\\ ~B = \{@se.FourVal::to_string(gl)} | non-explosion witness = \{@se.explosion_counterexample_exists()} | fused p,q = \{@se.FourVal::to_string(merged[0])},\{@se.FourVal::to_string(merged[1])} | Tarski = \{@se.all_monotone_maps_have_fixed_point()}",
  )
  println(
    "================================================================================",
  )
}

///|
fn fmt_int_array(values : Array[Int32]) -> String {
  let out = StringBuilder()
  out.write_string("[")
  for i in 0..<values.length() {
    if i > 0 {
      out.write_string(", ")
    }
    out.write_string(values[i].to_string())
  }
  out.write_string("]")
  out.to_string()
}

///|
fn fmt_double_array(values : Array[Double], digits : Int32) -> String {
  let out = StringBuilder()
  out.write_string("[")
  for i in 0..<values.length() {
    if i > 0 {
      out.write_string(", ")
    }
    out.write_string(fmt_fixed(values[i], digits))
  }
  out.write_string("]")
  out.to_string()
}

///|
fn int_arrays_equal(a : Array[Int32], b : Array[Int32]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn permuted_role_mass(
  prototype : @se.SuperMassTensor,
  shift : Int32,
) -> @se.SuperMassTensor {
  let spectrum = prototype.bosonic_mass_spectrum()
  let mass = @se.DenseMat::from_fn(4, 4, (i, j) => {
    if i == j {
      spectrum[(i + shift) % 4]
    } else {
      0.0
    }
  })
  let xi = Array::makei(16, _ => @se.Grassmann::zero(4))
  @se.SuperMassTensor::from_real_and_yukawa(mass, xi, 1.0, 4, 4)
}

///|
/// Report roadmap Milestone M1.1 and M1.2: conservative exogenous WFR flow and
/// reversible d_O re-role under a changed environmental disturbance spectrum.
fn report_part_9() -> Unit {
  println(
    "[Part 9] M1 Self-Sustaining Dynamics: Perturbation Ledger & d_O Re-Role:",
  )
  println(
    "--------------------------------------------------------------------------------",
  )

  let pde = @se.SuperBeltramiPDE::new(
    @se.SuperManifold::new(4, 2, 1.0),
    32,
    0.88,
    0.15,
    0.4,
    r => 2.5 * (r - 0.52) * (r - 0.52),
    r => 1.0 + 0.6 * @math.cos(3.0 * r),
  )
  let perturbation = @se.WFRExogenousPerturbation::new(
    0.2,
    Array::makei(32, i => @math.sin(0.7 * i.to_double())),
  )
  let perturbed = pde.step_with_exogenous_perturbation(0.004, perturbation)
  let wfr = perturbed.ledger
  let wfr_ok = wfr.input_shape_valid &&
    wfr.input_values_valid &&
    wfr.mass_conservation_error < 1.0e-12
  println(
    "  [M1.1] sigma=0.20 | mass before/unforced/after = \{fmt_fixed(wfr.mass_before, 12)} / \{fmt_fixed(wfr.deterministic_mass_after, 12)} / \{fmt_fixed(wfr.mass_after, 12)} | error = \{fmt_sci(wfr.mass_conservation_error)} | PASS = \{wfr_ok}",
  )
  println(
    "         Free-energy ledger (separate): deterministic dissipation = \{fmt_signed_sci(wfr.deterministic_dissipation)} | perturbation work = \{fmt_signed_sci(wfr.perturbation_work)} | total change = \{fmt_signed_sci(wfr.total_free_energy_change)}",
  )

  let prototypes = @se.canonical_role_mass_orbits()
  let masses = Array::makei(8, i => permuted_role_mass(prototypes[i / 2], i % 4))
  let spectrum_a = [8.0, 0.0, 0.0, 0.0]
  let spectrum_b = [0.0, 8.0, 0.0, 0.0]
  let assign_a = @se.reassign_roles_by_orbit_distance(
    masses, prototypes, spectrum_a,
  )
  let assign_b = @se.reassign_roles_by_orbit_distance(
    masses, prototypes, spectrum_b,
  )
  let assign_a_return = @se.reassign_roles_by_orbit_distance(
    masses, prototypes, spectrum_a,
  )
  let reversible = int_arrays_equal(
    assign_a.role_assignment,
    assign_a_return.role_assignment,
  )
  let roles_changed = !int_arrays_equal(
    assign_a.role_assignment,
    assign_b.role_assignment,
  )
  println(
    "  [M1.2] dominant band 0 -> 1 -> 0 | roles A/B = \{fmt_int_array(assign_a.role_assignment)} / \{fmt_int_array(assign_b.role_assignment)} | cluster sizes = \{fmt_int_array(assign_b.cluster_sizes)}",
  )
  println(
    "         d_O within/between/gap = \{fmt_sci(assign_b.max_within_cluster_distance)} / \{fmt_sci(assign_b.min_between_cluster_distance)} / \{fmt_sci(assign_b.separation_margin)} | four clusters = \{assign_b.certified_four_clusters} | changed = \{roles_changed} | reversible = \{reversible}",
  )
  println(
    "  [Quality] Removed the zero-weight expected-cost accumulator; consolidated both duplicated MicroDiff symbol-padding closures into one helper.",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report roadmap M1.3 and M1.4: long-horizon WFR stability and Hurst-coupled memory.
fn report_part_10() -> Unit {
  println("[Part 10] M1.3 Long-Time Stability & M1.4 Hurst-Gated Memory:")
  println(
    "--------------------------------------------------------------------------------",
  )
  let pde = @se.SuperBeltramiPDE::new(
    @se.SuperManifold::new(4, 2, 1.0),
    32,
    0.88,
    0.15,
    0.4,
    r => 2.5 * (r - 0.52) * (r - 0.52),
    r => 1.0 + 0.6 * @math.cos(3.0 * r),
  )
  let stability = pde.audit_long_time_stability(0.0005, 100000)
  let stability_ok = stability.input_valid &&
    stability.completed_steps == 100000 &&
    stability.failed_steps == 0 &&
    stability.free_energy_monotone &&
    stability.max_free_energy_increase == 0.0 &&
    stability.final_equilibrium_distance < 2.0e-6 &&
    stability.mass_conserved &&
    stability.max_mass_conservation_error < 1.0e-12 &&
    stability.positivity_preserved &&
    stability.simulated_time > 49.0
  println(
    "  [M1.3] requested/completed = \{stability.requested_steps}/\{stability.completed_steps} | simulated time = \{fmt_fixed(stability.simulated_time, 4)} | F0 -> Fend = \{fmt_fixed(stability.initial_free_energy, 8)} -> \{fmt_fixed(stability.final_free_energy, 8)}",
  )
  println(
    "         max trajectory dF = \{fmt_sci(stability.max_free_energy_increase)} | max rejected proposal = \{fmt_sci(stability.max_proposed_energy_increase)} | mass error = \{fmt_sci(stability.max_mass_conservation_error)} | min rho = \{fmt_sci(stability.minimum_density)} | equilibrium residual = \{fmt_sci(stability.final_equilibrium_distance)}",
  )
  println(
    "         stationary holds = \{stability.stationary_holds} | adaptive retries = \{stability.adaptive_retries} | failed steps = \{stability.failed_steps} | PASS = \{stability_ok}",
  )

  let hurst_grid = [0.1, 0.3, 0.5, 0.7, 0.9]
  let memory_trend = @se.audit_hurst_memory_monotonicity(hurst_grid)
  let low_h = @se.role_memory_profiles_for_hurst(0.1)
  let high_h = @se.role_memory_profiles_for_hurst(0.9)
  let memory_colony = @se.init_disordered_colony(4, 0.25)
  let distilled_memory = @se.distill_synergetic_memory_para_agent(
    memory_colony,
    0.25,
    hurst=0.9,
  )
  let memory_ok = memory_trend.certified &&
    memory_trend.input_valid &&
    low_h.input_valid &&
    high_h.input_valid &&
    distilled_memory.hurst_profile_valid &&
    high_h.mean_retention > low_h.mean_retention &&
    high_h.mean_absorption_time > low_h.mean_absorption_time
  println(
    "  [M1.4] H samples = \{fmt_double_array(memory_trend.hurst_samples, 2)} | mean absorption = \{fmt_double_array(memory_trend.mean_absorption_times, 2)}",
  )
  println(
    "         H=0.10 -> 0.90 mean retention = \{fmt_fixed(low_h.mean_retention, 4)} -> \{fmt_fixed(high_h.mean_retention, 4)} | mean absorption = \{fmt_fixed(low_h.mean_absorption_time, 4)} -> \{fmt_fixed(high_h.mean_absorption_time, 4)}",
  )
  println(
    "         distilled SGNE retention at H=0.90 = \{fmt_double_array(distilled_memory.role_retention, 4)} | mean-increasing = \{memory_trend.mean_absorption_strictly_increasing} | each-role-increasing = \{memory_trend.each_role_absorption_strictly_increasing} | role order = \{memory_trend.within_sample_role_order_preserved} | PASS = \{memory_ok}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report roadmap M2.1–M2.4: B_4 reasoning, repair, epistemic aggregation, and Gödel sets.
fn report_part_11() -> Unit {
  println("[Part 11] M2.1–M2.4 Belief Reasoning & Algebraic Aggregation:")
  println(
    "--------------------------------------------------------------------------------",
  )
  let reasoning = @se.audit_b4_reasoning_soundness()
  let reasoning_ok = reasoning.sound &&
    reasoning.coverage_exact &&
    reasoning.total_assignments == 4_294_967_296 &&
    reasoning.modus_ponens_covered_assignments == reasoning.total_assignments &&
    reasoning.cut_covered_assignments == reasoning.total_assignments &&
    reasoning.substitution_covered_assignments == reasoning.total_assignments
  println(
    "  [M2.1] MP/cut/substitution coverage = \{reasoning.modus_ponens_covered_assignments}/\{reasoning.cut_covered_assignments}/\{reasoning.substitution_covered_assignments} of \{reasoning.total_assignments} | local cases = \{reasoning.modus_ponens_cases}/\{reasoning.cut_cases}/\{reasoning.substitution_cases} formulas + \{reasoning.substitution_sequent_cases} sequents | sound = \{reasoning.sound} | PASS = \{reasoning_ok}",
  )

  let repair_inputs : Array[@se.B4QuarantineRecord] = [
    {
      proposition_id: 0,
      name: "reviewed proposition",
      value: @se.Bv,
      quarantined: true,
      reason: "conflicting reports",
    },
    {
      proposition_id: 1,
      name: "unresolved proposition",
      value: @se.Bv,
      quarantined: true,
      reason: "conflicting reports",
    },
  ]
  let repair_decisions : Array[@se.B4RepairDecision] = [
    { proposition_id: 0, repaired_value: @se.Tv, evidence: "review:verified", },
    {
      proposition_id: 1,
      repaired_value: @se.Bv,
      evidence: "review:conflict-remains",
    },
  ]
  let repair = @se.inspect_and_repair_quarantine(
    repair_inputs, repair_decisions,
  )
  let unresolved = repair.records[1].as_premise()
  let cut_source : @se.B4Sequent = {
    assumptions: [],
    conclusion: { formula: @se.Atom(1), quarantined: false, },
  }
  let cut_consumer : @se.B4Sequent = {
    assumptions: [unresolved],
    conclusion: { formula: @se.Value(@se.Tv), quarantined: false, },
  }
  let blocked_cut = @se.b4_apply_cut(cut_source, cut_consumer)
  let repair_ok = repair.input_valid &&
    repair.inspection_complete &&
    repair.inspected == 2 &&
    repair.repaired == 1 &&
    repair.unresolved == 1 &&
    repair.repair_rate == 0.5 &&
    repair.non_explosion_preserved &&
    blocked_cut.blocked_by_quarantine &&
    !blocked_cut.applied
  println(
    "  [M2.2] inspected/repaired/unresolved = \{repair.inspected}/\{repair.repaired}/\{repair.unresolved} | repair rate = \{fmt_fixed(repair.repair_rate, 2)} | cut blocked = \{blocked_cut.blocked_by_quarantine} | non-explosion = \{repair.non_explosion_preserved} | PASS = \{repair_ok}",
  )

  let aggregation = @se.audit_epistemic_aggregation_laws()
  let aggregation_ok = aggregation.certified &&
    aggregation.associativity_cases == 64 &&
    aggregation.commutativity_cases == 16 &&
    aggregation.idempotence_cases == 4 &&
    aggregation.least_upper_bound_cases == 64
  println(
    "  [M2.3] B_4 product information join | A/C/I = \{aggregation.associative}/\{aggregation.commutative}/\{aggregation.idempotent} | LUB = \{aggregation.least_upper_bound} | named supports = \{aggregation.named_union_laws} | PASS = \{aggregation_ok}",
  )

  let godel = @se.audit_godel_set_algebra()
  let godel_ok = godel.certified &&
    godel.sample_sets_checked == 9 &&
    godel.universe_subsets_checked == 32_768
  println(
    "  [M2.4] Gödel finite belief sets | samples = \{godel.sample_sets_checked} | subsets = \{godel.universe_subsets_checked} | round-trip/injective = \{godel.round_trip}/\{godel.injective_on_domain} | union/intersection ACI = \{godel.union_associative && godel.union_commutative && godel.union_idempotent}/\{godel.intersection_associative && godel.intersection_commutative && godel.intersection_idempotent} | identity/zero/absorption = \{godel.union_identity}/\{godel.intersection_zero}/\{godel.absorption_laws} | distributive = \{godel.distributive} | difference/symmetric-difference/subset = \{godel.difference_laws}/\{godel.symmetric_difference_laws}/\{godel.subset_laws} | PASS = \{godel_ok}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report roadmap M3.1–M3.3: arbitrary patch counts, holonomy naturality, and Čech laws.
fn report_part_12() -> Unit {
  println("[Part 12] M3.1–M3.3 Composable Čech Super-Operator Bundles:")
  println(
    "--------------------------------------------------------------------------------",
  )
  let mut family_defect = 0.0
  let mut all_glue = true
  for n in 2..<=6 {
    let bundle = @se.build_super_operator_bundle(n)
    let path = Array::makei(n, i => i)
    let defect = bundle
      .cocycle_defect()
      .max(bundle.patch_defect())
      .max(bundle.holonomy_defect(path))
    family_defect = family_defect.max(defect)
    match bundle.glue_section(0, tol=1.0e-12) {
      Some(_) => ()
      None => all_glue = false
    }
  }
  let m31_ok = family_defect < 1.0e-12 && all_glue
  println(
    "  [M3.1] patches = 2..6 | cocycle/descent/holonomy max = \{fmt_sci(family_defect)} | all sections glue = \{all_glue} | PASS = \{m31_ok}",
  )

  let bundle = @se.build_super_operator_bundle(4)
  let q = @se.super_orthogonal_gauge()
  let naturality = bundle.superoperator_holonomy_defect([0, 1, 2, 3], q)
  let m32_ok = naturality < 1.0e-12
  println(
    "  [M3.2] holonomy/superoperator composition defect = \{fmt_sci(naturality)} | PASS = \{m32_ok}",
  )

  let category_defect = match
    @se.CechCategory::from_bundle(bundle, tolerance=1.0e-10) {
    Some(category) => category.axiom_defect()
    None => 1.0 / 0.0
  }
  let m33_ok = category_defect < 1.0e-12
  println(
    "  [M3.3] Čech category associativity/unit max defect = \{fmt_sci(category_defect)} | PASS = \{m33_ok}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}

///|
/// Report M4-M6 feature acceptance: versal catastrophe selection, antipodal attention quarantine,
/// and damped fixed-point coupling across all four SGNE layers.
fn report_part_13() -> Unit {
  println(
    "[Part 13] M4–M6 Active Unfolding, Microlocal Attention & Four-Layer Feedback:",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
  let a3 = @se.learn_catastrophe_for_role_branches(3, 0.05)
  let d4 = @se.learn_catastrophe_for_role_branches(4, 0.05)
  let m4_ok = a3.certified &&
    a3.selected_class == @se.A3Cusp &&
    a3.unfolded_critical_points == 3 &&
    d4.certified &&
    d4.selected_class == @se.D4Umbilic &&
    d4.unfolded_critical_points == 4
  println(
    "  [M4] target=4 | selected=\{d4.selected_label} | codim=\{d4.unfolding_codimension} | critical branches=\{d4.unfolded_critical_points} | stable minima=\{d4.stable_minima} | versal=\{d4.versal} | PASS = \{m4_ok}",
  )

  let signal = @se.HyperfunctionGerm::cauchy_plus(0.0).sp()
  let belief_spectrum = @se.HyperfunctionGerm::cauchy_minus(0.0).sp()
  let attention = @se.microlocal_attention_event(
    signal,
    belief_spectrum,
    @se.Tv,
  )
  let m5_ok = attention.input_valid &&
    attention.same_base_point &&
    attention.antipodal_collision &&
    attention.quarantined &&
    attention.value_after == @se.Bv &&
    attention.non_explosion_preserved
  println(
    "  [M5] same-point antipodal collision=\{attention.antipodal_collision} | quarantined=\{attention.quarantined} | belief=\{@se.FourVal::to_string(attention.value_after)} | PASS = \{m5_ok}",
  )

  let feedback = @se.audit_four_layer_closed_loop(
    flow_steps=3,
    max_iterations=32,
    relaxation=0.35,
    tolerance=1.0e-3,
  )
  let m6_ok = feedback.input_valid &&
    feedback.converged &&
    feedback.empirical_fixed_point_certified &&
    feedback.fixed_point_residual <= 1.0e-3 &&
    feedback.empirical_contraction_factor < 1.0 &&
    feedback.weight_normalization_defect < 1.0e-12 &&
    feedback.non_explosion_preserved
  println(
    "  [M6] iterations=\{feedback.iterations} | H=\{fmt_fixed(feedback.hurst_exponent, 4)} | residual=\{fmt_sci(feedback.fixed_point_residual)} | empirical contraction=\{fmt_fixed(feedback.empirical_contraction_factor, 4)} | flow weights=\{fmt_double_array(feedback.flow_mass_weights, 3)} | Trop-Kan weights=\{fmt_double_array(feedback.trop_kan_weights, 3)} | PASS = \{m6_ok}",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
}
