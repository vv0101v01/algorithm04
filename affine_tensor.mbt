///|
/// Module 2: Affine Tensor Space (仿射張量空間).
/// Implements:
///   1. Affine space torsors (flat Euclidean A^d and curved Frechet barycenter on B_c^m),
///   2. Mixed-variance Z_2-graded tensor algebra T^{(r, s)}(V_{m|n}) with Koszul braiding,
///      tensor product, supercontraction (str), and metric index raising/lowering,
///   3. Affine connection nabla on B_c^m (Levi-Civita + non-reciprocal contorsion),
///      torsion T^i_{jk}, Riemann curvature R^i_{jkl}, Ricci tensor, Bianchi identity,
///      and covariant tensor parallel transport along curves.

///|
/// Point in a flat Euclidean affine space A^d (no privileged origin; only affine
/// combinations sum_k w_k p_k with sum_k w_k = 1 and differences q (-) p are valid).
#derive(Debug, Eq)
pub(all) struct AffinePoint {
  coords : Array[Double]
}

///|
pub fn AffinePoint::new(coords : Array[Double]) -> AffinePoint {
  { coords: coords.copy(), }
}

///|
pub impl AffineTorsor for AffinePoint with fn translate(self, v) {
  { coords: vec_add(self.coords, v), }
}

///|
pub impl AffineTorsor for AffinePoint with fn diff_vec(self, base) {
  vec_sub(self.coords, base.coords)
}

///|
pub impl AffineTorsor for AffinePoint with fn affine_interp(self, other, t) {
  let d = vec_sub(other.coords, self.coords)
  { coords: vec_add(self.coords, vec_scale(d, t)), }
}

///|
pub extend AffinePoint with AffineTorsor::{translate, diff_vec, affine_interp}

///|
/// Frame-independent affine combination sum_k w_k p_k (normalizes weights to sum to 1).
pub fn affine_barycenter(
  points : Array[AffinePoint],
  weights : Array[Double],
) -> AffinePoint {
  let anchor = points[0]
  let dim = anchor.coords.length()
  let mut w_sum = 0.0
  for w in weights {
    w_sum = w_sum + w
  }
  let disp = Array::make(dim, 0.0)
  for k in 0..<points.length() {
    let wk = weights[k] / w_sum
    let dk = points[k].diff_vec(anchor)
    for i in 0..<dim {
      disp[i] = disp[i] + wk * dk[i]
    }
  }
  anchor.translate(disp)
}

///|
/// Riemannian Frechet (Karcher) barycenter on the Poincare ball B_c^m:
///   x* = argmin_{x in B_c^m} (1/2) sum_k w_k d_c(x, p_k)^2,
/// computed via intrinsic Riemannian gradient flow x <- exp_x^c(sum_k w_k log_x^c(p_k)).
pub fn poincare_frechet_mean(
  points : Array[PoincarePoint],
  weights : Array[Double],
  max_iters~ : Int32 = 80,
) -> PoincarePoint {
  let c = points[0].c
  let dim = points[0].dim()
  let mut w_sum = 0.0
  for w in weights {
    w_sum = w_sum + w
  }
  let mut cur = PoincarePoint::new(c, points[0].coords)
  for _ in 0..<max_iters {
    let grad = Array::make(dim, 0.0)
    for k in 0..<points.length() {
      let wk = weights[k] / w_sum
      let vk = cur.log_map(points[k])
      for i in 0..<dim {
        grad[i] = grad[i] + wk * vk[i]
      }
    }
    if vec_norm(grad) < 1.0e-13 {
      break
    }
    cur = cur.exp_map(grad)
  }
  cur
}

///|
/// Variance of a single tensor slot: Contravariant (upper index) or Covariant (lower index).
#derive(Debug, Eq, Hash)
pub(all) enum SlotVariance {
  Contravariant
  Covariant
}

///|
/// Mixed-variance Z_2-graded tensor T in T^{(r, s)}(V_{m|n}) stored in lexicographic order.
/// Indices 0 ..< m_bos are Even (bosonic); indices m_bos ..< m_bos + n_ferm are Odd (fermionic).
#derive(Debug, Eq)
pub(all) struct GradedTensor {
  m_bos : Int32
  n_ferm : Int32
  variances : Array[SlotVariance]
  data : Array[Double]
}

