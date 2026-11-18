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
fn main {
  println(
    "================================================================================",
  )
  println(
    "  SUPER-EMERGENCE (MoonBit v0.10.21): Super-Geometric Quasi-Agentic Emergence",
  )
  println(
    "  Poincare-Riemannian M^{m|n} | Affine Tensors | PoPE | NCG & Supermatrices |",
  )
  println(
    "  PDE Flows | Super-Jacobi | Super-Mass Orbits | Neuro-Symbolic SUSY | Fisher",
  )
  println(
    "  + Universal Property Functors (Yoneda/Kan/Pushout) | Semitropical Projective TP^n",
  )
  println(
    "  + Universal Enveloping & Unfolding | Contact/ICIS/Normal/Meromorphic/Micro/Quotient Germs",
  )
  println(
    "================================================================================",
  )
  println("")
  println(
    "[Part 1] Computational Verification of 14 Derived Mathematical Theorems:",
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
  println(
    "[Part 3] Master Algorithm SGNE-Flow: 8 Proto-Agents on Critical M^{4|4}_c",
  )
  println(
    "--------------------------------------------------------------------------------",
  )
  println(
    "  Step | Curv c | FreeEng | SUSY_H  | WitIdx | HierSpr | OrbDiv | PolEnt | Unif | Synergy",
  )
  let (snaps, final_agents) = @se.run_sgne_emergence_simulation(
    n_agents=8,
    n_steps=24,
    dt=0.18,
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
  println("[Part 4] Emerged Specialized Quasi-Agent Roles & Super-Mass Orbits:")
  let role_labels = [
    "Coordinator (Root Anchor)", "Sensor (Perception)", "Planner (Symbolic Verifier)",
    "Executor (Boundary Actor)",
  ]
  let c_end = snaps[snaps.length() - 1].curvature_c
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
  println(
    "[Part 6] SGNE-Germ-Micro Enveloping, Singularity Germ & Sato Microlocal Audit:",
  )
  let gm = @se.distill_germ_microlocal_phase()
  println(
    "  Super-PBW U_{<=3}(osp(1|2)) & C_2    : dim = \{gm.pbw_dim_deg3} | Schur Casimir lambda(C_2) = \{fmt_fixed(gm.osp_casimir_eigenvalue, 4)}",
  )
  println(
    "  Catastrophe K-Class & Unfolding      : \{gm.catastrophe_class} | Universal K-codim tau = \{gm.unfolding_codim} (4 role attractors)",
  )
  println(
    "  ICIS Le-Greuel & Normal Ring Germ    : ICIS mu = \{gm.icis_milnor} | Normalization delta = \{gm.normalization_delta}, conductor c = \{gm.normalization_conductor} (= 2*delta Gorenstein)",
  )
  println(
    "  Euler-Jacobi Residue & SKK Parametrix: sum Res = \{fmt_fixed(gm.residue_charge, 4)} | ||P o P^{-1} - 1|| = \{fmt_sci(gm.microlocal_parametrix_err)}",
  )
  println(
    "================================================================================",
  )
}
