///|
/// Core Categorical & Z_2-Graded Algebraic Trait Hierarchy.
/// Written in MoonBit v0.10.20 (explicit `fn` in trait/impl, `#derive(...)`,
/// polymorphic trait methods, and explicit `pub extend`).

///|
/// Z_2 grading group {Even = 0, Odd = 1} governing all super-structures.
#derive(Debug, Eq, Hash)
pub(all) enum Parity {
  Even
  Odd
}

///|
/// Group addition in Z_2 = Z / 2Z.
pub fn Parity::add_z2(self : Parity, other : Parity) -> Parity {
  match (self, other) {
    (Even, Even) | (Odd, Odd) => Even
    _ => Odd
  }
}

///|
/// Integer degree |p| in {0, 1}.
pub fn Parity::degree(self : Parity) -> Int32 {
  match self {
    Even => 0
    Odd => 1
  }
}

///|
/// Koszul braiding sign functor kappa(p, q) = (-1)^{|p||q|}.
/// Only (Odd, Odd) produces -1.0; all other parity pairs produce +1.0.
pub fn koszul_sign(p : Parity, q : Parity) -> Double {
  match (p, q) {
    (Odd, Odd) => -1.0
    _ => 1.0
  }
}

///|
/// Abelian group abstraction (A, +, 0, -) with an archive squared seminorm.
pub(open) trait AbelianGroup {
  fn zero_elem() -> Self
  fn add_elem(Self, Self) -> Self
  fn neg_elem(Self) -> Self
  fn sub_elem(Self, Self) -> Self = _
  fn norm_sq(Self) -> Double
}

///|
impl AbelianGroup with fn sub_elem(self, other) {
  AbelianGroup::add_elem(self, AbelianGroup::neg_elem(other))
}

///|
/// Left R-module abstraction extending AbelianGroup.
pub(open) trait Module: AbelianGroup {
  fn scale(Self, Double) -> Self
}

///|
/// Associative unital ring abstraction.
pub(open) trait Ring: AbelianGroup {
  fn one_elem() -> Self
  fn mul_elem(Self, Self) -> Self
}

///|
/// Associative unital Z_2-graded superalgebra over R with DeWitt body-soul split.
pub(open) trait SuperAlgebra: Module + Ring {
  fn even_part(Self) -> Self
  fn odd_part(Self) -> Self
  fn grade_involution(Self) -> Self = _
  fn body(Self) -> Double
  fn soul(Self) -> Self
}

///|
impl SuperAlgebra with fn grade_involution(self) {
  AbelianGroup::sub_elem(
    SuperAlgebra::even_part(self),
    SuperAlgebra::odd_part(self),
  )
}

///|
/// Lie superalgebra g = g_0 (+) g_1 with graded superbracket [X, Y]_s.
/// Includes a polymorphic functorial action hook `map_bracket` illustrating
/// MoonBit v0.10 polymorphic trait methods.
pub(open) trait LieSuperAlgebra: Module {
  fn sbracket(Self, Self) -> Self
  fn parity_of(Self) -> Parity
  fn[R] eval_bilinear(Self, Self, (Self) -> R) -> R = _
}

///|
impl LieSuperAlgebra with fn eval_bilinear(self, other, observer) {
  observer(LieSuperAlgebra::sbracket(self, other))
}

///|
/// Affine space (torsor) A modeled on its translation vector/module space V:
///   translate(p, diff(q, p)) == q,
///   diff(r, q) + diff(q, p)  == diff(r, p) (Chasles relation).
pub(open) trait AffineTorsor {
  fn translate(Self, Array[Double]) -> Self
  fn diff_vec(Self, Self) -> Array[Double]
  fn affine_interp(Self, Self, Double) -> Self
}

///|
/// Riemannian manifold M equipped with metric inner product, exp, log,
/// geodesic distance, and Levi-Civita parallel transport.
pub(open) trait RiemannianGeometry {
  fn metric_inner(Self, Array[Double], Array[Double]) -> Double
  fn exp_map(Self, Array[Double]) -> Self
  fn log_map(Self, Self) -> Array[Double]
  fn geodesic_dist(Self, Self) -> Double
  fn parallel_transport(Self, Self, Array[Double]) -> Array[Double]
}

///|
/// Generic cyclic Super-Jacobiator derived purely from the LieSuperAlgebra trait:
/// J_s(X, Y, Z) = (-1)^{|X||Z|} [X, [Y, Z]_s]_s
///              + (-1)^{|Y||X|} [Y, [Z, X]_s]_s
///              + (-1)^{|Z||Y|} [Z, [X, Y]_s]_s.
pub fn[L : LieSuperAlgebra] super_jacobiator(x : L, y : L, z : L) -> L {
  let px = LieSuperAlgebra::parity_of(x)
  let py = LieSuperAlgebra::parity_of(y)
  let pz = LieSuperAlgebra::parity_of(z)
  let t1 = Module::scale(
    LieSuperAlgebra::sbracket(x, LieSuperAlgebra::sbracket(y, z)),
    koszul_sign(px, pz),
  )
  let t2 = Module::scale(
    LieSuperAlgebra::sbracket(y, LieSuperAlgebra::sbracket(z, x)),
    koszul_sign(py, px),
  )
  let t3 = Module::scale(
    LieSuperAlgebra::sbracket(z, LieSuperAlgebra::sbracket(x, y)),
    koszul_sign(pz, py),
  )
  AbelianGroup::add_elem(AbelianGroup::add_elem(t1, t2), t3)
}