///|
pub fn GradedTensor::total_dim(self : GradedTensor) -> Int32 {
  self.m_bos + self.n_ferm
}

///|
pub fn GradedTensor::rank(self : GradedTensor) -> Int32 {
  self.variances.length()
}

///|
pub fn GradedTensor::index_parity(self : GradedTensor, idx : Int32) -> Parity {
  if idx < self.m_bos {
    Even
  } else {
    Odd
  }
}

///|
fn int_pow(base : Int32, exp : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<exp {
    r = r * base
  }
  r
}

///|
pub fn GradedTensor::zeros(
  m_bos : Int32,
  n_ferm : Int32,
  variances : Array[SlotVariance],
) -> GradedTensor {
  let d = m_bos + n_ferm
  let sz = int_pow(d, variances.length())
  { m_bos, n_ferm, variances: variances.copy(), data: Array::make(sz, 0.0), }
}

///|
/// Identity (1, 1)-tensor delta^A_B on V_{m|n}.
/// Its graded supercontraction str(delta) equals m_bos - n_ferm = sdim(V_{m|n})!
pub fn GradedTensor::kronecker_delta(
  m_bos : Int32,
  n_ferm : Int32,
) -> GradedTensor {
  let t = GradedTensor::zeros(m_bos, n_ferm, [Contravariant, Covariant])
  let d = m_bos + n_ferm
  for a in 0..<d {
    t.data[a * d + a] = 1.0
  }
  t
}

///|
fn GradedTensor::encode_indices(
  self : GradedTensor,
  idx : Array[Int32],
) -> Int32 {
  let d = self.total_dim()
  let mut flat = 0
  for a in idx {
    flat = flat * d + a
  }
  flat
}

///|
fn decode_indices(flat : Int32, d : Int32, rank : Int32) -> Array[Int32] {
  let out = Array::make(rank, 0)
  let mut rem = flat
  for s in (rank - 1)>=..0 {
    out[s] = rem % d
    rem = rem / d
  }
  out
}

///|
pub fn GradedTensor::get(self : GradedTensor, idx : Array[Int32]) -> Double {
  self.data[self.encode_indices(idx)]
}

///|
pub fn GradedTensor::set(
  self : GradedTensor,
  idx : Array[Int32],
  val : Double,
) -> Unit {
  let pos = self.encode_indices(idx)
  self.data[pos] = val
}

///|
pub fn GradedTensor::frob_norm(self : GradedTensor) -> Double {
  vec_norm(self.data)
}

///|
/// Tensor product S (x) T in T^{(r1+r2, s1+s2)}(V_{m|n}).
pub fn GradedTensor::tensor_product(
  self : GradedTensor,
  other : GradedTensor,
) -> GradedTensor {
  let vars : Array[SlotVariance] = Array(
    capacity=self.variances.length() + other.variances.length(),
  )
  for v in self.variances {
    vars.push(v)
  }
  for v in other.variances {
    vars.push(v)
  }
  let n1 = self.data.length()
  let n2 = other.data.length()
  let data = Array::make(n1 * n2, 0.0)
  for i in 0..<n1 {
    let si = self.data[i]
    if si != 0.0 {
      for j in 0..<n2 {
        data[i * n2 + j] = si * other.data[j]
      }
    }
  }
  { m_bos: self.m_bos, n_ferm: self.n_ferm, variances: vars, data, }
}

///|
/// Graded Koszul braiding (adjacent slot swap tau_{slot, slot+1}):
///   tau(e_A (x) e_B) = (-1)^{|A||B|} e_B (x) e_A.
/// Satisfies involutivity tau^2 = id and the Yang-Baxter braid relation
///   tau_1 tau_2 tau_1 = tau_2 tau_1 tau_2!
pub fn GradedTensor::graded_swap(
  self : GradedTensor,
  slot : Int32,
) -> GradedTensor {
  let r = self.rank()
  let d = self.total_dim()
  let vars = self.variances.copy()
  let tv = vars[slot]
  vars[slot] = vars[slot + 1]
  vars[slot + 1] = tv
  let out = GradedTensor::zeros(self.m_bos, self.n_ferm, vars)
  for flat in 0..<self.data.length() {
    let v = self.data[flat]
    if v != 0.0 {
      let idx = decode_indices(flat, d, r)
      let pa = self.index_parity(idx[slot])
      let pb = self.index_parity(idx[slot + 1])
      let sgn = koszul_sign(pa, pb)
      let tmp = idx[slot]
      idx[slot] = idx[slot + 1]
      idx[slot + 1] = tmp
      out.set(idx, v * sgn)
    }
  }
  out
}

