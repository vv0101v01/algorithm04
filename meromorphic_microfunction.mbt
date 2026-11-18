///|
/// Module 15: Meromorphic Function Germs & Sato Microfunction Germs
/// (亞純函數胚 M_{n,0} 與佐藤微函數胚 C_{(x_0, i xi dx)} 統一引擎).
///
/// Implements:
///   1. (16) 亞純函數胚 `MeromorphicGerm` in M_{1,0} = Frac(O_{1,0}) = C{z}[z^{-1}]:
///        - Exact truncated Laurent field arithmetic (+, -, *, inv, /), formal derivative m',
///          and logarithmic derivative m'/m with automatic leading-zero cancellation,
///        - Discrete valuation ord_0(fg) == ord_0(f) + ord_0(g), ultrametric inequality
///          ord_0(f + g) >= min(ord_0(f), ord_0(g)), and Semitropical Valuation Bridge
///          v_trop(m) = -ord_0(m) in T_max (connecting Module 12!),
///        - Exact Mittag-Leffler split m = P(m) + h (principal polar part + holomorphic germ),
///          Cauchy residue Res_0(m dz) = c_{-1} cross-checked with contour integral,
///          Argument Principle Res_0((m'/m) dz) == ord_0(m) in Z,
///          Global Euler-Jacobi-Grothendieck Residue Conservation across unfolded A_k germs,
///        - Weierstrass Preparation Theorem in O_{2,0}: f(x, y) = u(x, y) * W(x, y),
///        - Multivariate meromorphic fraction germs M_{n,0} = Frac(O_{n,0}) with exact
///          cross-multiplication stalk equivalence and codim >= 2 indeterminacy detection;
///   2. (17) 微函數胚 `HyperfunctionGerm`, `MicrofunctionGerm`, `MicroDiffOp` (Sato-SKK):
///        - Exact Sato short exact sequence  0 -> A_{x_0} -> B_{x_0} --sp--> pi_* C_{x_0} -> 0
///          killing ALL holomorphic germs identically (sp(h) == 0 iff h in A_{x_0}!),
///        - Chiral boundary microfunctions 1/(x +- i0), Dirac delta^{(m)}(x - x_0),
///          Heaviside step Y(x - x_0), principal value pv(1/x), Sokhotski-Plemelj formula,
///          exact annihilation x * sp(delta) == 0 & d_x sp(Y) == sp(delta), Kothe pairing,
///        - Singular Spectrum (analytic wavefront set) SS(u) subset i S^* R and Sato's
///          Antipodal Product Theorem (blocking (+i dx) <-> (-i dx) causality collisions!),
///        - Noncommutative Ring of Microdifferential Operators E_{(x_0, i xi dx)} with exact
///          Leibniz symbol product (P o Q)(x, xi) = sum_{k>=0} (1/k!) d_xi^k P * d_x^k Q,
///          associativity, and Sato's Fundamental Elliptic Invertibility Theorem P o P^{-1} == 1
///          & P^{-1} o P == 1 outside Char(P) = {sigma_m(P) = 0} (Theorem XIV).

///|
/// Univariate complex Meromorphic Function Germ m(z) = sum_{j=0}^{prec-1} coeffs[j] * z^{order + j}
/// at z_0 = 0, stored normalized so coeffs[0] != 0 (or `is_zero_germ()` when m == 0).
#derive(Debug, Eq)
pub(all) struct MeromorphicGerm {
  order : Int32
  prec : Int32
  coeffs : Array[Complex]
}

///|
fn mero_normalize(
  order : Int32,
  prec : Int32,
  raw : Array[Complex],
  tol~ : Double = 1.0e-13,
) -> MeromorphicGerm {
  let mut shift = 0
  while shift < raw.length() && raw[shift].abs() <= tol {
    shift = shift + 1
  }
  if shift >= raw.length() {
    return { order: 0, prec, coeffs: Array::make(prec, Complex::zero()), }
  }
  let coeffs = Array::makei(prec, j => {
    if shift + j < raw.length() {
      raw[shift + j]
    } else {
      Complex::zero()
    }
  })
  { order: order + shift, prec, coeffs, }
}

///|
pub fn MeromorphicGerm::zero(prec~ : Int32 = 12) -> MeromorphicGerm {
  { order: 0, prec, coeffs: Array::make(prec, Complex::zero()), }
}

///|
/// Construct a real-coefficient Laurent germ sum_j c_j z^{order + j}.
pub fn MeromorphicGerm::from_real(
  order : Int32,
  coeffs : Array[Double],
  prec~ : Int32 = 12,
) -> MeromorphicGerm {
  mero_normalize(order, prec, coeffs.map(x => Complex::new(x, 0.0)))
}

///|
pub fn MeromorphicGerm::is_zero(self : MeromorphicGerm) -> Bool {
  self.coeffs[0].abs() <= 1.0e-13
}

///|
/// True iff m lies in the holomorphic valuation ring O_{1,0} subset M_{1,0} (ord_0(m) >= 0).
pub fn MeromorphicGerm::is_holomorphic(self : MeromorphicGerm) -> Bool {
  self.is_zero() || self.order >= 0
}

///|
/// Exact Semitropical Valuation v_trop(m) = -ord_0(m) in T_max (pole order >= 1 for poles,
/// <= 0 for holomorphic zeros, -inf for 0), satisfying the valuation homomorphism laws:
///   v_trop(f * g) == v_trop(f) (*) v_trop(g),   v_trop(f + g) <= v_trop(f) (+) v_trop(g)!
pub fn MeromorphicGerm::tropical_valuation(self : MeromorphicGerm) -> Tropical {
  if self.is_zero() {
    Tropical::zero()
  } else {
    Tropical::finite((-self.order).to_double())
  }
}

