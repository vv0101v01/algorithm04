///|
/// Module 12: Semitropical / Tropical Semiring Projective Geometry (半熱帶環射影).
/// Implements:
///   1. IdempotentSemiring trait & three canonical models:
///        - `Tropical` T_max = (R U {-inf}, max, +) (idempotent max-plus semiring),
///        - `MaslovSemiring` S_hbar = (R U {-inf}, (+)_hbar, +) (Litvinov-Maslov
///          log-semiring bridging Fisher-Boltzmann analysis and PoPE softplus to T_max),
///        - `SuperTropical` ST = T U G U {-inf} (Izhakian-Rowen semitropical/supertropical
///          semiring with Ghost Ideal G capturing exact tie-breaking corner loci a (+) a = a^nu
///          where tropical hypersurfaces & multi-agent phase transitions occur!);
///   2. Tropical Projective Space TP^{n-1} = (T_max^n \ {0}) / (x ~ lambda (*) x):
///        - Universal quotient canonicalization (max-gauge, chart-gauge, zero-sum gauge),
///        - Asymmetric Funk weak metric & Tropical Hilbert Projective Metric d_TH([x], [y]),
///        - Exact Viro-Maslov Log-Simplex Diffeomorphism TP^{n-1} <-> Delta^{n-1}_+
///          identifying TP^{n-1} with Module 8's categorical Fisher natural parameter space!;
///   3. Tropical Matrix Algebra, Residuation Galois Connection & Projective Polytope Projection:
///        - Tropical product A (*) B, residuation A \ B verifying (V (*) u <= x <=> u <= V \ x),
///        - Cohen-Gaubert-Quadrat Projective Retraction Pi_V(x) = V (*) (V \ x) : TP^{n-1} -> V
///          (idempotent, 1-Lipschitz in d_TH, and exact global d_TH nearest-point projector!),
///        - Kleene Star A^* = I (+) A (+) ... (+) A^{(*)(n-1)},
///        - Karp's Exact O(n^3) Tropical Spectral Radius lambda_trop(A) & Kleene Projective
///          Eigenvector [v*] in TP^{n-1} satisfying [A (*) v*] == [v*],
///        - Maslov-Perron-Frobenius Spectral Sandwich Theorem:
///            lambda_trop(A) <= hbar ln rho(exp(A / hbar)) <= lambda_trop(A) + hbar ln n;
///   4. Tropical Grassmannian Trop Gr(2, N) subset TP^{C(N,2)-1} & Poincare Asymptotic Tree Limit:
///        - Supertropical Plucker Ghost Criterion for phylogenetic tree metrics,
///        - Exact Subdominant Ultrametric Projection onto Trop Gr(2, N),
///        - Gromov-Plucker curvature bound connecting B_c^m (Module 1) to Trop Gr(2, N)!

///|
/// Sentinel representing tropical additive zero -infinity.
pub const TROP_NEG_INF : Double = -1.0e30

///|
/// Abstract Idempotent Semiring (S, (+), (*), 0_S, 1_S) satisfying a (+) a == a.
pub(open) trait IdempotentSemiring: Eq {
  fn tzero() -> Self
  fn tone() -> Self
  fn tadd(Self, Self) -> Self
  fn tmul(Self, Self) -> Self
}

///|
/// Max-plus Tropical Semiring element in T_max = R U {-inf}.
#derive(Debug, Eq)
pub(all) struct Tropical {
  val : Double
}

///|
pub fn Tropical::finite(v : Double) -> Tropical {
  { val: v, }
}

///|
pub fn Tropical::zero() -> Tropical {
  { val: TROP_NEG_INF, }
}

///|
pub fn Tropical::one() -> Tropical {
  { val: 0.0, }
}

///|
pub fn Tropical::is_zero(self : Tropical) -> Bool {
  self.val <= TROP_NEG_INF * 0.5
}

///|
pub impl IdempotentSemiring for Tropical with fn tzero() {
  Tropical::zero()
}

///|
pub impl IdempotentSemiring for Tropical with fn tone() {
  Tropical::one()
}

