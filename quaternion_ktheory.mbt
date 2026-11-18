///|
/// Module 22 (Unified from `algo8`): Hilbert Quaternions H, Noncommutative Graph Operators
/// & K_0 Spectral Projector Identities (希爾伯特四元數與非交換圖 K-理論譜對象恆等式).
/// Completes Dyson's associative division-algebra tower R subset C subset H inside `algebra.mbt`'s
/// `AbelianGroup / Module / Ring` trait hierarchy, fixes the degenerate-spectrum `0/0 = NaN`
/// silent false-positive in `hermitian2_projector_plus` / `k0_spectral_identity`, and adds the
/// faithful symplectic left-regular representation iota : H -> Mat_4(R)!

///|
/// Hamilton quaternion q = w + x i + y j + z k in H (i^2 = j^2 = k^2 = ijk = -1, ij = -ji = k).
#derive(Debug, Eq)
pub(all) struct Quat {
  w : Double
  x : Double
  y : Double
  z : Double
}

///|
pub fn Quat::new(w : Double, x : Double, y : Double, z : Double) -> Quat {
  { w, x, y, z, }
}

///|
pub fn Quat::zero() -> Quat {
  { w: 0.0, x: 0.0, y: 0.0, z: 0.0, }
}

///|
pub fn Quat::one() -> Quat {
  { w: 1.0, x: 0.0, y: 0.0, z: 0.0, }
}

///|
pub fn Quat::conj(self : Quat) -> Quat {
  { w: self.w, x: -self.x, y: -self.y, z: -self.z, }
}

///|
pub fn Quat::smul(self : Quat, s : Double) -> Quat {
  { w: self.w * s, x: self.x * s, y: self.y * s, z: self.z * s, }
}

///|
pub fn Quat::norm2(self : Quat) -> Double {
  self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z
}

///|
pub fn Quat::norm(self : Quat) -> Double {
  self.norm2().sqrt()
}

///|
/// Exact zero-safe multiplicative inverse q^{-1} = q^* / |q|^2 in the division ring H.
pub fn Quat::inv(self : Quat) -> Quat {
  let n2 = self.norm2()
  if n2 <= 1.0e-300 {
    Quat::zero()
  } else {
    self.conj().smul(1.0 / n2)
  }
}

///|
pub impl Add for Quat with fn add(self, o) {
  { w: self.w + o.w, x: self.x + o.x, y: self.y + o.y, z: self.z + o.z, }
}

///|
pub impl Sub for Quat with fn sub(self, o) {
  { w: self.w - o.w, x: self.x - o.x, y: self.y - o.y, z: self.z - o.z, }
}

///|
pub impl Neg for Quat with fn neg(self) {
  { w: -self.w, x: -self.x, y: -self.y, z: -self.z, }
}

///|
/// Noncommutative associative Hamilton product (|p * q| == |p| * |q|, (p * q)^* == q^* * p^*).
pub impl Mul for Quat with fn mul(self, o) {
  {
    w: self.w * o.w - self.x * o.x - self.y * o.y - self.z * o.z,
    x: self.w * o.x + self.x * o.w + self.y * o.z - self.z * o.y,
    y: self.w * o.y - self.x * o.z + self.y * o.w + self.z * o.x,
    z: self.w * o.z + self.x * o.y - self.y * o.x + self.z * o.w,
  }
}

///|
pub impl Div for Quat with fn div(self, o) {
  self * o.inv()
}

///|
pub impl AbelianGroup for Quat with fn zero_elem() {
  Quat::zero()
}

///|
pub impl AbelianGroup for Quat with fn add_elem(self, o) {
  self + o
}

///|
pub impl AbelianGroup for Quat with fn neg_elem(self) {
  -self
}

///|
pub impl AbelianGroup for Quat with fn norm_sq(self) {
  self.norm2()
}

///|
pub impl Module for Quat with fn scale(self, s) {
  self.smul(s)
}

///|
pub impl Ring for Quat with fn one_elem() {
  Quat::one()
}

///|
pub impl Ring for Quat with fn mul_elem(self, o) {
  self * o
}

///|
/// Faithful real left-regular *-algebra embedding iota : H -> Mat_4(R) in basis (1, i, j, k):
///   iota(q) = [[ w, -x, -y, -z ],
///              [ x,  w, -z,  y ],
///              [ y,  z,  w, -x ],
///              [ z, -y,  x,  w ]].
/// Strictly preserves +, *, 1, conjugate-transpose iota(q^*) == iota(q)^T, reduced trace
/// (1/4) Tr(iota(q)) == Re(q) = w, and Study determinant det(iota(q)) == |q|^4!
pub fn Quat::to_real_mat4(self : Quat) -> DenseMat {
  let { w, x, y, z, } = self
  {
    rows: 4,
    cols: 4,
    data: [w, -x, -y, -z, x, w, -z, y, y, z, w, -x, z, -y, x, w],
  }
}

