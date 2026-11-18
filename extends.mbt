///|
/// Explicit MoonBit v0.10.21 trait-to-method promotion declarations (`pub extend`).

///|
pub extend AffineConnection with @debug.Debug::{to_repr}

///|
pub extend AffineConnection with Eq::{not_equal, equal}

///|
pub extend AffinePoint with @debug.Debug::{to_repr}

///|
pub extend AffinePoint with Eq::{not_equal, equal}

///|
pub extend Complex with @debug.Debug::{to_repr}

///|
pub extend Complex with Add::{add}

///|
pub extend Complex with Eq::{not_equal, equal}

///|
pub extend Complex with Mul::{mul}

///|
pub extend Complex with Neg::{neg}

///|
pub extend Complex with Sub::{sub}

///|
pub extend DenseMat with @debug.Debug::{to_repr}

///|
pub extend DenseMat with Add::{add}

///|
pub extend DenseMat with Eq::{not_equal, equal}

///|
pub extend DenseMat with Mul::{mul}

///|
pub extend DenseMat with Neg::{neg}

///|
pub extend DenseMat with Sub::{sub}

///|
pub extend EmergenceSnapshot with @debug.Debug::{to_repr}

///|
pub extend EmergenceSnapshot with Eq::{not_equal, equal}

///|
pub extend GradedTensor with @debug.Debug::{to_repr}

///|
pub extend GradedTensor with Eq::{not_equal, equal}

///|
pub extend Grassmann with @debug.Debug::{to_repr}

///|
pub extend Grassmann with AbelianGroup::{
  sub_elem,
  neg_elem,
  add_elem,
  zero_elem,
}

///|
pub extend Grassmann with Add::{add}

///|
pub extend Grassmann with Div::{div}

///|
pub extend Grassmann with Eq::{not_equal, equal}

///|
pub extend Grassmann with Module::{scale}

///|
pub extend Grassmann with Mul::{mul}

///|
pub extend Grassmann with Neg::{neg}

///|
pub extend Grassmann with Ring::{mul_elem, one_elem}

///|
pub extend Grassmann with Sub::{sub}

///|
pub extend NeuroSymState with @debug.Debug::{to_repr}

///|
pub extend NeuroSymState with Eq::{not_equal, equal}

///|
pub extend Parity with @debug.Debug::{to_repr}

///|
pub extend Parity with Eq::{not_equal, equal}

///|
pub extend Parity with Hash::{hash, hash_combine}

///|
pub extend PoPEConfig with @debug.Debug::{to_repr}

///|
pub extend PoPEConfig with Eq::{not_equal, equal}

///|
pub extend PoincarePoint with @debug.Debug::{to_repr}

///|
pub extend PoincarePoint with Eq::{not_equal, equal}

///|
pub extend ProtoAgent with @debug.Debug::{to_repr}

///|
pub extend ProtoAgent with Eq::{not_equal, equal}

///|
pub extend SlotVariance with @debug.Debug::{to_repr}

///|
pub extend SlotVariance with Eq::{not_equal, equal}

///|
pub extend SlotVariance with Hash::{hash, hash_combine}

///|
pub extend SpectralTriple with @debug.Debug::{to_repr}

///|
pub extend SpectralTriple with Eq::{not_equal, equal}

///|
pub extend Substitution with @debug.Debug::{to_repr}

///|
pub extend Substitution with Eq::{not_equal, equal}

///|
pub extend SuperBeltramiPDE with @debug.Debug::{to_repr}

///|
pub extend SuperBeltramiPDE with Eq::{not_equal, equal}

///|
pub extend SuperManifold with @debug.Debug::{to_repr}

///|
pub extend SuperManifold with Eq::{not_equal, equal}

///|
pub extend SuperMassTensor with @debug.Debug::{to_repr}

///|
pub extend SuperMassTensor with Eq::{not_equal, equal}

///|
pub extend SuperMatrix with @debug.Debug::{to_repr}

///|
pub extend SuperMatrix with AbelianGroup::{
  sub_elem,
  neg_elem,
  norm_sq,
  add_elem,
  zero_elem,
}

///|
pub extend SuperMatrix with Add::{add}

///|
pub extend SuperMatrix with Eq::{not_equal, equal}

///|
pub extend SuperMatrix with LieSuperAlgebra::{eval_bilinear, parity_of}

///|
pub extend SuperMatrix with Module::{scale}

///|
pub extend SuperMatrix with Mul::{mul}

///|
pub extend SuperMatrix with Neg::{neg}

///|
pub extend SuperMatrix with Sub::{sub}

