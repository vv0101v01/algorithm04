///|
/// Module 1: Poincare-Riemannian Supermanifold M^{m|n}_c.
/// Models continuous hierarchical semantics on the Poincare ball B_c^m (even/bosonic)
/// coupled to anti-commuting symbolic constraint coordinates R^{0|2k} (odd/fermionic)
/// via the OSp(m|2k)-invariant Poincare-Riemannian supermetric G_{AB}(z).

///|
/// Point on the bosonic Poincare ball B_c^m = { x in R^m : c ||x||^2 < 1 }
/// with constant negative sectional curvature K = -c (c > 0).
#derive(Debug, Eq)
pub(all) struct PoincarePoint {
  c : Double
  coords : Array[Double]
}

///|
/// Project a raw vector safely inside the open Poincare ball B_c^m.
pub fn PoincarePoint::new(c : Double, coords : Array[Double]) -> PoincarePoint {
  let max_norm = (1.0 - 1.0e-7) / c.sqrt()
  let nrm = vec_norm(coords)
  let safe = if nrm >= max_norm {
    vec_scale(coords, max_norm / nrm)
  } else {
    coords.copy()
  }
  { c, coords: safe, }
}

///|
pub fn PoincarePoint::origin(c : Double, dim : Int32) -> PoincarePoint {
  { c, coords: Array::make(dim, 0.0), }
}

///|
pub fn PoincarePoint::dim(self : PoincarePoint) -> Int32 {
  self.coords.length()
}

///|
/// Conformal factor lambda_x^c = 2 / (1 - c ||x||^2).
pub fn PoincarePoint::conformal_factor(self : PoincarePoint) -> Double {
  2.0 / (1.0 - self.c * vec_norm_sq(self.coords))
}

///|
/// Mobius gyrovector addition x (+)_c y on B_c^m.
pub fn mobius_add(
  c : Double,
  x : Array[Double],
  y : Array[Double],
) -> Array[Double] {
  let x2 = vec_norm_sq(x)
  let y2 = vec_norm_sq(y)
  let xy = vec_dot(x, y)
  let denom = 1.0 + 2.0 * c * xy + c * c * x2 * y2
  let alpha = (1.0 + 2.0 * c * xy + c * y2) / denom
  let beta = (1.0 - c * x2) / denom
  Array::makei(x.length(), i => alpha * x[i] + beta * y[i])
}

///|
/// Thomas-Ungar gyration operator gyr[u, v] w = (-(u (+)_c v)) (+)_c (u (+)_c (v (+)_c w)).
/// Preserves the Euclidean inner product and generates hyperbolic holonomy.
pub fn mobius_gyration(
  c : Double,
  u : Array[Double],
  v : Array[Double],
  w : Array[Double],
) -> Array[Double] {
  let uv = mobius_add(c, u, v)
  let neg_uv = vec_scale(uv, -1.0)
  let vw = mobius_add(c, v, w)
  let u_vw = mobius_add(c, u, vw)
  mobius_add(c, neg_uv, u_vw)
}

///|
pub impl RiemannianGeometry for PoincarePoint with fn metric_inner(self, u, v) {
  let lam = self.conformal_factor()
  lam * lam * vec_dot(u, v)
}

///|
pub impl RiemannianGeometry for PoincarePoint with fn exp_map(self, v) {
  let v_norm = vec_norm(v)
  if v_norm < 1.0e-15 {
    return PoincarePoint::new(self.c, self.coords)
  }
  let sc = self.c.sqrt()
  let lam = self.conformal_factor()
  let factor = @math.tanh(sc * lam * v_norm * 0.5) / (sc * v_norm)
  let step = vec_scale(v, factor)
  PoincarePoint::new(self.c, mobius_add(self.c, self.coords, step))
}

