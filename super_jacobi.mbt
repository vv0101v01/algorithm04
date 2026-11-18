///|
/// Module 5: Jacobi & Super-Jacobi Identity (雅可比與超雅可比恆等式).
/// Implements LieSuperAlgebra on:
///   1. General linear Lie superalgebra gl(m|n, Lambda_N) (homogeneous & mixed parity),
///   2. Orthosymplectic isometry Lie superalgebra osp(m|2k) of M^{m|2k}_c,
///   3. Classical Lie algebra so(m) (recovering classical Jacobi when parity = Even),
///   4. Canonical Super-Poisson algebra C^inf(R^{2p|q}) on phase superspace,
/// plus multi-agent protocol Jacobiator obstruction diagnosis (Theorem IIIa).

///|
/// Implement AbelianGroup, Module, and LieSuperAlgebra for SuperMatrix,
/// allowing generic `super_jacobiator`, `adjoint_leibniz_defect`, and
/// `graded_skew_defect` from `algebra.mbt` to work directly on gl(m|n) & osp(m|2k)!
pub impl AbelianGroup for SuperMatrix with fn zero_elem() {
  SuperMatrix::zeros(2, 2, Even)
}

///|
pub impl AbelianGroup for SuperMatrix with fn add_elem(self, other) {
  self + other
}

///|
pub impl AbelianGroup for SuperMatrix with fn neg_elem(self) {
  -self
}

///|
pub impl AbelianGroup for SuperMatrix with fn norm_sq(self) {
  let mut s = 0.0
  for e in self.entries {
    s = s + e.norm_sq()
  }
  s
}

///|
pub impl Module for SuperMatrix with fn scale(self, s) {
  self.smul(s)
}

///|
/// Graded supercommutator [X, Y]_s = X * Y - (-1)^{|X||Y|} Y * X:
///   - Commutator X Y - Y X when X or Y is Even,
///   - Anticommutator {X, Y} = X Y + Y X when BOTH X and Y are Odd!
pub impl LieSuperAlgebra for SuperMatrix with fn sbracket(self, other) {
  let sgn = koszul_sign(self.parity, other.parity)
  self * other - (other * self).smul(sgn)
}

///|
pub impl LieSuperAlgebra for SuperMatrix with fn parity_of(self) {
  self.parity
}

///|
pub extend SuperMatrix with LieSuperAlgebra::{sbracket}

///|
/// Construct an Even generator of the orthosymplectic Lie superalgebra osp(m|2k)_0
/// satisfying X^{st} G_0 + G_0 X = 0 for G_0 = diag(I_m, J_{2k}):
///   X = [[A, B], [-J B^T, D]],
/// where A in so(m) (A^T = -A, even), D in sp(2k) (D = -J S with S^T = S, even),
/// and B is an m x 2k matrix of ODD Grassmann elements.
pub fn make_osp_even_generator(
  m_bos : Int32,
  n_ferm : Int32,
  n_gen : Int32,
  skew_seed : DenseMat,
  sym_sp_seed : DenseMat,
  odd_b : Array[Grassmann],
) -> SuperMatrix {
  let a_real = (skew_seed - skew_seed.transpose()).scale(0.5)
  let s_real = (sym_sp_seed + sym_sp_seed.transpose()).scale(0.5)
  let j_mat = canonical_symplectic(n_ferm)
  // For S symmetric, D = J * S satisfies D^T J + J D = S J^T J + J^2 S = S - S = 0!
  let d_real = j_mat * s_real
  let a = Array::makei(m_bos * m_bos, idx => {
    Grassmann::scalar(n_gen, a_real.get(idx / m_bos, idx % m_bos))
  })
  let b = Array::makei(m_bos * n_ferm, idx => odd_b[idx].odd_part())
  // C = -J * B^T
  let c = Array::makei(n_ferm * m_bos, idx => {
    let alpha = idx / m_bos
    let i = idx % m_bos
    let mut acc = Grassmann::zero(n_gen)
    for beta in 0..<n_ferm {
      let jab = j_mat.get(alpha, beta)
      if jab != 0.0 {
        acc = acc - b[i * n_ferm + beta].smul(jab)
      }
    }
    acc
  })
  let d = Array::makei(n_ferm * n_ferm, idx => {
    Grassmann::scalar(n_gen, d_real.get(idx / n_ferm, idx % n_ferm))
  })
  SuperMatrix::from_blocks(m_bos, n_ferm, n_gen, Even, a, b, c, d)
}

///|
/// Construct an Odd generator of osp(m|2k)_1 satisfying X^{st} G_0 + G_0 X = 0:
///   X = [[0, B], [J B^T, 0]],
/// where B is an m x 2k matrix of EVEN elements (e.g. real scalars).
/// By closure of osp(m|2k), {X_1, X_2} = X_1 X_2 + X_2 X_1 lies strictly in osp(m|2k)_0!
pub fn make_osp_odd_generator(
  m_bos : Int32,
  n_ferm : Int32,
  n_gen : Int32,
  b_real : DenseMat,
) -> SuperMatrix {
  let j_mat = canonical_symplectic(n_ferm)
  let c_real = j_mat * b_real.transpose()
  let a = Array::makei(m_bos * m_bos, _ => Grassmann::zero(n_gen))
  let b = Array::makei(m_bos * n_ferm, idx => {
    Grassmann::scalar(n_gen, b_real.get(idx / n_ferm, idx % n_ferm))
  })
  let c = Array::makei(n_ferm * m_bos, idx => {
    Grassmann::scalar(n_gen, c_real.get(idx / m_bos, idx % m_bos))
  })
  let d = Array::makei(n_ferm * n_ferm, _ => Grassmann::zero(n_gen))
  SuperMatrix::from_blocks(m_bos, n_ferm, n_gen, Odd, a, b, c, d)
}