///|
/// Generic graded Leibniz (adjoint derivation) defect:
/// D(X, Y, Z) = [X, [Y, Z]_s]_s - [[X, Y]_s, Z]_s - (-1)^{|X||Y|} [Y, [X, Z]_s]_s.
pub fn[L : LieSuperAlgebra] adjoint_leibniz_defect(x : L, y : L, z : L) -> L {
  let px = LieSuperAlgebra::parity_of(x)
  let py = LieSuperAlgebra::parity_of(y)
  let lhs = LieSuperAlgebra::sbracket(x, LieSuperAlgebra::sbracket(y, z))
  let rhs1 = LieSuperAlgebra::sbracket(LieSuperAlgebra::sbracket(x, y), z)
  let rhs2 = Module::scale(
    LieSuperAlgebra::sbracket(y, LieSuperAlgebra::sbracket(x, z)),
    koszul_sign(px, py),
  )
  AbelianGroup::sub_elem(lhs, AbelianGroup::add_elem(rhs1, rhs2))
}

///|
/// Generic graded skew-symmetry defect:
/// S(X, Y) = [X, Y]_s + (-1)^{|X||Y|} [Y, X]_s.
pub fn[L : LieSuperAlgebra] graded_skew_defect(x : L, y : L) -> L {
  let s = koszul_sign(
    LieSuperAlgebra::parity_of(x),
    LieSuperAlgebra::parity_of(y),
  )
  AbelianGroup::add_elem(
    LieSuperAlgebra::sbracket(x, y),
    Module::scale(LieSuperAlgebra::sbracket(y, x), s),
  )
}

///|
/// NaN-safe floating-point proximity check |a - b| < eps (returns false on NaN).
pub fn approx(a : Double, b : Double, eps : Double) -> Bool {
  (a - b).abs() < eps
}

///|
/// Complex number z = re + i * im unifying the Hamel-basis field C (algo8)
/// with PoPE polar fibers U(1)^d, Laurent meromorphic germs, and Sato hyperfunctions (algorithm04).
#derive(Debug, Eq)
pub(all) struct Complex {
  re : Double
  im : Double
}

///|
pub fn Complex::new(re : Double, im : Double) -> Complex {
  { re, im, }
}

///|
pub fn Complex::zero() -> Complex {
  { re: 0.0, im: 0.0, }
}

///|
pub fn Complex::one() -> Complex {
  { re: 1.0, im: 0.0, }
}

///|
pub fn Complex::i_unit() -> Complex {
  { re: 0.0, im: 1.0, }
}

///|
/// Polar form r * exp(i * phi) = r * (cos phi + i sin phi).
pub fn Complex::from_polar(radius : Double, phase : Double) -> Complex {
  { re: radius * @math.cos(phase), im: radius * @math.sin(phase), }
}

///|
pub fn Complex::conj(self : Complex) -> Complex {
  { re: self.re, im: -self.im, }
}

///|
pub fn Complex::scale(self : Complex, s : Double) -> Complex {
  { re: self.re * s, im: self.im * s, }
}

///|
pub fn Complex::norm_sq(self : Complex) -> Double {
  self.re * self.re + self.im * self.im
}

///|
/// Compatibility alias for squared modulus |z|^2 = re^2 + im^2 (from algo8).
pub fn Complex::norm2(self : Complex) -> Double {
  self.norm_sq()
}

///|
pub fn Complex::abs(self : Complex) -> Double {
  if !self.re.is_finite() || !self.im.is_finite() {
    return self.norm_sq().sqrt()
  }
  let scale = self.re.abs().max(self.im.abs())
  if scale == 0.0 {
    return 0.0
  }
  let re = self.re / scale
  let im = self.im / scale
  scale * (re * re + im * im).sqrt()
}

///|
/// Compatibility alias for Euclidean modulus |z| = sqrt(re^2 + im^2) (from algo8).
pub fn Complex::norm(self : Complex) -> Double {
  self.abs()
}

///|
/// Near-zero field element predicate |z|^2 < 1e-30 (from algo8).
pub fn Complex::is_zero(self : Complex) -> Bool {
  self.norm_sq() < 1.0e-30
}

///|
pub fn Complex::phase(self : Complex) -> Double {
  @math.atan2(self.im, self.re)
}

///|
/// Scaled multiplicative inverse on C \ {0}; exact zero retains the package's zero fallback.
/// Scaling before squaring avoids classifying small nonzero values as zero and avoids
/// overflow for large finite coordinates.
pub fn Complex::inv(self : Complex) -> Complex {
  let scale = self.re.abs().max(self.im.abs())
  if scale == 0.0 {
    return Complex::zero()
  }
  let re = self.re / scale
  let im = self.im / scale
  let norm_sq = re * re + im * im
  { re: re / norm_sq / scale, im: -im / norm_sq / scale, }
}

///|
/// Hermitian scalar product z1^* * z2 (conjugate linear in first slot).
pub fn Complex::hermitian_dot(a : Complex, b : Complex) -> Complex {
  a.conj() * b
}

///|
pub impl Add for Complex with fn add(self, other) {
  { re: self.re + other.re, im: self.im + other.im, }
}

///|
pub impl Sub for Complex with fn sub(self, other) {
  { re: self.re - other.re, im: self.im - other.im, }
}

///|
pub impl Mul for Complex with fn mul(self, other) {
  {
    re: self.re * other.re - self.im * other.im,
    im: self.re * other.im + self.im * other.re,
  }
}

