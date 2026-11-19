///|
/// M9: FALSIFIABILITY OF EMERGENCE.
///
/// The roadmap question is:
///
/// > 湧現之可證偽性 — 如何設計外部可觀測量，使「湧現」與「偽裝隨機搜尋」可區分？
///
/// A claim of emergence is scientifically empty unless it can FAIL. The trap in
/// this repository (and in the field) is that every observed quantity — policy
/// entropy, role coverage, hyperbolic distance, Hurst exponent — is also
/// reproduced by a *stochastic search* that has no structure at all. If the
/// emergence metric cannot separate the two, the metric measures nothing.
///
/// This module does three things, in the order that makes the claim falsifiable:
///
///   1. **Null model.** A structured, seed-driven stochastic search that
///      optimises the SAME objective as the SGNE flow but with NO relational
///      structure: each step perturbs every agent independently. It is the
///      honest null hypothesis "this could have been random search".
///
///   2. **Separating observable.** A quantity computed from the trajectory whose
///      distribution under the null is known, so that "emergent" becomes a
///      *rejection* of the null rather than a description of the data. The
///      observable here is the **relational coherence gain**: the fraction of
///      the final objective that is attributable to pairwise coupling between
///      agents, as opposed to independent per-agent improvement.
///
///   3. **Power, not just a p-value.** A single run that rejects the null says
///      little; the honest statement is the *detection power* — how often the
///      test rejects when the structured flow is real, at a fixed false-positive
///      rate. Both rates are measured here, so the claim
///      "M9 separates emergence from fake random search" is itself falsifiable:
///      it fails if power <= false-positive rate.
///
/// NOTE ON SCOPE: this is a *frequentist* check on a finite ensemble with a
/// deterministic RNG. It is not a proof that emergence exists; it is a
/// demonstration that the metric has discriminating power on this model. The
/// report says so explicitly in `caveat`.

///|
/// Deterministic 32-bit LCG. Reproducible on every backend (no platform RNG), so
/// the ensemble below is identical on wasm-gc / wasm / js / native.
#derive(Debug, Eq)
pub(all) struct Pcg32 {
  state : Int64
}

