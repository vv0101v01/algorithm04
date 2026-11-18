///|
/// Module 3: PoPE Positional Encoding Function (PoPE 位置編碼函數).
/// Implements:
///   1. Polar Coordinate Positional Embedding (PoPE, Gopalakrishnan et al. 2025,
///      arXiv:2509.10534): q~_{tc} = softplus(q_{tc}) exp(i t theta_c),
///      k~_{sc} = softplus(k_{sc}) exp(i (s theta_c + delta_c)),
///      a^{PoPE}_{ts} = Re(q~_t^H k~_s) = sum_{c=1}^d mu_{q,tc} mu_{k,sc} cos((s-t)theta_c + delta_c).
///   2. Rotary Positional Embedding (RoPE) baseline and exact What-Where Jacobian
///      decoupling diagnostic + Bochner positive-semidefiniteness verification.
///   3. Super-PoPE on the Poincare-Riemannian Supermanifold M^{m|2k}_c: lifts content
///      magnitudes to hyperbolic geodesic log-maps log_0^c(x_t) weighted by conformal
///      hierarchy depth, phases to U(1)^m characters, and odd spinors to symplectic
///      Pauli-complementary Grassmann couplings (Theorem II).

///|
/// Numerically stable softplus activation sigma(x) = ln(1 + exp(x)) > 0.
pub fn softplus(x : Double) -> Double {
  if x > 20.0 {
    x + @math.ln_1p(@math.exp(-x))
  } else if x < -20.0 {
    @math.exp(x)
  } else {
    @math.ln_1p(@math.exp(x))
  }
}

///|
/// Derivative of softplus: logistic sigmoid sigma'(x) = 1 / (1 + exp(-x)).
pub fn sigmoid(x : Double) -> Double {
  if x >= 0.0 {
    1.0 / (1.0 + @math.exp(-x))
  } else {
    let ex = @math.exp(x)
    ex / (1.0 + ex)
  }
}

///|
/// PoPE configuration over `dim` polar frequency channels U(1)^dim.
/// `freqs[c] = base^{-(c / dim)}` (full d frequencies — 2x frequency resolution vs RoPE);
/// `delta[c]` learnable relative-phase bias clamped to [-2*pi, 0].
#derive(Debug, Eq)
pub(all) struct PoPEConfig {
  dim : Int32
  base : Double
  freqs : Array[Double]
  delta : Array[Double]
}

///|
pub fn PoPEConfig::new(
  dim : Int32,
  base~ : Double = 10000.0,
  delta~ : Array[Double] = [],
) -> PoPEConfig {
  let d_f = dim.to_double()
  let freqs = Array::makei(dim, c => @math.pow(base, -c.to_double() / d_f))
  let two_pi = 2.0 * @math.PI
  let clamped_delta = Array::makei(dim, c => {
    if c < delta.length() {
      delta[c].clamp(min=-two_pi, max=0.0)
    } else {
      0.0
    }
  })
  { dim, base, freqs, delta: clamped_delta, }
}

///|
/// Encode query q_t in R^d at continuous or discrete position t into C^d:
///   q~_{tc} = softplus(q_{tc}) * exp(i * t * theta_c).
pub fn PoPEConfig::encode_query(
  self : PoPEConfig,
  q : Array[Double],
  pos_t : Double,
) -> Array[Complex] {
  Array::makei(self.dim, c => {
    let mu = softplus(q[c])
    let phi = pos_t * self.freqs[c]
    Complex::from_polar(mu, phi)
  })
}

///|
/// Encode key k_s in R^d at position s into C^d with bounded phase offset delta_c in [-2pi, 0]:
///   k~_{sc} = softplus(k_{sc}) * exp(i * (s * theta_c + delta_c)).
pub fn PoPEConfig::encode_key(
  self : PoPEConfig,
  k : Array[Double],
  pos_s : Double,
) -> Array[Complex] {
  Array::makei(self.dim, c => {
    let mu = softplus(k[c])
    let phi = pos_s * self.freqs[c] + self.delta[c]
    Complex::from_polar(mu, phi)
  })
}