///|
pub impl Div for Complex with fn div(self, other) {
  self * other.inv()
}

///|
pub impl Neg for Complex with fn neg(self) {
  { re: -self.re, im: -self.im, }
}

///|
pub impl AbelianGroup for Complex with fn zero_elem() {
  Complex::zero()
}

///|
pub impl AbelianGroup for Complex with fn add_elem(self, other) {
  self + other
}

///|
pub impl AbelianGroup for Complex with fn neg_elem(self) {
  -self
}

///|
pub impl AbelianGroup for Complex with fn norm_sq(self) {
  self.re * self.re + self.im * self.im
}

///|
pub impl Module for Complex with fn scale(self, s) {
  { re: self.re * s, im: self.im * s, }
}

///|
pub impl Ring for Complex with fn one_elem() {
  Complex::one()
}

///|
pub impl Ring for Complex with fn mul_elem(self, other) {
  self * other
}

///|
/// Bit population count on a non-negative bitmask.
pub fn popcount(mask : Int32) -> Int32 {
  let mut m = mask
  let mut c = 0
  while m > 0 {
    c = c + (m & 1)
    m = m >> 1
  }
  c
}

///|
/// Exact Koszul reordering sign for exterior wedge product theta^I ^ theta^J.
/// Returns 0.0 if I & J != 0 (Pauli exclusion / nilpotency theta^a ^ theta^a = 0),
/// else (-1)^{#{ (i, j) in I x J : i > j }}.
pub fn wedge_sign(mask_i : Int32, mask_j : Int32, n_gen : Int32) -> Double {
  if (mask_i & mask_j) != 0 {
    return 0.0
  }
  let mut swaps = 0
  let mut higher_in_i = mask_i
  for bit in 0..<n_gen {
    higher_in_i = higher_in_i >> 1
    if ((mask_j >> bit) & 1) != 0 {
      swaps = swaps + popcount(higher_in_i)
    }
  }
  if (swaps & 1) == 0 {
    1.0
  } else {
    -1.0
  }
}

///|
/// Exact Grassmann (Exterior) Superalgebra Lambda_N = /\ R^N with 2^N basis blades.
/// Basis blade indexed by bitmask `mask` represents theta^{i_1} ^ ... ^ theta^{i_k}
/// with i_1 < ... < i_k. Supports exact super-arithmetic, finite Neumann inversion,
/// smooth functional calculus, left Berezin differentiation, and Berezin integration.
#derive(Debug, Eq)
pub(all) struct Grassmann {
  n_gen : Int32
  coeffs : Array[Double]
}

///|
/// Default number of Grassmann generators for trait-level zero/one construction.
pub const DEFAULT_GRASSMANN_GEN : Int32 = 4

///|
pub fn Grassmann::zero(n_gen : Int32) -> Grassmann {
  let dim = 1 << n_gen
  { n_gen, coeffs: Array::make(dim, 0.0), }
}

///|
pub fn Grassmann::scalar(n_gen : Int32, value : Double) -> Grassmann {
  let g = Grassmann::zero(n_gen)
  g.coeffs[0] = value
  g
}

///|
/// Odd generator theta^alpha (0 <= alpha < n_gen), satisfying theta^a * theta^b = -theta^b * theta^a
/// and (theta^a)^2 = 0.
pub fn Grassmann::generator(
  n_gen : Int32,
  alpha : Int32,
  coeff~ : Double = 1.0,
) -> Grassmann {
  let g = Grassmann::zero(n_gen)
  if alpha >= 0 && alpha < n_gen {
    g.coeffs[1 << alpha] = coeff
  }
  g
}

///|
/// Basis blade theta^mask.
pub fn Grassmann::blade(
  n_gen : Int32,
  mask : Int32,
  coeff~ : Double = 1.0,
) -> Grassmann {
  let g = Grassmann::zero(n_gen)
  let dim = 1 << n_gen
  if mask >= 0 && mask < dim {
    g.coeffs[mask] = coeff
  }
  g
}

///|
/// Lift two Grassmann elements into a common ambient Lambda_{max(n1, n2)}.
fn unify_gen(a : Grassmann, b : Grassmann) -> Int32 {
  if a.n_gen >= b.n_gen {
    a.n_gen
  } else {
    b.n_gen
  }
}

///|
pub fn Grassmann::coeff_at(self : Grassmann, mask : Int32) -> Double {
  if mask >= 0 && mask < self.coeffs.length() {
    self.coeffs[mask]
  } else {
    0.0
  }
}

///|
pub impl Add for Grassmann with fn add(self, other) {
  let n = unify_gen(self, other)
  let dim = 1 << n
  let coeffs = Array::makei(dim, i => self.coeff_at(i) + other.coeff_at(i))
  { n_gen: n, coeffs, }
}

///|
pub impl Sub for Grassmann with fn sub(self, other) {
  let n = unify_gen(self, other)
  let dim = 1 << n
  let coeffs = Array::makei(dim, i => self.coeff_at(i) - other.coeff_at(i))
  { n_gen: n, coeffs, }
}

///|
pub impl Neg for Grassmann with fn neg(self) {
  { n_gen: self.n_gen, coeffs: self.coeffs.map(c => -c), }
}