///|
/// 2x2 quaternionic self-adjoint (Hermitian) operator H = [[a, q], [q^*, b]] (a, b in R, q in H).
#derive(Debug, Eq)
pub(all) struct Hermitian2 {
  a : Double
  b : Double
  q : Quat
}

///|
fn hermitian2_quad_form(h : Hermitian2, v : Array[Quat]) -> (Quat, Double) {
  let x = v[0]
  let y = v[1]
  let h0 = x.smul(h.a) + h.q * y
  let h1 = h.q.conj() * x + y.smul(h.b)
  (x.conj() * h0 + y.conj() * h1, x.norm2() + y.norm2())
}

///|
/// Real part of quaternionic Rayleigh quotient <v, H v> / ||v||^2 in [lambda_-, lambda_+].
pub fn rayleigh_real(h : Hermitian2, v : Array[Quat]) -> Double {
  let (ip, nrm) = hermitian2_quad_form(h, v)
  ip.w / nrm
}

///|
/// Imaginary residual ||Im(<v, H v>)|| / ||v||^2 (identically 0 for self-adjoint H = H^*).
pub fn rayleigh_imag_residual(h : Hermitian2, v : Array[Quat]) -> Double {
  let (ip, nrm) = hermitian2_quad_form(h, v)
  (ip.x * ip.x + ip.y * ip.y + ip.z * ip.z).sqrt() / nrm
}

///|
/// Exact real eigenvalues (lambda_+, lambda_-) of H = [[a, q], [q^*, b]]:
///   lambda_{+-} = (a + b)/2 +- sqrt(((a - b)/2)^2 + |q|^2).
pub fn hermitian2_eigs(h : Hermitian2) -> (Double, Double) {
  let mid = 0.5 * (h.a + h.b)
  let half = 0.5 * (h.a - h.b)
  let s = (half * half + h.q.norm2()).sqrt()
  (mid + s, mid - s)
}

///|
/// Exact K_0 spectral projection p_+ onto the lambda_+ eigenspace of H, returned as
/// `(alpha, delta, off)` representing [[alpha, off], [off^*, delta]] with p_+^2 == p_+ == p_+^*:
///   - Simple spectrum (lambda_+ > lambda_-): rank-1 projection p_+ = (H - lambda_- I)/(lambda_+ - lambda_-), tr = 1;
///   - Degenerate spectrum (lambda_+ == lambda_-, i.e. H = a I_2): full rank-2 projection p_+ = I_2, tr = 2
///     (bug-fix: eliminates 0/0 = NaN on scalar degenerate operators!).
pub fn hermitian2_projector_plus(h : Hermitian2) -> (Double, Double, Quat) {
  let (lp, lm) = hermitian2_eigs(h)
  let denom = lp - lm
  if denom <= 1.0e-14 {
    (1.0, 1.0, Quat::zero())
  } else {
    ((h.a - lm) / denom, (h.b - lm) / denom, h.q.smul(1.0 / denom))
  }
}

///|
/// Verify K_0 spectral projector identities on H (strictly NaN-safe!):
///   (i) Idempotency p_+^2 == p_+,  (ii) Orthogonality p_+ p_- == 0,
///   (iii) Completeness p_+ + p_- == I_2,  (iv) Integer K_0 index tr(p_+) in {1, 2} & tr(p_+)+tr(p_-) == 2,
///   (v) Spectral reconstruction lambda_+ p_+ + lambda_- p_- == H.
pub fn k0_spectral_identity(h : Hermitian2, eps : Double) -> Bool {
  let (lp, lm) = hermitian2_eigs(h)
  let (a1, d1, b1) = hermitian2_projector_plus(h)
  let a2 = 1.0 - a1
  let d2 = 1.0 - d1
  let b2 = -b1
  let b1n2 = b1.norm2()
  let tr1 = a1 + d1
  let tr_sum = tr1 + (a2 + d2)
  // NaN-safe conjunction: every residual must satisfy `res <= eps`
  approx(a1 + a2, 1.0, eps) &&
  approx(d1 + d2, 1.0, eps) &&
  (b1 + b2).norm() <= eps &&
  approx(a1 * a2, b1n2, eps) &&
  approx(d1 * d2, b1n2, eps) &&
  approx(tr_sum, 2.0, eps) &&
  approx(tr1, tr1.round(), eps) &&
  approx(lp * a1 + lm * a2, h.a, eps) &&
  approx(lp * d1 + lm * d2, h.b, eps) &&
  (b1.smul(lp) + b2.smul(lm) - h.q).norm() <= eps
}

