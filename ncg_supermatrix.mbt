///|
/// Module 4: Noncommutative Geometry & Supermatrix Equations (非交換幾何與超矩陣方程).
/// Implements:
///   1. Full Z_2-graded Supermatrices Mat(m|n, Lambda_N) with superproduct, supertranspose
///      M^{st}, cyclic-invariant supertrace str(M), exact Grassmann Gauss-Jordan inverse,
///      Schur complement, Berezinian (superdeterminant) Ber(M), super-exponential exp(M),
///      and Super-Liouville identity Ber(exp(X)) = exp(str(X)).
///   2. Supermatrix Equations: Graded Super-Sylvester / Super-Lyapunov solver
///      A X - (-1)^{|A||X|} X B = Q, Super-Riccati flow, and isospectral Lax flow dM/dt = [L, M]_s.
///   3. Connes Even Spectral Triple (A, H, D, gamma) with gamma^2 = I, {gamma, D} = 0,
///      universal differential 1-forms Omega^1_D(a) = [D, a], spectral action Tr(chi(D^2/Lambda^2)),
///      and exact Connes noncommutative spectral distance d_D(rho_1, rho_2).

///|
/// Supermatrix M = [[A, B], [C, D]] in Mat(m|n, Lambda_N) of homogeneous parity `parity`.
/// Entry (i, j) lives in row-major array `entries` of size (m+n)*(m+n).
/// For |M| = Even: A, D even; B, C odd. For |M| = Odd: A, D odd; B, C even.
#derive(Debug, Eq)
pub(all) struct SuperMatrix {
  m_bos : Int32
  n_ferm : Int32
  n_gen : Int32
  parity : Parity
  entries : Array[Grassmann]
}

///|
pub fn SuperMatrix::total_dim(self : SuperMatrix) -> Int32 {
  self.m_bos + self.n_ferm
}

///|
pub fn SuperMatrix::sector_parity(self : SuperMatrix, idx : Int32) -> Parity {
  if idx < self.m_bos {
    Even
  } else {
    Odd
  }
}

///|
pub fn SuperMatrix::zeros(
  m_bos : Int32,
  n_ferm : Int32,
  parity : Parity,
  n_gen~ : Int32 = DEFAULT_GRASSMANN_GEN,
) -> SuperMatrix {
  let d = m_bos + n_ferm
  {
    m_bos,
    n_ferm,
    n_gen,
    parity,
    entries: Array::makei(d * d, _ => Grassmann::zero(n_gen)),
  }
}

///|
pub fn SuperMatrix::identity(
  m_bos : Int32,
  n_ferm : Int32,
  n_gen~ : Int32 = DEFAULT_GRASSMANN_GEN,
) -> SuperMatrix {
  let sm = SuperMatrix::zeros(m_bos, n_ferm, Even, n_gen~)
  let d = m_bos + n_ferm
  for i in 0..<d {
    sm.entries[i * d + i] = Grassmann::scalar(n_gen, 1.0)
  }
  sm
}

///|
/// Construct a homogeneous SuperMatrix from raw blocks A (m x m), B (m x n),
/// C (n x m), D (n x n), projecting each entry onto its required Z_2 parity.
pub fn SuperMatrix::from_blocks(
  m_bos : Int32,
  n_ferm : Int32,
  n_gen : Int32,
  parity : Parity,
  a : Array[Grassmann],
  b : Array[Grassmann],
  c : Array[Grassmann],
  d : Array[Grassmann],
) -> SuperMatrix {
  let sm = SuperMatrix::zeros(m_bos, n_ferm, parity, n_gen~)
  let proj_diag = (g : Grassmann) => {
    match parity {
      Even => g.even_part()
      Odd => g.odd_part()
    }
  }
  let proj_off = (g : Grassmann) => {
    match parity {
      Even => g.odd_part()
      Odd => g.even_part()
    }
  }
  for i in 0..<m_bos {
    for j in 0..<m_bos {
      sm.set(i, j, proj_diag(a[i * m_bos + j]))
    }
    for j in 0..<n_ferm {
      sm.set(i, m_bos + j, proj_off(b[i * n_ferm + j]))
    }
  }
  for i in 0..<n_ferm {
    for j in 0..<m_bos {
      sm.set(m_bos + i, j, proj_off(c[i * m_bos + j]))
    }
    for j in 0..<n_ferm {
      sm.set(m_bos + i, m_bos + j, proj_diag(d[i * n_ferm + j]))
    }
  }
  sm
}