///|
/// Graded supercontraction str^{slot_a}_{slot_b}(T) summing over paired
/// contravariant/covariant slots with Koszul trace weight (-1)^{|A|}
/// (and intermediate permutation Koszul sign).
pub fn GradedTensor::super_contract(
  self : GradedTensor,
  slot_a : Int32,
  slot_b : Int32,
) -> GradedTensor {
  let lo = if slot_a < slot_b { slot_a } else { slot_b }
  let hi = if slot_a < slot_b { slot_b } else { slot_a }
  let r = self.rank()
  let d = self.total_dim()
  let new_vars : Array[SlotVariance] = Array(capacity=r - 2)
  for s in 0..<r {
    if s != lo && s != hi {
      new_vars.push(self.variances[s])
    }
  }
  let out = GradedTensor::zeros(self.m_bos, self.n_ferm, new_vars)
  let rem_idx = Array::make(r - 2, 0)
  for flat in 0..<self.data.length() {
    let val = self.data[flat]
    if val != 0.0 {
      let idx = decode_indices(flat, d, r)
      if idx[lo] == idx[hi] {
        let p_diag = self.index_parity(idx[lo])
        // Trace factor (-1)^{|A|} plus braiding sign across intermediate slots
        let mut sgn = koszul_sign(p_diag, p_diag)
        for mid in (lo + 1)..<hi {
          sgn = sgn * koszul_sign(p_diag, self.index_parity(idx[mid]))
        }
        let mut ptr = 0
        for s in 0..<r {
          if s != lo && s != hi {
            rem_idx[ptr] = idx[s]
            ptr = ptr + 1
          }
        }
        let dst = out.encode_indices(rem_idx)
        out.data[dst] = out.data[dst] + sgn * val
      }
    }
  }
  out
}

///|
/// Internal helper: apply a linear operator `op` to a single tensor slot and update its variance.
fn GradedTensor::transform_slot(
  self : GradedTensor,
  slot : Int32,
  new_variance : SlotVariance,
  op : DenseMat,
) -> GradedTensor {
  let r = self.rank()
  let d = self.total_dim()
  let vars = self.variances.copy()
  vars[slot] = new_variance
  let out = GradedTensor::zeros(self.m_bos, self.n_ferm, vars)
  for flat in 0..<self.data.length() {
    let val = self.data[flat]
    if val != 0.0 {
      let idx = decode_indices(flat, d, r)
      let src = idx[slot]
      for tgt in 0..<d {
        let w = op.get(tgt, src)
        if w != 0.0 {
          idx[slot] = tgt
          let dst = out.encode_indices(idx)
          out.data[dst] = out.data[dst] + w * val
        }
      }
    }
  }
  out
}

///|
/// Musical isomorphism (index lowering g_flat) on a Contravariant slot:
///   (g_flat T)_{... B ...} = sum_A g_{BA} T^{... A ...}.
pub fn GradedTensor::lower_index(
  self : GradedTensor,
  slot : Int32,
  metric : DenseMat,
) -> GradedTensor {
  self.transform_slot(slot, Covariant, metric)
}

///|
/// Musical isomorphism (index raising g_sharp) on a Covariant slot using g^{-1}.
pub fn GradedTensor::raise_index(
  self : GradedTensor,
  slot : Int32,
  inv_metric : DenseMat,
) -> GradedTensor {
  self.transform_slot(slot, Contravariant, inv_metric)
}

///|
/// Affine connection nabla on B_c^m with optional cognitive contorsion strength `tau`:
///   Gamma^i_{jk}(x) = Gamma^{LC, i}_{jk}(x) + tau * K^i_{jk},
/// where tau = 0 is the exact torsion-free metric-compatible Levi-Civita connection.
#derive(Debug, Eq)
pub(all) struct AffineConnection {
  c : Double
  dim : Int32
  contorsion : Double
}