///|
/// Tropical addition a (+) b = max(a, b) (idempotent: a (+) a == a).
pub impl IdempotentSemiring for Tropical with fn tadd(self, other) {
  if self.is_zero() {
    other
  } else if other.is_zero() {
    self
  } else {
    { val: self.val.max(other.val), }
  }
}

///|
/// Tropical multiplication a (*) b = a + b (with -inf absorbing).
pub impl IdempotentSemiring for Tropical with fn tmul(self, other) {
  if self.is_zero() || other.is_zero() {
    Tropical::zero()
  } else {
    { val: self.val + other.val, }
  }
}

///|
/// Maslov hbar-deformed semiring sum: a (+)_hbar b = hbar * ln(exp(a/hbar) + exp(b/hbar)).
/// Satisfies:
///   - Associativity, commutativity, and distributivity of (+) over (+)_hbar,
///   - PoPE identity: 0 (+)_1 q == softplus(q)  and  lim_{hbar->0+} 0 (+)_hbar q == max(0, q),
///   - Universal Maslov bound: max(a, b) <= a (+)_hbar b <= max(a, b) + hbar * ln(2)!
pub fn maslov_add(a : Double, b : Double, hbar : Double) -> Double {
  if a <= TROP_NEG_INF * 0.5 {
    return b
  }
  if b <= TROP_NEG_INF * 0.5 {
    return a
  }
  if hbar <= 1.0e-15 {
    return a.max(b)
  }
  let m = a.max(b)
  let diff = (a - b).abs()
  m + hbar * @math.ln_1p(@math.exp(-diff / hbar))
}

///|
/// N-ary Maslov log-sum-exp (+)_(hbar, i) a_i with exact bound [max a_i, max a_i + hbar ln n].
pub fn maslov_sum(xs : Array[Double], hbar : Double) -> Double {
  if xs.length() == 0 {
    return TROP_NEG_INF
  }
  let mut m = xs[0]
  for x in xs {
    if x > m {
      m = x
    }
  }
  if hbar <= 1.0e-15 || m <= TROP_NEG_INF * 0.5 {
    return m
  }
  let mut s = 0.0
  for x in xs {
    if x > TROP_NEG_INF * 0.5 {
      s = s + @math.exp((x - m) / hbar)
    }
  }
  m + hbar * @math.ln(s)
}

///|
/// Izhakian-Rowen Semitropical / Supertropical Semiring ST = Tangible U Ghost U {Zero}:
///   - `Tangible(a)`: unique dominant maximum with valuation nu = a (decisive regime);
///   - `Ghost(a)`: critical corner / tie a (+) a = a^nu (ghost ideal G: tropical variety,
///                 polyhedral crease, and multi-agent symmetry-breaking bifurcation locus!);
///   - `TropZero`: additive identity -infinity.
#derive(Debug, Eq)
pub(all) enum SuperTropical {
  TropZero
  Tangible(Double)
  Ghost(Double)
}

///|
/// Ghost projection operator nu : ST -> G U {TropZero}.
pub fn SuperTropical::nu_val(self : SuperTropical) -> Double {
  match self {
    TropZero => TROP_NEG_INF
    Tangible(a) | Ghost(a) => a
  }
}

///|
pub fn SuperTropical::is_ghost(self : SuperTropical) -> Bool {
  match self {
    Ghost(_) => true
    _ => false
  }
}

///|
/// Supertropical addition with tolerance `tie_tol` detecting exact/near-degenerate
/// corner loci: when |nu(x) - nu(y)| <= tie_tol, collapses into the Ghost Ideal G!
pub fn SuperTropical::st_add(
  a : SuperTropical,
  b : SuperTropical,
  tie_tol~ : Double = 1.0e-11,
) -> SuperTropical {
  match (a, b) {
    (TropZero, y) => y
    (x, TropZero) => x
    _ => {
      let va = a.nu_val()
      let vb = b.nu_val()
      if (va - vb).abs() <= tie_tol {
        Ghost(va.max(vb))
      } else if va > vb {
        a
      } else {
        b
      }
    }
  }
}

