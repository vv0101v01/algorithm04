///|
/// Module 17 (Unified from `algo8`): Long-Term Memory Cell State Transition & Markov
/// Consolidation Semigroups (長期記憶細胞狀態轉移與馬可夫吸收半群).
/// Deduplicated & bug-fixed against `algebra.mbt`:
///   - O(log t) binary exponentiation in `memory_closed_form`,
///   - Non-mutating, zero-pivot-safe fundamental matrix solve `(I - Q) t = r` via `DenseMat::solve_vec`.

///|
/// Gated recurrent memory control parameters (forget f, input i, output o, candidate g).
#derive(Debug, Eq)
pub(all) struct Gates {
  forget : Double
  input : Double
  output : Double
  candidate : Double
}

///|
/// Long-term memory cell state (internal potential c, exposed activation h = o * tanh(c)).
#derive(Debug, Eq)
pub(all) struct MemoryCell {
  c : Double
  h : Double
}

///|
/// Single-step gated state transition step : MemoryCell x Gates -> MemoryCell.
pub fn MemoryCell::step(self : MemoryCell, g : Gates) -> MemoryCell {
  let c2 = g.forget * self.c + g.input * g.candidate
  { c: c2, h: g.output * @math.tanh(c2), }
}

///|
/// Binary exponentiation f^t in O(log t) multiplications.
fn pow_double_int(base : Double, exp : Int32) -> Double {
  let mut acc = 1.0
  let mut b = base
  let mut e = exp
  while e > 0 {
    if (e & 1) == 1 {
      acc = acc * b
    }
    b = b * b
    e = e >> 1
  }
  acc
}

///|
/// Exact transition-semigroup closed-form solution under constant gates (f, ig = i * g):
///   c_t = f^t * c_0 + ig * (1 - f^t) / (1 - f)   for f != 1,  and  c_0 + ig * t  for f == 1.
/// Converges exponentially to the unique fixed point c* = ig / (1 - f) whenever |f| < 1.
pub fn memory_closed_form(
  c0 : Double,
  f : Double,
  ig : Double,
  t : Int32,
) -> Double {
  if (f - 1.0).abs() < 1.0e-14 {
    c0 + ig * t.to_double()
  } else {
    let ft = pow_double_int(f, t)
    ft * c0 + ig * (1.0 - ft) / (1.0 - f)
  }
}

///|
/// Discrete cognitive memory consolidation lifecycle phases.
#derive(Debug, Eq, Hash)
pub(all) enum Phase {
  ShortTerm
  Encoding
  LongTerm
  Retrieval
  Lost
}

///|
/// Canonical state index of a memory phase in {0, 1, 2, 3, 4}.
pub fn phase_index(p : Phase) -> Int32 {
  match p {
    ShortTerm => 0
    Encoding => 1
    LongTerm => 2
    Retrieval => 3
    Lost => 4
  }
}

///|
/// Primitive (ergodic) 4-state Markov transition matrix across active memory phases
/// {ShortTerm, Encoding, LongTerm, Retrieval} (P^3 > 0 => unique stationary distribution pi).
pub fn memory_ergodic_matrix() -> Array[Array[Double]] {
  [
    [0.4, 0.4, 0.1, 0.1],
    [0.2, 0.4, 0.3, 0.1],
    [0.1, 0.2, 0.5, 0.2],
    [0.3, 0.2, 0.2, 0.3],
  ]
}

///|
/// Absorbing 5-state Markov transition matrix with `Lost` (index 4) as absorbing state.
pub fn memory_absorbing_matrix() -> Array[Array[Double]] {
  [
    [0.5, 0.4, 0.05, 0.0, 0.05],
    [0.1, 0.4, 0.4, 0.05, 0.05],
    [0.05, 0.1, 0.7, 0.1, 0.05],
    [0.2, 0.3, 0.3, 0.15, 0.05],
    [0.0, 0.0, 0.0, 0.0, 1.0],
  ]
}

///|
fn to_dense_square(p : Array[Array[Double]]) -> DenseMat {
  let n = p.length()
  DenseMat::from_fn(n, n, (i, j) => p[i][j])
}

///|
/// Power iteration pi_{k+1} = pi_k P = (P^T pi_k^T)^T converging to unique stationary pi.
pub fn stationary_power_iteration(
  p : Array[Array[Double]],
  steps : Int32,
) -> Array[Double] {
  let n = p.length()
  let pt = to_dense_square(p).transpose()
  let mut pi = Array::make(n, 1.0 / n.to_double())
  for _ in 0..<steps {
    pi = pt.matvec(pi)
  }
  pi
}

///|
/// Exact expected absorption time via Neumann fundamental matrix linear system (I - Q) t = r.
/// Pure (never mutates caller's `r`) and pivot-guarded via `DenseMat::solve_vec`.
pub fn absorption_time_linear_solve(
  q : Array[Array[Double]],
  r : Array[Double],
) -> Array[Double] {
  let n = q.length()
  let i_minus_q = DenseMat::from_fn(n, n, (i, j) => {
    (if i == j { 1.0 } else { 0.0 }) - q[i][j]
  })
  i_minus_q.solve_vec(r)
}

///|
/// Survival-probability tail series E_start[T] = sum_{n >= 0} P_start(T > n) truncated at `tol`.
/// Equals `((I - Q)^{-1} 1)[start]` by exact Markov fundamental-matrix duality.
pub fn absorption_time_series(
  start : Int32,
  p : Array[Array[Double]],
  n_transient : Int32,
  tol : Double,
) -> Double {
  let n = p.length()
  let pt = to_dense_square(p).transpose()
  let mut cur = Array::makei(n, i => if i == start { 1.0 } else { 0.0 })
  let mut acc = 0.0
  for _ in 0..<100000 {
    let mut transient_mass = 0.0
    for i in 0..<n_transient {
      transient_mass = transient_mass + cur[i]
    }
    acc = acc + transient_mass
    if transient_mass < tol {
      break
    }
    cur = pt.matvec(cur)
  }
  acc
}