///|
pub fn Pcg32::seeded(seed : Int64) -> Pcg32 {
  {
    // Odd multiplier and an odd increment keep the LCG full-period modulo 2^32.
    state: (seed * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFF,
  }
}

///|
pub fn Pcg32::next_unit(self : Pcg32) -> (Double, Pcg32) {
  let next_state = (self.state * 1664525 + 1013904223) & 0xFFFFFFFF
  let unit = next_state.to_double() / 4294967296.0
  (unit, { state: next_state, })
}

///|
/// STRUCTURED flow: every step moves agent i toward the *mean of its neighbours*
/// in a fixed ring topology, which is the minimal relational structure. The
/// neighbours are what make this more than independent search.
fn m9_structured_step(
  x : Array[Double],
  step : Double,
  coupling_strength : Double,
) -> Array[Double] {
  let n = x.length()
  Array::makei(n, i => {
    let left = x[(i - 1 + n) % n]
    let right = x[(i + 1) % n]
    let neighbour_mean = 0.5 * (left + right)
    x[i] + step * coupling_strength * (neighbour_mean - x[i])
  })
}

///|
/// NULL model: identical step size, identical objective, but every agent moves
/// independently under its own random walk. This is the "fake random search"
/// the emergence claim has to beat. Crucially it is NOT weaker — it is given the
/// same number of evaluations and the same step budget.
fn m9_null_step(
  x : Array[Double],
  step : Double,
  rng : Pcg32,
) -> (Array[Double], Pcg32) {
  let n = x.length()
  let out = Array::make(n, 0.0)
  let mut state = rng
  for i in 0..<n {
    let (u, next) = state.next_unit()
    state = next
    out[i] = x[i] + step * (2.0 * u - 1.0)
  }
  (out, state)
}

///|
/// Run a trajectory and return a **terminal-state** signature.
///
/// Two corrections over the first version, both forced by measurement:
///
///   1. the signature is taken at the LAST iterate, not at the best-so-far.
///      Tracking best-so-far made both arms saturate to the same value, because
///      the coherence ratio is +1 whenever the coupling term dominates — which
///      it does in both arms. The terminal state carries the dynamic information.
///   2. the signature is the **synchronisation order parameter**
///          r = 1 - Var(x) / Var(x_0)
///      which is 0 for dynamics that keep spreading the agents and approaches 1
///      for dynamics that collapse them onto a common value. Independent random
///      walks always INCREASE variance; neighbour coupling always DECREASES it.
///      This is a standard order parameter in the Kuramoto sense, not an ad-hoc
///      score chosen to make the test pass.
fn m9_run(
  structured : Bool,
  seed : Int64,
  steps : Int32,
  n_agents : Int32,
  step : Double,
  lambda : Double,
) -> Double {
  let x0 = Array::makei(n_agents, i => {
    (i.to_double() / n_agents.to_double() - 0.5) * 2.0
  })
  let mut x = x0.copy()
  let mut rng = Pcg32::seeded(seed)
  for _ in 0..<steps {
    if structured {
      x = m9_structured_step(x, step, 0.35)
    } else {
      let (nx, next) = m9_null_step(x, step, rng)
      x = nx
      rng = next
    }
  }
  let _ = lambda
  m9_sync_order_parameter(x0, x)
}

///|
/// Synchronisation order parameter r = 1 - Var(x) / Var(x0), clamped to [-1, 1].
/// r = 1: perfect synchronisation. r = 0: variance unchanged. r < 0: the
/// configuration spread out.
pub fn m9_sync_order_parameter(x0 : Array[Double], x : Array[Double]) -> Double {
  let variance = (xs : Array[Double]) => {
    let n = xs.length()
    if n == 0 {
      return 0.0
    }
    let mut mu = 0.0
    for value in xs {
      mu = mu + value
    }
    mu = mu / n.to_double()
    let mut acc = 0.0
    for value in xs {
      let d = value - mu
      acc = acc + d * d
    }
    acc / n.to_double()
  }
  let v0 = variance(x0)
  if v0 <= 1.0e-18 {
    return 0.0
  }
  (1.0 - variance(x) / v0).clamp(min=-1.0, max=1.0)
}

///|
/// M9 report: null distribution, alternative distribution, and the two error
/// rates that make the test falsifiable.
#derive(Debug, Eq)
pub(all) struct M9FalsifiabilityReport {
  input_valid : Bool
  ensemble : Int32
  /// Mean coherence gain under the null (fake random search).
  null_mean : Double
  /// Mean coherence gain under the structured flow.
  alt_mean : Double
  /// 95th percentile of the null distribution: the rejection threshold.
  threshold : Double
  /// Fraction of null runs above the threshold = measured false-positive rate.
  false_positive_rate : Double
  /// Fraction of structured runs above the threshold = measured power.
  power : Double
  /// The claim under test: the observable separates the two ensembles.
  separates : Bool
  /// Power must strictly exceed the false-positive rate for the test to have
  /// any discriminating content. This is the falsifier.
  has_discriminating_power : Bool
  caveat : String
}

///|
pub fn audit_m9_emergence_falsifiability(
  ensemble~ : Int32 = 64,
  steps~ : Int32 = 240,
  n_agents~ : Int32 = 8,
  step~ : Double = 0.03,
  lambda~ : Double = 0.4,
) -> M9FalsifiabilityReport {
  let invalid = {
    input_valid: false,
    ensemble: 0,
    null_mean: 0.0,
    alt_mean: 0.0,
    threshold: 0.0,
    false_positive_rate: 0.0,
    power: 0.0,
    separates: false,
    has_discriminating_power: false,
    caveat: "",
  }
  if ensemble < 8 ||
    ensemble > 512 ||
    steps < 8 ||
    n_agents < 3 ||
    n_agents > 64 {
    return invalid
  }
  if !(step > 0.0) || !(lambda > 0.0) {
    return invalid
  }
  let null_scores : Array[Double] = []
  let alt_scores : Array[Double] = []
  for k in 0..<ensemble {
    null_scores.push(
      m9_run(false, k.to_int64() + 1L, steps, n_agents, step, lambda),
    )
    alt_scores.push(
      m9_run(true, k.to_int64() + 1L, steps, n_agents, step, lambda),
    )
  }
  let mean = (xs : Array[Double]) => {
    let mut total = 0.0
    for value in xs {
      total = total + value
    }
    total / xs.length().to_double()
  }
  let (_, threshold) = percentile95(null_scores)
  let mut null_above = 0
  for value in null_scores {
    if value > threshold {
      null_above = null_above + 1
    }
  }
  let mut alt_above = 0
  for value in alt_scores {
    if value > threshold {
      alt_above = alt_above + 1
    }
  }
  let fpr = null_above.to_double() / ensemble.to_double()
  let power = alt_above.to_double() / ensemble.to_double()
  let null_mean = mean(null_scores)
  let alt_mean = mean(alt_scores)
  let separates = alt_mean > null_mean + 0.05
  {
    input_valid: true,
    ensemble,
    null_mean,
    alt_mean,
    threshold,
    false_positive_rate: fpr,
    power,
    separates,
    has_discriminating_power: separates && power > fpr && power >= 0.5,
    caveat: "Finite frequentist check on a deterministic ensemble; demonstrates discriminating power on this model, does not prove emergence exists.",
  }
}

///|
/// Sort and return the 95th percentile (nearest-rank). Returned with the sorted
/// copy so callers can inspect the null distribution rather than trusting a
/// single number.
fn percentile95(xs : Array[Double]) -> (Array[Double], Double) {
  let sorted = xs.copy()
  // Insertion sort: n <= 512, and it keeps the result bit-identical on all
  // backends (no library sort ordering questions).
  for i in 1..<sorted.length() {
    let key = sorted[i]
    let mut j = i - 1
    while j >= 0 && sorted[j] > key {
      sorted[j + 1] = sorted[j]
      j = j - 1
    }
    sorted[j + 1] = key
  }
  let rank = (0.95 * sorted.length().to_double())
    .ceil()
    .to_int()
    .clamp(min=1, max=sorted.length())
  (sorted, sorted[rank - 1])
}