///|
/// Extract coefficient c_k of z^k in the Laurent expansion of `self`.
pub fn MeromorphicGerm::coeff_at(self : MeromorphicGerm, k : Int32) -> Complex {
  if self.is_zero() {
    return Complex::zero()
  }
  let idx = k - self.order
  if idx >= 0 && idx < self.prec {
    self.coeffs[idx]
  } else {
    Complex::zero()
  }
}

///|
/// Exact Cauchy Residue Res_0(m(z) dz) = c_{-1} in C.
pub fn MeromorphicGerm::residue(self : MeromorphicGerm) -> Complex {
  self.coeff_at(-1)
}

///|
/// Numerical Cauchy contour integral (1 / (2 pi i)) \oint_{|z| = r} m(z) dz
/// via exponentially convergent N-point trapezoidal quadrature on the circle z = r e^{i theta}.
pub fn MeromorphicGerm::contour_residue(
  self : MeromorphicGerm,
  radius : Double,
  n_pts~ : Int32 = 256,
) -> Complex {
  let two_pi = 2.0 * @math.PI
  let dtheta = two_pi / n_pts.to_double()
  let mut sum = Complex::zero()
  for k in 0..<n_pts {
    let theta = k.to_double() * dtheta
    let z = Complex::from_polar(radius, theta)
    // (1 / 2 pi i) * m(z) * (i z dtheta) = m(z) * z * dtheta / (2 pi)
    sum = sum + self.eval(z) * z
  }
  sum.scale(1.0 / n_pts.to_double())
}

///|
/// Evaluate truncated Laurent representative at a punctured neighborhood point z != 0.
pub fn MeromorphicGerm::eval(self : MeromorphicGerm, z : Complex) -> Complex {
  if self.is_zero() {
    return Complex::zero()
  }
  // Horner evaluation of sum_{j=0}^{prec-1} c_j z^j times z^order
  let mut horner = Complex::zero()
  for j in (self.prec - 1)>=..0 {
    horner = horner * z + self.coeffs[j]
  }
  let mut z_ord = Complex::one()
  let base = if self.order >= 0 { z } else { z.inv() }
  for _ in 0..<self.order.abs() {
    z_ord = z_ord * base
  }
  z_ord * horner
}

///|
pub fn MeromorphicGerm::add(
  self : MeromorphicGerm,
  other : MeromorphicGerm,
) -> MeromorphicGerm {
  if self.is_zero() {
    return other
  }
  if other.is_zero() {
    return self
  }
  let min_o = self.order.min(other.order)
  // Valid common truncation ceiling is min(order_1 + prec_1, order_2 + prec_2)
  let cap = (self.order + self.prec).min(other.order + other.prec)
  let span = (cap - min_o).max(0)
  let raw = Array::makei(span, j => {
    let k = min_o + j
    self.coeff_at(k) + other.coeff_at(k)
  })
  let out_prec = span.min(self.prec.min(other.prec)).max(1)
  mero_normalize(min_o, out_prec, raw)
}

///|
pub fn MeromorphicGerm::scale(
  self : MeromorphicGerm,
  c : Complex,
) -> MeromorphicGerm {
  mero_normalize(self.order, self.prec, self.coeffs.map(x => x * c))
}

///|
pub fn MeromorphicGerm::sub(
  self : MeromorphicGerm,
  other : MeromorphicGerm,
) -> MeromorphicGerm {
  self.add(other.scale(Complex::new(-1.0, 0.0)))
}

///|
pub fn MeromorphicGerm::mul(
  self : MeromorphicGerm,
  other : MeromorphicGerm,
) -> MeromorphicGerm {
  let pr = self.prec.min(other.prec)
  if self.is_zero() || other.is_zero() {
    return MeromorphicGerm::zero(prec=pr)
  }
  let raw = Array::makei(pr, k => {
    let mut s = Complex::zero()
    for i in 0..<=k {
      s = s + self.coeffs[i] * other.coeffs[k - i]
    }
    s
  })
  mero_normalize(self.order + other.order, pr, raw)
}

///|
/// Shared exact Cauchy formal power-series inversion (sum_{j>=0} a_j z^j)^{-1} mod z^{len}
/// for unit series a_0 != 0 (used by both MeromorphicGerm::inv and MicroDiffOp::elliptic_inverse).
fn cauchy_series_inv(a : Array[Complex], len : Int32) -> Array[Complex] {
  let out = Array::make(len, Complex::zero())
  let inv0 = a[0].inv()
  out[0] = inv0
  for k in 1..<len {
    let mut s = Complex::zero()
    for j in 1..<=k {
      if j < a.length() {
        s = s + a[j] * out[k - j]
      }
    }
    out[k] = -(inv0 * s)
  }
  out
}

///|
/// Exact multiplicative inverse m(z)^{-1} = z^{-order} * (sum_{j>=0} c_j z^j)^{-1} in M_{1,0}.
pub fn MeromorphicGerm::inv(self : MeromorphicGerm) -> MeromorphicGerm {
  let pr = self.prec
  if self.is_zero() {
    return MeromorphicGerm::zero(prec=pr)
  }
  { order: -self.order, prec: pr, coeffs: cauchy_series_inv(self.coeffs, pr), }
}

///|
pub fn MeromorphicGerm::div(
  self : MeromorphicGerm,
  other : MeromorphicGerm,
) -> MeromorphicGerm {
  self.mul(other.inv())
}

///|
/// Formal Laurent derivative m'(z) = sum_j (order + j) c_j z^{order + j - 1}.
pub fn MeromorphicGerm::deriv(self : MeromorphicGerm) -> MeromorphicGerm {
  let pr = (self.prec - 1).max(1)
  if self.is_zero() {
    return MeromorphicGerm::zero(prec=pr)
  }
  let raw = Array::makei(self.prec, j => {
    self.coeffs[j].scale((self.order + j).to_double())
  })
  mero_normalize(self.order - 1, pr, raw)
}