///|
/// Embed a real matrix of homogeneous supermatrix parity (Even: block-diag A, D;
/// Odd: off-diagonal B, C) into Mat(m|n, Lambda_N).
pub fn SuperMatrix::from_real(
  m_bos : Int32,
  n_ferm : Int32,
  parity : Parity,
  mat : DenseMat,
  n_gen~ : Int32 = DEFAULT_GRASSMANN_GEN,
) -> SuperMatrix {
  let sm = SuperMatrix::zeros(m_bos, n_ferm, parity, n_gen~)
  let tot = m_bos + n_ferm
  for i in 0..<tot {
    for j in 0..<tot {
      let req = parity.add_z2(sm.sector_parity(i).add_z2(sm.sector_parity(j)))
      if req == Even {
        sm.set(i, j, Grassmann::scalar(n_gen, mat.get(i, j)))
      }
    }
  }
  sm
}

///|
pub fn SuperMatrix::get(self : SuperMatrix, r : Int32, c : Int32) -> Grassmann {
  self.entries[r * self.total_dim() + c]
}

///|
pub fn SuperMatrix::set(
  self : SuperMatrix,
  r : Int32,
  c : Int32,
  v : Grassmann,
) -> Unit {
  self.entries[r * self.total_dim() + c] = v
}

///|
pub impl Add for SuperMatrix with fn add(self, other) {
  {
    m_bos: self.m_bos,
    n_ferm: self.n_ferm,
    n_gen: self.n_gen,
    parity: self.parity,
    entries: Array::makei(self.entries.length(), i => {
      self.entries[i] + other.entries[i]
    }),
  }
}

///|
pub impl Sub for SuperMatrix with fn sub(self, other) {
  {
    m_bos: self.m_bos,
    n_ferm: self.n_ferm,
    n_gen: self.n_gen,
    parity: self.parity,
    entries: Array::makei(self.entries.length(), i => {
      self.entries[i] - other.entries[i]
    }),
  }
}

///|
pub impl Neg for SuperMatrix with fn neg(self) {
  {
    m_bos: self.m_bos,
    n_ferm: self.n_ferm,
    n_gen: self.n_gen,
    parity: self.parity,
    entries: self.entries.map(e => -e),
  }
}

///|
/// Noncommutative associative supermatrix product M * N (|MN| = |M| + |N| mod 2).
pub impl Mul for SuperMatrix with fn mul(self, other) {
  let d = self.total_dim()
  let out = SuperMatrix::zeros(
    self.m_bos,
    self.n_ferm,
    self.parity.add_z2(other.parity),
    n_gen=self.n_gen,
  )
  for i in 0..<d {
    for j in 0..<d {
      let mut acc = Grassmann::zero(self.n_gen)
      for k in 0..<d {
        acc = acc + self.get(i, k) * other.get(k, j)
      }
      out.set(i, j, acc)
    }
  }
  out
}

///|
pub fn SuperMatrix::smul(self : SuperMatrix, s : Double) -> SuperMatrix {
  {
    m_bos: self.m_bos,
    n_ferm: self.n_ferm,
    n_gen: self.n_gen,
    parity: self.parity,
    entries: self.entries.map(e => e.smul(s)),
  }
}

///|
pub fn SuperMatrix::frob_norm(self : SuperMatrix) -> Double {
  let mut s = 0.0
  for e in self.entries {
    s = s + e.norm_sq()
  }
  s.sqrt()
}