///|
pub extend SuperPoint with @debug.Debug::{to_repr}

///|
pub extend SuperPoint with Eq::{not_equal, equal}

///|
pub extend SymTerm with @debug.Debug::{to_repr}

///|
pub extend SymTerm with Eq::{not_equal, equal}

///|
pub extend SymTerm with Hash::{hash, hash_combine}

///|
pub extend TheoremReport with @debug.Debug::{to_repr}

///|
pub extend TheoremReport with Eq::{not_equal, equal}

///|
pub extend UnifyResult with @debug.Debug::{to_repr}

///|
pub extend UnifyResult with Eq::{not_equal, equal}

///|
pub extend WittenSUSYSystem with @debug.Debug::{to_repr}

///|
pub extend WittenSUSYSystem with Eq::{not_equal, equal}

///|
pub extend FinitePushout with @debug.Debug::{to_repr}

///|
pub extend FinitePushout with Eq::{not_equal, equal}

///|
pub extend FreeVec with @debug.Debug::{to_repr}

///|
pub extend FreeVec with Eq::{not_equal, equal}

///|
pub extend FreeVec with UniversalFreeObject::{lift_linear, unit_gen}

///|
pub extend SuperTropical with @debug.Debug::{to_repr}

///|
pub extend SuperTropical with Eq::{not_equal, equal}

///|
pub extend TropMatrix with @debug.Debug::{to_repr}

///|
pub extend TropMatrix with Eq::{not_equal, equal}

///|
pub extend TropProjPoint with @debug.Debug::{to_repr}

///|
pub extend TropProjPoint with Eq::{not_equal, equal}

///|
pub extend Tropical with @debug.Debug::{to_repr}

///|
pub extend Tropical with Eq::{not_equal, equal}

///|
pub extend Tropical with IdempotentSemiring::{tzero, tone, tmul, tadd}

///|
pub extend TropicalKanMacroAgent with @debug.Debug::{to_repr}

///|
pub extend TropicalKanMacroAgent with Eq::{not_equal, equal}

///|
pub extend Complex with Div::{div}

///|
pub extend CompleteIntersectionReport with @debug.Debug::{to_repr}

///|
pub extend CompleteIntersectionReport with Eq::{not_equal, equal}

///|
pub extend CurveNormalization with @debug.Debug::{to_repr}

///|
pub extend CurveNormalization with Eq::{not_equal, equal}

///|
pub extend GermEquivClass with @debug.Debug::{to_repr}

///|
pub extend GermEquivClass with Eq::{not_equal, equal}

///|
pub extend GermMicrolocalReport with @debug.Debug::{to_repr}

///|
pub extend GermMicrolocalReport with Eq::{not_equal, equal}

///|
pub extend HalfPlaneGerm with @debug.Debug::{to_repr}

///|
pub extend HalfPlaneGerm with Eq::{not_equal, equal}

///|
pub extend HyperfunctionGerm with @debug.Debug::{to_repr}

///|
pub extend HyperfunctionGerm with Eq::{not_equal, equal}

///|
pub extend JetBasis with @debug.Debug::{to_repr}

///|
pub extend JetBasis with Eq::{not_equal, equal}

///|
pub extend MapGerm with @debug.Debug::{to_repr}

///|
pub extend MapGerm with Eq::{not_equal, equal}

///|
pub extend MeromorphicGerm with @debug.Debug::{to_repr}

///|
pub extend MeromorphicGerm with Eq::{not_equal, equal}

///|
pub extend MicroDiffOp with @debug.Debug::{to_repr}

///|
pub extend MicroDiffOp with Eq::{not_equal, equal}

///|
pub extend MicrofunctionGerm with @debug.Debug::{to_repr}

///|
pub extend MicrofunctionGerm with Eq::{not_equal, equal}

///|
pub extend MultiMeroGerm with @debug.Debug::{to_repr}

///|
pub extend MultiMeroGerm with Eq::{not_equal, equal}

///|
pub extend PolyGerm with @debug.Debug::{to_repr}

///|
pub extend PolyGerm with Eq::{not_equal, equal}

///|
pub extend SerreNormalityReport with @debug.Debug::{to_repr}

///|
pub extend SerreNormalityReport with Eq::{not_equal, equal}

///|
pub extend SuperLieTable with @debug.Debug::{to_repr}

///|
pub extend SuperLieTable with Eq::{not_equal, equal}

///|
pub extend UEAElement with @debug.Debug::{to_repr}

///|
pub extend UEAElement with Eq::{not_equal, equal}

///|
pub extend UniversalUnfolding with @debug.Debug::{to_repr}