///|
/// Supertropical multiplication: G is a multiplicative semiring ideal (T * G subset G, G * G subset G)!
pub fn SuperTropical::st_mul(
  a : SuperTropical,
  b : SuperTropical,
) -> SuperTropical {
  match (a, b) {
    (TropZero, _) | (_, TropZero) => TropZero
    (Tangible(x), Tangible(y)) => Tangible(x + y)
    (x, y) => Ghost(x.nu_val() + y.nu_val())
  }
}

///|
/// Evaluate a tropical polynomial P(x) = (+)_m (c_m (*) x^{alpha_m}) in the supertropical
/// semiring ST. A point x in TP^{n-1} lies on the TROPICAL HYPERSURFACE V_trop(P)
/// iff P(x) is a `Ghost(_)` element (the maximum is achieved by >= 2 monomials simultaneously)!
pub fn eval_supertropical_poly(
  coeffs : Array[Double],
  exponents : Array[Array[Double]],
  x : Array[Double],
  tie_tol~ : Double = 1.0e-9,
) -> SuperTropical {
  let mut acc : SuperTropical = TropZero
  for m in 0..<coeffs.length() {
    let term_val = coeffs[m] + vec_dot(exponents[m], x)
    acc = SuperTropical::st_add(acc, Tangible(term_val), tie_tol~)
  }
  acc
}

///|
/// Point [x_0 : x_1 : ... : x_{n-1}] in Tropical Projective Space TP^{n-1} = R^n / R*1,
/// canonically stored in max-normalized gauge: max_i coords[i] == 0.0 (i.e. (+)_i x_i = 1_T).
/// By universal quotient property, [x_0 + c : ... : x_{n-1} + c] == [x_0 : ... : x_{n-1}]
/// for EVERY real scalar c in R!
#derive(Debug, Eq)
pub(all) struct TropProjPoint {
  coords : Array[Double]
}

///|
/// Universal quotient projection pi : R^n -> TP^{n-1} normalizing max_i x_i = 0.
pub fn TropProjPoint::from_homogeneous(raw : Array[Double]) -> TropProjPoint {
  let mut m = raw[0]
  for x in raw {
    if x > m {
      m = x
    }
  }
  { coords: raw.map(x => x - m), }
}

///|
/// Affine chart map TP^{n-1} -> R^{n-1} fixing the last homogeneous coordinate to 0:
///   eta_i = x_i - x_{n-1}   (i = 0, ..., n-2),
/// which is IDENTICAL to Module 8's categorical Fisher natural coordinates `eta`!
pub fn TropProjPoint::to_fisher_natural_coords(
  self : TropProjPoint,
) -> Array[Double] {
  let n = self.coords.length()
  let anchor = self.coords[n - 1]
  Array::makei(n - 1, i => self.coords[i] - anchor)
}

///|
/// Inverse chart map from Fisher natural coordinates eta in R^{K-1} to TP^{K-1}.
pub fn TropProjPoint::from_fisher_natural_coords(
  eta : Array[Double],
) -> TropProjPoint {
  let k = eta.length() + 1
  let raw = Array::makei(k, i => if i < eta.length() { eta[i] } else { 0.0 })
  TropProjPoint::from_homogeneous(raw)
}

///|
/// Sentinel predicate: true iff `v` represents a finite real element of T_max \ {-inf}.
fn is_trop_finite(v : Double) -> Bool {
  v > TROP_NEG_INF * 0.5
}

///|
/// Viro-Maslov Log-Simplex Diffeomorphism  Phi_hbar : TP^{n-1} -> int(Delta^{n-1}):
///   Phi_hbar([x])_i = exp(x_i / hbar) / sum_j exp(x_j / hbar),
/// with exact inverse  Phi_hbar^{-1}(p) = [hbar ln p_0 : ... : hbar ln p_{n-1}] in TP^{n-1}!
/// Strictly invariant under tropical projective scaling x |-> x + c * 1!
pub fn TropProjPoint::to_simplex(
  self : TropProjPoint,
  hbar : Double,
) -> Array[Double] {
  softmax_vec(self.coords.map(x => x / hbar))
}