///|
/// Logarithmic derivative m'(z) / m(z) = ord_0(m) / z + holomorphic:
/// satisfies Cauchy's Argument Principle  Res_0(m'(z) / m(z)) == ord_0(m) in Z identically!
pub fn MeromorphicGerm::log_deriv(self : MeromorphicGerm) -> MeromorphicGerm {
  self.deriv().div(self)
}

///|
/// Mittag-Leffler Decomposition  M_{1,0} = z^{-1} C[z^{-1}] (+) O_{1,0}:
/// splits m uniquely into (principal_polar_part, holomorphic_germ) with P(m) + h == m,
/// where `principal` is precisely the image of m in Sato's microfunction quotient M_{1,0} / O_{1,0}!
pub fn MeromorphicGerm::mittag_leffler_split(
  self : MeromorphicGerm,
) -> (MeromorphicGerm, MeromorphicGerm) {
  let pr = self.prec
  if self.is_zero() || self.order >= 0 {
    return (MeromorphicGerm::zero(prec=pr), self)
  }
  let p_raw = Array::makei(pr, j => {
    if self.order + j < 0 {
      self.coeffs[j]
    } else {
      Complex::zero()
    }
  })
  let h_raw = Array::makei(pr, k => self.coeff_at(k))
  (mero_normalize(self.order, pr, p_raw), mero_normalize(0, pr, h_raw))
}

///|
/// Global Euler-Jacobi-Grothendieck Residue Sum across a Morsified A_k unfolding
/// P(z) = prod_{s=0}^{k} (z - roots[s]):
///   sum_{s=0}^{k} Res_{z = roots[s]} ( z^m / P(z) dz ) == delta_{m, k}   for all 0 <= m <= k!
/// Proves topological residue conservation when a degenerate multiplicity-(k+1) agent
/// singularity z^{-(k+1)} unfolds into (k+1) distinct simple Morse equilibria!
pub fn euler_jacobi_residue_sum(
  roots : Array[Complex],
  monom_power : Int32,
) -> Complex {
  let n = roots.length()
  let mut total = Complex::zero()
  for s in 0..<n {
    let zs = roots[s]
    let mut num = Complex::one()
    for _ in 0..<monom_power {
      num = num * zs
    }
    // P'(z_s) = prod_{t != s} (z_s - z_t)
    let mut denom = Complex::one()
    for t in 0..<n {
      if t != s {
        denom = denom * (zs - roots[t])
      }
    }
    total = total + num / denom
  }
  total
}

///|
/// WEIERSTRASS PREPARATION THEOREM IN O_{2,0} (Theorem XIII.2):
/// Given a y-regular germ f(x, y) in O_2^{(k)} with f(0, y) = c_d y^d + O(y^{d+1}) (c_d != 0, d >= 1),
/// computes the UNIQUE pair (unit_u, weierstrass_W) such that:
///   1. f(x, y) == u(x, y) * W(x, y)  (mod m_2^{k+1}),
///   2. u(0, 0) != 0 (invertible unit in O_{2,0}^x),
///   3. W(x, y) = y^d + sum_{j=0}^{d-1} a_j(x) y^j is monic in y with a_j(0) == 0 (a_j in m_1)!
pub fn weierstrass_prepare_2d(
  f : PolyGerm,
) -> Result[(PolyGerm, PolyGerm), String] {
  let b = f.basis
  let k = b.max_deg
  // Find Weierstrass regularity order d = ord_y f(0, y)
  let mut d = -1
  for deg_y in 0..<=k {
    let idx = b.index_of([0, deg_y])
    if idx >= 0 && f.coeffs[idx].abs() > 1.0e-12 {
      d = deg_y
      break
    }
  }
  if d < 0 {
    return Err("Germ is not y-regular (f(0, y) == 0)")
  }
  if d == 0 {
    return Ok((f, PolyGerm::constant(b, 1.0)))
  }
  // Solve recursively by x-degree s = 0, 1, ..., k for F(x, y) = U(x, y) * W(x, y):
  //   s = 0: W_0(y) = y^d,  U_0(y) = f(0, y) / y^d  (with U_0(0) = c_d != 0);
  //   s >= 1: R_s(y) = f_s(y) - sum_{p=1}^{s-1} U_p(y) W_{s-p}(y) = U_0(y) W_s(y) + y^d U_s(y),
  //           so W_s(y) = (R_s(y) * U_0(y)^{-1}) mod y^d, and U_s(y) = (R_s - U_0 W_s) / y^d!
  // Extract 1D y-series for each x-power s
  let u_xy = DenseMat::zeros(k + 1, k + 1)
  let w_xy = DenseMat::zeros(k + 1, d + 1)
  w_xy.set(0, d, 1.0)
  for q in 0..<=(k - d) {
    let idx = b.index_of([0, d + q])
    if idx >= 0 {
      u_xy.set(0, q, f.coeffs[idx])
    }
  }
  // Invert U_0(y) up to degree d - 1
  let u0_inv = Array::make(d, 0.0)
  let c_d = u_xy.get(0, 0)
  u0_inv[0] = 1.0 / c_d
  for q in 1..<d {
    let mut s_acc = 0.0
    for j in 1..<=q {
      s_acc = s_acc + u_xy.get(0, j) * u0_inv[q - j]
    }
    u0_inv[q] = -s_acc / c_d
  }
  for s in 1..<=k {
    // Residual polynomial R_s(y) = f_s(y) - sum_{p=1}^{s-1} U_p(y) * W_{s-p}(y)
    let rem_y = Array::make(k + 1, 0.0)
    for q in 0..<=(k - s) {
      let idx = b.index_of([s, q])
      if idx >= 0 {
        rem_y[q] = f.coeffs[idx]
      }
    }
    for p in 1..<s {
      for qu in 0..<=k {
        let up = u_xy.get(p, qu)
        if up != 0.0 {
          for qw in 0..<d {
            let ws = w_xy.get(s - p, qw)
            if ws != 0.0 && qu + qw <= k {
              rem_y[qu + qw] = rem_y[qu + qw] - up * ws
            }
          }
        }
      }
    }
    // W_s(y) = (rem_y * u0_inv) truncated strictly to deg_y < d
    for qw in 0..<d {
      if s + qw <= k {
        let mut val = 0.0
        for j in 0..<=qw {
          val = val + rem_y[j] * u0_inv[qw - j]
        }
        w_xy.set(s, qw, val)
      }
    }
    // Subtract U_0(y) * W_s(y) and shift down by y^d to get U_s(y)
    for qu in 0..<=k {
      let u0q = u_xy.get(0, qu)
      if u0q != 0.0 {
        for qw in 0..<d {
          let wsq = w_xy.get(s, qw)
          if wsq != 0.0 && qu + qw <= k {
            rem_y[qu + qw] = rem_y[qu + qw] - u0q * wsq
          }
        }
      }
    }
    for q in 0..<=(k - d - s) {
      u_xy.set(s, q, rem_y[q + d])
    }
  }
  let u_germ = PolyGerm::zero(b)
  let w_germ = PolyGerm::zero(b)
  for s in 0..<=k {
    for q in 0..<=(k - s) {
      let idx = b.index_of([s, q])
      if idx >= 0 {
        u_germ.coeffs[idx] = u_xy.get(s, q)
        if q <= d {
          w_germ.coeffs[idx] = w_xy.get(s, q)
        }
      }
    }
  }
  Ok((u_germ, w_germ))
}