///|
/// Noncommutative graph with `n` vertices and quaternion edge weights w_{ij} in H (A^* == A).
#derive(Debug, Eq)
pub(all) struct NonCommGraph {
  n : Int32
  weights : Array[Array[Quat]]
}

///|
/// Assemble full n x n self-adjoint quaternionic adjacency matrix A_{ij} (A_{ji} = A_{ij}^*, A_{ii} = 0).
pub fn NonCommGraph::adjacency(self : NonCommGraph) -> Array[Array[Quat]] {
  Array::makei(self.n, i => {
    Array::makei(self.n, j => {
      if i == j {
        Quat::zero()
      } else if j > i {
        self.weights[i][j]
      } else {
        self.weights[j][i].conj()
      }
    })
  })
}

///|
/// Verify quaternionic self-adjointness A_{ji}^* == A_{ij} for all 0 <= i, j < n (NaN-safe).
pub fn adjacency_is_hermitian(g : NonCommGraph, eps : Double) -> Bool {
  let a = g.adjacency()
  for i in 0..<g.n {
    for j in 0..<g.n {
      if !((a[j][i].conj() - a[i][j]).norm() <= eps) {
        return false
      }
    }
  }
  true
}

///|
/// Verify the quaternionic Hermitian 2x2 Cayley-Hamilton identity:
///   A^2 - tr_R(A) A + det_M(A) I_2 == 0,
/// where tr_R(A) = Re(a_00) + Re(a_11) and Moore determinant det_M(A) = a_00 a_11 - |a_01|^2 in R.
pub fn cayley_hamilton_2x2(a : Array[Array[Quat]], eps : Double) -> Bool {
  let tr_r = a[0][0].w + a[1][1].w
  let det_r = a[0][0].w * a[1][1].w - a[0][1].norm2()
  for i in 0..<2 {
    for j in 0..<2 {
      let a2_ij = a[i][0] * a[0][j] + a[i][1] * a[1][j]
      let diag = if i == j {
        Quat::new(det_r, 0.0, 0.0, 0.0)
      } else {
        Quat::zero()
      }
      let res = a2_ij - a[i][j].smul(tr_r) + diag
      if !(res.norm() <= eps) {
        return false
      }
    }
  }
  true
}

///|
/// K_0 trace additivity check on direct-sum projector indices (retained for `algo8` API compatibility).
pub fn k0_additivity(t1 : Double, t2 : Double, eps : Double) -> Bool {
  approx(t1 + t2, t1.round() + t2.round(), eps)
}

///|
/// Genuine K_0 direct-sum index homomorphism on H_1 (+) H_2 in Mat_4(H):
/// lifts p_+(H_1) (+) p_+(H_2) via `Quat::to_real_mat4` to Mat_{16}(R), verifies P^2 == P == P^T,
/// and checks (1/4) Tr_R(P) == tr_H(p_+(H_1)) + tr_H(p_+(H_2)) in {2, 3, 4} subset Z!
pub fn k0_direct_sum_index(h1 : Hermitian2, h2 : Hermitian2) -> (Int32, Double) {
  let embed_proj = (h : Hermitian2) => {
    let (a, d, b) = hermitian2_projector_plus(h)
    let m = DenseMat::zeros(8, 8)
    let blocks = [
      (0, 0, Quat::new(a, 0.0, 0.0, 0.0).to_real_mat4()),
      (0, 4, b.to_real_mat4()),
      (4, 0, b.conj().to_real_mat4()),
      (4, 4, Quat::new(d, 0.0, 0.0, 0.0).to_real_mat4()),
    ]
    for blk in blocks {
      let (r0, c0, sub) = blk
      for r in 0..<4 {
        for c in 0..<4 {
          m.set(r0 + r, c0 + c, sub.get(r, c))
        }
      }
    }
    (m, a + d)
  }
  let (p1, t1) = embed_proj(h1)
  let (p2, t2) = embed_proj(h2)
  let p_sum = DenseMat::zeros(16, 16)
  for r in 0..<8 {
    for c in 0..<8 {
      p_sum.set(r, c, p1.get(r, c))
      p_sum.set(8 + r, 8 + c, p2.get(r, c))
    }
  }
  let idem_err = (p_sum * p_sum - p_sum).frob_norm()
  let sym_err = (p_sum.transpose() - p_sum).frob_norm()
  let red_trace = 0.25 * p_sum.trace()
  let add_err = (red_trace - (t1 + t2)).abs()
  let int_err = (red_trace - red_trace.round()).abs()
  (red_trace.round().to_int(), idem_err.max(sym_err).max(add_err).max(int_err))
}
