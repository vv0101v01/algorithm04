///|
/// Module 8: Natural Gradient & Fisher Information Metric (自然梯度與費雪資訊度量).
/// Implements:
///   1. Categorical / Boltzmann exponential-family policy manifold Delta^{K-1} with
///      exact Fisher-Rao matrix F_{ij}(eta) = p_i delta_{ij} - p_i p_j, KL divergence
///      D_KL(p || q), and second-order Taylor law D_KL(p_eta || p_{eta+d}) = (1/2) d^T F d,
///   2. Gaussian belief manifold N(mu, sigma^2) and its EXACT Cayley isometry onto the
///      Poincare hyperbolic disk B_{1/2}^2 (Theorem V: Fisher-Poincare Isometry),
///   3. Bures-Helstrom Quantum/Fermionic Fisher Information Metric via Symmetric
///      Logarithmic Derivative (SLD) Lyapunov equation (1/2)(rho L + L rho) = d rho
///      composed directly with Module 4's Sylvester solver,
///   4. Amari's Natural Gradient F^{-1} grad L with exact diffeomorphism covariance
///      verification J * natgrad_xi L == natgrad_theta L, KL trust-region optimality,
///      and Cramer-Rao covariance bound verification.

///|
/// Softmax mapping natural parameters eta in R^{K-1} (with gauge eta_{K-1} = 0)
/// to full simplex probabilities p in Delta^{K-1}.
pub fn categorical_probs(eta : Array[Double]) -> Array[Double] {
  let n = eta.length()
  softmax_vec(Array::makei(n + 1, i => if i < n { eta[i] } else { 0.0 }))
}

///|
/// Exact Fisher-Rao Information Matrix F(eta) on the categorical manifold Delta^{K-1}
/// in minimal natural coordinates eta in R^{K-1}:
///   F_{ij}(eta) = E_p[ d_i log p * d_j log p ] = p_i delta_{ij} - p_i p_j  (SPD!).
pub fn categorical_fisher_matrix(eta : Array[Double]) -> DenseMat {
  let d = eta.length()
  let p = categorical_probs(eta)
  DenseMat::from_fn(d, d, (i, j) => {
    let diag = if i == j { p[i] } else { 0.0 }
    diag - p[i] * p[j]
  })
}

///|
/// Kullback-Leibler divergence D_KL(p || q) = sum_i p_i ln(p_i / q_i) >= 0.
pub fn kl_divergence(p : Array[Double], q : Array[Double]) -> Double {
  let mut s = 0.0
  for i in 0..<p.length() {
    if p[i] > 1.0e-15 {
      s = s + p[i] * @math.ln(p[i] / q[i].max(1.0e-15))
    }
  }
  s.max(0.0)
}

///|
/// Exact Fisher-Rao metric of the Gaussian belief manifold N(mu, sigma^2) (sigma > 0):
///   F(mu, sigma) = [[ 1 / sigma^2, 0 ], [ 0, 2 / sigma^2 ]],
/// possessing constant negative Gaussian curvature K = -1/2!
pub fn gaussian_fisher_matrix(mu : Double, sigma : Double) -> DenseMat {
  let _ = mu
  let inv_s2 = 1.0 / (sigma * sigma)
  let f = DenseMat::zeros(2, 2)
  f.set(0, 0, inv_s2)
  f.set(1, 1, 2.0 * inv_s2)
  f
}

///|
/// Exact Cayley Isometry Phi : N(mu, sigma^2) -> B_{1/2}^2 (Theorem V):
///   1. Map (mu, sigma) to upper half-plane w = u + i v with u = mu / sqrt(2), v = sigma > 0,
///   2. Apply conformal Cayley map z = (w - i) / (w + i) in unit disk B_1^2,
///   3. Rescale x = sqrt(2) * z in B_{1/2}^2 (radius < sqrt(2), curvature K = -1/2).
/// Guarantees EXACT global geodesic & infinitesimal metric isometry:
///   d_{Fisher}(N(mu_1, s_1^2), N(mu_2, s_2^2)) == d_{B_{1/2}^2}(Phi(mu_1, s_1), Phi(mu_2, s_2))
///   AND  (D Phi)^T * g_{B_{1/2}^2}(Phi(mu, s)) * (D Phi) == F(mu, s)!
pub fn gaussian_to_poincare_isometry(
  mu : Double,
  sigma : Double,
) -> PoincarePoint {
  let s2 = (2.0 : Double).sqrt()
  let u = mu / s2
  let v = sigma
  let denom = u * u + (v + 1.0) * (v + 1.0)
  // (u + i(v-1))(u - i(v+1)) = (u^2 + v^2 - 1) + i(-2u)
  let z_re = (u * u + v * v - 1.0) / denom
  let z_im = -2.0 * u / denom
  PoincarePoint::new(0.5, [s2 * z_re, s2 * z_im])
}