///|
pub impl RiemannianGeometry for PoincarePoint with fn log_map(self, target) {
  let neg_x = vec_scale(self.coords, -1.0)
  let diff = mobius_add(self.c, neg_x, target.coords)
  let d_norm = vec_norm(diff)
  if d_norm < 1.0e-15 {
    return Array::make(self.dim(), 0.0)
  }
  let sc = self.c.sqrt()
  let lam = self.conformal_factor()
  let arg = (sc * d_norm).clamp(min=0.0, max=1.0 - 1.0e-15)
  let factor = 2.0 * @math.atanh(arg) / (sc * lam * d_norm)
  vec_scale(diff, factor)
}

///|
pub impl RiemannianGeometry for PoincarePoint with fn geodesic_dist(self, other) {
  let neg_x = vec_scale(self.coords, -1.0)
  let diff = mobius_add(self.c, neg_x, other.coords)
  let sc = self.c.sqrt()
  let arg = (sc * vec_norm(diff)).clamp(min=0.0, max=1.0 - 1.0e-15)
  2.0 * @math.atanh(arg) / sc
}

///|
pub impl RiemannianGeometry for PoincarePoint with fn parallel_transport(
  self,
  target,
  v,
) {
  let neg_x = vec_scale(self.coords, -1.0)
  let gyr_v = mobius_gyration(self.c, target.coords, neg_x, v)
  let ratio = self.conformal_factor() / target.conformal_factor()
  vec_scale(gyr_v, ratio)
}

///|
pub extend PoincarePoint with RiemannianGeometry::{
  metric_inner,
  exp_map,
  log_map,
  geodesic_dist,
  parallel_transport,
}

///|
/// Geodesic interpolation gamma_{x -> y}(t) = exp_x^c(t * log_x^c(y)).
pub fn PoincarePoint::geodesic_interp(
  self : PoincarePoint,
  other : PoincarePoint,
  t : Double,
) -> PoincarePoint {
  let v = self.log_map(other)
  self.exp_map(vec_scale(v, t))
}

///|
/// Riemannian metric tensor g_{ij}(x) = lambda_x^2 * delta_{ij}.
pub fn PoincarePoint::metric_matrix(self : PoincarePoint) -> DenseMat {
  let lam2 = self.conformal_factor() * self.conformal_factor()
  DenseMat::eye(self.dim()).scale(lam2)
}

///|
/// Specification of the Poincare-Riemannian Supermanifold M^{m|n}_c.
/// `m_bos` = bosonic dimension m; `n_ferm` = even fermionic dimension n = 2k;
/// `c` = hyperbolic curvature parameter (K = -c < 0);
/// `n_gen` = ambient Grassmann algebra generator count.
#derive(Debug, Eq)
pub(all) struct SuperManifold {
  m_bos : Int32
  n_ferm : Int32
  c : Double
  n_gen : Int32
}

///|
pub fn SuperManifold::new(
  m_bos : Int32,
  n_ferm : Int32,
  c : Double,
  n_gen~ : Int32 = 4,
) -> SuperManifold {
  let even_ferm = if (n_ferm & 1) == 0 { n_ferm } else { n_ferm + 1 }
  { m_bos, n_ferm: even_ferm, c, n_gen, }
}

///|
/// Superdimension sdim(M^{m|n}) = m - n (governs Berezinian volume scaling).
pub fn SuperManifold::super_dim(self : SuperManifold) -> Int32 {
  self.m_bos - self.n_ferm
}

///|
/// Canonical symplectic matrix J_{2k} = [[0, I_k], [-I_k, 0]] on the odd fiber.
pub fn canonical_symplectic(n_ferm : Int32) -> DenseMat {
  let k = n_ferm / 2
  let j = DenseMat::zeros(n_ferm, n_ferm)
  for r in 0..<k {
    j.set(r, r + k, 1.0)
    j.set(r + k, r, -1.0)
  }
  j
}