///|
/// Graded-associative exterior product obeying Koszul sign and Pauli exclusion.
pub impl Mul for Grassmann with fn mul(self, other) {
  let n = unify_gen(self, other)
  let dim = 1 << n
  let out = Array::make(dim, 0.0)
  for i in 0..<self.coeffs.length() {
    let ci = self.coeffs[i]
    if ci != 0.0 {
      for j in 0..<other.coeffs.length() {
        let cj = other.coeffs[j]
        if cj != 0.0 && (i & j) == 0 {
          let s = wedge_sign(i, j, n)
          out[i | j] = out[i | j] + s * ci * cj
        }
      }
    }
  }
  { n_gen: n, coeffs: out, }
}

///|
pub fn Grassmann::smul(self : Grassmann, s : Double) -> Grassmann {
  { n_gen: self.n_gen, coeffs: self.coeffs.map(c => c * s), }
}

///|
pub impl AbelianGroup for Grassmann with fn zero_elem() {
  Grassmann::zero(DEFAULT_GRASSMANN_GEN)
}

///|
pub impl AbelianGroup for Grassmann with fn add_elem(self, other) {
  self + other
}

///|
pub impl AbelianGroup for Grassmann with fn neg_elem(self) {
  -self
}

///|
pub impl AbelianGroup for Grassmann with fn norm_sq(self) {
  for c in self.coeffs; acc = 0.0 {
    continue acc + c * c
  } nobreak {
    acc
  }
}

///|
pub impl Module for Grassmann with fn scale(self, s) {
  self.smul(s)
}

///|
pub impl Ring for Grassmann with fn one_elem() {
  Grassmann::scalar(DEFAULT_GRASSMANN_GEN, 1.0)
}

///|
pub impl Ring for Grassmann with fn mul_elem(self, other) {
  self * other
}

///|
pub impl SuperAlgebra for Grassmann with fn even_part(self) {
  let coeffs = Array::makei(self.coeffs.length(), i => {
    if (popcount(i) & 1) == 0 {
      self.coeffs[i]
    } else {
      0.0
    }
  })
  { n_gen: self.n_gen, coeffs, }
}

///|
pub impl SuperAlgebra for Grassmann with fn odd_part(self) {
  let coeffs = Array::makei(self.coeffs.length(), i => {
    if (popcount(i) & 1) == 1 {
      self.coeffs[i]
    } else {
      0.0
    }
  })
  { n_gen: self.n_gen, coeffs, }
}

///|
pub impl SuperAlgebra for Grassmann with fn body(self) {
  self.coeffs[0]
}

///|
pub impl SuperAlgebra for Grassmann with fn soul(self) {
  let coeffs = self.coeffs.copy()
  coeffs[0] = 0.0
  { n_gen: self.n_gen, coeffs, }
}

///|
/// Explicitly expose SuperAlgebra methods as dot-methods (MoonBit v0.10 `extend`).
pub extend Grassmann with SuperAlgebra::{
  body,
  soul,
  even_part,
  odd_part,
  grade_involution,
}

///|
/// Explicitly expose AbelianGroup::norm_sq as a dot-method.
pub extend Grassmann with AbelianGroup::{norm_sq}

///|
/// Euclidean coefficient norm ||a||_2 across all 2^N Grassmann blades.
pub fn Grassmann::l2_norm(self : Grassmann) -> Double {
  self.norm_sq().sqrt()
}

///|
/// Determine pure parity if homogeneous (defaults to Even for zero).
pub fn Grassmann::parity(self : Grassmann) -> Parity {
  let ev = self.even_part().norm_sq()
  let od = self.odd_part().norm_sq()
  if od > 1.0e-24 && ev <= 1.0e-24 {
    Odd
  } else {
    Even
  }
}

///|
/// Exact multiplicative inverse (b + s)^{-1} = b^{-1} sum_{k=0}^{N} (-s / b)^k.
/// Terminates exactly at k = n_gen because s^{n_gen + 1} == 0 identically.
/// ZERO-DIVISOR GUARD: an element whose body vanishes has no inverse; in that case
/// the zero element is returned instead of letting 1/0 = Inf propagate as NaN.
pub fn Grassmann::inv(self : Grassmann) -> Grassmann {
  let b = self.body()
  if b.abs() <= 1.0e-300 {
    return Grassmann::zero(self.n_gen)
  }
  let inv_b = 1.0 / b
  let u = self.soul().smul(-inv_b)
  let mut acc = Grassmann::scalar(self.n_gen, 1.0)
  let mut power = Grassmann::scalar(self.n_gen, 1.0)
  for _ in 0..<self.n_gen {
    power = power * u
    acc = acc + power
  }
  acc.smul(inv_b)
}

///|
pub impl Div for Grassmann with fn div(self, other) {
  self * other.inv()
}

///|
/// Exact smooth functional calculus f(b + s) = sum_{k=0}^{N} (f^{(k)}(b) / k!) s^k.
pub fn Grassmann::lift_taylor(
  self : Grassmann,
  derivs : Array[Double],
) -> Grassmann {
  let s = self.soul()
  let mut acc = Grassmann::scalar(self.n_gen, derivs[0])
  let mut power = Grassmann::scalar(self.n_gen, 1.0)
  let mut fact = 1.0
  let max_k = if self.n_gen < derivs.length() - 1 {
    self.n_gen
  } else {
    derivs.length() - 1
  }
  for k in 1..<=max_k {
    fact = fact * k.to_double()
    power = power * s
    acc = acc + power.smul(derivs[k] / fact)
  }
  acc
}