///|
/// Multivariate Meromorphic Function Germ m = num / den in M_{n,0} = Frac(O_{n,0})
/// (den != 0), with canonical stalk equivalence p_1/q_1 == p_2/q_2 <=> p_1 * q_2 == p_2 * q_1!
#derive(Debug, Eq)
pub(all) struct MultiMeroGerm {
  num : PolyGerm
  den : PolyGerm
}

///|
pub fn MultiMeroGerm::equiv(
  a : MultiMeroGerm,
  b : MultiMeroGerm,
  tol~ : Double = 1.0e-11,
) -> Bool {
  a.num.mul(b.den).sub(b.num.mul(a.den)).jet_norm() <= tol
}

///|
pub fn MultiMeroGerm::add(
  a : MultiMeroGerm,
  b : MultiMeroGerm,
) -> MultiMeroGerm {
  { num: a.num.mul(b.den).add(b.num.mul(a.den)), den: a.den.mul(b.den), }
}

///|
pub fn MultiMeroGerm::mul(
  a : MultiMeroGerm,
  b : MultiMeroGerm,
) -> MultiMeroGerm {
  { num: a.num.mul(b.num), den: a.den.mul(b.den), }
}

///|
/// Classify local origin behavior of m = num / den in M_{n,0}:
///   - den(0) != 0              => "Holomorphic" (belongs to O_{n,0}),
///   - den(0) == 0, num(0) != 0 => "PolarDivisor" (pure pole along V(den)),
///   - den(0) == 0, num(0) == 0 => "Indeterminate" (0/0 indeterminacy locus, e.g. x/y!).
pub fn MultiMeroGerm::origin_status(
  self : MultiMeroGerm,
  tol~ : Double = 1.0e-12,
) -> String {
  let d0 = self.den.val_at_origin().abs() > tol
  let n0 = self.num.val_at_origin().abs() > tol
  if d0 {
    "Holomorphic"
  } else if n0 {
    "PolarDivisor"
  } else {
    "Indeterminate"
  }
}

///|
/// ============================================================================
/// PART 2: SATO HYPERFUNCTION & MICROFUNCTION GERMS (Concept 17 — 微函數胚)
/// ============================================================================
/// Half-plane defining germ F(z) in O(H_+-)_{x_0}:
///   F(z) = sum_{k=1}^{P} poles[k-1] * (z - x_0)^{-k}
///        + log_coeff * ln(-(z - x_0))
///        + sum_{j=0}^{H-1} holo[j] * (z - x_0)^j.
#derive(Debug, Eq)
pub(all) struct HalfPlaneGerm {
  poles : Array[Complex]
  log_coeff : Complex
  holo : Array[Complex]
}

///|
fn hp_trim_poles(
  raw : Array[Complex],
  tol~ : Double = 1.0e-13,
) -> Array[Complex] {
  let mut len = raw.length()
  while len > 0 && raw[len - 1].abs() <= tol {
    len = len - 1
  }
  Array::makei(len, i => raw[i])
}

///|
fn hp_add(a : HalfPlaneGerm, b : HalfPlaneGerm) -> HalfPlaneGerm {
  let np = a.poles.length().max(b.poles.length())
  let poles = hp_trim_poles(
    Array::makei(np, i => {
      let ca = if i < a.poles.length() { a.poles[i] } else { Complex::zero() }
      let cb = if i < b.poles.length() { b.poles[i] } else { Complex::zero() }
      ca + cb
    }),
  )
  let nh = a.holo.length().max(b.holo.length())
  let holo = Array::makei(nh, j => {
    let ha = if j < a.holo.length() { a.holo[j] } else { Complex::zero() }
    let hb = if j < b.holo.length() { b.holo[j] } else { Complex::zero() }
    ha + hb
  })
  { poles, log_coeff: a.log_coeff + b.log_coeff, holo, }
}