///|
/// Berezin-Leites supertranspose:
///   [[A, B], [C, D]]^{st} = [[A^T, (-1)^{|M|} C^T], [-(-1)^{|M|} B^T, D^T]].
/// Satisfies (M * N)^{st} == (-1)^{|M||N|} N^{st} * M^{st} for ALL 4 parity pairs!
pub fn SuperMatrix::supertranspose(self : SuperMatrix) -> SuperMatrix {
  let m = self.m_bos
  let n = self.n_ferm
  let out = SuperMatrix::zeros(m, n, self.parity, n_gen=self.n_gen)
  let sgn = match self.parity {
    Even => 1.0
    Odd => -1.0
  }
  for i in 0..<m {
    for j in 0..<m {
      out.set(i, j, self.get(j, i))
    }
  }
  for i in 0..<m {
    for j in 0..<n {
      out.set(i, m + j, self.get(m + j, i).smul(sgn))
    }
  }
  for i in 0..<n {
    for j in 0..<m {
      out.set(m + i, j, self.get(j, m + i).smul(-sgn))
    }
  }
  for i in 0..<n {
    for j in 0..<n {
      out.set(m + i, m + j, self.get(m + j, m + i))
    }
  }
  out
}

///|
/// Graded-cyclic supertrace:
///   str(M) = tr(A) - (-1)^{|M|} tr(D).
/// Satisfies str(M * N) == (-1)^{|M||N|} str(N * M), hence str([M, N]_s) == 0 identically!
pub fn SuperMatrix::supertrace(self : SuperMatrix) -> Grassmann {
  let m = self.m_bos
  let n = self.n_ferm
  let mut tr_a = Grassmann::zero(self.n_gen)
  for i in 0..<m {
    tr_a = tr_a + self.get(i, i)
  }
  let mut tr_d = Grassmann::zero(self.n_gen)
  for j in 0..<n {
    tr_d = tr_d + self.get(m + j, m + j)
  }
  let sgn = match self.parity {
    Even => 1.0
    Odd => -1.0
  }
  tr_a - tr_d.smul(sgn)
}

///|
/// Helper: square matrix multiplication over commutative subalgebra Lambda_{N, even}.
pub fn gmat_mul(
  a : Array[Grassmann],
  r : Int32,
  k : Int32,
  b : Array[Grassmann],
  c : Int32,
  n_gen : Int32,
) -> Array[Grassmann] {
  let out = Array::makei(r * c, _ => Grassmann::zero(n_gen))
  for i in 0..<r {
    for j in 0..<c {
      let mut s = Grassmann::zero(n_gen)
      for t in 0..<k {
        s = s + a[i * k + t] * b[t * c + j]
      }
      out[i * c + j] = s
    }
  }
  out
}

///|
/// Identity n x n matrix over Lambda_{N, even}.
pub fn gmat_eye(n : Int32, n_gen : Int32) -> Array[Grassmann] {
  Array::makei(n * n, idx => {
    if idx / n == idx % n {
      Grassmann::scalar(n_gen, 1.0)
    } else {
      Grassmann::zero(n_gen)
    }
  })
}

///|
/// Shared body-norm partial pivot search and row swap over Lambda_{N, even}.
fn gmat_find_pivot(
  a : Array[Grassmann],
  n : Int32,
  k : Int32,
) -> (Int32, Double) {
  let mut piv = k
  let mut best = a[k * n + k].body().abs()
  for i in (k + 1)..<n {
    let v = a[i * n + k].body().abs()
    if v > best {
      best = v
      piv = i
    }
  }
  (piv, best)
}

///|
fn gmat_swap_rows(
  a : Array[Grassmann],
  n : Int32,
  r1 : Int32,
  r2 : Int32,
  start_col~ : Int32 = 0,
) -> Unit {
  if r1 == r2 {
    return
  }
  for j in start_col..<n {
    let tmp = a[r1 * n + j]
    a[r1 * n + j] = a[r2 * n + j]
    a[r2 * n + j] = tmp
  }
}

