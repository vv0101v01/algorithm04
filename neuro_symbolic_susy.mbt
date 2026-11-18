///|
/// Module 7: Neuro-Symbolic Algebraic Unification Operator & Supersymmetry
/// Transformation (符號-神經混合之代數合一算子與超對稱變換).
/// Implements:
///   1. First-order symbolic term algebra `SymTerm` with idempotent Substitution
///      monoid, strict occurs-check, and graded Martelli-Montanari-Poincare-Grassmann
///      unification operator U_tau (bridging exact syntactic MGU, hyperbolic semantic
///      soft unification on B_c^m, and Pauli-Grassmann logical contradiction rejection),
///   2. N = 2 Witten-Hodge Supersymmetry on twisted simplicial neuro-symbolic cochain
///      complexes (Q, Q^dagger, H = (1/2){Q, Q^dagger}, gamma = (-1)^F), verifying
///      Q^2 = 0, [H, Q] = 0, boson-fermion spectral pairing, topological invariance
///      of the Witten index Delta_W = str(exp(-beta H)) = chi(K), BPS ground state
///      harmonic projection, and finite orthogonal SUSY transformations U(eps) = exp(eps(Q - Q^dagger)).

///|
/// First-order symbolic term grammar T(Sigma, V).
#derive(Debug, Eq, Hash)
pub(all) enum SymTerm {
  Var(String)
  Const(String)
  App(String, Array[SymTerm])
}

///|
/// Render a symbolic term in standard first-order logic notation.
pub fn SymTerm::format_term(self : SymTerm) -> String {
  match self {
    Var(v) => "?\{v}"
    Const(c) => c
    App(f, args) => {
      let buf = StringBuilder()
      buf.write_string(f)
      buf.write_string("(")
      for i in 0..<args.length() {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(args[i].format_term())
      }
      buf.write_string(")")
      buf.to_string()
    }
  }
}

///|
/// Occurs-check predicate: true iff variable `v` appears strictly inside `term`.
pub fn occurs_in(v : String, term : SymTerm) -> Bool {
  match term {
    Var(w) => v == w
    Const(_) => false
    App(_, args) => {
      for a in args {
        if occurs_in(v, a) {
          return true
        }
      }
      false
    }
  }
}

///|
/// Algebraic substitution sigma : V -> T(Sigma, V) forming a substitution monoid.
#derive(Debug, Eq)
pub(all) struct Substitution {
  bindings : Array[(String, SymTerm)]
}

///|
pub fn Substitution::empty() -> Substitution {
  { bindings: [], }
}