///|
/// Inverse Viro-Maslov Tropicalization Map  Log_hbar : int(Delta^{n-1}) -> TP^{n-1}.
pub fn TropProjPoint::from_simplex(
  probs : Array[Double],
  hbar : Double,
) -> TropProjPoint {
  TropProjPoint::from_homogeneous(
    probs.map(p => hbar * @math.ln(p.max(1.0e-30))),
  )
}

///|
/// Check whether [x] in TP^{n-1} sits on the supertropical Ghost Locus (critical decision
/// boundary where >= 2 projective coordinates tie for the global maximum 0.0!).
pub fn TropProjPoint::is_on_ghost_boundary(
  self : TropProjPoint,
  tie_tol~ : Double = 1.0e-6,
) -> Bool {
  let mut sum : SuperTropical = TropZero
  for c in self.coords {
    sum = SuperTropical::st_add(sum, Tangible(c), tie_tol~)
  }
  sum.is_ghost()
}

///|
/// Asymmetric Funk weak metric Funk(x, y) = max_i (x_i - y_i).
pub fn funk_metric(x : Array[Double], y : Array[Double]) -> Double {
  let mut m = x[0] - y[0]
  for i in 1..<x.length() {
    let d = x[i] - y[i]
    if d > m {
      m = d
    }
  }
  m
}

///|
/// Tropical Hilbert Projective Metric (Variation / Hopf Oscillation Metric) on TP^{n-1}:
///   d_TH([x], [y]) = max_i (x_i - y_i) - min_i (x_i - y_i) = Funk(x, y) + Funk(y, x).
/// Satisfies:
///   - Scale invariance: d_TH(x + a*1, y + b*1) == d_TH(x, y) for all a, b in R,
///   - Positivity & identity: d_TH([x], [y]) == 0 <=> [x] == [y] in TP^{n-1},
///   - Symmetry & exact triangle inequality: d_TH([x], [z]) <= d_TH([x], [y]) + d_TH([y], [z]),
///   - Equals Thompson-Hilbert log-odds metric max_{i,j} |ln((p_i q_j)/(p_j q_i))| on Delta^{n-1}!
pub fn tropical_hilbert_dist(p : TropProjPoint, q : TropProjPoint) -> Double {
  funk_metric(p.coords, q.coords) + funk_metric(q.coords, p.coords)
}

///|
/// Tropical geodesic segment gamma(t) = [(a (*) x) (+) (b (*) y)] joining p and q in TP^{n-1}
/// for t in [0, 1] (piecewise-linear 2-segment tropical line achieving d_TH(p, gamma) + d_TH(gamma, q) == d_TH(p, q)!).
pub fn tropical_projective_geodesic(
  p : TropProjPoint,
  q : TropProjPoint,
  t : Double,
) -> TropProjPoint {
  let lo = -funk_metric(p.coords, q.coords) // min_i (q_i - p_i)
  let hi = funk_metric(q.coords, p.coords) // max_i (q_i - p_i)
  let alpha = (1.0 - t) * lo + t * hi
  let raw = Array::makei(p.coords.length(), i => {
    (alpha + p.coords[i]).max(q.coords[i])
  })
  TropProjPoint::from_homogeneous(raw)
}

///|
/// Matrix over the max-plus tropical semiring T_max^{rows x cols}.
#derive(Debug, Eq)
pub(all) struct TropMatrix {
  rows : Int32
  cols : Int32
  data : Array[Double]
}

///|
pub fn TropMatrix::zeros(rows : Int32, cols : Int32) -> TropMatrix {
  { rows, cols, data: Array::make(rows * cols, TROP_NEG_INF), }
}

///|
/// Tropical identity matrix I_T: diagonal = 1_T = 0.0, off-diagonal = 0_T = -inf.
pub fn TropMatrix::identity(n : Int32) -> TropMatrix {
  let m = TropMatrix::zeros(n, n)
  for i in 0..<n {
    m.data[i * n + i] = 0.0
  }
  m
}

///|
pub fn TropMatrix::from_fn(
  rows : Int32,
  cols : Int32,
  f : (Int32, Int32) -> Double,
) -> TropMatrix {
  let data = Array::make(rows * cols, TROP_NEG_INF)
  for i in 0..<rows {
    for j in 0..<cols {
      data[i * cols + j] = f(i, j)
    }
  }
  { rows, cols, data, }
}