///|
/// Exact super-exponential exp(b + s) = exp(b) * sum_{k=0}^{N} s^k / k!.
pub fn Grassmann::exp(self : Grassmann) -> Grassmann {
  let eb = @math.exp(self.body())
  let derivs = Array::make(self.n_gen + 1, eb)
  self.lift_taylor(derivs)
}

///|
/// Exact super-logarithm ln(b + s) = ln(b) + sum_{k=1}^{N} (-1)^{k-1} (s/b)^k / k.
/// DOMAIN: b != 0. Outside the domain the zero element is returned rather than
/// letting ln(0) = -Inf and 1/0 = Inf propagate as NaN.
pub fn Grassmann::ln(self : Grassmann) -> Grassmann {
  let b = self.body()
  if b.abs() <= 1.0e-300 {
    return Grassmann::zero(self.n_gen)
  }
  let u = self.soul().smul(1.0 / b)
  let mut acc = Grassmann::scalar(self.n_gen, @math.ln(b))
  let mut power = Grassmann::scalar(self.n_gen, 1.0)
  for k in 1..<=self.n_gen {
    power = power * u
    let sign = if (k & 1) == 1 { 1.0 } else { -1.0 }
    acc = acc + power.smul(sign / k.to_double())
  }
  acc
}

///|
/// Exact principal square root sqrt(b + s) for b > 0.
/// DOMAIN: b > 0. Outside the domain the zero element is returned rather than
/// letting sqrt(b < 0) and 1/b propagate as NaN.
pub fn Grassmann::sqrt(self : Grassmann) -> Grassmann {
  let b = self.body()
  if b <= 0.0 {
    return Grassmann::zero(self.n_gen)
  }
  let sb = b.sqrt()
  let u = self.soul().smul(1.0 / b)
  let mut acc = Grassmann::scalar(self.n_gen, 1.0)
  let mut power = Grassmann::scalar(self.n_gen, 1.0)
  let mut binom = 1.0
  for k in 1..<=self.n_gen {
    binom = binom * (0.5 - (k - 1).to_double()) / k.to_double()
    power = power * u
    acc = acc + power.smul(binom)
  }
  acc.smul(sb)
}

///|
/// Exact super-atanh(z) = 0.5 * (ln(1 + z) - ln(1 - z)) for |body(z)| < 1.
pub fn Grassmann::atanh(self : Grassmann) -> Grassmann {
  let one = Grassmann::scalar(self.n_gen, 1.0)
  ((one + self).ln() - (one - self).ln()).smul(0.5)
}

///|
/// Exact super-tanh(z) = (exp(2z) - 1) / (exp(2z) + 1).
pub fn Grassmann::tanh(self : Grassmann) -> Grassmann {
  let one = Grassmann::scalar(self.n_gen, 1.0)
  let e2 = self.smul(2.0).exp()
  (e2 - one) / (e2 + one)
}

///|
/// Exact super-softplus sigma(z) = ln(1 + exp(z)) used by Super-PoPE.
pub fn Grassmann::softplus(self : Grassmann) -> Grassmann {
  let one = Grassmann::scalar(self.n_gen, 1.0)
  if self.body() > 20.0 {
    self + (one + (-self).exp()).ln()
  } else {
    (one + self.exp()).ln()
  }
}

///|
/// Left Berezin derivative d_L / d(theta^alpha):
/// satisfies graded Leibniz rule d_a(f * g) = (d_a f) * g + (-1)^{|f|} f * (d_a g).
pub fn Grassmann::berezin_deriv(self : Grassmann, alpha : Int32) -> Grassmann {
  let out = Grassmann::zero(self.n_gen)
  let bit = 1 << alpha
  let lower_mask = bit - 1
  for mask in 0..<self.coeffs.length() {
    if (mask & bit) != 0 && self.coeffs[mask] != 0.0 {
      let n_before = popcount(mask & lower_mask)
      let sign = if (n_before & 1) == 0 { 1.0 } else { -1.0 }
      out.coeffs[mask ^ bit] = sign * self.coeffs[mask]
    }
  }
  out
}

///|
/// Top-form Berezin integral \int d(theta^{N-1}) ... d(theta^0) f(theta).
/// Extracts the coefficient of theta^0 ^ theta^1 ^ ... ^ theta^{N-1}.
pub fn Grassmann::berezin_integral(self : Grassmann) -> Double {
  let top = (1 << self.n_gen) - 1
  self.coeffs[top]
}

///|
/// Dense Real Matrix utility for spectral decompositions, PDEs, NCG, and Fisher geometry.
#derive(Debug, Eq)
pub(all) struct DenseMat {
  rows : Int32
  cols : Int32
  data : Array[Double]
}

///|
pub fn DenseMat::zeros(rows : Int32, cols : Int32) -> DenseMat {
  { rows, cols, data: Array::make(rows * cols, 0.0), }
}

///|
pub fn DenseMat::eye(n : Int32) -> DenseMat {
  let m = DenseMat::zeros(n, n)
  for i in 0..<n {
    m.data[i * n + i] = 1.0
  }
  m
}

///|
/// Shared row-major body construction: fill `rows x cols` from the index generator `f`.
/// Used by both `DenseMat::from_fn` and `TropMatrix::from_fn`, whose constructors differ
/// only in the container they wrap (the pre-fill value is always overwritten by `f`).
fn dense_from_fn_body(
  rows : Int32,
  cols : Int32,
  f : (Int32, Int32) -> Double,
) -> Array[Double] {
  let data = Array::make(rows * cols, 0.0)
  for i in 0..<rows {
    for j in 0..<cols {
      data[i * cols + j] = f(i, j)
    }
  }
  data
}