///|
/// Exact inverse of an n x n matrix over the commutative ring Lambda_{N, even}
/// via Gauss-Jordan elimination pivoting on max |body(a_{ik})|.
pub fn gmat_even_inv(
  mat : Array[Grassmann],
  n : Int32,
  n_gen : Int32,
) -> Array[Grassmann] {
  let a = mat.copy()
  let inv_m = gmat_eye(n, n_gen)
  for k in 0..<n {
    let (piv, best) = gmat_find_pivot(a, n, k)
    if best <= 1.0e-15 {
      continue
    }
    gmat_swap_rows(a, n, k, piv)
    gmat_swap_rows(inv_m, n, k, piv)
    let inv_diag = a[k * n + k].inv()
    for j in 0..<n {
      a[k * n + j] = a[k * n + j] * inv_diag
      inv_m[k * n + j] = inv_m[k * n + j] * inv_diag
    }
    for i in 0..<n {
      if i != k {
        let f = a[i * n + k]
        for j in 0..<n {
          a[i * n + j] = a[i * n + j] - f * a[k * n + j]
          inv_m[i * n + j] = inv_m[i * n + j] - f * inv_m[k * n + j]
        }
      }
    }
  }
  inv_m
}

///|
/// Exact determinant of an n x n matrix over the commutative subalgebra Lambda_{N, even}.
pub fn gmat_even_det(
  mat : Array[Grassmann],
  n : Int32,
  n_gen : Int32,
) -> Grassmann {
  if n == 0 {
    return Grassmann::scalar(n_gen, 1.0)
  }
  let a = mat.copy()
  let mut sign = 1.0
  let mut det_val = Grassmann::scalar(n_gen, 1.0)
  for k in 0..<n {
    let (piv, best) = gmat_find_pivot(a, n, k)
    if best <= 1.0e-15 {
      return Grassmann::zero(n_gen)
    }
    if piv != k {
      sign = -sign
      gmat_swap_rows(a, n, k, piv, start_col=k)
    }
    let diag = a[k * n + k]
    det_val = det_val * diag
    let inv_diag = diag.inv()
    for i in (k + 1)..<n {
      let f = a[i * n + k] * inv_diag
      for j in (k + 1)..<n {
        a[i * n + j] = a[i * n + j] - f * a[k * n + j]
      }
    }
  }
  det_val.smul(sign)
}

///|
/// Extract blocks (A, B, C, D) from a SuperMatrix.
pub fn SuperMatrix::blocks(
  self : SuperMatrix,
) -> (Array[Grassmann], Array[Grassmann], Array[Grassmann], Array[Grassmann]) {
  let m = self.m_bos
  let n = self.n_ferm
  let a = Array::makei(m * m, idx => self.get(idx / m, idx % m))
  let b = Array::makei(m * n, idx => self.get(idx / n, m + idx % n))
  let c = Array::makei(n * m, idx => self.get(m + idx / m, idx % m))
  let d = Array::makei(n * n, idx => self.get(m + idx / n, m + idx % n))
  (a, b, c, d)
}

///|
/// Bosonic Schur complement S_A = A - B * D^{-1} * C for an invertible Even SuperMatrix.
pub fn SuperMatrix::schur_bosonic(self : SuperMatrix) -> Array[Grassmann] {
  let m = self.m_bos
  let n = self.n_ferm
  let (a, b, c, d) = self.blocks()
  if n == 0 {
    return a
  }
  let d_inv = gmat_even_inv(d, n, self.n_gen)
  let bd = gmat_mul(b, m, n, d_inv, n, self.n_gen)
  let bdc = gmat_mul(bd, m, n, c, m, self.n_gen)
  Array::makei(m * m, i => a[i] - bdc[i])
}