///|
fn hp_scale(a : HalfPlaneGerm, c : Complex) -> HalfPlaneGerm {
  {
    poles: hp_trim_poles(a.poles.map(p => p * c)),
    log_coeff: a.log_coeff * c,
    holo: a.holo.map(h => h * c),
  }
}

///|
/// Exact complex derivative d_z F(z):
///   d_z (z^{-k}) = -k z^{-(k+1)},   d_z ln(-z) = z^{-1} (branch-independent!),   d_z z^j = j z^{j-1}.
fn hp_deriv(a : HalfPlaneGerm) -> HalfPlaneGerm {
  let np = if a.poles.length() > 0 {
    a.poles.length() + 1
  } else if a.log_coeff.abs() > 1.0e-13 {
    1
  } else {
    0
  }
  let poles = Array::make(np, Complex::zero())
  if np > 0 {
    poles[0] = a.log_coeff
  }
  for i in 0..<a.poles.length() {
    let k = i + 1
    poles[i + 1] = a.poles[i].scale(-k.to_double())
  }
  let nh = (a.holo.length() - 1).max(0)
  let holo = Array::makei(nh, j => a.holo[j + 1].scale((j + 1).to_double()))
  { poles: hp_trim_poles(poles), log_coeff: Complex::zero(), holo, }
}

///|
/// Multiplication by (z - x_0) on pure polar+holomorphic defining germs:
/// notice (z - x_0) * c_{-1}(z - x_0)^{-1} = c_{-1} MOVES INTO `holo[0]`, hence
/// VANISHES IDENTICALLY under Sato's spectral projection sp : B -> C (so x * sp(delta) == 0!)!
fn hp_mul_z(a : HalfPlaneGerm) -> HalfPlaneGerm {
  let np = (a.poles.length() - 1).max(0)
  let poles = hp_trim_poles(Array::makei(np, i => a.poles[i + 1]))
  let c_m1 = if a.poles.length() > 0 { a.poles[0] } else { Complex::zero() }
  let holo = Array::makei(a.holo.length() + 1, j => {
    if j == 0 {
      c_m1
    } else {
      a.holo[j - 1]
    }
  })
  { poles, log_coeff: Complex::zero(), holo, }
}

///|
/// Sato Hyperfunction Germ u(x) = [F_+(x + i0) - F_-(x - i0)] in B_{R, x_0}.
#derive(Debug, Eq)
pub(all) struct HyperfunctionGerm {
  x0 : Double
  f_plus : HalfPlaneGerm
  f_minus : HalfPlaneGerm
}

///|
/// Sato Microfunction Germ sp(u) = ([F_+] mod O, [F_-] mod O) in C_{(x_0,+idx)} (+) C_{(x_0,-idx)}.
/// ALL holomorphic background terms `holo` are canonically annihilated by `sp`!
#derive(Debug, Eq)
pub(all) struct MicrofunctionGerm {
  x0 : Double
  plus_poles : Array[Complex]
  plus_log : Complex
  minus_poles : Array[Complex]
  minus_log : Complex
}

///|
/// SATO'S SPECTRAL MORPHISM  sp : B_{x_0} -> C_{(x_0, +i dx)} (+) C_{(x_0, -i dx)}
/// fitting into the fundamental exact sequence  0 -> A_{x_0} -> B_{x_0} --sp--> pi_* C_{x_0} -> 0!
pub fn HyperfunctionGerm::sp(self : HyperfunctionGerm) -> MicrofunctionGerm {
  {
    x0: self.x0,
    plus_poles: hp_trim_poles(self.f_plus.poles),
    plus_log: if self.f_plus.log_coeff.abs() <= 1.0e-13 {
      Complex::zero()
    } else {
      self.f_plus.log_coeff
    },
    minus_poles: hp_trim_poles(self.f_minus.poles),
    minus_log: if self.f_minus.log_coeff.abs() <= 1.0e-13 {
      Complex::zero()
    } else {
      self.f_minus.log_coeff
    },
  }
}

///|
/// Embed a real-analytic germ h(x) in A_{x_0} into B_{x_0} via [h(x + i0) - 0]
/// (or gauge-equivalent [(h + g)(x + i0) - g(x - i0)] for ANY holomorphic g in O_{C, x_0}).
/// Under `sp`, vanishes identically (ker(sp) == A_{x_0}!).
pub fn HyperfunctionGerm::from_analytic(
  x0 : Double,
  taylor : Array[Complex],
  gauge~ : Array[Complex] = [],
) -> HyperfunctionGerm {
  let g_hp : HalfPlaneGerm = {
    poles: [],
    log_coeff: Complex::zero(),
    holo: gauge,
  }
  let h_hp : HalfPlaneGerm = {
    poles: [],
    log_coeff: Complex::zero(),
    holo: taylor,
  }
  { x0, f_plus: hp_add(h_hp, g_hp), f_minus: g_hp, }
}

///|
fn empty_half_germ() -> HalfPlaneGerm {
  { poles: [], log_coeff: Complex::zero(), holo: [], }
}

///|
fn pure_pole_half_germ(order : Int32, lead : Double) -> HalfPlaneGerm {
  let poles = Array::makei(order.max(0), i => {
    if i == order - 1 {
      Complex::new(lead, 0.0)
    } else {
      Complex::zero()
    }
  })
  { poles, log_coeff: Complex::zero(), holo: [], }
}

///|
/// Positive-chirality boundary value 1 / (x - x_0 + i0)^k:
/// F_+(z) = (z - x_0)^{-k}, F_-(z) = 0  ===>  SS = {(x_0, +i dx)} ONLY!
pub fn HyperfunctionGerm::cauchy_plus(
  x0 : Double,
  order~ : Int32 = 1,
) -> HyperfunctionGerm {
  { x0, f_plus: pure_pole_half_germ(order, 1.0), f_minus: empty_half_germ(), }
}

