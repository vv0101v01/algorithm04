# `arena/super_emergence` — 統一數理類智能體湧現框架：超幾何・泛性質・半熱帶射影・奇點胚・微局部分析・辛相調・算子叢・副相容邏輯 (MoonBit v0.10.21)

[![MoonBit CI](https://github.com/vv0101v01/super_emergence/actions/workflows/ci.yml/badge.svg)](https://github.com/vv0101v01/super_emergence/actions/workflows/ci.yml)

以最新穩定版 **MoonBit**（`moonc v0.10.21` / `moon 0.1.20261117`）之嚴格型別系統、多型代數 Trait 與顯式 `pub extend` 方法擴充機制，將 **`algorithm04`（十八大現代數學結構 + 14 條定理）** 與 **`algo8`（八大數學結構 + 31 條定理）** 融合為單一零外部依賴、零編譯警告（`--deny-warn`）、零死碼且跨三後端（`wasm-gc` / `wasm` / `js`）機器精度驗證之 **26 大數學結構 + 18 條複合定理 + 31 條基礎定理** 計算框架，並驅動 **四層類智能體湧現引擎 `SGNE-Flow` + `SGNE-Trop-Kan` + `SGNE-Germ-Micro` + `SGNE-Syn-Mem-Para`**。

> **本倉庫為 `vv0101v01/algorithm04`（`d85a35f`）與 `vv0101v01/algo8`（`99bdadf`）之雙親統一合併（dual-parent merge）成果**，
> 版本 `2.0.0`，套件名稱 `arena/super_emergence`。合併策略為「分層正交核心 + 單向橋接層」
> （Stratified Orthogonal Core + Unidirectional Bridge），詳見 `MERGE_ANALYSIS.md`。

## 模組架構（26 大數學結構與四層湧現引擎）

| 檔案 | 對應數學結構與核心演算法 |
| :--- | :--- |
| `moon.mod` / `moon.pkg` | MoonBit v0.10 新式模組與套件宣告（零外部依賴，支援 `wasm-gc` / `wasm` / `js`） |
| `algebra.mbt` | 範疇與代數 Trait 塔（`Parity`, `AbelianGroup`, `Module`, `Ring`, `SuperAlgebra`, `LieSuperAlgebra`, `AffineTorsor`, `RiemannianGeometry`）、精確 Grassmann 外超代數 $\Lambda_N$、複數域 $\mathbb{C}$、列最簡階梯形 `rref_with_pivots`、零主元安全線性求解與 Jacobi 對稱特徵分解 |
| `supermanifold.mbt` | **(1) 龐加萊-黎曼超流形 $\mathcal{M}^{m\mid n}_c$**：Möbius 陀螺向量加法、$\exp_x^c/\log_x^c$、Levi-Civita 平行移動、$\mathrm{OSp}(m\mid 2k)$ 不變超度量 $G_{AB}(z)$ 與 Berezinian 體積元 $\sqrt{\mathrm{Ber}\,G}=\lambda_c^{m-2k}$ |
| `affine_tensor.mbt` | **(2) 仿射張量空間**：仿射 Torsor 與 Fréchet 雙曲質心、混合變異 $\mathbb{Z}_2$-分次張量 $T^{(r,s)}(V_{m\mid n})$、Yang–Baxter 編織、音樂同構、仿射聯絡（含撓率 contorsion）、Riemann/Ricci 曲率與 Bianchi 恆等式 |
| `pope.mbt` | **(3) PoPE 位置編碼函數**：極座標位置編碼（Gopalakrishnan et al., 2025）內容-位置雅可比正交解耦、Bochner–Mercer 正定核、以及 $\mathcal{M}^{m\mid 2k}_c$ 上之 Pauli 互補 `super_pope_score` |
| `ncg_supermatrix.mbt` | **(4) 非交換幾何與超矩陣方程**：$\mathrm{Mat}(m\mid n,\Lambda_N)$、超轉置 $M^{st}$、超跡 $\mathrm{str}$、雙逆元 Frobenius–Banachiewicz 超逆、Berezinian $\mathrm{Ber}(M)$、Super-Liouville 定理、Super-Sylvester / Riccati / Lax 方程、Connes 偶譜三元組與譜距離 $d_{\mathcal{D}}$ |
| `pde_flow.mbt` | **(5) 偏微分演化流**：Wasserstein–Fisher–Rao Fokker–Planck–Beltrami–Berezin 守恆耗散流（自由能 H 定理）、Witten–Hodge 超對稱熱流 $\partial_t\Psi=-H\Psi$、以及自適應 Poincaré–Ricci–Fisher 曲率流 |
| `super_jacobi.mbt` | **(6) 雅可比與超雅可比恆等式**：$\mathfrak{gl}(m\mid n)$、$\mathfrak{osp}(m\mid 2k)$、$\mathfrak{so}(m)$、相超空間 Super-Poisson 括號 $\{F,G\}_{SP}$、全 8 宇稱扇區驗證與協議 Jacobiator 異常檢測 |
| `super_mass_orbit.mbt` | **(7) 二階超質量張量軌道空間**：偶分次對稱慣量張量 $\mathcal{I}$、超合同規範作用 $g^{st}\mathcal{I}g$、Schur–Berezin 么冪標準形 $M_{\mathrm{eff}}=M+\Xi\Omega^{-1}\Xi^T$、$\mathrm{OSp}$ Casimir 不變量、軌道-穩定子分解與商空間測地距離 $d_{\mathcal{O}}$ |
| `neuro_symbolic_susy.mbt` | **(8) 符號-神經混合之代數合一算子與超對稱變換**：一階項代數、同步安全代換么半群、Robinson MGU + 雙曲上位概念提升 + Pauli–Grassmann 矛盾阻斷之分次合一 $\mathcal{U}_\tau$、以及 $\mathcal{N}=2$ Witten–Hodge 超對稱複形與拓撲 Witten 指數 $\Delta_W$ |
| `fisher_natural_grad.mbt` | **(9) 自然梯度與費雪資訊度量**：分類 Fisher–Rao 度量、高斯流形至 $\mathbb{B}_{1/2}^2$ 之精確 Cayley 等距同構、量子 SLD Bures–Helstrom 度量、Amari 自然梯度協變與 KL 信賴域步進 |
| `universal_functor.mbt` | **(10) 泛性質函子**：Yoneda 引理雙射、$O(1)$ 融合 `Coyoneda`、自由-遺忘伴隨 `UniversalFreeObject`、Grassmann 外代數泛同態提升、張量積泛雙線性分解、MGU 泛餘等化子、有限本體推出 `FinitePushout` 與熱帶/Maslov 左右 Kan 擴張 $\mathrm{Lan}_K\dashv K^*\dashv\mathrm{Ran}_K$ |
| `semitropical_projective.mbt` | **(11) 半熱帶環射影**：熱帶半環 $\mathbb{T}$、Litvinov–Maslov 半環 $\mathbb{S}_\hbar$、Izhakian–Rowen 超熱帶半環 $\mathbb{ST}=\mathcal{T}\cup\mathcal{G}$、熱帶射影空間 $\mathbb{TP}^{n-1}$、Galois 殘差多胞形收縮投影 $\Pi_{\mathcal{V}}$、稀疏圖安全 Karp 熱帶射影特徵對、Maslov 譜夾擠與熱帶 Grassmann 流形 $\mathrm{Trop}\,\mathrm{Gr}(2,N)$ |
| `universal_enveloping.mbt` | **(12a) 萬有展開 I — 李超代數萬有包絡超代數 $U(\mathfrak{g})$**：$\mathfrak{sl}(2)$ 與 $\mathfrak{osp}(1\mid 2)$ 精確結構表、Super-PBW 濾過基拉直演算法（含奇元平方 $F_\alpha^2=\frac{1}{2}\{F_\alpha,F_\alpha\}$）、泛表示提升 $U(\mathfrak{g})\to\mathrm{End}(V)$、超 Hopf 餘積/餘單位/分次對極 $S$ 與二次 Casimir 中心元 $C_2$ |
| `singularity_germs.mbt` | **(12b, 13, 14, 15, 18) 萬有展開 II 與奇點映射胚**：截斷局部環 $\mathcal{O}_{n,0}/\mathfrak{m}^{k+1}$、**Mather 接觸群 $\mathcal{K}=A\ltimes\mathcal{D}$ 等價性**（$T\mathcal{K}_e f$、Tjurina 數 $\tau$、Milnor 數 $\mu$、非擬齊次 $\tau<\mu$ 分離）、**Thom–Mather 萬有 $\mathcal{K}$-開折**與泛參數誘導、**孤立完備相交奇點胚（ICIS）**（Koszul $H_1=0$、Lê–Greuel 遞推與零維 Gorenstein 一維 Socle 對偶）、**正規環胚**（Serre $R_1+S_2$ 判準與半群曲線胚正規化 $c=2\delta$）及**等價類映射胚**（芽等價、商胚泛分解 $h=\bar{h}\circ\pi$ 與 ADE 接觸等價分類） |
| `meromorphic_microfunction.mbt` | **(16, 17) 亞純函數胚與佐藤微函數胚**：Laurent 亞純函數胚域 $\mathcal{M}_{1,0}$（熱帶賦值、Cauchy 留數、輻角原則、Mittag–Leffler 分解）、全域 Euler–Jacobi 留數消失定理、二維 Weierstrass 預備定理 $f=u\cdot W$、多變元亞純胚 $\mathcal{M}_{n,0}$、**Sato 超函數與微函數胚** $0\to\mathcal{A}_0\to\mathcal{B}_0\xrightarrow{\mathrm{sp}}\mathcal{C}_0\to 0$（Sokhotski–Plemelj、奇異譜 $SS(u)$、Köthe 對偶、反對徑波前積）與 **SKK 微微分算子環 $\mathcal{E}_{X,(0,+idx)}$**（Leibniz 符號合成與雙邊橢圓擬逆 $P\circ P^{-1}=P^{-1}\circ P=1$） |
| `memory.mbt` | **(19) 長期記憶細胞狀態轉移與馬可夫吸收半群**：$f^t$ 記憶轉移半群閉式解（$O(\log t)$ 二冪快取）、平穩分佈冪迭代、吸收時間 Neumann 基本矩陣線性求解（零主元防護、純函式） |
| `universal.mbt` | **(20) 有限範疇極限**：終物件唯一性、乘積泛性質窮舉見證、笛卡爾函子律、**有限拉回（fiber product limit）`FinitePullback`** 與唯一中介映射 |
| `complex_field.mbt` | **(21) 複數域強基數**：Hamel 強基座標 $\varphi:\mathbb{C}\to\mathbb{R}^2$、複數域公理計算驗證器、Cantor 配對 $O(1)$ 反演、Gaussian 整數範數篩 |
| `synergetic.mbt` | **(22) 協同學函子神經網絡**：ReLU 編碼層之推前函子律、Haken 奴役不動點 $\xi^2-1$ 指數收斂、序參數 Winner-Take-All 競爭動力學 |
| `symplectic.mbt` | **(23) 神經偏微分辛相調恆等式方程**：可分離神經哈密頓量、辛 Euler 與顯式 Euler 對照、$M^{\mathsf T}\Omega M=\Omega$ 變分殘差、離散 Liouville 面積守恆 |
| `bundle.mbt` | **(24) 湧現算子叢**：Čech 轉移上邊條件 $g_{\alpha\beta}g_{\beta\gamma}=g_{\alpha\gamma}$、截面拼接 $s_\beta=g_{\alpha\beta}s_\alpha g_{\alpha\beta}^{-1}$、交換子跡共軛不變與量變不變譜隙 |
| `quaternion_ktheory.mbt` | **(25) 希爾伯特四元數與非交換圖 $K_0$ 譜對象**：Hamilton 四元數除環、$K_0$ 譜投影恆等式（退化譜 $0/0$ 已修）、Cayley–Hamilton、任意 $n$ 四元數非交換圖、**實四維嵌入 $\iota:\mathbb{H}\hookrightarrow\mathrm{Mat}_4(\mathbb{R})$** 與整數 $K_0$ 直接和指標 |
| `para_universe.mbt` | **(26) 仿宇宙與 Belnap 四值雙格 $B_4$**：$\mathrm{Nv}/\mathrm{Fv}/\mathrm{Tv}/\mathrm{Bv}$ 資訊序與真值序、副相容不爆炸、Knaster–Tarski 最小不動點、跨世界逐點融合 |
| `unified_bridges.mbt` | **統一橋接層（第 4 層）**：Schur-質量 Metriplectic 保守-耗散流、Belnap–Grassmann–Poincaré 副相容統一、Čech 超算子叢餘擺與 Kramers 四重實嵌入、角色閘控記憶半群與 Haken–超熱帶對偶、有限雙完全性與 Cantor Gödel 引擎 |
| `emergence.mbt` | **四層類智能體湧現與驗證主引擎**：微觀 **`SGNE-Flow`**（A1–A4）、半熱帶泛函宏觀蒸餾 **`SGNE-Trop-Kan`**（A5–A6）、奇點胚-微局部相變認證 **`SGNE-Germ-Micro`**（A7–A8）、**跨層蒸餾 `SGNE-Syn-Mem-Para`（A9–A10）**，以及統一 **18 大定理**數值證明器 `verify_all_theorems()` |
| `extends.mbt` | MoonBit v0.10.21 顯式 `pub extend Type with Trait::{...}` 方法掛載宣告 |
| `super_emergence_test.mbt` | 涵蓋 18 大模組、18 條複合定理與邊界迴歸測試之黑盒測試套件 |
| `math_structures_test.mbt` | 涵蓋 8 大基礎模組、31 條基礎定理與 6 項缺陷回歸測試之黑盒測試套件 |
| `cmd/main/main.mbt` | 可執行 18 大定理驗證報告與四層湧現模擬 CLI |
| `THEOREMS_AND_ALGORITHMS.md` | 完整數學形式化、18 條複合定理嚴格證明、四層演算法偽代碼、31 條基礎定理附錄與工程重構審計專論 |
| `MERGE_ANALYSIS.md` | 合併前利弊分析、僅合併可得之數學紅利、合併方案選擇與損害最小化對策 |
| `AGENT_EMERGENCE_PLAN.md` | 數理類智能體（**非 LLM**）湧現之後續路線圖與前端 NL2Math 小模型規格 |
| `EMERGENCE_PROBLEM_SET.md` / `benchmarks/emergence_problem_set.json` | 迫出類智能體之問題集（可機器讀取） |
| `.github/workflows/ci.yml` | GitHub Actions 嚴格八道門檻 CI（格式、`--deny-warn`、`.mbti` 介面一致性、三後端測試、18 定理 CLI 驗證、問題集 JSON 機器驗證） |

## 快速執行與持續整合門檻

```bash
moon fmt --check                        # 零格式漂移檢查
moon check --deny-warn                  # 零警告、零錯誤嚴格型別檢查
moon info && git diff --exit-code       # 公開介面 pkg.generated.mbti 一致性檢查
moon test --target wasm-gc              # Wasm-GC 後端執行全部測試與文件測試
moon test --target wasm                 # Wasm 線性記憶體後端交叉驗證
moon test --target js                   # JavaScript (V8) 後端交叉驗證
moon run cmd/main                       # 執行 18 大定理驗證與四層湧現模擬報告
```

```mbt check
///|
test "doctest: all 18 emergent theorems and SGNE-Syn-Mem-Para audit pass" {
  let reports = @super_emergence.verify_all_theorems()
  assert_eq(reports.length(), 18)
  for r in reports {
    assert_true(r.passed)
  }
  let gm = @super_emergence.distill_germ_microlocal_phase()
  assert_eq(gm.pbw_dim_deg3, 44)
  assert_eq(gm.normalization_conductor, 2 * gm.normalization_delta)
}
```

## 授權

Apache-2.0（合併自 `vv0101v01/algorithm04` 與 `vv0101v01/algo8`，兩者皆為 Apache-2.0）。