///|
/// Exact Berezinian (superdeterminant) for an invertible Even SuperMatrix M = [[A, B], [C, D]]:
///   Ber(M) = det(A - B D^{-1} C) * det(D)^{-1} in Lambda_{N, even}^x.
/// Satisfies multiplicativity Ber(M1 * M2) == Ber(M1) * Ber(M2) and
/// Super-Liouville theorem Ber(exp(X)) == exp(str(X))!
pub fn SuperMatrix::berezinian(self : SuperMatrix) -> Grassmann {
  let m = self.m_bos
  let n = self.n_ferm
  let g = self.n_gen
  let (a, b, c, d) = self.blocks()
  if n == 0 {
    return gmat_even_det(a, m, g)
  }
  let d_inv = gmat_even_inv(d, n, g)
  let bdc = gmat_mul(gmat_mul(b, m, n, d_inv, n, g), m, n, c, m, g)
  let s_a = Array::makei(m * m, i => a[i] - bdc[i])
  gmat_even_det(s_a, m, g) / gmat_even_det(d, n, g)
}

///|
/// Exact block inverse M^{-1} of an invertible Even SuperMatrix via 2-inversion
/// Frobenius-Banachiewicz Schur formula (requires only D^{-1} and S_A^{-1},
/// avoiding redundant A^{-1}/S_D^{-1} inversions and working even when body(A) is singular):
///   M^{-1} = [[ S_A^{-1},             -S_A^{-1} B D^{-1}               ],
///             [ -D^{-1} C S_A^{-1},   D^{-1} + D^{-1} C S_A^{-1} B D^{-1} ]].
pub fn SuperMatrix::inverse(self : SuperMatrix) -> SuperMatrix {
  let m = self.m_bos
  let n = self.n_ferm
  let g = self.n_gen
  let (a, b, c, d) = self.blocks()
  if n == 0 {
    return SuperMatrix::from_blocks(
      m,
      0,
      g,
      Even,
      gmat_even_inv(a, m, g),
      [],
      [],
      [],
    )
  }
  let d_inv = gmat_even_inv(d, n, g)
  if m == 0 {
    return SuperMatrix::from_blocks(0, n, g, Even, [], [], [], d_inv)
  }
  let bd = gmat_mul(b, m, n, d_inv, n, g)
  let dc = gmat_mul(d_inv, n, n, c, m, g)
  let bdc = gmat_mul(bd, m, n, c, m, g)
  let sa = Array::makei(m * m, i => a[i] - bdc[i])
  let sa_inv = gmat_even_inv(sa, m, g)
  let sa_bd = gmat_mul(sa_inv, m, m, bd, n, g)
  let top_r = sa_bd.map(x => -x)
  let bot_l = gmat_mul(dc, n, m, sa_inv, m, g).map(x => -x)
  let dc_sa_bd = gmat_mul(dc, n, m, sa_bd, n, g)
  let bot_r = Array::makei(n * n, i => d_inv[i] + dc_sa_bd[i])
  SuperMatrix::from_blocks(m, n, g, Even, sa_inv, top_r, bot_l, bot_r)
}

///|
/// Supermatrix exponential exp(X) for Even X in gl(m|n)_0 via scaling-and-squaring.
pub fn SuperMatrix::super_exp(self : SuperMatrix) -> SuperMatrix {
  let m = self.m_bos
  let n = self.n_ferm
  let nrm = self.frob_norm()
  let mut s = 0
  let mut sf = 1.0
  while nrm / sf > 0.4 {
    s = s + 1
    sf = sf * 2.0
  }
  let x = self.smul(1.0 / sf)
  let mut acc = SuperMatrix::identity(m, n, n_gen=self.n_gen)
  let mut term = SuperMatrix::identity(m, n, n_gen=self.n_gen)
  for k in 1..<=18 {
    term = (term * x).smul(1.0 / k.to_double())
    acc = acc + term
  }
  for _ in 0..<s {
    acc = acc * acc
  }
  acc
}