///|
/// Construct a generator matrix V in T^{n x r} whose columns are r projective vertices in TP^{n-1}.
pub fn TropMatrix::from_projective_columns(
  vertices : Array[TropProjPoint],
) -> TropMatrix {
  let r = vertices.length()
  let n = vertices[0].coords.length()
  TropMatrix::from_fn(n, r, (i, k) => vertices[k].coords[i])
}

///|
pub fn TropMatrix::get(self : TropMatrix, r : Int32, c : Int32) -> Double {
  self.data[r * self.cols + c]
}

///|
/// Tropical matrix addition (A (+) B)_{ij} = max(A_{ij}, B_{ij}).
pub fn TropMatrix::tadd(self : TropMatrix, other : TropMatrix) -> TropMatrix {
  {
    rows: self.rows,
    cols: self.cols,
    data: Array::makei(self.data.length(), i => self.data[i].max(other.data[i])),
  }
}

///|
/// Shared max-plus inner product of row `r` with an arbitrary indexed sequence.
fn TropMatrix::row_trop_dot(
  self : TropMatrix,
  r : Int32,
  get_rhs : (Int32) -> Double,
) -> Double {
  let mut best = TROP_NEG_INF
  for k in 0..<self.cols {
    let a = self.get(r, k)
    let b = get_rhs(k)
    if is_trop_finite(a) && is_trop_finite(b) {
      let s = a + b
      if s > best {
        best = s
      }
    }
  }
  best
}

///|
/// Tropical matrix multiplication (A (*) B)_{ij} = max_k (A_{ik} + B_{kj}).
pub fn TropMatrix::tmul(self : TropMatrix, other : TropMatrix) -> TropMatrix {
  TropMatrix::from_fn(self.rows, other.cols, (i, j) => {
    self.row_trop_dot(i, k => other.get(k, j))
  })
}

///|
/// Tropical matrix-vector action (A (*) x)_i = max_j (A_{ij} + x_j).
pub fn TropMatrix::tmul_vec(
  self : TropMatrix,
  x : Array[Double],
) -> Array[Double] {
  Array::makei(self.rows, i => self.row_trop_dot(i, j => x[j]))
}

///|
/// Induced Projective Linear Map [A] : TP^{cols-1} -> TP^{rows-1}, [x] |-> [A (*) x].
/// Well-defined by homogeneity A (*) (c (*) x) = c (*) (A (*) x), and strictly
/// 1-Lipschitz (contractive) under the Tropical Hilbert Metric d_TH!
pub fn TropMatrix::projective_apply(
  self : TropMatrix,
  p : TropProjPoint,
) -> TropProjPoint {
  TropProjPoint::from_homogeneous(self.tmul_vec(p.coords))
}

///|
/// Left Residuation (Right Galois Adjoint)  (V \ x)_k = min_{0 <= i < n} (x_i - V_{ik}).
/// Satisfies the EXACT UNIVERSAL GALOIS ADJUNCTION (Theorem IX.1):
///   V (*) u <= x    <==>    u <= V \ x    (for ALL u in R^r, x in R^n)!
pub fn TropMatrix::residuate_vec(
  self : TropMatrix,
  x : Array[Double],
) -> Array[Double] {
  Array::makei(self.cols, k => {
    let mut worst = -TROP_NEG_INF
    for i in 0..<self.rows {
      let vik = self.get(i, k)
      if vik > TROP_NEG_INF * 0.5 {
        let diff = x[i] - vik
        if diff < worst {
          worst = diff
        }
      }
    }
    worst
  })
}