///|
pub fn DenseMat::from_fn(
  rows : Int32,
  cols : Int32,
  f : (Int32, Int32) -> Double,
) -> DenseMat {
  { rows, cols, data: dense_from_fn_body(rows, cols, f), }
}

///|
pub fn DenseMat::get(self : DenseMat, r : Int32, c : Int32) -> Double {
  self.data[r * self.cols + c]
}

///|
pub fn DenseMat::set(self : DenseMat, r : Int32, c : Int32, v : Double) -> Unit {
  self.data[r * self.cols + c] = v
}

///|
pub fn DenseMat::clone(self : DenseMat) -> DenseMat {
  { rows: self.rows, cols: self.cols, data: self.data.copy(), }
}

///|
pub fn DenseMat::transpose(self : DenseMat) -> DenseMat {
  DenseMat::from_fn(self.cols, self.rows, (i, j) => self.get(j, i))
}

///|
pub fn DenseMat::scale(self : DenseMat, s : Double) -> DenseMat {
  { rows: self.rows, cols: self.cols, data: self.data.map(x => x * s), }
}

///|
pub impl Add for DenseMat with fn add(self, other) {
  {
    rows: self.rows,
    cols: self.cols,
    data: Array::makei(self.data.length(), i => self.data[i] + other.data[i]),
  }
}

///|
pub impl Sub for DenseMat with fn sub(self, other) {
  {
    rows: self.rows,
    cols: self.cols,
    data: Array::makei(self.data.length(), i => self.data[i] - other.data[i]),
  }
}

///|
pub impl Neg for DenseMat with fn neg(self) {
  self.scale(-1.0)
}

///|
pub impl Mul for DenseMat with fn mul(self, other) {
  let out = DenseMat::zeros(self.rows, other.cols)
  for i in 0..<self.rows {
    for k in 0..<self.cols {
      let aik = self.get(i, k)
      if aik != 0.0 {
        for j in 0..<other.cols {
          out.data[i * other.cols + j] = out.data[i * other.cols + j] +
            aik * other.get(k, j)
        }
      }
    }
  }
  out
}

///|
pub fn DenseMat::matvec(self : DenseMat, v : Array[Double]) -> Array[Double] {
  Array::makei(self.rows, i => {
    let mut s = 0.0
    for j in 0..<self.cols {
      s = s + self.get(i, j) * v[j]
    }
    s
  })
}

///|
pub fn DenseMat::trace(self : DenseMat) -> Double {
  let n = if self.rows < self.cols { self.rows } else { self.cols }
  let mut s = 0.0
  for i in 0..<n {
    s = s + self.get(i, i)
  }
  s
}

///|
pub fn DenseMat::frob_norm(self : DenseMat) -> Double {
  let mut s = 0.0
  for x in self.data {
    s = s + x * x
  }
  s.sqrt()
}

///|
/// Shared partial-pivoting helper: locate row r in start_row..<rows maximizing |A_{r, col}|.
fn DenseMat::find_pivot(
  self : DenseMat,
  start_row : Int32,
  col : Int32,
) -> (Int32, Double) {
  let mut piv = start_row
  let mut best = self.get(start_row, col).abs()
  for i in (start_row + 1)..<self.rows {
    let v = self.get(i, col).abs()
    if v > best {
      best = v
      piv = i
    }
  }
  (piv, best)
}

///|
/// Shared in-place row swap on columns start_col..<cols.
fn DenseMat::swap_rows(
  self : DenseMat,
  r1 : Int32,
  r2 : Int32,
  start_col~ : Int32 = 0,
) -> Unit {
  if r1 == r2 {
    return
  }
  for j in start_col..<self.cols {
    let tmp = self.get(r1, j)
    self.set(r1, j, self.get(r2, j))
    self.set(r2, j, tmp)
  }
}

///|
/// Solve A * x = b by Gaussian elimination with guarded partial pivoting
/// (never emits NaN/Inf on singular or rank-deficient systems).
pub fn DenseMat::solve_vec(self : DenseMat, b : Array[Double]) -> Array[Double] {
  let n = self.rows
  let a = self.clone()
  let x = b.copy()
  for k in 0..<n {
    let (piv, best) = a.find_pivot(k, k)
    if best <= 1.0e-15 {
      continue
    }
    if piv != k {
      a.swap_rows(k, piv, start_col=k)
      let tb = x[k]
      x[k] = x[piv]
      x[piv] = tb
    }
    let diag = a.get(k, k)
    for i in (k + 1)..<n {
      let factor = a.get(i, k) / diag
      for j in k..<n {
        a.set(i, j, a.get(i, j) - factor * a.get(k, j))
      }
      x[i] = x[i] - factor * x[k]
    }
  }
  let sol = Array::make(n, 0.0)
  for i in (n - 1)>=..0 {
    let diag = a.get(i, i)
    if diag.abs() > 1.0e-15 {
      let mut s = x[i]
      for j in (i + 1)..<n {
        s = s - a.get(i, j) * sol[j]
      }
      sol[i] = s / diag
    }
  }
  sol
}