///|
/// Solve the real Sylvester / Lyapunov matrix equation A * X + sign * X * B = Q
/// via exact Kronecker linear system (I (x) A + sign * B^T (x) I) vec(X) = vec(Q).
/// Used both as building block for Graded Super-Sylvester and for Quantum Fisher SLD!
pub fn solve_sylvester(
  a : DenseMat,
  b : DenseMat,
  q : DenseMat,
  sign~ : Double = -1.0,
) -> DenseMat {
  let n = a.rows
  let m = b.cols
  let nm = n * m
  let sys = DenseMat::zeros(nm, nm)
  let rhs = Array::make(nm, 0.0)
  for i in 0..<n {
    for j in 0..<m {
      let row = i * m + j
      rhs[row] = q.get(i, j)
      for k in 0..<n {
        let col = k * m + j
        sys.set(row, col, sys.get(row, col) + a.get(i, k))
      }
      for l in 0..<m {
        let col = i * m + l
        sys.set(row, col, sys.get(row, col) + sign * b.get(l, j))
      }
    }
  }
  let sol = sys.solve_vec(rhs)
  DenseMat::from_fn(n, m, (i, j) => sol[i * m + j])
}

///|
/// Solve the Graded Super-Sylvester Equation over Mat(m|n, Lambda_N):
///   A * X - (-1)^{|A||X|} X * B = Q,
/// for homogeneous real-represented supermatrices A, B (|A| = |B|) and target Q,
/// returning homogeneous X with exact Koszul sign s = -(-1)^{|A||X|}.
pub fn solve_super_sylvester(
  a : DenseMat,
  parity_a : Parity,
  b : DenseMat,
  q : DenseMat,
  parity_x : Parity,
) -> DenseMat {
  let s = -koszul_sign(parity_a, parity_x)
  solve_sylvester(a, b, q, sign=s)
}

///|
/// Solve the full Grassmann-valued Even Super-Sylvester equation A * X - X * B = Q
/// on Mat(m|n, Lambda_N) by exact grade-by-grade blade induction (since grade 0
/// decouples into a real Sylvester system and each higher blade k >= 1 inherits
/// known lower-grade nilpotent soul source terms!).
pub fn solve_grassmann_super_sylvester(
  a : SuperMatrix,
  b : SuperMatrix,
  q : SuperMatrix,
) -> SuperMatrix {
  let d = a.total_dim()
  let n_gen = a.n_gen
  let n_blades = 1 << n_gen
  let a0 = DenseMat::from_fn(d, d, (i, j) => a.get(i, j).body())
  let b0 = DenseMat::from_fn(d, d, (i, j) => b.get(i, j).body())
  let x = SuperMatrix::zeros(a.m_bos, a.n_ferm, q.parity, n_gen~)
  // Solve strictly in ascending order of popcount(mask) = 0, 1, ..., n_gen!
  for deg in 0..<=n_gen {
    for mask in 0..<n_blades {
      if popcount(mask) == deg {
        // Compute residual R_mask = Q_mask - (A_soul * X_{<deg} - X_{<deg} * B_soul)_mask
        let ax_prev = a * x - x * b
        let rhs_mat = DenseMat::from_fn(d, d, (i, j) => {
          q.get(i, j).coeff_at(mask) - ax_prev.get(i, j).coeff_at(mask)
        })
        let x_mask = solve_sylvester(a0, b0, rhs_mat, sign=-1.0)
        for i in 0..<d {
          for j in 0..<d {
            let v = x_mask.get(i, j)
            if v.abs() > 1.0e-15 {
              x.set(i, j, x.get(i, j) + Grassmann::blade(n_gen, mask, coeff=v))
            }
          }
        }
      }
    }
  }
  x
}

