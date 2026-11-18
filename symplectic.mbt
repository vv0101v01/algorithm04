///|
/// Module 20 (Unified from `algo8`): Neural-PDE Symplectic Phase-Harmony Identity &
/// Structure-Preserving Geometric Integration (神經偏微分辛相調恆等式與離散 Liouville 守恆).
/// Deduplicated against `algebra.mbt` (`DenseMat`, `numerical_jacobian`) and
/// `supermanifold.mbt` (`canonical_symplectic`), eliminating ~120 lines of duplicate
/// Jacobian, matrix-multiply, and LU-determinant code and fixing step-size argument passing!

///|
/// Separable neural Hamiltonian H(q, p) = T(p) + V(q) with quadratic kinetic energy
/// T(p) = (1/2) sum_i tw_i p_i^2 and tanh neural potential V(q) = sum_j va_j tanh(vw_j . q + vb_j).
#derive(Debug, Eq)
pub(all) struct NeuralH {
  tw : Array[Double]
  va : Array[Double]
  vw : Array[Array[Double]]
  vb : Array[Double]
}

///|
pub fn NeuralH::kinetic(self : NeuralH, p : Array[Double]) -> Double {
  let mut s = 0.0
  for i in 0..<p.length() {
    s = s + 0.5 * self.tw[i] * p[i] * p[i]
  }
  s
}

///|
pub fn NeuralH::potential(self : NeuralH, q : Array[Double]) -> Double {
  let mut s = 0.0
  for j in 0..<self.va.length() {
    let z = self.vb[j] + vec_dot(self.vw[j], q)
    s = s + self.va[j] * @math.tanh(z)
  }
  s
}

///|
pub fn NeuralH::energy(
  self : NeuralH,
  q : Array[Double],
  p : Array[Double],
) -> Double {
  self.kinetic(p) + self.potential(q)
}

///|
/// Analytical potential gradient nabla_q V(q) = sum_j va_j sech^2(vw_j . q + vb_j) vw_j.
pub fn NeuralH::grad_potential(
  self : NeuralH,
  q : Array[Double],
) -> Array[Double] {
  let sech2 = Array::makei(self.va.length(), j => {
    let th = @math.tanh(self.vb[j] + vec_dot(self.vw[j], q))
    self.va[j] * (1.0 - th * th)
  })
  Array::makei(q.length(), k => {
    let mut s = 0.0
    for j in 0..<self.va.length() {
      s = s + sech2[j] * self.vw[j][k]
    }
    s
  })
}

///|
/// Analytical kinetic gradient nabla_p T(p) = diag(tw) * p.
pub fn NeuralH::grad_kinetic(
  self : NeuralH,
  p : Array[Double],
) -> Array[Double] {
  Array::makei(p.length(), i => self.tw[i] * p[i])
}

///|
/// Exact Symplectic Euler (semi-implicit) step preserving omega = sum_i dq_i ^ dp_i:
///   p' = p - dt * nabla_q V(q),   q' = q + dt * nabla_p T(p').
pub fn symplectic_euler_step(
  h : NeuralH,
  q : Array[Double],
  p : Array[Double],
  dt : Double,
) -> (Array[Double], Array[Double]) {
  let p2 = vec_sub(p, vec_scale(h.grad_potential(q), dt))
  let q2 = vec_add(q, vec_scale(h.grad_kinetic(p2), dt))
  (q2, p2)
}

///|
/// Non-symplectic Explicit Euler baseline:
///   p' = p - dt * nabla_q V(q),   q' = q + dt * nabla_p T(p).
pub fn explicit_euler_step(
  h : NeuralH,
  q : Array[Double],
  p : Array[Double],
  dt : Double,
) -> (Array[Double], Array[Double]) {
  let p2 = vec_sub(p, vec_scale(h.grad_potential(q), dt))
  let q2 = vec_add(q, vec_scale(h.grad_kinetic(p), dt))
  (q2, p2)
}

///|
/// Variational 2n x 2n phase-space Jacobian d(q', p') / d(q, p) via shared `numerical_jacobian`.
pub fn phase_space_jacobian(
  step_qp : (Array[Double], Array[Double]) -> (Array[Double], Array[Double]),
  q : Array[Double],
  p : Array[Double],
  eps~ : Double = 1.0e-5,
) -> DenseMat {
  let n = q.length()
  let z0 = Array::makei(2 * n, i => if i < n { q[i] } else { p[i - n] })
  numerical_jacobian(
    z => {
      let q_in = Array::makei(n, i => z[i])
      let p_in = Array::makei(n, i => z[n + i])
      let (q_out, p_out) = step_qp(q_in, p_in)
      Array::makei(2 * n, i => if i < n { q_out[i] } else { p_out[i - n] })
    },
    z0,
    eps~,
  )
}

///|
/// Symplectic phase-harmony identity residual || M^T Omega M - Omega ||_F for Omega = J_{2n},
/// shared between `NeuralH` symplectic integration and Layer-4 Metriplectic dynamics.
pub fn symplectic_form_defect(jac : DenseMat) -> Double {
  let omega = canonical_symplectic(jac.rows)
  (jac.transpose() * omega * jac - omega).frob_norm()
}

///|
/// Symplectic Euler variational residual || M^T Omega M - Omega ||_F (vanishes identically!).
pub fn symplectic_identity_residual(
  h : NeuralH,
  q : Array[Double],
  p : Array[Double],
  dt : Double,
) -> Double {
  symplectic_form_defect(
    phase_space_jacobian((qq, pp) => symplectic_euler_step(h, qq, pp, dt), q, p),
  )
}

///|
/// Non-symplectic Explicit Euler residual || M^T Omega M - Omega ||_F (> 0, O(dt)).
pub fn explicit_identity_residual(
  h : NeuralH,
  q : Array[Double],
  p : Array[Double],
  dt : Double,
) -> Double {
  symplectic_form_defect(
    phase_space_jacobian((qq, pp) => explicit_euler_step(h, qq, pp, dt), q, p),
  )
}

///|
/// Discrete Liouville phase-volume factor det(d(q', p') / d(q, p)) == 1 for Symplectic Euler.
pub fn symplectic_det_area(
  q : Array[Double],
  p : Array[Double],
  dt : Double,
) -> Double {
  let h = default_neural_h()
  phase_space_jacobian((qq, pp) => symplectic_euler_step(h, qq, pp, dt), q, p).det()
}

///|
/// Canonical 2-DoF nonlinear coupled neural Hamiltonian benchmark instance.
pub fn default_neural_h() -> NeuralH {
  {
    tw: [1.0, 1.0],
    va: [0.6, -0.4],
    vw: [[1.2, -0.7], [0.5, 1.1]],
    vb: [0.1, -0.3],
  }
}

///|
/// Long-horizon Hamiltonian energy drift |H(q_T, p_T) - H(q_0, p_0)| comparing Symplectic
/// Euler (`symp = true`, bounded shadow Hamiltonian oscillation) vs Explicit Euler (`false`).
pub fn energy_drift(symp : Bool, steps : Int32, dt : Double) -> Double {
  let h = default_neural_h()
  let mut q = [0.7, -0.4]
  let mut p = [0.3, 0.9]
  let e0 = h.energy(q, p)
  for _ in 0..<steps {
    let (nq, np) = if symp {
      symplectic_euler_step(h, q, p, dt)
    } else {
      explicit_euler_step(h, q, p, dt)
    }
    q = nq
    p = np
  }
  (h.energy(q, p) - e0).abs()
}