///|
/// Measure the osp(m|2k) Lie superalgebra condition defect || X^{st} G_0 + G_0 X ||_F.
/// Equals 0 iff X in osp(m|2k) (holds uniformly for BOTH Even and Odd X!).
pub fn osp_invariance_defect(x : SuperMatrix) -> Double {
  let g0 = SuperMatrix::from_real(
    x.m_bos,
    x.n_ferm,
    Even,
    flat_osp_metric_mat(x.m_bos, x.n_ferm),
    n_gen=x.n_gen,
  )
  (x.supertranspose() * g0 + g0 * x).frob_norm()
}

///|
/// Verify all 8 parity sectors (p_X, p_Y, p_Z) in {Even, Odd}^3 of both the cyclic
/// Super-Jacobi identity and the graded Leibniz identity on pairs of Even/Odd generators.
/// Returns (max_jacobi_residual, max_leibniz_residual, max_skew_residual).
pub fn verify_all_8_super_jacobi_sectors(
  even_ops : (SuperMatrix, SuperMatrix, SuperMatrix),
  odd_ops : (SuperMatrix, SuperMatrix, SuperMatrix),
) -> (Double, Double, Double) {
  let (e0, e1, e2) = even_ops
  let (o0, o1, o2) = odd_ops
  let parities = [Even, Odd]
  let mut max_jac = 0.0
  let mut max_leib = 0.0
  let mut max_skew = 0.0
  for px in parities {
    let x = match px {
      Even => e0
      Odd => o0
    }
    for py in parities {
      let y = match py {
        Even => e1
        Odd => o1
      }
      let sk = graded_skew_defect(x, y).frob_norm()
      if sk > max_skew {
        max_skew = sk
      }
      for pz in parities {
        let z = match pz {
          Even => e2
          Odd => o2
        }
        let jn = super_jacobiator(x, y, z).frob_norm()
        let ln = adjoint_leibniz_defect(x, y, z).frob_norm()
        if jn > max_jac {
          max_jac = jn
        }
        if ln > max_leib {
          max_leib = ln
        }
      }
    }
  }
  (max_jac, max_leib, max_skew)
}

///|
/// Classical Lie bracket [A, B] = A B - B A and classical Jacobiator
///   J(A, B, C) = [A, [B, C]] + [B, [C, A]] + [C, [A, B]] on Mat(n, R).
pub fn classical_commutator(a : DenseMat, b : DenseMat) -> DenseMat {
  a * b - b * a
}

///|
pub fn classical_jacobiator(
  a : DenseMat,
  b : DenseMat,
  c : DenseMat,
) -> DenseMat {
  classical_commutator(a, classical_commutator(b, c)) +
  classical_commutator(b, classical_commutator(c, a)) +
  classical_commutator(c, classical_commutator(a, b))
}

///|
/// Canonical Super-Poisson Bracket on phase superspace R^{2|N} with bosonic
/// Darboux coordinates (q, p) and fermionic Clifford-Poisson coordinates (theta^0, ..., theta^{N-1}):
///   {F, G}_{SP}(q, p) = (dF/dq)(dG/dp) - (dF/dp)(dG/dq)
///                     + (-1)^{|F|} sum_{a=0}^{N-1} (d_L F / d theta^a)(d_L G / d theta^a).
/// Satisfies graded skew-symmetry {F, G}_{SP} = -(-1)^{|F||G|} {G, F}_{SP}
/// and the exact Super-Jacobi identity!
pub fn super_poisson_bracket(
  f : (Double, Double) -> Grassmann,
  parity_f : Parity,
  g : (Double, Double) -> Grassmann,
  q : Double,
  p : Double,
  eps~ : Double = 1.0e-5,
) -> Grassmann {
  let fq = (f(q + eps, p) - f(q - eps, p)).smul(0.5 / eps)
  let fp = (f(q, p + eps) - f(q, p - eps)).smul(0.5 / eps)
  let gq = (g(q + eps, p) - g(q - eps, p)).smul(0.5 / eps)
  let gp = (g(q, p + eps) - g(q, p - eps)).smul(0.5 / eps)
  let mut res = fq * gp - fp * gq
  let fv = f(q, p)
  let gv = g(q, p)
  let sgn = match parity_f {
    Even => 1.0
    Odd => -1.0
  }
  for a in 0..<fv.n_gen {
    res = res + (fv.berezin_deriv(a) * gv.berezin_deriv(a)).smul(sgn)
  }
  res
}

///|
/// Multi-agent protocol Super-Jacobiator anomaly: given a custom (possibly distorted
/// or non-associative) bilinear interaction product `prod`, measures the failure of
/// the induced graded bracket [X, Y]_prod = prod(X, Y) - (-1)^{|X||Y|} prod(Y, X)
/// to close into a consistent Lie superalgebra. Equals 0 when `prod` is associative!
pub fn protocol_super_jacobi_anomaly(
  x : SuperMatrix,
  y : SuperMatrix,
  z : SuperMatrix,
  prod : (SuperMatrix, SuperMatrix) -> SuperMatrix,
) -> Double {
  let br = (u : SuperMatrix, v : SuperMatrix) => {
    let s = koszul_sign(u.parity, v.parity)
    prod(u, v) - prod(v, u).smul(s)
  }
  let t1 = br(x, br(y, z)).smul(koszul_sign(x.parity, z.parity))
  let t2 = br(y, br(z, x)).smul(koszul_sign(y.parity, x.parity))
  let t3 = br(z, br(x, y)).smul(koszul_sign(z.parity, y.parity))
  (t1 + t2 + t3).frob_norm()
}