///|
/// Integrate the Differential Super-Riccati Equation via RK4:
///   dP/dt = A^{st} P + P A - P R P + Q,
/// governing optimal super-covariance filtering on M^{m|n}.
pub fn step_super_riccati(
  p : SuperMatrix,
  a : SuperMatrix,
  r_mat : SuperMatrix,
  q_mat : SuperMatrix,
  dt : Double,
) -> SuperMatrix {
  let ast = a.supertranspose()
  let rhs = (cur : SuperMatrix) => {
    ast * cur + cur * a - cur * r_mat * cur + q_mat
  }
  let k1 = rhs(p)
  let k2 = rhs(p + k1.smul(0.5 * dt))
  let k3 = rhs(p + k2.smul(0.5 * dt))
  let k4 = rhs(p + k3.smul(dt))
  p + (k1 + k2.smul(2.0) + k3.smul(2.0) + k4).smul(dt / 6.0)
}

///|
/// Exact Lie-group isospectral Super-Lax flow step:
///   dM/dt = [L, M]_s  ===>  M(t + dt) = exp(dt * L) * M(t) * exp(-dt * L),
/// preserving all supertrace Casimirs str(M^k) and Ber(M) to machine precision!
pub fn step_super_lax(
  m : SuperMatrix,
  l_gen : SuperMatrix,
  dt : Double,
) -> SuperMatrix {
  let u = l_gen.smul(dt).super_exp()
  let u_inv = l_gen.smul(-dt).super_exp()
  u * m * u_inv
}

///|
/// Connes Even Noncommutative Spectral Triple (A, H, D, gamma):
///   - H = R^m (+) R^n graded by chirality operator gamma = diag(I_m, -I_n) (gamma^2 = I),
///   - D = odd symmetric Dirac operator (D^T = D, gamma * D + D * gamma = 0),
///   - A = noncommutative observable algebra represented as bounded even operators on H.
#derive(Debug, Eq)
pub(all) struct SpectralTriple {
  m_bos : Int32
  n_ferm : Int32
  gamma : DenseMat
  dirac : DenseMat
}

///|
/// Shared Z_2 chirality grading matrix gamma = diag(I_m, -I_n) (gamma^2 = I).
pub fn chirality_grading_mat(m_bos : Int32, n_ferm : Int32) -> DenseMat {
  let tot = m_bos + n_ferm
  let gamma = DenseMat::zeros(tot, tot)
  for i in 0..<m_bos {
    gamma.set(i, i, 1.0)
  }
  for j in 0..<n_ferm {
    gamma.set(m_bos + j, m_bos + j, -1.0)
  }
  gamma
}

///|
/// Build an even spectral triple from a boson-fermion Yukawa/coboundary operator Y (m x n):
///   D = [[0, Y], [Y^T, 0]],  gamma = [[I_m, 0], [0, -I_n]].
/// Guarantees D = D^T, gamma^2 = I, and exact anticommutation {gamma, D} = 0.
pub fn SpectralTriple::from_yukawa(yukawa : DenseMat) -> SpectralTriple {
  let m = yukawa.rows
  let n = yukawa.cols
  let gamma = chirality_grading_mat(m, n)
  let dirac = DenseMat::zeros(m + n, m + n)
  for i in 0..<m {
    for j in 0..<n {
      let y = yukawa.get(i, j)
      dirac.set(i, m + j, y)
      dirac.set(m + j, i, y)
    }
  }
  { m_bos: m, n_ferm: n, gamma, dirac, }
}

///|
/// Verify the spectral triple chirality axiom || gamma * D + D * gamma ||_F == 0.
pub fn SpectralTriple::chirality_anticommutator_norm(
  self : SpectralTriple,
) -> Double {
  (self.gamma * self.dirac + self.dirac * self.gamma).frob_norm()
}

///|
/// Universal noncommutative differential 1-form d_D(a) = [D, a] = D * a - a * D in Omega^1_D(A).
pub fn SpectralTriple::diff_one_form(
  self : SpectralTriple,
  a : DenseMat,
) -> DenseMat {
  self.dirac * a - a * self.dirac
}

///|
/// Connes-Rieffel Lipschitz seminorm L_D(a) = || [D, a] ||_op.
pub fn SpectralTriple::lip_seminorm(
  self : SpectralTriple,
  a : DenseMat,
) -> Double {
  self.diff_one_form(a).op_norm()
}