///|
pub extend UniversalUnfolding with Eq::{not_equal, equal}

///|
/// NOTE: `Complex::norm_sq` and `Complex::scale` already exist as inherent methods in
/// `algebra.mbt`, so only the non-conflicting trait methods are promoted here; the trait
/// implementations themselves (`impl AbelianGroup for Complex`, `impl Module for Complex`)
/// remain fully available through `AbelianGroup::norm_sq` / `Module::scale`.
pub extend Complex with AbelianGroup::{sub_elem, neg_elem, add_elem, zero_elem}

///|
pub extend Complex with Ring::{mul_elem, one_elem}

///|
pub extend Quat with @debug.Debug::{to_repr}

///|
pub extend Quat with Add::{add}

///|
pub extend Quat with Div::{div}

///|
pub extend Quat with Eq::{not_equal, equal}

///|
pub extend Quat with Mul::{mul}

///|
pub extend Quat with Neg::{neg}

///|
pub extend Quat with Sub::{sub}

///|
pub extend Quat with AbelianGroup::{
  sub_elem,
  neg_elem,
  add_elem,
  zero_elem,
  norm_sq,
}

///|
pub extend Quat with Module::{scale}

///|
pub extend Quat with Ring::{mul_elem, one_elem}

///|
pub extend Gates with @debug.Debug::{to_repr}

///|
pub extend Gates with Eq::{not_equal, equal}

///|
pub extend MemoryCell with @debug.Debug::{to_repr}

///|
pub extend MemoryCell with Eq::{not_equal, equal}

///|
pub extend Phase with @debug.Debug::{to_repr}

///|
pub extend Phase with Eq::{not_equal, equal}

///|
pub extend Phase with Hash::{hash, hash_combine}

///|
pub extend Layer with @debug.Debug::{to_repr}

///|
pub extend Layer with Eq::{not_equal, equal}

///|
pub extend SynergeticNet with @debug.Debug::{to_repr}

///|
pub extend SynergeticNet with Eq::{not_equal, equal}

///|
pub extend NeuralH with @debug.Debug::{to_repr}

///|
pub extend NeuralH with Eq::{not_equal, equal}

///|
pub extend Obj with @debug.Debug::{to_repr}

///|
pub extend Obj with Eq::{not_equal, equal}

///|
pub extend Hom with @debug.Debug::{to_repr}

///|
pub extend Hom with Eq::{not_equal, equal}

///|
pub extend Cone with @debug.Debug::{to_repr}

///|
pub extend Cone with Eq::{not_equal, equal}

///|
pub extend FinitePullback with @debug.Debug::{to_repr}

///|
pub extend FinitePullback with Eq::{not_equal, equal}

///|
pub extend Hermitian2 with @debug.Debug::{to_repr}

///|
pub extend Hermitian2 with Eq::{not_equal, equal}

///|
pub extend NonCommGraph with @debug.Debug::{to_repr}

///|
pub extend NonCommGraph with Eq::{not_equal, equal}

///|
pub extend FourVal with @debug.Debug::{to_repr}

///|
pub extend FourVal with Eq::{not_equal, equal}

///|
pub extend FourVal with Hash::{hash, hash_combine}

///|
pub extend ParaUniverse with @debug.Debug::{to_repr}

///|
pub extend ParaUniverse with Eq::{not_equal, equal}

///|
pub extend MultiWorld with @debug.Debug::{to_repr}

///|
pub extend MultiWorld with Eq::{not_equal, equal}

///|
pub extend SuperHamiltonian with @debug.Debug::{to_repr}

///|
pub extend SuperHamiltonian with Eq::{not_equal, equal}

///|
pub extend BarrierEscapeReport with @debug.Debug::{to_repr}

///|
pub extend BarrierEscapeReport with Eq::{not_equal, equal}

///|
pub extend ParaUnifyReport with @debug.Debug::{to_repr}

///|
pub extend ParaUnifyReport with Eq::{not_equal, equal}

///|
pub extend SuperOperatorBundle with @debug.Debug::{to_repr}

///|
pub extend SuperOperatorBundle with Eq::{not_equal, equal}

///|
pub extend QuatSpectralTriple with @debug.Debug::{to_repr}

///|
pub extend QuatSpectralTriple with Eq::{not_equal, equal}

///|
pub extend RoleMemoryProfile with @debug.Debug::{to_repr}

///|
pub extend RoleMemoryProfile with Eq::{not_equal, equal}

///|
pub extend SynMemParaReport with @debug.Debug::{to_repr}

///|
pub extend SynMemParaReport with Eq::{not_equal, equal}