///|
/// Matrix inverse via guarded Gauss-Jordan elimination with partial pivoting.
///
/// SINGULAR-PIVOT CONTRACT: a degenerate pivot (`best <= 1e-15`) means the matrix is
/// singular and no inverse exists, so the ZERO matrix is returned (the same neutral
/// element convention as `Grassmann::inv`, `gmat_even_det` and `gmat_even_inv`)
/// instead of a partially eliminated matrix that silently fails to satisfy
/// `A * A^{-1} == I`. Use `DenseMat::det` to test invertibility first.
pub fn DenseMat::inv(self : DenseMat) -> DenseMat {
  let n = self.rows
  let a = self.clone()
  let inv_m = DenseMat::eye(n)
  for k in 0..<n {
    let (piv, best) = a.find_pivot(k, k)
    if best <= 1.0e-15 {
      // SINGULAR: no inverse exists -> return the zero matrix (documented contract).
      return DenseMat::zeros(n, n)
    }
    a.swap_rows(k, piv)
    inv_m.swap_rows(k, piv)
    let inv_diag = 1.0 / a.get(k, k)
    for j in 0..<n {
      a.set(k, j, a.get(k, j) * inv_diag)
      inv_m.set(k, j, inv_m.get(k, j) * inv_diag)
    }
    for i in 0..<n {
      if i != k {
        let f = a.get(i, k)
        if f != 0.0 {
          for j in 0..<n {
            a.set(i, j, a.get(i, j) - f * a.get(k, j))
            inv_m.set(i, j, inv_m.get(i, j) - f * inv_m.get(k, j))
          }
        }
      }
    }
  }
  inv_m
}

///|
/// Exact determinant via LU with partial pivoting.
pub fn DenseMat::det(self : DenseMat) -> Double {
  let n = self.rows
  if n == 0 {
    return 1.0
  }
  let a = self.clone()
  let mut sign = 1.0
  let mut det_val = 1.0
  for k in 0..<n {
    let (piv, best) = a.find_pivot(k, k)
    if best <= 1.0e-15 {
      return 0.0
    }
    if piv != k {
      sign = -sign
      a.swap_rows(k, piv, start_col=k)
    }
    let diag = a.get(k, k)
    det_val = det_val * diag
    for i in (k + 1)..<n {
      let f = a.get(i, k) / diag
      for j in (k + 1)..<n {
        a.set(i, j, a.get(i, j) - f * a.get(k, j))
      }
    }
  }
  sign * det_val
}

///|
/// Row-reduced echelon form (RREF) with partial pivoting:
/// returns (rref_matrix, pivot_columns). Avoids condition-number squaring kappa(A)^2
/// of A^T A, giving exact algebraic rank and quotient/normal-space bases for arbitrary
/// rectangular matrices (stabilizers, Macaulay jet ideals, Koszul complexes, Tjurina spaces).
pub fn DenseMat::rref_with_pivots(
  self : DenseMat,
  tol~ : Double = 1.0e-10,
) -> (DenseMat, Array[Int32]) {
  let r = self.rows
  let c = self.cols
  let a = self.clone()
  let pivots : Array[Int32] = []
  let mut row = 0
  for col in 0..<c {
    if row >= r {
      break
    }
    let (piv, best) = a.find_pivot(row, col)
    if best <= tol {
      continue
    }
    a.swap_rows(row, piv, start_col=col)
    let inv_d = 1.0 / a.get(row, col)
    for j in col..<c {
      a.set(row, j, a.get(row, j) * inv_d)
    }
    for i in 0..<r {
      if i != row {
        let f = a.get(i, col)
        if f.abs() > 0.0 {
          a.set(i, col, 0.0)
          for j in (col + 1)..<c {
            a.set(i, j, a.get(i, j) - f * a.get(row, j))
          }
        }
      }
    }
    pivots.push(col)
    row = row + 1
  }
  (a, pivots)
}

///|
/// Matrix exponential exp(A) via scaling-and-squaring with 18-term Taylor series.
pub fn DenseMat::mat_exp(self : DenseMat) -> DenseMat {
  let n = self.rows
  let norm = self.frob_norm()
  let mut s = 0
  let mut scale_factor = 1.0
  while norm / scale_factor > 0.5 {
    s = s + 1
    scale_factor = scale_factor * 2.0
  }
  let a = self.scale(1.0 / scale_factor)
  let mut acc = DenseMat::eye(n)
  let mut term = DenseMat::eye(n)
  for k in 1..<=18 {
    term = (term * a).scale(1.0 / k.to_double())
    acc = acc + term
  }
  for _ in 0..<s {
    acc = acc * acc
  }
  acc
}