///|
/// Closed-form Fisher-Rao geodesic distance between two univariate Gaussians
/// N(mu_1, sigma_1^2) and N(mu_2, sigma_2^2):
///   d_FR = sqrt(2) * acosh(1 + ((mu_1 - mu_2)^2 + 2(sigma_1 - sigma_2)^2) / (4 sigma_1 sigma_2)).
pub fn gaussian_fisher_distance(
  mu1 : Double,
  sigma1 : Double,
  mu2 : Double,
  sigma2 : Double,
) -> Double {
  let dmu = mu1 - mu2
  let dsig = sigma1 - sigma2
  let arg = 1.0 + (dmu * dmu + 2.0 * dsig * dsig) / (4.0 * sigma1 * sigma2)
  (2.0 : Double).sqrt() * @math.acosh(arg.max(1.0))
}

///|
/// Pullback of the Poincare B_{1/2}^2 Riemannian metric via Jacobian of Phi,
/// verifying || J^T g_{B_{1/2}^2} J - F(mu, sigma) ||_F ~ 0!
pub fn gaussian_poincare_pullback_metric(
  mu : Double,
  sigma : Double,
  eps~ : Double = 1.0e-6,
) -> DenseMat {
  let g_poinc = gaussian_to_poincare_isometry(mu, sigma).metric_matrix()
  let jac = numerical_jacobian(
    v => gaussian_to_poincare_isometry(v[0], v[1]).coords,
    [mu, sigma],
    eps~,
  )
  jac.transpose() * g_poinc * jac
}

///|
/// Symmetric Logarithmic Derivative (SLD) L solving the anti-commutator Lyapunov equation:
///   (1/2) (rho * L + L * rho) = d_rho
/// for an SPD density matrix rho (Tr(rho) = 1, rho > 0), solved via Module 4's Sylvester solver!
pub fn symmetric_log_derivative(rho : DenseMat, d_rho : DenseMat) -> DenseMat {
  solve_sylvester(rho.scale(0.5), rho.scale(0.5), d_rho, sign=1.0)
}

///|
/// Bures-Helstrom Quantum/Noncommutative Fisher Information Matrix:
///   F^Q_{ab}(rho) = (1/2) Tr(rho * (L_a L_b + L_b L_a)) = Tr(d_a rho * L_b),
/// governing the noncommutative fermionic/operator sector of Super-Fisher geometry!
pub fn quantum_bures_fisher_matrix(
  rho : DenseMat,
  d_rhos : Array[DenseMat],
) -> DenseMat {
  let p = d_rhos.length()
  let slds = d_rhos.map(dr => symmetric_log_derivative(rho, dr))
  DenseMat::from_fn(p, p, (a, b) => (d_rhos[a] * slds[b]).trace())
}

///|
/// Composite Super-Fisher Information Matrix F_super = diag(F_bos, F_quantum)
/// equipping a hybrid belief-and-operator agent manifold with unified information geometry.
pub fn super_fisher_matrix(
  eta_bos : Array[Double],
  rho_op : DenseMat,
  d_rhos : Array[DenseMat],
) -> DenseMat {
  let fb = categorical_fisher_matrix(eta_bos)
  let fq = quantum_bures_fisher_matrix(rho_op, d_rhos)
  let nb = fb.rows
  let nq = fq.rows
  let tot = nb + nq
  let out = DenseMat::zeros(tot, tot)
  for i in 0..<nb {
    for j in 0..<nb {
      out.set(i, j, fb.get(i, j))
    }
  }
  for i in 0..<nq {
    for j in 0..<nq {
      out.set(nb + i, nb + j, fq.get(i, j))
    }
  }
  out
}