///|
/// COHEN-GAUBERT-QUADRAT SEMITROPICAL PROJECTIVE POLYTOPE PROJECTION (Theorem IX.1):
/// Projects ANY point [x] in TP^{n-1} onto the tropical convex hull V = tconv(v_1, ..., v_r)
/// via the Galois adjunction counit:
///   Pi_V([x]) = [ V (*) (V \ x) ] in V subset TP^{n-1}.
/// Guarantees simultaneously:
///   1. Scale invariance (well-defined on TP^{n-1}),
///   2. Strict idempotency Pi_V(Pi_V([x])) == Pi_V([x]) and Pi_V([v_k]) == [v_k],
///   3. 1-Lipschitz contractivity d_TH(Pi_V([x]), Pi_V([y])) <= d_TH([x], [y]),
///   4. Global nearest-point optimality: d_TH([x], Pi_V([x])) == min_{[w] in V} d_TH([x], [w])!
pub fn TropMatrix::project_onto_polytope(
  self : TropMatrix,
  p : TropProjPoint,
) -> TropProjPoint {
  let u_star = self.residuate_vec(p.coords)
  TropProjPoint::from_homogeneous(self.tmul_vec(u_star))
}

///|
/// Maslov hbar-smoothed Semitropical Projective Projection Pi^{(hbar)}_V([x]):
/// replaces max by (+)_hbar and min by (-)_hbar = -((+)_hbar(-.)), converging uniformly
/// to Pi_V([x]) as hbar -> 0+ with error O(hbar * ln(n * r))!
pub fn TropMatrix::maslov_project_onto_polytope(
  self : TropMatrix,
  p : TropProjPoint,
  hbar : Double,
) -> TropProjPoint {
  if hbar <= 1.0e-12 {
    return self.project_onto_polytope(p)
  }
  let u_soft = Array::makei(self.cols, k => {
    let neg_diffs = Array::makei(self.rows, i => self.get(i, k) - p.coords[i])
    -maslov_sum(neg_diffs, hbar)
  })
  let raw = Array::makei(self.rows, i => {
    let terms = Array::makei(self.cols, k => self.get(i, k) + u_soft[k])
    maslov_sum(terms, hbar)
  })
  TropProjPoint::from_homogeneous(raw)
}

///|
/// Tropical Kleene Star  A^* = I (+) A (+) A^{(*)2} (+) ... (+) A^{(*)(n-1)}
/// computed in O(n^3) via tropical Floyd-Warshall closure (converges iff all directed
/// cycles have tropical weight <= 0, i.e. lambda_trop(A) <= 0!).
pub fn TropMatrix::kleene_star(self : TropMatrix) -> TropMatrix {
  let n = self.rows
  let star = self.tadd(TropMatrix::identity(n))
  for k in 0..<n {
    for i in 0..<n {
      let ik = star.get(i, k)
      if ik > TROP_NEG_INF * 0.5 {
        for j in 0..<n {
          let kj = star.get(k, j)
          if kj > TROP_NEG_INF * 0.5 {
            let cand = ik + kj
            if cand > star.get(i, j) {
              star.data[i * n + j] = cand
            }
          }
        }
      }
    }
  }
  star
}