///|
pub fn Substitution::lookup(self : Substitution, v : String) -> SymTerm? {
  for pair in self.bindings {
    if pair.0 == v {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Simultaneous Free-Term-Monad substitution sigma^#(t):
/// applies bindings once per leaf variable (avoiding infinite recursion on cyclic
/// variable swaps {X <-> Y} or non-idempotent endomorphisms {X |-> f(X)}, while
/// strictly satisfying the Kleisli law (s2 o s1)^#(t) == s2^#(s1^#(t))).
pub fn Substitution::apply(self : Substitution, term : SymTerm) -> SymTerm {
  match term {
    Var(v) =>
      match self.lookup(v) {
        Some(bound) => bound
        None => Var(v)
      }
    Const(c) => Const(c)
    App(f, args) => App(f, args.map(a => self.apply(a)))
  }
}

///|
/// Extend substitution with a solved binding v |-> t, normalizing existing bindings
/// so sigma stays strictly idempotent (sigma . sigma == sigma).
pub fn Substitution::extend_idempotent(
  self : Substitution,
  v : String,
  t : SymTerm,
) -> Substitution {
  let single : Substitution = { bindings: [(v, t)], }
  let updated : Array[(String, SymTerm)] = Array(
    capacity=self.bindings.length() + 1,
  )
  for pair in self.bindings {
    updated.push((pair.0, single.apply(pair.1)))
  }
  updated.push((v, t))
  { bindings: updated, }
}

///|
/// Neuro-Symbolic Superstate Phi = (term, emb in B_c^m, logic in Lambda_N).
#derive(Debug, Eq)
pub(all) struct NeuroSymState {
  term : SymTerm
  emb : PoincarePoint
  logic : Grassmann
}

///|
/// Outcome of graded neuro-symbolic unification U_tau(Phi_1, Phi_2).
#derive(Debug, Eq)
pub(all) enum UnifyResult {
  Unified(Substitution, SymTerm, PoincarePoint, Grassmann, Double, Double)
  Contradiction(String)
}

///|
/// Shared hyperbolic semantic symbol lifting for mismatched constant/functor symbols:
/// computes geodesic coherence and lifts the deeper symbol to its closer-to-origin hypernym.
fn unify_symbol_pair(
  a : String,
  b : String,
  sym_embed : (String) -> PoincarePoint,
  tau : Double,
  min_coherence : Double,
  coherence : Double,
  anomaly : Double,
  kind : String,
) -> Result[(Double, Double, (String, String)), String] {
  if tau <= 1.0e-12 {
    return Err("Strict \{kind} clash: \{a} != \{b}")
  }
  let ea = sym_embed(a)
  let eb = sym_embed(b)
  let d = ea.geodesic_dist(eb)
  let next_coh = coherence * @math.exp(-d / tau)
  if next_coh < min_coherence {
    return Err("Hyperbolic \{kind} incompatibility: \{a} vs \{b}")
  }
  let hyper = if vec_norm_sq(ea.coords) <= vec_norm_sq(eb.coords) {
    (b, a)
  } else {
    (a, b)
  }
  Ok((next_coh, anomaly + d, hyper))
}

///|
/// Recursive graded term unifier combining Robinson-Martelli-Montanari MGU
/// with Poincare hyperbolic ontology lifting on mismatched symbols.
fn unify_terms_graded(
  t1 : SymTerm,
  t2 : SymTerm,
  subst : Substitution,
  sym_embed : (String) -> PoincarePoint,
  tau : Double,
  min_coherence : Double,
  coherence : Double,
  anomaly : Double,
) -> Result[(Substitution, Double, Double, Array[(String, String)]), String] {
  let s1 = subst.apply(t1)
  let s2 = subst.apply(t2)
  if s1 == s2 {
    return Ok((subst, coherence, anomaly, []))
  }
  match (s1, s2) {
    (Var(v), other) | (other, Var(v)) =>
      if occurs_in(v, other) {
        Err("Occurs-check failure: ?\{v} in \{other.format_term()}")
      } else {
        Ok((subst.extend_idempotent(v, other), coherence, anomaly, []))
      }
    (Const(a), Const(b)) =>
      match
        unify_symbol_pair(
          a, b, sym_embed, tau, min_coherence, coherence, anomaly, "symbol",
        ) {
        Ok((nc, na, hyper)) => Ok((subst, nc, na, [hyper]))
        Err(msg) => Err(msg)
      }
    (App(f, args1), App(g, args2)) => {
      if args1.length() != args2.length() {
        return Err(
          "Arity mismatch: \{f}/\{args1.length()} vs \{g}/\{args2.length()}",
        )
      }
      let mut cur_coh = coherence
      let mut cur_anom = anomaly
      let aliases : Array[(String, String)] = []
      if f != g {
        match
          unify_symbol_pair(
            f, g, sym_embed, tau, min_coherence, cur_coh, cur_anom, "functor",
          ) {
          Ok((nc, na, hyper)) => {
            cur_coh = nc
            cur_anom = na
            aliases.push(hyper)
          }
          Err(msg) => return Err(msg)
        }
      }
      let mut cur_sub = subst
      for i in 0..<args1.length() {
        match
          unify_terms_graded(
            args1[i],
            args2[i],
            cur_sub,
            sym_embed,
            tau,
            min_coherence,
            cur_coh,
            cur_anom,
          ) {
          Err(msg) => return Err(msg)
          Ok((ns, nc, na, sub_aliases)) => {
            cur_sub = ns
            cur_coh = nc
            cur_anom = na
            for al in sub_aliases {
              aliases.push(al)
            }
          }
        }
      }
      Ok((cur_sub, cur_coh, cur_anom, aliases))
    }
    _ => Err("Structural clash: \{s1.format_term()} vs \{s2.format_term()}")
  }
}

///|
fn rewrite_aliases(
  term : SymTerm,
  aliases : Array[(String, String)],
) -> SymTerm {
  let map_name = (name : String) => {
    for pair in aliases {
      if pair.0 == name {
        return pair.1
      }
    }
    name
  }
  match term {
    Var(v) => Var(v)
    Const(c) => Const(map_name(c))
    App(f, args) => App(map_name(f), args.map(a => rewrite_aliases(a, aliases)))
  }
}

///|
/// Graded Neuro-Symbolic Algebraic Unification Operator U_tau(Phi_1, Phi_2):
///   1. Enforces Pauli-Grassmann exclusion: rejects if psi_1 ^ psi_2 == 0 for non-zero
///      logical constraints (eliminating logically contradictory agent rule merges),
///   2. Computes exact MGU (for tau -> 0) or hyperbolic-weighted soft MGU (for tau > 0)
///      with automatic hypernym lifting toward the Poincare origin,
///   3. Fuses continuous embeddings along the exact Poincare geodesic midpoint
///      x_12 = exp_{x_1}^c(0.5 * log_{x_1}^c(x_2)), guaranteeing bounded anomaly
///      d_c(x_12, x_i) == 0.5 * d_c(x_1, x_2) (Theorem VIb).
pub fn unify_neuro_symbolic(
  s1 : NeuroSymState,
  s2 : NeuroSymState,
  sym_embed : (String) -> PoincarePoint,
  tau~ : Double = 0.8,
  min_coherence~ : Double = 0.35,
) -> UnifyResult {
  // 1. Grassmann exterior logical consistency check
  let merged_logic = s1.logic * s2.logic
  if s1.logic.l2_norm() > 1.0e-12 &&
    s2.logic.l2_norm() > 1.0e-12 &&
    merged_logic.l2_norm() < 1.0e-12 {
    return Contradiction(
      "Pauli-Grassmann logical exclusion (psi_1 ^ psi_2 = 0)",
    )
  }
  // 2. Graded symbolic-hyperbolic term unification
  match
    unify_terms_graded(
      s1.term,
      s2.term,
      Substitution::empty(),
      sym_embed,
      tau,
      min_coherence,
      1.0,
      0.0,
    ) {
    Err(reason) => Contradiction(reason)
    Ok((subst, coh, anom, aliases)) => {
      let unified_term = rewrite_aliases(subst.apply(s1.term), aliases)
      // 3. Poincare geodesic midpoint fusion weighted equally (or by coherence)
      let fused_emb = s1.emb.geodesic_interp(s2.emb, 0.5)
      Unified(subst, unified_term, fused_emb, merged_logic, coh, anom)
    }
  }
}

///|
/// N = 2 Witten-Hodge Supersymmetric Neuro-Symbolic System on a twisted finite
/// 2-dimensional simplicial complex K = (V, E, F) with Hilbert superspace
///   H = H_bos (+) H_ferm = (C^0(K) (+) C^2(K)) (+) C^1(K).
/// Supercharge Q = d_W lifts neural states C^0 -> symbolic rules C^1 -> higher axioms C^2;
/// adjoint supercharge Q^dagger = d_W^* projects symbolic constraints back to neural states;
/// Hamiltonian H = (1/2) {Q, Q^dagger} measures total neuro-symbolic frustration energy!
#derive(Debug, Eq)
pub(all) struct WittenSUSYSystem {
  n_v : Int32
  n_e : Int32
  n_f : Int32
  m_bos : Int32
  n_ferm : Int32
  q_op : DenseMat
  q_dag : DenseMat
  hamiltonian : DenseMat
  grading : DenseMat
}

///|
/// Build an N = 2 Witten-deformed SUSY system from vertex count `n_v`,
/// oriented edges `(u, v)` with u < v, oriented triangles `(u, v, w)` with u < v < w,
/// and smooth neural superpotential weights `(w0, w1, w2)` on (C^0, C^1, C^2):
///   d_{0,W} = exp(-W_1) d_0 exp(W_0),   d_{1,W} = exp(-W_2) d_1 exp(W_1).
/// Exact cochain cancellation guarantees d_{1,W} * d_{0,W} == 0 for ALL (w0, w1, w2)!
pub fn WittenSUSYSystem::from_simplicial_complex(
  n_v : Int32,
  edges : Array[(Int32, Int32)],
  triangles : Array[(Int32, Int32, Int32)],
  w0~ : Array[Double] = [],
  w1~ : Array[Double] = [],
  w2~ : Array[Double] = [],
) -> WittenSUSYSystem {
  let n_e = edges.length()
  let n_f = triangles.length()
  let m_bos = n_v + n_f
  let n_ferm = n_e
  let tot = m_bos + n_ferm
  let get_w = (arr : Array[Double], idx : Int32) => {
    if idx < arr.length() {
      arr[idx]
    } else {
      0.0
    }
  }
  // Construct d_{0,W} : C^0 -> C^1 (n_e x n_v)
  let d0w = DenseMat::zeros(n_e, n_v)
  for e_idx in 0..<n_e {
    let (u, v) = edges[e_idx]
    let ew1 = @math.exp(-get_w(w1, e_idx))
    d0w.set(e_idx, u, -ew1 * @math.exp(get_w(w0, u)))
    d0w.set(e_idx, v, ew1 * @math.exp(get_w(w0, v)))
  }
  // Helper to locate oriented edge index and sign
  let find_edge = (a : Int32, b : Int32) => {
    for e_idx in 0..<n_e {
      let (u, v) = edges[e_idx]
      if u == a && v == b {
        return (e_idx, 1.0)
      }
      if u == b && v == a {
        return (e_idx, -1.0)
      }
    }
    (-1, 0.0)
  }
  // Construct d_{1,W} : C^1 -> C^2 (n_f x n_e)
  let d1w = DenseMat::zeros(n_f, n_e)
  for f_idx in 0..<n_f {
    let (u, v, w) = triangles[f_idx]
    let ew2 = @math.exp(-get_w(w2, f_idx))
    let bdy = [(u, v, 1.0), (v, w, 1.0), (u, w, -1.0)]
    for item in bdy {
      let (ei, orient) = find_edge(item.0, item.1)
      if ei >= 0 {
        d1w.set(f_idx, ei, ew2 * item.2 * orient * @math.exp(get_w(w1, ei)))
      }
    }
  }
  // Assemble Q in basis [C^0 (0..<n_v), C^2 (n_v..<n_v+n_f) | C^1 (m_bos..<tot)]
  let q_op = DenseMat::zeros(tot, tot)
  for e in 0..<n_e {
    for v in 0..<n_v {
      q_op.set(m_bos + e, v, d0w.get(e, v))
    }
  }
  for f in 0..<n_f {
    for e in 0..<n_e {
      q_op.set(n_v + f, m_bos + e, d1w.get(f, e))
    }
  }
  let q_dag = q_op.transpose()
  let hamiltonian = (q_op * q_dag + q_dag * q_op).scale(0.5)
  let grading = chirality_grading_mat(m_bos, n_ferm)
  { n_v, n_e, n_f, m_bos, n_ferm, q_op, q_dag, hamiltonian, grading, }
}

///|
/// Verify all N = 2 Witten SUSY algebraic residuals:
///   (|| Q^2 ||_F, || [H, Q] ||_F, || {gamma, Q} ||_F).
/// By Theorem IIIb, all three vanish identically to machine precision!
pub fn WittenSUSYSystem::susy_algebra_residuals(
  self : WittenSUSYSystem,
) -> (Double, Double, Double) {
  let q2 = (self.q_op * self.q_op).frob_norm()
  let hq = (self.hamiltonian * self.q_op - self.q_op * self.hamiltonian).frob_norm()
  let gq = (self.grading * self.q_op + self.q_op * self.grading).frob_norm()
  (q2, hq, gq)
}

///|
/// Shared bosonic and fermionic Hamiltonian sector eigenvalue extractor.
fn WittenSUSYSystem::sector_spectra(
  self : WittenSUSYSystem,
) -> (Array[Double], Array[Double]) {
  let h_bos = DenseMat::from_fn(self.m_bos, self.m_bos, (i, j) => {
    self.hamiltonian.get(i, j)
  })
  let h_ferm = DenseMat::from_fn(self.n_ferm, self.n_ferm, (i, j) => {
    self.hamiltonian.get(self.m_bos + i, self.m_bos + j)
  })
  let (eb, _) = h_bos.sym_eigen()
  let (ef, _) = h_ferm.sym_eigen()
  (eb, ef)
}

///|
/// Topological Witten Index Delta_W(beta) = str(exp(-beta * H)) = Tr((-1)^F exp(-beta * H)).
/// Equals dim ker(H_bos) - dim ker(H_ferm) = n_v - n_e + n_f = chi(K),
/// strictly invariant under BOTH beta > 0 and arbitrary neural superpotentials W!
pub fn WittenSUSYSystem::witten_index(
  self : WittenSUSYSystem,
  beta : Double,
) -> Double {
  let (eb, ef) = self.sector_spectra()
  let mut tr_b = 0.0
  for e in eb {
    tr_b = tr_b + @math.exp(-beta * e.max(0.0))
  }
  let mut tr_f = 0.0
  for e in ef {
    tr_f = tr_f + @math.exp(-beta * e.max(0.0))
  }
  tr_b - tr_f
}

///|
/// Extract sorted positive spectrum pairing error between bosonic H_bos and fermionic H_ferm.
/// By SUSY, every excited eigenvalue E > 0 appears with identical multiplicity in both sectors!
pub fn WittenSUSYSystem::excited_pairing_error(
  self : WittenSUSYSystem,
  zero_tol~ : Double = 1.0e-9,
) -> Double {
  let (eb, ef) = self.sector_spectra()
  let pos_b : Array[Double] = []
  let pos_f : Array[Double] = []
  for e in eb {
    if e > zero_tol {
      pos_b.push(e)
    }
  }
  for e in ef {
    if e > zero_tol {
      pos_f.push(e)
    }
  }
  if pos_b.length() != pos_f.length() {
    return 1.0e9
  }
  let mut max_diff = 0.0
  for i in 0..<pos_b.length() {
    let d = (pos_b[i] - pos_f[i]).abs()
    if d > max_diff {
      max_diff = d
    }
  }
  max_diff
}

///|
/// Finite orthogonal supersymmetry transformation U(eps) = exp(eps * (Q - Q^dagger)),
/// mixing bosonic sub-symbolic states and fermionic symbolic rules while strictly
/// preserving total energy <psi, H psi> and norm ||psi||_2.
pub fn WittenSUSYSystem::susy_transform(
  self : WittenSUSYSystem,
  eps : Double,
) -> DenseMat {
  (self.q_op - self.q_dag).scale(eps).mat_exp()
}

///|
/// Neuro-symbolic frustration energy E(psi) = <psi, H psi> = (1/2)(||Q psi||^2 + ||Q^dagger psi||^2).
/// Vanishes iff psi is a BPS supersymmetric equilibrium (Q psi = 0 and Q^dagger psi = 0)!
pub fn WittenSUSYSystem::frustration_energy(
  self : WittenSUSYSystem,
  psi : Array[Double],
) -> Double {
  vec_dot(psi, self.hamiltonian.matvec(psi))
}

///|
/// Orthogonal projector P_BPS onto the zero-energy BPS ground-state subspace ker(H)
/// (topologically protected emergent neuro-symbolic consensus concepts & harmonic rules).
pub fn WittenSUSYSystem::project_to_bps(
  self : WittenSUSYSystem,
  psi : Array[Double],
  zero_tol~ : Double = 1.0e-9,
) -> Array[Double] {
  let tot = self.m_bos + self.n_ferm
  let (eigs, v) = self.hamiltonian.sym_eigen()
  let out = Array::make(tot, 0.0)
  for k in 0..<tot {
    if eigs[k].abs() <= zero_tol {
      let mut coeff = 0.0
      for i in 0..<tot {
        coeff = coeff + v.get(i, k) * psi[i]
      }
      for i in 0..<tot {
        out[i] = out[i] + coeff * v.get(i, k)
      }
    }
  }
  out
}