///|
/// Amari's Natural Gradient natgrad L(theta) = (F(theta) + damping * I)^{-1} grad L(theta).
/// Represents the steepest ascent/descent direction on the statistical manifold under
/// the infinitesimal KL / Bures trust region (1/2) dtheta^T F(theta) dtheta <= eps^2!
pub fn natural_gradient(
  fisher : DenseMat,
  euclid_grad : Array[Double],
  damping~ : Double = 0.0,
) -> Array[Double] {
  let n = fisher.rows
  let reg = if damping > 0.0 {
    fisher + DenseMat::eye(n).scale(damping)
  } else {
    fisher
  }
  reg.solve_vec(euclid_grad)
}

///|
/// Trust-region normalized natural gradient step minimizing L(theta + delta)
/// subject to D_KL(p_theta || p_{theta + delta}) <= kl_radius:
///   delta* = - sqrt(2 * kl_radius / (g^T F^{-1} g)) * F^{-1} g
/// (returns zero step cleanly at stationary points instead of amplifying float noise).
pub fn natural_gradient_kl_step(
  fisher : DenseMat,
  euclid_grad : Array[Double],
  kl_radius : Double,
  damping~ : Double = 1.0e-8,
) -> Array[Double] {
  let ng = natural_gradient(fisher, euclid_grad, damping~)
  let fisher_norm_sq = vec_dot(euclid_grad, ng)
  if fisher_norm_sq <= 1.0e-24 || kl_radius <= 0.0 {
    return Array::make(euclid_grad.length(), 0.0)
  }
  vec_scale(ng, -(2.0 * kl_radius / fisher_norm_sq).sqrt())
}

///|
/// Verify Amari's Reparameterization Covariance Theorem under a smooth coordinate
/// diffeomorphism theta = phi(xi):
///   || J(xi) * natgrad_xi(L o phi) - natgrad_theta(L) ||_2 == 0,
/// contrasted with Euclidean gradient non-covariance || J(xi) * grad_xi(L o phi) - grad_theta(L) ||_2 > 0!
pub fn verify_natural_gradient_covariance(
  xi : Array[Double],
  phi : (Array[Double]) -> Array[Double],
  loss_theta : (Array[Double]) -> Double,
  eps~ : Double = 1.0e-6,
) -> (Double, Double) {
  let theta = phi(xi)
  let f_theta = categorical_fisher_matrix(theta)
  let jac = numerical_jacobian(phi, xi, eps~)
  let grad_theta = numerical_grad(loss_theta, theta, eps~)
  let grad_xi = numerical_grad(v => loss_theta(phi(v)), xi, eps~)
  let f_xi = jac.transpose() * f_theta * jac
  let nat_theta = natural_gradient(f_theta, grad_theta)
  let nat_xi = natural_gradient(f_xi, grad_xi)
  (
    vec_norm(vec_sub(jac.matvec(nat_xi), nat_theta)),
    vec_norm(vec_sub(jac.matvec(grad_xi), grad_theta)),
  )
}

///|
/// Compare convergence of Fisher-Rao Natural Gradient Descent vs Euclidean Gradient
/// Descent on minimizing KL divergence D_KL(p* || p_eta) (equivalently expected agent
/// surprise / variational free energy). Returns (final_kl_natural, final_kl_euclidean).
pub fn compare_natural_vs_euclidean_kl(
  target_probs : Array[Double],
  init_eta : Array[Double],
  steps : Int32,
  lr : Double,
) -> (Double, Double) {
  let d = init_eta.length()
  let mut eta_nat = init_eta.copy()
  let mut eta_euc = init_eta.copy()
  // Exact gradient of L(eta) = D_KL(p* || p_eta) wrt eta_i is p_i(eta) - p*_i!
  for _ in 0..<steps {
    let pn = categorical_probs(eta_nat)
    let gn = Array::makei(d, i => pn[i] - target_probs[i])
    let fn_mat = categorical_fisher_matrix(eta_nat)
    let ng = natural_gradient(fn_mat, gn, damping=1.0e-6)
    eta_nat = vec_sub(eta_nat, vec_scale(ng, lr))
    let pe = categorical_probs(eta_euc)
    let ge = Array::makei(d, i => pe[i] - target_probs[i])
    eta_euc = vec_sub(eta_euc, vec_scale(ge, lr))
  }
  let kl_nat = kl_divergence(target_probs, categorical_probs(eta_nat))
  let kl_euc = kl_divergence(target_probs, categorical_probs(eta_euc))
  (kl_nat, kl_euc)
}