///|
/// KARP'S EXACT TROPICAL PERRON-FROBENIUS EIGENVALUE & PROJECTIVE EIGENVECTOR (Theorem IX.3):
/// For a finite square tropical matrix A in R^{n x n}:
///   1. Computes the EXACT unique tropical eigenvalue (maximum cycle mean):
///        lambda_trop(A) = max_{0 <= j < n} min_{0 <= k < n} (F_n(j) - F_k(j)) / (n - k),
///      where F_k(j) is the maximum k-step walk weight ending at j;
///   2. Normalizes B = A - lambda_trop(A), forms Kleene star B^*, finds a critical node i*
///      on a zero-weight cycle ((B^+)_{i*,i*} == 0), and extracts column v* = B^*_{:, i*}
///      satisfying the EXACT tropical projective fixed-point equation:
///        A (*) v* == lambda_trop(A) (*) v*    <==>    [A]([v*]) == [v*]  in TP^{n-1}!
pub fn TropMatrix::tropical_eigenpair(
  self : TropMatrix,
) -> (Double, TropProjPoint) {
  let n = self.rows
  // F[k][i] = max weight of a k-step path starting from any node arriving at i:
  // using A (*) x convention: F_{k+1}(i) = max_j (A_{ij} + F_k(j))
  let f_dp : Array[Array[Double]] = Array(capacity=n + 1)
  f_dp.push(Array::make(n, 0.0))
  for k in 0..<n {
    f_dp.push(self.tmul_vec(f_dp[k]))
  }
  let mut lambda = TROP_NEG_INF
  for i in 0..<n {
    if !is_trop_finite(f_dp[n][i]) {
      continue
    }
    let mut min_ratio = -TROP_NEG_INF
    for k in 0..<n {
      if is_trop_finite(f_dp[k][i]) {
        let ratio = (f_dp[n][i] - f_dp[k][i]) / (n - k).to_double()
        if ratio < min_ratio {
          min_ratio = ratio
        }
      }
    }
    if min_ratio < -TROP_NEG_INF * 0.5 && min_ratio > lambda {
      lambda = min_ratio
    }
  }
  if !is_trop_finite(lambda) {
    return (TROP_NEG_INF, TropProjPoint::from_homogeneous(Array::make(n, 0.0)))
  }
  // Normalized matrix B_{ij} = A_{ij} - lambda (preserving TROP_NEG_INF on missing arcs!)
  let b = TropMatrix::from_fn(n, n, (i, j) => {
    let v = self.get(i, j)
    if is_trop_finite(v) {
      v - lambda
    } else {
      TROP_NEG_INF
    }
  })
  let b_star = b.kleene_star()
  let b_plus = b.tmul(b_star)
  // Locate critical node i* maximizing (B^+)_{i*, i*} (equals 0.0 to machine precision!)
  let mut crit = 0
  let mut best_diag = b_plus.get(0, 0)
  for i in 1..<n {
    if b_plus.get(i, i) > best_diag {
      best_diag = b_plus.get(i, i)
      crit = i
    }
  }
  let eigvec_raw = Array::makei(n, i => b_star.get(i, crit))
  (lambda, TropProjPoint::from_homogeneous(eigvec_raw))
}

///|
/// Classical Perron-Frobenius spectral radius rho(exp(A / hbar)) dequantized as
/// lambda_hbar(A) = hbar * ln rho(exp(A / hbar)) via overflow-free Maslov log-semiring
/// repeated matrix squaring  X^{(p+1)} = X^{(p)} (*)_hbar X^{(p)}.
/// Reaches exponent T = 2^steps (~ 1.1e15 for steps=50) without oscillation on ANY
/// critical-cycle periodicity, giving 15-digit exactness for all hbar > 0!
/// By Theorem IX.3, satisfies the universal Maslov-Perron-Frobenius sandwich:
///   lambda_trop(A) <= lambda_hbar(A) <= lambda_trop(A) + hbar * ln(n)   forall hbar > 0!
pub fn TropMatrix::maslov_spectral_radius(
  self : TropMatrix,
  hbar : Double,
  iters~ : Int32 = 46,
) -> Double {
  if hbar <= 1.0e-14 {
    let (lam, _) = self.tropical_eigenpair()
    return lam
  }
  let n = self.rows
  // Maintain log(M^{2^p}) = (2^p) * shift_acc + cur, normalized so max(cur) == 0
  let mut cur = TropMatrix::from_fn(n, n, (i, j) => self.get(i, j))
  let mut shift_acc = 0.0
  let mut inv_pow = 1.0
  for _ in 0..<iters {
    let mut cmax = TROP_NEG_INF
    for v in cur.data {
      if v > cmax {
        cmax = v
      }
    }
    if cmax <= TROP_NEG_INF * 0.5 {
      return TROP_NEG_INF
    }
    shift_acc = shift_acc + cmax * inv_pow
    let normed = TropMatrix::from_fn(n, n, (i, j) => {
      let v = cur.get(i, j)
      if v <= TROP_NEG_INF * 0.5 {
        TROP_NEG_INF
      } else {
        v - cmax
      }
    })
    // Maslov log-semiring matrix square: (normed (*)_hbar normed)_{ij}
    cur = TropMatrix::from_fn(n, n, (i, j) => {
      let terms = Array::makei(n, k => {
        let a = normed.get(i, k)
        let b = normed.get(k, j)
        if a <= TROP_NEG_INF * 0.5 || b <= TROP_NEG_INF * 0.5 {
          TROP_NEG_INF
        } else {
          a + b
        }
      })
      maslov_sum(terms, hbar)
    })
    inv_pow = inv_pow * 0.5
  }
  let diag = Array::makei(n, i => cur.get(i, i))
  shift_acc + maslov_sum(diag, hbar) * inv_pow
}