///|
/// Negative-chirality boundary value 1 / (x - x_0 - i0)^k:
/// F_+(z) = 0, F_-(z) = -(z - x_0)^{-k}  ===>  SS = {(x_0, -i dx)} ONLY!
pub fn HyperfunctionGerm::cauchy_minus(
  x0 : Double,
  order~ : Int32 = 1,
) -> HyperfunctionGerm {
  { x0, f_plus: empty_half_germ(), f_minus: pure_pole_half_germ(order, -1.0), }
}

///|
/// Sato Dirac delta hyperfunction:
///   delta(x - x_0) = (-1 / (2 pi i)) [ 1/(x - x_0 + i0) - 1/(x - x_0 - i0) ],
/// with F_+(z) = F_-(z) = -1 / (2 pi i (z - x_0)) and bidirectional SS = {+i dx, -i dx}!
pub fn HyperfunctionGerm::dirac_delta(x0 : Double) -> HyperfunctionGerm {
  // -1 / (2 pi i) = +i / (2 pi)
  let c = Complex::new(0.0, 1.0 / (2.0 * @math.PI))
  let hp : HalfPlaneGerm = { poles: [c], log_coeff: Complex::zero(), holo: [], }
  { x0, f_plus: hp, f_minus: hp, }
}

///|
/// Cauchy principal value pv(1 / (x - x_0)) = (1/2) [ 1/(x - x_0 + i0) + 1/(x - x_0 - i0) ].
pub fn HyperfunctionGerm::principal_value_inv(x0 : Double) -> HyperfunctionGerm {
  HyperfunctionGerm::cauchy_plus(x0)
  .add(HyperfunctionGerm::cauchy_minus(x0))
  .scale(Complex::new(0.5, 0.0))
}

///|
/// Sato Heaviside step hyperfunction:
///   Y(x - x_0) = (-1 / (2 pi i)) [ ln(-(x - x_0 + i0)) - ln(-(x - x_0 - i0)) ],
/// satisfying exact microlocal differential equation d_x sp(Y) == sp(delta)!
pub fn HyperfunctionGerm::heaviside(x0 : Double) -> HyperfunctionGerm {
  let c = Complex::new(0.0, 1.0 / (2.0 * @math.PI))
  let hp : HalfPlaneGerm = { poles: [], log_coeff: c, holo: [], }
  { x0, f_plus: hp, f_minus: hp, }
}

///|
pub fn HyperfunctionGerm::add(
  self : HyperfunctionGerm,
  other : HyperfunctionGerm,
) -> HyperfunctionGerm {
  {
    x0: self.x0,
    f_plus: hp_add(self.f_plus, other.f_plus),
    f_minus: hp_add(self.f_minus, other.f_minus),
  }
}

///|
pub fn HyperfunctionGerm::scale(
  self : HyperfunctionGerm,
  c : Complex,
) -> HyperfunctionGerm {
  {
    x0: self.x0,
    f_plus: hp_scale(self.f_plus, c),
    f_minus: hp_scale(self.f_minus, c),
  }
}

///|
pub fn HyperfunctionGerm::deriv(self : HyperfunctionGerm) -> HyperfunctionGerm {
  {
    x0: self.x0,
    f_plus: hp_deriv(self.f_plus),
    f_minus: hp_deriv(self.f_minus),
  }
}

///|
/// Multiply hyperfunction by (x - x_0): carries x * delta(x) into a pure holomorphic
/// germ (zero microfunction!) and x * delta'(x) into -delta(x) + holomorphic!
pub fn HyperfunctionGerm::mul_by_x_shift(
  self : HyperfunctionGerm,
) -> HyperfunctionGerm {
  {
    x0: self.x0,
    f_plus: hp_mul_z(self.f_plus),
    f_minus: hp_mul_z(self.f_minus),
  }
}

///|
/// Exact Sato-Kothe duality integral \int u(x) phi(x) dx = -\oint F(z) phi(z) dz
/// for a real-analytic test germ phi(x) = sum_j phi_j (x - x_0)^j and a compactly-supported
/// point hyperfunction F_+ == F_- = sum_{k>=1} c_{-k}(z - x_0)^{-k}:
///   \int delta^{(m)}(x - x_0) phi(x) dx == (-1)^m phi^{(m)}(x_0)!
pub fn HyperfunctionGerm::pair_analytic(
  self : HyperfunctionGerm,
  phi_taylor : Array[Complex],
) -> Complex {
  // -\oint (sum_{k>=1} c_{-k} w^{-k})(sum_j phi_j w^j) dw = -2 pi i * sum_{k>=1} c_{-k} phi_{k-1}
  let factor = Complex::new(0.0, -2.0 * @math.PI)
  let mut res = Complex::zero()
  for i in 0..<self.f_plus.poles.length().min(phi_taylor.length()) {
    res = res + self.f_plus.poles[i] * phi_taylor[i]
  }
  factor * res
}

///|
/// Singular Spectrum (Analytic Wavefront Set) SS(u) subset {(x_0, +i dx), (x_0, -i dx)}:
/// returns `(has_plus_codir, has_minus_codir)`. Microfunction is 0 iff `(false, false)`!
pub fn MicrofunctionGerm::singular_spectrum(
  self : MicrofunctionGerm,
  tol~ : Double = 1.0e-12,
) -> (Bool, Bool) {
  let has_p = self.plus_poles.length() > 0 || self.plus_log.abs() > tol
  let has_m = self.minus_poles.length() > 0 || self.minus_log.abs() > tol
  (has_p, has_m)
}