///|
/// Flat orthosymplectic metric G_0 = diag(I_m, J_{2k}) of signature (m | 2k)
/// (shared directly across supermanifold, osp(m|2k) Lie superalgebra, and super-mass Casimirs).
pub fn flat_osp_metric_mat(m_bos : Int32, n_ferm : Int32) -> DenseMat {
  let g = DenseMat::zeros(m_bos + n_ferm, m_bos + n_ferm)
  for i in 0..<m_bos {
    g.set(i, i, 1.0)
  }
  let k = n_ferm / 2
  for r in 0..<k {
    g.set(m_bos + r, m_bos + r + k, 1.0)
    g.set(m_bos + r + k, m_bos + r, -1.0)
  }
  g
}

///|
/// Symplectic odd spinor inner product <xi, eta>_{J_{2k}} = sum_{r=0}^{k-1} (xi^r eta^{r+k} - xi^{r+k} eta^r).
pub fn symplectic_odd_inner(
  xi : Array[Grassmann],
  eta : Array[Grassmann],
  n_gen : Int32,
) -> Grassmann {
  let k = xi.length().min(eta.length()) / 2
  let mut acc = Grassmann::zero(n_gen)
  for r in 0..<k {
    acc = acc + (xi[r] * eta[r + k] - xi[r + k] * eta[r])
  }
  acc
}

///|
/// Lambda_N-valued point z = (x^1, ..., x^m | xi^1, ..., xi^{2k}) on M^{m|2k}_c.
/// `bos` holds m even Grassmann supernumbers with c * sum body(x^i)^2 < 1;
/// `ferm` holds 2k odd Grassmann supernumbers.
#derive(Debug, Eq)
pub(all) struct SuperPoint {
  manifold : SuperManifold
  bos : Array[Grassmann]
  ferm : Array[Grassmann]
}

///|
pub fn SuperPoint::new(
  manifold : SuperManifold,
  bos : Array[Grassmann],
  ferm : Array[Grassmann],
) -> SuperPoint {
  let even_bos = Array::makei(manifold.m_bos, i => bos[i].even_part())
  let odd_ferm = Array::makei(manifold.n_ferm, a => ferm[a].odd_part())
  { manifold, bos: even_bos, ferm: odd_ferm, }
}

///|
/// Construct a SuperPoint from classical bosonic coordinates and odd spinor xi.
pub fn SuperPoint::from_body_and_ferm(
  manifold : SuperManifold,
  x : Array[Double],
  ferm : Array[Grassmann],
) -> SuperPoint {
  let p = PoincarePoint::new(manifold.c, x)
  let bos = p.coords.map(v => Grassmann::scalar(manifold.n_gen, v))
  SuperPoint::new(manifold, bos, ferm)
}

///|
/// Negate superpoint: -z = (-x | -xi).
pub fn SuperPoint::neg_point(self : SuperPoint) -> SuperPoint {
  {
    manifold: self.manifold,
    bos: self.bos.map(x => -x),
    ferm: self.ferm.map(xi => -xi),
  }
}

///|
/// Orthosymplectic graded-symmetric inner product <z, w>_{m|2k} in Lambda_{N, even}:
///   <z, w>_s = sum_{i=1}^m x^i y^i + sum_{r=1}^k (xi^r eta^{r+k} - xi^{r+k} eta^r).
/// Exact symmetry <z, w>_s == <w, z>_s follows from odd Grassmann anticommutation!
pub fn super_osp_inner(z : SuperPoint, w : SuperPoint) -> Grassmann {
  let n_gen = z.manifold.n_gen.max(w.manifold.n_gen)
  let m = z.manifold.m_bos.min(w.manifold.m_bos)
  let mut acc = Grassmann::zero(n_gen)
  for i in 0..<m {
    acc = acc + z.bos[i] * w.bos[i]
  }
  acc + symplectic_odd_inner(z.ferm, w.ferm, n_gen)
}

///|
/// Squared orthosymplectic super-radius r_s^2(z) = <z, z>_s = sum (x^i)^2 + 2 sum xi^r xi^{r+k}.
/// Notice the fermionic bilinear 2 xi^r xi^{r+k} is NON-ZERO and EVEN!
pub fn SuperPoint::super_radius_sq(self : SuperPoint) -> Grassmann {
  super_osp_inner(self, self)
}