///|
/// TROPICAL GRASSMANNIAN Trop Gr(2, N) subset TP^{C(N,2)-1} PLUCKER GHOST TEST (Theorem X.1):
/// For a symmetric distance matrix D (N x N), checks every 4-tuple (i < j < k < l) for the
/// Speyer-Sturmfels tropical Plucker condition:
///   P_{ijkl}(D) = (D_{ij} + D_{kl}) (+) (D_{ik} + D_{jl}) (+) (D_{il} + D_{jk}) in Ghost(ST),
/// i.e. the largest two of the three pairwise sums are EQUAL (S_(1) - S_(2) == 0)!
/// Returns (max_plucker_defect, all_in_ghost_ideal).
pub fn tropical_grassmannian_plucker_defect(
  dist : DenseMat,
  tie_tol~ : Double = 1.0e-9,
) -> (Double, Bool) {
  let n = dist.rows
  let mut max_def = 0.0
  let mut all_ghost = true
  for i in 0..<n {
    for j in (i + 1)..<n {
      for k in (j + 1)..<n {
        for l in (k + 1)..<n {
          let s1 = dist.get(i, j) + dist.get(k, l)
          let s2 = dist.get(i, k) + dist.get(j, l)
          let s3 = dist.get(i, l) + dist.get(j, k)
          // Evaluate in supertropical semiring ST!
          let st_p = SuperTropical::st_add(
            SuperTropical::st_add(Tangible(s1), Tangible(s2), tie_tol~),
            Tangible(s3),
            tie_tol~,
          )
          if !st_p.is_ghost() {
            all_ghost = false
          }
          // Sort descending to measure exact gap S_(1) - S_(2)
          let top1 = s1.max(s2).max(s3)
          let bot1 = s1.min(s2).min(s3)
          let mid = s1 + s2 + s3 - top1 - bot1
          let gap = top1 - mid
          if gap > max_def {
            max_def = gap
          }
        }
      }
    }
  }
  (max_def, all_ghost)
}

///|
/// SUBDOMINANT ULTRAMETRIC PROJECTION onto Trop Gr(2, N) subset TP^{C(N,2)-1}:
/// Computes the min-max Kleene closure U_{ij} = min_{paths i -> j} max_{e in path} D_e,
/// which is the UNIQUE GREATEST ultrametric U <= D (universal right adjoint to the
/// inclusion Ult_N -> Met_N!), landing strictly on the Tropical Grassmannian Trop Gr(2, N)
/// with ZERO tropical Plucker defect (every 4-tuple sits inside the Ghost Ideal G)!
pub fn project_to_tropical_grassmannian_ultrametric(
  dist : DenseMat,
) -> DenseMat {
  let n = dist.rows
  let u = dist.clone()
  for i in 0..<n {
    u.set(i, i, 0.0)
  }
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        let minimax_path = u.get(i, k).max(u.get(k, j))
        if minimax_path < u.get(i, j) {
          u.set(i, j, minimax_path)
        }
      }
    }
  }
  u
}

///|
/// Exact SHARP Gromov 4-point tropical Plucker supremum  2 * ln(2) / sqrt(c)
/// on the Poincare hyperbolic ball B_c^m (attained asymptotically by ideal squares!):
///   forall x_1, x_2, x_3, x_4 in B_c^m,  S_(1) - S_(2) < 2 * ln(2) / sqrt(c) -> 0 as c -> +inf,
/// proving that high-curvature Poincare agent embeddings asymptotically collapse onto
/// the Speyer-Sturmfels Tropical Grassmannian Trop Gr(2, N) subset TP^{C(N,2)-1}!
pub fn poincare_gromov_plucker_bound(c : Double) -> Double {
  2.0 * @math.ln(2.0) / c.sqrt()
}