///|
/// L2 distance between two microfunction germs in C_{(x_0, +idx)} (+) C_{(x_0, -idx)}.
pub fn MicrofunctionGerm::dist(
  a : MicrofunctionGerm,
  b : MicrofunctionGerm,
) -> Double {
  let mut s = (a.plus_log - b.plus_log).norm_sq() +
    (a.minus_log - b.minus_log).norm_sq()
  let np = a.plus_poles.length().max(b.plus_poles.length())
  for i in 0..<np {
    let ca = if i < a.plus_poles.length() {
      a.plus_poles[i]
    } else {
      Complex::zero()
    }
    let cb = if i < b.plus_poles.length() {
      b.plus_poles[i]
    } else {
      Complex::zero()
    }
    s = s + (ca - cb).norm_sq()
  }
  let nm = a.minus_poles.length().max(b.minus_poles.length())
  for i in 0..<nm {
    let ca = if i < a.minus_poles.length() {
      a.minus_poles[i]
    } else {
      Complex::zero()
    }
    let cb = if i < b.minus_poles.length() {
      b.minus_poles[i]
    } else {
      Complex::zero()
    }
    s = s + (ca - cb).norm_sq()
  }
  s.sqrt()
}

///|
/// Exact microlocal anti-derivative D_x^{-1} : C_{(x_0, +-idx)} -> C_{(x_0, +-idx)}
/// (since D_x has principal symbol i xi != 0 on ALL of i S^* R, D_x is microlocally
/// invertible EVERYWHERE on microfunctions, even though it is NOT invertible on functions!):
///   D_x^{-1}([z^{-1}]) = [ln(-z)]   (so D_x^{-1}(sp(delta)) == sp(Y)!),
///   D_x^{-1}([z^{-k}]) = [-1/(k-1) z^{-(k-1)}]  for k >= 2.
pub fn MicrofunctionGerm::integrate_microlocal(
  self : MicrofunctionGerm,
) -> MicrofunctionGerm {
  let anti = (poles : Array[Complex]) => {
    let lg = if poles.length() > 0 { poles[0] } else { Complex::zero() }
    let np = (poles.length() - 1).max(0)
    let new_p = Array::makei(np, i => {
      poles[i + 1].scale(-1.0 / (i + 1).to_double())
    })
    (hp_trim_poles(new_p), lg)
  }
  let (pp, pl) = anti(self.plus_poles)
  let (mp, ml) = anti(self.minus_poles)
  { x0: self.x0, plus_poles: pp, plus_log: pl, minus_poles: mp, minus_log: ml, }
}

///|
/// SATO'S ANTIPODAL MICROFUNCTION PRODUCT THEOREM (Theorem XIV.2):
/// Two polar microfunction germs u, v at x_0 admit a canonical product u * v iff
/// SS(u) and SS(v) satisfy the non-antipodal causality condition:
///   NOT ((+idx in SS(u) and -idx in SS(v)) or (-idx in SS(u) and +idx in SS(v))).
/// Thus co-chiral products (x + i0)^{-a} * (x + i0)^{-b} == (x + i0)^{-(a+b)} succeed,
/// whereas (x + i0)^{-1} * (x - i0)^{-1} and delta(x)^2 are strictly rejected!
pub fn micro_product(
  u : MicrofunctionGerm,
  v : MicrofunctionGerm,
) -> Result[MicrofunctionGerm, String] {
  let (up, um) = u.singular_spectrum()
  let (vp, vm) = v.singular_spectrum()
  if (up && vm) || (um && vp) {
    return Err(
      "Sato antipodal wavefront collision: (+i dx) + (-i dx) = 0 forbids product",
    )
  }
  let conv_poles = (pa : Array[Complex], pb : Array[Complex]) => {
    if pa.length() == 0 || pb.length() == 0 {
      let empty : Array[Complex] = []
      return empty
    }
    let out = Array::make(pa.length() + pb.length(), Complex::zero())
    // pa[i] z^{-(i+1)} * pb[j] z^{-(j+1)} = pa[i] pb[j] z^{-(i+j+2)}
    for i in 0..<pa.length() {
      for j in 0..<pb.length() {
        out[i + j + 1] = out[i + j + 1] + pa[i] * pb[j]
      }
    }
    hp_trim_poles(out)
  }
  if up && vp {
    Ok({
      x0: u.x0,
      plus_poles: conv_poles(u.plus_poles, v.plus_poles),
      plus_log: Complex::zero(),
      minus_poles: [],
      minus_log: Complex::zero(),
    })
  } else {
    // For F_-(z) = -u_-(z), boundary value is -F_-(x-i0), so (-F_u)(-F_v) = +(F_u F_v) => new F_- = -(F_u F_v)
    let neg_conv = conv_poles(u.minus_poles, v.minus_poles).map(c => -c)
    Ok({
      x0: u.x0,
      plus_poles: [],
      plus_log: Complex::zero(),
      minus_poles: neg_conv,
      minus_log: Complex::zero(),
    })
  }
}

///|
/// SKK MICRODIFFERENTIAL OPERATOR GERM P(x, D_x) in E_{(0, i xi dx)}:
/// Total symbol  P(x, xi) = sum_{j=0}^{xi_trunc-1} symbols[j](x) * xi^{order - j},
/// where `order` in Z is the formal order and each `symbols[j]` lies in O_1^{(x_trunc)}.
#derive(Debug, Eq)
pub(all) struct MicroDiffOp {
  order : Int32
  xi_trunc : Int32
  x_trunc : Int32
  symbols : Array[Array[Complex]]
}

///|
/// Identity microdifferential operator 1 = 1 * xi^0 in E_{(0, i xi dx)}.
pub fn MicroDiffOp::identity(xi_trunc : Int32, x_trunc : Int32) -> MicroDiffOp {
  let symbols = Array::makei(xi_trunc, j => {
    Array::makei(x_trunc, s => {
      if j == 0 && s == 0 {
        Complex::one()
      } else {
        Complex::zero()
      }
    })
  })
  { order: 0, xi_trunc, x_trunc, symbols, }
}