///|
/// Super-conformal factor lambda_c(z) = 2 / (1 - c * <z, z>_s) in Lambda_{N, even}.
pub fn SuperPoint::super_conformal_factor(self : SuperPoint) -> Grassmann {
  let n_gen = self.manifold.n_gen
  let one = Grassmann::scalar(n_gen, 1.0)
  let two = Grassmann::scalar(n_gen, 2.0)
  two / (one - self.super_radius_sq().smul(self.manifold.c))
}

///|
/// Super-Mobius gyrovector addition z (+)_c w on M^{m|2k}_c.
/// Simultaneously couples bosonic hierarchy translation and fermionic soul backreaction.
pub fn super_mobius_add(z : SuperPoint, w : SuperPoint) -> SuperPoint {
  let m = z.manifold
  let c = m.c
  let one = Grassmann::scalar(m.n_gen, 1.0)
  let z2 = z.super_radius_sq()
  let w2 = w.super_radius_sq()
  let zw = super_osp_inner(z, w)
  let denom = one + zw.smul(2.0 * c) + (z2 * w2).smul(c * c)
  let alpha = (one + zw.smul(2.0 * c) + w2.smul(c)) / denom
  let beta = (one - z2.smul(c)) / denom
  let bos = Array::makei(m.m_bos, i => alpha * z.bos[i] + beta * w.bos[i])
  let ferm = Array::makei(m.n_ferm, a => alpha * z.ferm[a] + beta * w.ferm[a])
  { manifold: m, bos, ferm, }
}

///|
/// Exact Super-Poincare geodesic distance d_c(z, w) in Lambda_{N, even}
/// for points with distinct DeWitt bodies (body(z) != body(w)):
///   d_c(z, w) = (2 / sqrt(c)) * atanh(sqrt(c) * sqrt(<(-z) (+)_c w, (-z) (+)_c w>_s)).
/// Invariant under OSp(m|2k) super-rotations and super-Mobius left isometries.
pub fn super_geodesic_dist(z : SuperPoint, w : SuperPoint) -> Grassmann {
  let c = z.manifold.c
  let sc = c.sqrt()
  let diff = super_mobius_add(z.neg_point(), w)
  let r2 = diff.super_radius_sq()
  if r2.body() <= 1.0e-24 {
    return Grassmann::zero(z.manifold.n_gen)
  }
  let arg = r2.sqrt().smul(sc)
  arg.atanh().smul(2.0 / sc)
}

///|
/// Exact Berezinian (superdeterminant) Ber(G(z)) = lambda_c(z)^{2 * sdim}
/// computed in O(|m - n|) multiplications (returns exact 1 at criticality m == n).
pub fn SuperPoint::metric_berezinian(self : SuperPoint) -> Grassmann {
  let sdim = self.manifold.super_dim()
  let mut acc = Grassmann::scalar(self.manifold.n_gen, 1.0)
  if sdim == 0 {
    return acc
  }
  let lam = self.super_conformal_factor()
  let lam2 = lam * lam
  let base = if sdim > 0 { lam2 } else { lam2.inv() }
  for _ in 0..<sdim.abs() {
    acc = acc * base
  }
  acc
}

///|
/// Berezinian Riemannian volume density sqrt(Ber(G(z))) = lambda_c(z)^{m - n}.
/// At supersymmetric criticality m == n, returns identically 1 + 0*soul everywhere!
pub fn SuperPoint::volume_density(self : SuperPoint) -> Grassmann {
  self.metric_berezinian().sqrt()
}

///|
/// Hyperbolic ball shell volume scaling ratio R_{m|n}(r) = (2 / (1 - c r^2))^{m - n},
/// quantifying exact dimensional reduction of hyperbolic volume explosion.
pub fn SuperManifold::effective_volume_density_at_radius(
  self : SuperManifold,
  r : Double,
) -> Double {
  let lam = 2.0 / (1.0 - self.c * r * r)
  @math.pow(lam, self.super_dim().to_double())
}
