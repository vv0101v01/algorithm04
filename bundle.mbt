///|
/// Module 21 (Unified from `algo8`): Emergence Operator Bundle, Čech Transition Cocycle,
/// Global Section Gluing & Gauge-Invariant Spectral Gap (湧現算子叢與截面拼接).
/// Deduplicated & hardened via `DenseMat` and `classical_commutator` (zero-det safe, NaN-safe),
/// and lifted to Grassmann SuperMatrix bundles in `unified_bridges.mbt`!

///|
fn mat2_from_flat(x : Array[Double]) -> DenseMat {
  { rows: 2, cols: 2, data: x.copy(), }
}

///|
fn conjugate_dense(a : DenseMat, g : DenseMat) -> DenseMat {
  g * a * g.inv()
}

///|
/// Verify the Čech 1-cocycle transition condition g_{ab} * g_{bc} == g_{ac} on triple overlaps
/// (NaN-safe Frobenius/max-entry comparison).
pub fn cocycle_condition(
  gab : Array[Double],
  gbc : Array[Double],
  gac : Array[Double],
  eps : Double,
) -> Bool {
  let diff = mat2_from_flat(gab) * mat2_from_flat(gbc) - mat2_from_flat(gac)
  for d in diff.data {
    if !(d.abs() <= eps) {
      return false
    }
  }
  true
}

///|
/// Verify local operator section compatibility s_b == g_{ab} s_a g_{ab}^{-1} across overlap U_a cap U_b.
pub fn patch_sections(
  sa : Array[Double],
  sb : Array[Double],
  gab : Array[Double],
  eps : Double,
) -> Bool {
  let g = mat2_from_flat(gab)
  if g.det().abs() <= 1.0e-15 {
    return false
  }
  let diff = conjugate_dense(mat2_from_flat(sa), g) - mat2_from_flat(sb)
  for d in diff.data {
    if !(d.abs() <= eps) {
      return false
    }
  }
  true
}

///|
/// Verify gauge invariance of commutator trace tr([g A g^{-1}, g B g^{-1}]) == tr([A, B])
/// across local bundle frame transformations.
pub fn emergent_commutator_trace(
  a : Array[Double],
  b : Array[Double],
  g : Array[Double],
  eps : Double,
) -> Bool {
  let ma = mat2_from_flat(a)
  let mb = mat2_from_flat(b)
  let mg = mat2_from_flat(g)
  if mg.det().abs() <= 1.0e-15 {
    return false
  }
  let c0 = classical_commutator(ma, mb).trace()
  let c1 = classical_commutator(
    conjugate_dense(ma, mg),
    conjugate_dense(mb, mg),
  ).trace()
  approx(c0, c1, eps)
}

///|
/// Certify existence & uniqueness of a global operator bundle section glued from `local_ops`
/// relative to reference patch `base_idx` under gauge transitions `transitions[k]`.
pub fn build_global_section(
  local_ops : Array[Array[Double]],
  transitions : Array[Array[Double]],
  base_idx : Int32,
  eps : Double,
) -> Bool {
  for i in 0..<local_ops.length() {
    if i != base_idx &&
      !patch_sections(local_ops[base_idx], local_ops[i], transitions[i], eps) {
      return false
    }
  }
  true
}

///|
/// Gauge-invariant emergent spectral gap |lambda_1 - lambda_2| of a glued 2x2 global section
/// (invariant under s |-> g s g^{-1} because both tr(s) and det(s) are similarity invariants).
pub fn emergent_spectral_gap(global_op : Array[Double]) -> Double {
  let m = mat2_from_flat(global_op)
  let tr = m.trace()
  let det = m.det()
  2.0 * (0.25 * tr * tr - det).max(0.0).sqrt()
}