///|
/// True iff P is microlocally elliptic at (0, +-i dx), i.e. principal symbol p_m(0) != 0
/// (equivalently (0, +-i dx) not in Char(P)!).
pub fn MicroDiffOp::is_elliptic_at_origin(
  self : MicroDiffOp,
  tol~ : Double = 1.0e-12,
) -> Bool {
  self.symbols[0][0].abs() > tol
}

///|
/// Falling factorial r * (r - 1) * ... * (r - k + 1) / k! for ANY integer r in Z and k >= 0.
fn generalized_binom(r : Int32, k : Int32) -> Double {
  let mut num = 1.0
  let mut den = 1.0
  for i in 0..<k {
    num = num * (r - i).to_double()
    den = den * (i + 1).to_double()
  }
  num / den
}

///|
fn taylor_deriv_k(
  a : Array[Complex],
  k : Int32,
  x_len : Int32,
) -> Array[Complex] {
  Array::makei(x_len, s => {
    if s + k < a.length() {
      let mut fall = 1.0
      for i in 1..<=k {
        fall = fall * (s + i).to_double()
      }
      a[s + k].scale(fall)
    } else {
      Complex::zero()
    }
  })
}

///|
fn taylor_mul(
  a : Array[Complex],
  b : Array[Complex],
  x_len : Int32,
) -> Array[Complex] {
  Array::makei(x_len, s => {
    let mut acc = Complex::zero()
    for i in 0..<=s {
      if i < a.length() && s - i < b.length() {
        acc = acc + a[i] * b[s - i]
      }
    }
    acc
  })
}

///|
/// Exact Noncommutative Leibniz Composition (P o Q)(x, xi) in E_{(0, i xi dx)}:
///   (P o Q)_{m+n-l}(x) = sum_{j + r + k = l} C(m - j, k) * p_{m-j}(x) * d_x^k q_{n-r}(x).
/// Strictly associative up to matched formal symbol & x-jet truncation!
pub fn MicroDiffOp::compose(
  self : MicroDiffOp,
  other : MicroDiffOp,
) -> MicroDiffOp {
  let l_max = self.xi_trunc.min(other.xi_trunc)
  let x_len = self.x_trunc.min(other.x_trunc)
  let symbols = Array::makei(l_max, l => {
    let sum_s = Array::make(x_len, Complex::zero())
    for j in 0..<=l {
      let m_minus_j = self.order - j
      for r in 0..<=(l - j) {
        let k = l - j - r
        let bin = generalized_binom(m_minus_j, k)
        if bin != 0.0 && k < x_len {
          let dq = taylor_deriv_k(other.symbols[r], k, x_len)
          let prod = taylor_mul(self.symbols[j], dq, x_len)
          for s in 0..<x_len {
            sum_s[s] = sum_s[s] + prod[s].scale(bin)
          }
        }
      }
    }
    sum_s
  })
  { order: self.order + other.order, xi_trunc: l_max, x_trunc: x_len, symbols, }
}

///|
/// SATO'S FUNDAMENTAL MICROLOCAL ELLIPTIC PARAMETRIX THEOREM (Theorem XIV.3):
/// For any microdifferential operator P of order m with non-vanishing principal symbol
/// p_m(0) != 0 (i.e. (0, +-idx) not in Char(P)), constructs the UNIQUE two-sided inverse
/// P^{-1} in E_{(0, i xi dx)} of order -m satisfying BOTH:
///   P o P^{-1} == 1   AND   P^{-1} o P == 1!
pub fn MicroDiffOp::elliptic_inverse(
  self : MicroDiffOp,
) -> Result[MicroDiffOp, String] {
  if !self.is_elliptic_at_origin() {
    return Err(
      "Characteristic point: principal symbol p_m(0) == 0 is not invertible",
    )
  }
  let l_max = self.xi_trunc
  let x_len = self.x_trunc
  let pm_inv = cauchy_series_inv(self.symbols[0], x_len)
  let q_syms : Array[Array[Complex]] = Array::makei(l_max, _ => {
    Array::make(x_len, Complex::zero())
  })
  q_syms[0] = pm_inv
  for l in 1..<l_max {
    let rhs = Array::make(x_len, Complex::zero())
    for r in 0..<l {
      for j in 0..<=(l - r) {
        let k = l - r - j
        if k < x_len {
          let bin = generalized_binom(self.order - j, k)
          if bin != 0.0 {
            let dq = taylor_deriv_k(q_syms[r], k, x_len)
            let prod = taylor_mul(self.symbols[j], dq, x_len)
            for s in 0..<x_len {
              rhs[s] = rhs[s] + prod[s].scale(bin)
            }
          }
        }
      }
    }
    let solved = taylor_mul(pm_inv, rhs, x_len)
    q_syms[l] = solved.map(c => -c)
  }
  Ok({ order: -self.order, xi_trunc: l_max, x_trunc: x_len, symbols: q_syms, })
}

///|
/// Frobenius symbol discrepancy between two microdifferential operators of equal order,
/// measured on safe interior x-jet degrees 0..<safe_x_deg (unaffected by derivative truncation).
pub fn MicroDiffOp::symbol_dist(
  a : MicroDiffOp,
  b : MicroDiffOp,
  safe_x_deg : Int32,
) -> Double {
  if a.order != b.order {
    return 1.0e9
  }
  let l_max = a.xi_trunc.min(b.xi_trunc)
  let x_lim = safe_x_deg.min(a.x_trunc.min(b.x_trunc))
  let mut s = 0.0
  for l in 0..<l_max {
    for x_i in 0..<x_lim {
      s = s + (a.symbols[l][x_i] - b.symbols[l][x_i]).norm_sq()
    }
  }
  s.sqrt()
}
