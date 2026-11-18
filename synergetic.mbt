///|
/// Module 19 (Unified from `algo8`): Haken Synergetic Functor Neural Network,
/// Adiabatic Slaving Manifold & Winner-Take-All Order Parameter Dynamics
/// (協同學函子神經網絡、快變數奴役不動點與序參數競爭收斂).
/// Deduplicated against `algebra.mbt` (`softmax_vec`, `vec_add`, `vec_sub`, `vec_norm`).

///|
/// Affine-ReLU neural encoding layer y = max(0, W x + b).
#derive(Debug, Eq)
pub(all) struct Layer {
  w : Array[Array[Double]]
  b : Array[Double]
}

///|
pub fn Layer::activate(self : Layer, x : Array[Double]) -> Array[Double] {
  Array::makei(self.w.length(), i => {
    let s = self.b[i] + vec_dot(self.w[i], x)
    if s > 0.0 {
      s
    } else {
      0.0
    }
  })
}

///|
/// Synergetic functor network encoding inputs to latent order-parameter space
/// and pushing forward translation morphisms tau_u(x) = x + u covariantly.
#derive(Debug, Eq)
pub(all) struct SynergeticNet {
  encoder : Layer
  n_order : Int32
}

///|
pub fn SynergeticNet::encode(
  self : SynergeticNet,
  x : Array[Double],
) -> Array[Double] {
  self.encoder.activate(x)
}

///|
/// Covariant pushforward F(tau_u)(e) = e + W u on latent tangent space.
pub fn SynergeticNet::push_morphism(
  self : SynergeticNet,
  e : Array[Double],
  u : Array[Double],
) -> Array[Double] {
  Array::makei(e.length(), i => e[i] + vec_dot(self.encoder.w[i], u))
}

///|
/// Verify functoriality F(id) == id and F(tau_{u2} o tau_{u1}) == F(tau_{u2}) o F(tau_{u1}).
pub fn functor_laws_synergetic(
  net : SynergeticNet,
  x : Array[Double],
  u1 : Array[Double],
  u2 : Array[Double],
) -> Bool {
  let e = net.encode(x)
  let zero = Array::make(u1.length(), 0.0)
  let fid = net.push_morphism(e, zero)
  if vec_norm(vec_sub(fid, e)) > 1.0e-12 {
    return false
  }
  let e12 = net.push_morphism(net.push_morphism(e, u1), u2)
  let esum = net.push_morphism(e, vec_add(u1, u2))
  vec_norm(vec_sub(e12, esum)) <= 1.0e-12
}

///|
/// Haken adiabatic slaving step for fast variable s driven by slow order parameter xi:
///   ds/dt = -gamma * s + g(xi),   g(xi) = xi^2 - 1,   gamma > 0.
/// Error contracts geometrically as e_{k+1} = (1 - eta * gamma) e_k for 0 < eta < 2 / gamma.
pub fn slaving_step(
  s : Double,
  xi : Double,
  gamma : Double,
  eta : Double,
) -> Double {
  s + eta * (-gamma * s + (xi * xi - 1.0))
}

///|
/// Exact Haken slaving manifold s*(xi) = (xi^2 - 1) / gamma (unique global attractor for gamma > 0).
pub fn slaving_fixed_point(xi : Double, gamma : Double) -> Double {
  (xi * xi - 1.0) / gamma
}

///|
/// Iterate fast-mode relaxation for `steps` steps from s_0 = 0 at fixed order parameter xi.
pub fn slaving_run(
  xi : Double,
  gamma : Double,
  eta : Double,
  steps : Int32,
) -> Double {
  let mut s = 0.0
  for _ in 0..<steps {
    s = slaving_step(s, xi, gamma, eta)
  }
  s
}

///|
/// Evolve Haken competitive order-parameter logits xi_{k+1} = xi_k + eta * (proj - softmax(xi_k))
/// reusing the canonical overflow-safe `softmax_vec` from `algebra.mbt`.
pub fn order_parameter_logits(
  proj : Array[Double],
  eta : Double,
  steps : Int32,
) -> Array[Double] {
  let mut xi = Array::make(proj.length(), 0.0)
  for _ in 0..<steps {
    let soft = softmax_vec(xi)
    xi = vec_add(xi, vec_scale(vec_sub(proj, soft), eta))
  }
  xi
}

///|
/// Winner-Take-All (WTA) order-parameter selection: returns indices achieving max_i xi_i
/// (singleton on Supertropical Tangible inputs; multi-element on Supertropical Ghost ties!).
pub fn order_parameter_wta(
  proj : Array[Double],
  eta : Double,
  steps : Int32,
) -> Array[Int32] {
  let xi = order_parameter_logits(proj, eta, steps)
  let mut best = xi[0]
  for v in xi {
    if v > best {
      best = v
    }
  }
  let winners : Array[Int32] = []
  for i in 0..<xi.length() {
    if (xi[i] - best).abs() < 1.0e-12 {
      winners.push(i)
    }
  }
  winners
}

///|
/// Verify Winner-Take-All argmax invariance between iteration 100 and 101.
pub fn wta_argmax_stable(proj : Array[Double]) -> Bool {
  order_parameter_wta(proj, 0.1, 100) == order_parameter_wta(proj, 0.1, 101)
}