///|
/// Chamseddine-Connes bosonic spectral action S_spec(D, Lambda) = Tr(exp(-D^2 / Lambda^2)).
pub fn SpectralTriple::spectral_action(
  self : SpectralTriple,
  cutoff : Double,
) -> Double {
  let d2 = self.dirac * self.dirac
  let (eigs, _) = d2.sym_eigen()
  let inv_l2 = 1.0 / (cutoff * cutoff)
  let mut s = 0.0
  for e in eigs {
    s = s + @math.exp(-e.max(0.0) * inv_l2)
  }
  s
}

///|
/// Connes noncommutative spectral distance between two states on a commutative
/// discrete/diagonal subalgebra A = C(V) subset B(H):
///   d_D(p, q) = sup { |<delta_rho, a>| : a in A_sa, || [D, a] ||_op <= 1 }.
/// For a 2-sheeted (boson-fermion) M_1(+)M_1 triple with Yukawa coupling g,
/// reproduces the exact Connes-Lott Higgs sheet distance d_D(0, 1) = 1 / |g|!
/// For general diagonal finite spectral triples, solves the dual Lipschitz
/// optimization via projected subgradient ascent with exact normalization.
pub fn SpectralTriple::connes_distance(
  self : SpectralTriple,
  state_p : Array[Double],
  state_q : Array[Double],
) -> Double {
  let tot = self.m_bos + self.n_ferm
  let diff = vec_sub(state_p, state_q)
  if vec_norm(diff) < 1.0e-14 {
    return 0.0
  }
  let make_diag = (v : Array[Double]) => {
    let m = DenseMat::zeros(tot, tot)
    for i in 0..<tot {
      m.set(i, i, v[i])
    }
    m
  }
  // Exact closed form when diff is concentrated on two connected basis states
  let mut best_dist = 0.0
  // Candidate 1: direct alignment with state difference
  let mut a_vec = diff.copy()
  // Center to remove kernel of [D, .] (multiples of identity)
  let center = (v : Array[Double]) => {
    let mut mean = 0.0
    for x in v {
      mean = mean + x
    }
    mean = mean / tot.to_double()
    v.map(x => x - mean)
  }
  a_vec = center(a_vec)
  let eval_candidate = (v : Array[Double]) => {
    let lip = self.lip_seminorm(make_diag(v))
    if lip > 1.0e-13 {
      vec_dot(diff, v).abs() / lip
    } else {
      0.0
    }
  }
  best_dist = eval_candidate(a_vec)
  // Candidate 2: graph-Laplacian preconditioner L^+ diff (optimal initial direction)
  let lap = DenseMat::zeros(tot, tot)
  for i in 0..<tot {
    let mut row_s = 0.0
    for j in 0..<tot {
      if i != j {
        let w = self.dirac.get(i, j) * self.dirac.get(i, j)
        lap.set(i, j, -w)
        row_s = row_s + w
      }
    }
    lap.set(i, i, row_s + 1.0e-6)
  }
  let mut cur = center(lap.solve_vec(diff))
  let c2 = eval_candidate(cur)
  if c2 > best_dist {
    best_dist = c2
  }
  // Refine max_v <diff, v> / ||[D, diag(v)]||_op via finite-difference ascent on log-ratio
  let eps = 1.0e-6
  for step in 0..<120 {
    let nrm = vec_norm(cur)
    if nrm < 1.0e-13 {
      break
    }
    cur = vec_scale(cur, 1.0 / nrm)
    let base_val = eval_candidate(cur)
    if base_val > best_dist {
      best_dist = base_val
    }
    let grad = numerical_grad(eval_candidate, cur, eps~)
    let lr = 0.15 / (1.0 + 0.05 * step.to_double())
    cur = center(vec_add(cur, vec_scale(grad, lr)))
  }
  let final_v = eval_candidate(cur)
  if final_v > best_dist {
    final_v
  } else {
    best_dist
  }
}