///|
/// PoPE Hermitian real-part attention score a^{PoPE}_{ts} = Re(q~_t^H k~_s).
pub fn PoPEConfig::score_from_complex(
  q_tilde : Array[Complex],
  k_tilde : Array[Complex],
) -> Double {
  let mut acc = 0.0
  for c in 0..<q_tilde.length() {
    acc = acc + Complex::hermitian_dot(q_tilde[c], k_tilde[c]).re
  }
  acc
}

///|
/// Closed-form polar PoPE attention score (Eq. 6 of Gopalakrishnan et al. 2025):
///   a^{PoPE}_{ts} = sum_{c=0}^{d-1} softplus(q_c) softplus(k_c) cos((s - t) theta_c + delta_c).
pub fn PoPEConfig::attention_score(
  self : PoPEConfig,
  q : Array[Double],
  pos_t : Double,
  k : Array[Double],
  pos_s : Double,
) -> Double {
  let dt = pos_s - pos_t
  let mut acc = 0.0
  for c in 0..<self.dim {
    let mu_q = softplus(q[c])
    let mu_k = softplus(k[c])
    acc = acc + mu_q * mu_k * @math.cos(dt * self.freqs[c] + self.delta[c])
  }
  acc
}

///|
/// Standard RoPE attention score (Su et al. 2024) for quantitative comparison:
///   a^{RoPE}_{ts} = sum_{c=0}^{d/2-1} mu_{q,c} mu_{k,c} cos((s - t) theta_c + phi_{k,c} - phi_{q,c}),
/// exhibiting the phi_{k,c} - phi_{q,c} What-Where entanglement term.
pub fn rope_attention_score(
  q : Array[Double],
  pos_t : Double,
  k : Array[Double],
  pos_s : Double,
  base~ : Double = 10000.0,
) -> Double {
  let half = q.length() / 2
  let d_f = q.length().to_double()
  let dt = pos_s - pos_t
  let mut acc = 0.0
  for c in 0..<half {
    let theta_c = @math.pow(base, -2.0 * c.to_double() / d_f)
    let angle = dt * theta_c
    let ca = @math.cos(angle)
    let sa = @math.sin(angle)
    let q0 = q[2 * c]
    let q1 = q[2 * c + 1]
    let k0 = k[2 * c]
    let k1 = k[2 * c + 1]
    // q^T R((s - t) theta_c) k
    acc = acc + q0 * (ca * k0 - sa * k1) + q1 * (sa * k0 + ca * k1)
  }
  acc
}

///|
/// Measure the What-Where phase entanglement norm || d(Delta*_{ts}) / dq ||_2,
/// where Delta*_{ts}(q, k) = argmax_{Delta = s - t} a_c(q, k; Delta) is the peak relative offset.
/// For PoPE: Delta*_c = -delta_c / theta_c (strictly independent of q and k => entanglement == 0!).
/// For RoPE: Delta*_c = (phi_{q,c} - phi_{k,c}) / theta_c (depends strongly on q and k => > 0!).
pub fn what_where_entanglement_norms(
  config : PoPEConfig,
  q : Array[Double],
) -> (Double, Double) {
  let eps = 1.0e-5
  // PoPE phase of encoded query channel c is t * theta_c (content-independent)
  let mut pope_grad_sq = 0.0
  let pos_t = 3.0
  let base_enc = config.encode_query(q, pos_t)
  for c in 0..<config.dim {
    let qp = q.copy()
    qp[c] = qp[c] + eps
    let enc_p = config.encode_query(qp, pos_t)
    let dphi = (enc_p[c].phase() - base_enc[c].phase()) / eps
    pope_grad_sq = pope_grad_sq + dphi * dphi
  }
  // RoPE phase of pair c is t * theta_c + atan2(q_{2c+1}, q_{2c})
  let mut rope_grad_sq = 0.0
  let half = q.length() / 2
  for c in 0..<half {
    let r2 = q[2 * c] * q[2 * c] + q[2 * c + 1] * q[2 * c + 1]
    if r2 > 1.0e-18 {
      // || grad_{(q0, q1)} atan2(q1, q0) ||^2 = 1 / r^2
      rope_grad_sq = rope_grad_sq + 1.0 / r2
    }
  }
  (pope_grad_sq.sqrt(), rope_grad_sq.sqrt())
}