///|
/// Classical Jacobi eigensolver for real symmetric matrices A = V * diag(eigs) * V^T.
/// Handles n <= 1 cleanly and scales rotation budget with 15 * n^2 so larger symmetric
/// operators (n >= 15) converge unconditionally to machine precision.
pub fn DenseMat::sym_eigen(self : DenseMat) -> (Array[Double], DenseMat) {
  let n = self.rows
  if n <= 1 {
    return (Array::makei(n, i => self.get(i, i)), DenseMat::eye(n))
  }
  let a = self.clone()
  let v = DenseMat::eye(n)
  let max_rot = (15 * n * n).max(120)
  for _ in 0..<max_rot {
    let mut p = 0
    let mut q = 1
    let mut max_off = 0.0
    for i in 0..<n {
      for j in (i + 1)..<n {
        let val = a.get(i, j).abs()
        if val > max_off {
          max_off = val
          p = i
          q = j
        }
      }
    }
    if max_off < 1.0e-14 {
      break
    }
    let app = a.get(p, p)
    let aqq = a.get(q, q)
    let apq = a.get(p, q)
    let tau = (aqq - app) / (2.0 * apq)
    let t = if tau >= 0.0 {
      1.0 / (tau + (1.0 + tau * tau).sqrt())
    } else {
      -1.0 / (-tau + (1.0 + tau * tau).sqrt())
    }
    let c = 1.0 / (1.0 + t * t).sqrt()
    let s = t * c
    for r in 0..<n {
      if r != p && r != q {
        let arp = a.get(r, p)
        let arq = a.get(r, q)
        a.set(r, p, c * arp - s * arq)
        a.set(p, r, c * arp - s * arq)
        a.set(r, q, s * arp + c * arq)
        a.set(q, r, s * arp + c * arq)
      }
    }
    a.set(p, p, c * c * app - 2.0 * s * c * apq + s * s * aqq)
    a.set(q, q, s * s * app + 2.0 * s * c * apq + c * c * aqq)
    a.set(p, q, 0.0)
    a.set(q, p, 0.0)
    for r in 0..<n {
      let vrp = v.get(r, p)
      let vrq = v.get(r, q)
      v.set(r, p, c * vrp - s * vrq)
      v.set(r, q, s * vrp + c * vrq)
    }
  }
  let eigs = Array::makei(n, i => a.get(i, i))
  // Insertion sort ascending with matching eigenvector column swaps
  for i in 0..<n {
    let mut best = i
    for j in (i + 1)..<n {
      if eigs[j] < eigs[best] {
        best = j
      }
    }
    if best != i {
      let te = eigs[i]
      eigs[i] = eigs[best]
      eigs[best] = te
      for r in 0..<n {
        let tv = v.get(r, i)
        v.set(r, i, v.get(r, best))
        v.set(r, best, tv)
      }
    }
  }
  (eigs, v)
}

///|
/// Spectral operator 2-norm ||A||_op = sqrt(lambda_max(A^T A)).
pub fn DenseMat::op_norm(self : DenseMat) -> Double {
  if self.rows == 0 || self.cols == 0 {
    return 0.0
  }
  let (eigs, _) = (self.transpose() * self).sym_eigen()
  eigs[eigs.length() - 1].max(0.0).sqrt()
}

///|
/// Algebraic/numerical rank via partial-pivoted RREF (immune to A^T A condition squaring).
pub fn DenseMat::numerical_rank(
  self : DenseMat,
  tol~ : Double = 1.0e-9,
) -> Int32 {
  let (_, pivs) = self.rref_with_pivots(tol~)
  pivs.length()
}

///|
/// Numerically stable Boltzmann softmax mapping R^K -> Delta^{K-1} (shared across
/// Fisher geometry, tropical Viro-Maslov simplex diffeomorphism, and SGNE attention).
pub fn softmax_vec(logits : Array[Double]) -> Array[Double] {
  if logits.length() == 0 {
    return []
  }
  let mut max_l = logits[0]
  for x in logits {
    if x > max_l {
      max_l = x
    }
  }
  let exps = logits.map(x => @math.exp(x - max_l))
  let mut z = 0.0
  for e in exps {
    z = z + e
  }
  exps.map(e => e / z)
}

///|
/// Centered finite-difference Euclidean gradient nabla f(x) in R^d.
pub fn numerical_grad(
  f : (Array[Double]) -> Double,
  x : Array[Double],
  eps~ : Double = 1.0e-6,
) -> Array[Double] {
  let inv_2e = 0.5 / eps
  Array::makei(x.length(), j => {
    let xp = x.copy()
    xp[j] = xp[j] + eps
    let xm = x.copy()
    xm[j] = xm[j] - eps
    (f(xp) - f(xm)) * inv_2e
  })
}

///|
/// Centered finite-difference Jacobian matrix J_{ij}(x) = d phi_i / d x_j (m x d).
pub fn numerical_jacobian(
  phi : (Array[Double]) -> Array[Double],
  x : Array[Double],
  eps~ : Double = 1.0e-6,
) -> DenseMat {
  let d = x.length()
  let y0 = phi(x)
  let m = y0.length()
  let jac = DenseMat::zeros(m, d)
  let inv_2e = 0.5 / eps
  for j in 0..<d {
    let xp = x.copy()
    xp[j] = xp[j] + eps
    let xm = x.copy()
    xm[j] = xm[j] - eps
    let yp = phi(xp)
    let ym = phi(xm)
    for i in 0..<m {
      jac.set(i, j, (yp[i] - ym[i]) * inv_2e)
    }
  }
  jac
}

///|
/// Vector inner product helper.
pub fn vec_dot(a : Array[Double], b : Array[Double]) -> Double {
  let mut s = 0.0
  for i in 0..<a.length() {
    s = s + a[i] * b[i]
  }
  s
}

///|
/// Vector squared Euclidean norm.
pub fn vec_norm_sq(a : Array[Double]) -> Double {
  vec_dot(a, a)
}

///|
/// Vector Euclidean norm.
pub fn vec_norm(a : Array[Double]) -> Double {
  vec_norm_sq(a).sqrt()
}

///|
pub fn vec_add(a : Array[Double], b : Array[Double]) -> Array[Double] {
  Array::makei(a.length(), i => a[i] + b[i])
}

///|
pub fn vec_sub(a : Array[Double], b : Array[Double]) -> Array[Double] {
  Array::makei(a.length(), i => a[i] - b[i])
}

///|
pub fn vec_scale(a : Array[Double], s : Double) -> Array[Double] {
  a.map(x => x * s)
}