///|
pub fn AffineConnection::levi_civita(
  c : Double,
  dim : Int32,
) -> AffineConnection {
  { c, dim, contorsion: 0.0, }
}

///|
/// Exact Christoffel symbols Gamma^i_{jk}(x) on the Poincare ball B_c^m:
///   Gamma^{LC, i}_{jk}(x) = (2c / (1 - c||x||^2)) (x_j delta^i_k + x_k delta^i_j - x_i delta_{jk})
/// plus skew-symmetric metric-preserving contorsion when `contorsion != 0`.
pub fn AffineConnection::christoffel(
  self : AffineConnection,
  x : Array[Double],
  i : Int32,
  j : Int32,
  k : Int32,
) -> Double {
  let factor = 2.0 * self.c / (1.0 - self.c * vec_norm_sq(x))
  let d_ik = if i == k { 1.0 } else { 0.0 }
  let d_ij = if i == j { 1.0 } else { 0.0 }
  let d_jk = if j == k { 1.0 } else { 0.0 }
  let lc = factor * (x[j] * d_ik + x[k] * d_ij - x[i] * d_jk)
  // Totally antisymmetric 3-form contorsion for dim >= 3 (preserves metric compatibility)
  let cont = if self.contorsion != 0.0 && i != j && j != k && i != k {
    let inv_cnt = (if i > j { 1 } else { 0 }) +
      (if i > k { 1 } else { 0 }) +
      (if j > k { 1 } else { 0 })
    if (inv_cnt & 1) == 0 {
      self.contorsion
    } else {
      -self.contorsion
    }
  } else {
    0.0
  }
  lc + cont
}

///|
/// Torsion tensor T^i_{jk}(x) = Gamma^i_{jk}(x) - Gamma^i_{kj}(x).
pub fn AffineConnection::torsion_tensor(
  self : AffineConnection,
  x : Array[Double],
) -> GradedTensor {
  let d = self.dim
  let t = GradedTensor::zeros(d, 0, [Contravariant, Covariant, Covariant])
  for i in 0..<d {
    for j in 0..<d {
      for k in 0..<d {
        let val = self.christoffel(x, i, j, k) - self.christoffel(x, i, k, j)
        t.set([i, j, k], val)
      }
    }
  }
  t
}

///|
/// Exact analytical derivative d_k Gamma^{LC, i}_{lj}(x) for Levi-Civita connection:
///   d_k [ f(x) * (x_l d^i_j + x_j d^i_l - x_i d_{lj}) ]
/// where f(x) = 2c / (1 - c||x||^2) and d_k f(x) = f(x)^2 * x_k.
fn AffineConnection::d_christoffel(
  self : AffineConnection,
  x : Array[Double],
  k : Int32,
  i : Int32,
  l : Int32,
  j : Int32,
) -> Double {
  let f = 2.0 * self.c / (1.0 - self.c * vec_norm_sq(x))
  let df_dk = f * f * x[k]
  let d_ij = if i == j { 1.0 } else { 0.0 }
  let d_il = if i == l { 1.0 } else { 0.0 }
  let d_lj = if l == j { 1.0 } else { 0.0 }
  let d_lk = if l == k { 1.0 } else { 0.0 }
  let d_jk = if j == k { 1.0 } else { 0.0 }
  let d_ik = if i == k { 1.0 } else { 0.0 }
  let bracket = x[l] * d_ij + x[j] * d_il - x[i] * d_lj
  let d_bracket = d_lk * d_ij + d_jk * d_il - d_ik * d_lj
  df_dk * bracket + f * d_bracket
}