///|
/// Construct the PoPE Gram/Mercer kernel matrix K_{ab} = a^{PoPE}(x_a, t_a; x_b, t_b)
/// with delta = 0. By Theorem II (Bochner PSD property), K = Re(Z^H Z) >= 0 always!
pub fn PoPEConfig::kernel_gram_matrix(
  self : PoPEConfig,
  features : Array[Array[Double]],
  positions : Array[Double],
) -> DenseMat {
  let zero_bias = PoPEConfig::new(self.dim, base=self.base)
  let n = features.length()
  let encoded = Array::makei(n, i => {
    zero_bias.encode_query(features[i], positions[i])
  })
  DenseMat::from_fn(n, n, (i, j) => {
    PoPEConfig::score_from_complex(encoded[i], encoded[j])
  })
}

///|
/// Gradient of PoPE attention score with respect to the learnable bias delta_c:
///   da^{PoPE}_{ts} / d(delta_c) = -mu_{q,tc} * mu_{k,sc} * sin((s - t) theta_c + delta_c).
pub fn PoPEConfig::grad_delta(
  self : PoPEConfig,
  q : Array[Double],
  pos_t : Double,
  k : Array[Double],
  pos_s : Double,
) -> Array[Double] {
  let dt = pos_s - pos_t
  Array::makei(self.dim, c => {
    -softplus(q[c]) *
    softplus(k[c]) *
    @math.sin(dt * self.freqs[c] + self.delta[c])
  })
}

///|
/// Super-PoPE attention score between two superpoints z_t, z_s on M^{m|2k}_c
/// at spatiotemporal/topological coordinates pos_t, pos_s:
///   A^{SPoPE}(z_t, t; z_s, s) = sum_{c=1}^m sigma(u^c(z_t)) sigma(u^c(z_s)) cos((s - t) theta_c + delta_c)
///                              + alpha_ferm * <xi_t, J xi_s> * cos((s - t) omega_F),
/// returning an even Grassmann supernumber whose body governs macro-attention and whose
/// soul encodes anti-commuting Pauli-complementary symbolic resonance!
pub fn super_pope_score(
  config : PoPEConfig,
  z_t : SuperPoint,
  pos_t : Double,
  z_s : SuperPoint,
  pos_s : Double,
  alpha_ferm~ : Double = 1.0,
) -> Grassmann {
  let m = z_t.manifold
  let n_gen = m.n_gen.max(z_s.manifold.n_gen)
  let dt = pos_s - pos_t
  let lam_t = z_t.super_conformal_factor().smul(0.5)
  let lam_s = z_s.super_conformal_factor().smul(0.5)
  let mut score = Grassmann::zero(n_gen)
  let channels = m.m_bos.min(config.dim)
  for c in 0..<channels {
    let mu_t = (lam_t * z_t.bos[c]).softplus()
    let mu_s = (lam_s * z_s.bos[c]).softplus()
    let phase = @math.cos(dt * config.freqs[c] + config.delta[c])
    score = score + (mu_t * mu_s).smul(phase)
  }
  let ferm_pair = symplectic_odd_inner(z_t.ferm, z_s.ferm, n_gen)
  score + ferm_pair.smul(alpha_ferm * @math.cos(dt * config.freqs[0]))
}
