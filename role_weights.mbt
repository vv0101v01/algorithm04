///|
/// Normalize a fixed four-role probability vector without overflowing its sum.
/// Reject ratios that underflow to zero so the returned simplex point stays strict-positive.
fn normalize_four_role_weights(
  weights : Array[Double],
) -> Result[Array[Double], String] {
  if weights.length() != 4 {
    return Err("role-weight vector must have four entries")
  }
  let mut scale = 0.0
  for weight in weights {
    if !weight.is_finite() || weight <= 0.0 {
      return Err("role weights must be finite and strictly positive")
    }
    scale = scale.max(weight)
  }
  let scaled = weights.map(weight => weight / scale)
  let mut scaled_total = 0.0
  for weight in scaled {
    scaled_total = scaled_total + weight
  }
  // One scaled entry equals one and all others are in (0, 1], so the finite
  // four-term sum is guaranteed to lie in (1, 4].
  let normalized = scaled.map(weight => weight / scaled_total)
  for weight in normalized {
    if !weight.is_finite() || weight <= 0.0 {
      return Err("normalized role weights must remain representably positive")
    }
  }
  Ok(normalized)
}
