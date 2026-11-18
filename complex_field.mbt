///|
/// Module 16 (Unified from `algo8`): Complex-Field Strong Cardinality, Field Axioms
/// & Cantor Bijective Gödelization (複數域強基數與 Cantor 等勢編碼).
/// Shares the canonical zero-safe `Complex` type in `algebra.mbt` (zero duplicate types!).

///|
/// Hamel strong-basis coordinate projection phi : C -> R^2 on basis {1, i}:
///   z = a * 1 + b * i  |->  (Re z, Im z)  (unique R-linear isomorphism).
pub fn strong_basis_coords(z : Complex) -> (Double, Double) {
  (z.re, z.im)
}

///|
/// Inverse Hamel-basis reconstruction phi^{-1}(a, b) = a * 1 + b * i in C.
pub fn rebuild_from_coords(a : Double, b : Double) -> Complex {
  Complex::one().scale(a) + Complex::i_unit().scale(b)
}

///|
fn complex_approx(x : Complex, y : Complex, eps : Double) -> Bool {
  approx(x.re, y.re, eps) && approx(x.im, y.im, eps)
}

///|
/// Computational verifier for all commutative field axioms of (C, +, *, 0, 1):
/// commutativity, identities, additive & multiplicative inverses, associativity,
/// and distributivity across arbitrary sample elements.
pub fn field_axioms_hold(samples : Array[Complex]) -> Bool {
  for x in samples {
    if !complex_approx(x + Complex::zero(), x, 1.0e-12) {
      return false
    }
    if !complex_approx(x * Complex::one(), x, 1.0e-12) {
      return false
    }
    if !complex_approx(x + -x, Complex::zero(), 1.0e-12) {
      return false
    }
    if !x.is_zero() {
      let inv_x = Complex::one() / x
      if !complex_approx(x * inv_x, Complex::one(), 1.0e-10) {
        return false
      }
    }
    for y in samples {
      if !complex_approx(x + y, y + x, 1.0e-12) {
        return false
      }
      if !complex_approx(x * y, y * x, 1.0e-12) {
        return false
      }
      for w in samples {
        if !complex_approx(x + y + w, x + (y + w), 1.0e-10) {
          return false
        }
        if !complex_approx(x * y * w, x * (y * w), 1.0e-9) {
          return false
        }
        if !complex_approx(x * (y + w), x * y + x * w, 1.0e-10) {
          return false
        }
      }
    }
  }
  true
}

///|
/// Cantor pairing bijection pi : N x N -> N, pi(a, b) = (a + b)(a + b + 1) / 2 + b.
/// Maps each triangular slice { (a, b) : a + b <= n } bijectively onto [0, T_{n+1} - 1],
/// serving as both discrete equipollence witness |N^2| = |N| and exact Gödel state encoder.
pub fn cantor_pair(a : Int32, b : Int32) -> Int32 {
  let s = a + b
  s * (s + 1) / 2 + b
}

///|
/// Exact O(1) inverse Cantor pairing pi^{-1} : N -> N x N via triangular-root formula
/// s = floor((sqrt(8z + 1) - 1) / 2) with exact integer guard against float rounding.
pub fn cantor_unpair(z : Int32) -> (Int32, Int32) {
  let disc = (8.0 * z.to_double() + 1.0).sqrt()
  let mut s = ((disc - 1.0) * 0.5).to_int()
  while (s + 1) * (s + 2) / 2 <= z {
    s = s + 1
  }
  while s > 0 && s * (s + 1) / 2 > z {
    s = s - 1
  }
  let t = s * (s + 1) / 2
  let b = z - t
  (s - b, b)
}

///|
/// Gaussian integer norm sieve N(a + b i) = a^2 + b^2 over 0 <= a, b <= bound in Z[i] subset C.
pub fn gaussian_int_norms(bound : Int32) -> Array[Int32] {
  let out : Array[Int32] = Array(capacity=(bound + 1) * (bound + 1))
  for a in 0..<=bound {
    for b in 0..<=bound {
      out.push(a * a + b * b)
    }
  }
  out
}