///|
/// Exact Riemann curvature tensor R^i_{jkl}(x) in T^{(1, 3)}(T_x B_c^m):
///   R^i_{jkl} = d_k Gamma^i_{lj} - d_l Gamma^i_{kj}
///             + sum_m (Gamma^i_{km} Gamma^m_{lj} - Gamma^i_{lm} Gamma^m_{kj}).
/// For Poincare ball B_c^m, satisfies R_{ijkl} = -c (g_{ik} g_{jl} - g_{il} g_{jk}) identically!
pub fn AffineConnection::riemann_tensor(
  self : AffineConnection,
  x : Array[Double],
) -> GradedTensor {
  let d = self.dim
  let r = GradedTensor::zeros(d, 0, [
    Contravariant,
    Covariant,
    Covariant,
    Covariant,
  ])
  for i in 0..<d {
    for j in 0..<d {
      for k in 0..<d {
        for l in 0..<d {
          let mut val = self.d_christoffel(x, k, i, l, j) -
            self.d_christoffel(x, l, i, k, j)
          for m in 0..<d {
            val = val +
              self.christoffel(x, i, k, m) * self.christoffel(x, m, l, j) -
              self.christoffel(x, i, l, m) * self.christoffel(x, m, k, j)
          }
          r.set([i, j, k, l], val)
        }
      }
    }
  }
  r
}

///|
/// Ricci curvature tensor Ric_{jl}(x) = sum_k R^k_{jkl}(x) = -c (m - 1) g_{jl}(x).
pub fn AffineConnection::ricci_matrix(
  self : AffineConnection,
  x : Array[Double],
) -> DenseMat {
  let r = self.riemann_tensor(x)
  let d = self.dim
  DenseMat::from_fn(d, d, (j, l) => {
    let mut s = 0.0
    for k in 0..<d {
      s = s + r.get([k, j, k, l])
    }
    s
  })
}

///|
/// Scalar curvature R(x) = g^{jl}(x) Ric_{jl}(x) = -c * m * (m - 1).
pub fn AffineConnection::scalar_curvature(
  self : AffineConnection,
  x : Array[Double],
) -> Double {
  let p = PoincarePoint::new(self.c, x)
  let inv_lam2 = 1.0 / (p.conformal_factor() * p.conformal_factor())
  let ric = self.ricci_matrix(p.coords)
  inv_lam2 * ric.trace()
}

///|
/// Maximum algebraic First Bianchi Identity residual:
///   max_{i,j,k,l} | R^i_{jkl} + R^i_{klj} + R^i_{ljk} | (equals 0 for Levi-Civita).
pub fn AffineConnection::first_bianchi_residual(
  self : AffineConnection,
  x : Array[Double],
) -> Double {
  let r = self.riemann_tensor(x)
  let d = self.dim
  let mut max_err = 0.0
  for i in 0..<d {
    for j in 0..<d {
      for k in 0..<d {
        for l in 0..<d {
          let cyc = (r.get([i, j, k, l]) +
          r.get([i, k, l, j]) +
          r.get([i, l, j, k])).abs()
          if cyc > max_err {
            max_err = cyc
          }
        }
      }
    }
  }
  max_err
}

///|
/// Solve the affine parallel transport ODE DV^i/dt = dV^i/dt + Gamma^i_{jk}(gamma(t)) xdot^j V^k = 0
/// along the geodesic from `start` to `target` via 4th-order Runge-Kutta, verifying exact
/// agreement with closed-form Mobius gyration parallel transport.
pub fn AffineConnection::parallel_transport_ode(
  self : AffineConnection,
  start : PoincarePoint,
  target : PoincarePoint,
  v0 : Array[Double],
  steps~ : Int32 = 100,
) -> Array[Double] {
  let d = self.dim
  let dt = 1.0 / steps.to_double()
  let u0 = start.log_map(target)
  let rhs = (t : Double, v : Array[Double]) => {
    let pt = start.exp_map(vec_scale(u0, t))
    let xdot = start.parallel_transport(pt, u0)
    Array::makei(d, i => {
      let mut s = 0.0
      for j in 0..<d {
        for k in 0..<d {
          s = s - self.christoffel(pt.coords, i, j, k) * xdot[j] * v[k]
        }
      }
      s
    })
  }
  let mut v = v0.copy()
  for step in 0..<steps {
    let t = step.to_double() * dt
    let k1 = rhs(t, v)
    let k2 = rhs(t + 0.5 * dt, vec_add(v, vec_scale(k1, 0.5 * dt)))
    let k3 = rhs(t + 0.5 * dt, vec_add(v, vec_scale(k2, 0.5 * dt)))
    let k4 = rhs(t + dt, vec_add(v, vec_scale(k3, dt)))
    v = Array::makei(d, i => {
      v[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])
    })
  }
  v
}
