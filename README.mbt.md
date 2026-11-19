# `arena/super_emergence` — 統一數理類智能體湧現框架：超幾何・泛性質・半熱帶射影・奇點胚・微局部分析・辛相調・算子叢・副相容邏輯 (MoonBit v0.10.21)

[![MoonBit CI](https://github.com/vv0101v01/algorithm04/actions/workflows/ci.yml/badge.svg)](https://github.com/vv0101v01/algorithm04/actions/workflows/ci.yml)

以最新穩定版 **MoonBit**（`moonc v0.10.21` / `moon 0.1.20261117`）之嚴格型別系統、多型代數 Trait 與顯式 `pub extend` 方法擴充機制，將 **`algorithm04`（十八大現代數學結構 + 14 條定理）** 與 **`algo8`（八大數學結構 + 31 條定理）** 融合為單一僅依賴 MoonBit core 的套件、以 `--deny-warn` 嚴格檢查並由跨三後端（`wasm-gc` / `wasm` / `js`）機器精度測試驗收之 **26 大數學結構 + 18 條複合定理 + 31 條基礎定理** 計算框架，並驅動 **四層類智能體湧現引擎 `SGNE-Flow` + `SGNE-Trop-Kan` + `SGNE-Germ-Micro` + `SGNE-Syn-Mem-Para`**。M4–M6 另提供有限 A3/D4 開折選擇、同基點微局部反對徑隔離，以及可量測殘差收縮的阻尼閉環回饋；CI 測試及編譯檢查不宣稱已證明全專案無死碼。

> **本倉庫為 `vv0101v01/algorithm04`（`d85a35f`）與 `vv0101v01/algo8`（`99bdadf`）之雙親統一合併（dual-parent merge）成果**，
> 版本 `2.0.0`，套件名稱 `arena/super_emergence`。合併策略為「分層正交核心 + 單向橋接層」
> （Stratified Orthogonal Core + Unidirectional Bridge），詳見 `MERGE_ANALYSIS.md`。

## 模組架構（26 大數學結構與四層湧現引擎）

| 檔案 | 對應數學結構與核心演算法 |
| :--- | :--- |
| `moon.mod` / `moon.pkg` | MoonBit v0.10 新式模組與套件宣告（僅依賴 MoonBit core，支援 `wasm-gc` / `wasm` / `js`） |
| `algebra.mbt` | 範疇與代數 Trait 塔（`Parity`, `AbelianGroup`, `Module`, `Ring`, `SuperAlgebra`, `LieSuperAlgebra`, `AffineTorsor`, `RiemannianGeometry`）、精確 Grassmann 外超代數 $\Lambda_N$、複數域 $\mathbb{C}$、列最簡階梯形 `rref_with_pivots`、零主元安全線性求解與 Jacobi 對稱特徵分解 |
| `supermanifold.mbt` | **(1) 龐加萊-黎曼超流形 $\mathcal{M}^{m\mid n}_c$**：Möbius 陀螺向量加法、$\exp_x^c/\log_x^c$、Levi-Civita 平行移動、$\mathrm{OSp}(m\mid 2k)$ 不變超度量 $G_{AB}(z)$ 與 Berezinian 體積元 $\sqrt{\mathrm{Ber}\,G}=\lambda_c^{m-2k}$ |
| `affine_tensor.mbt` | **(2) 仿射張量空間**：仿射 Torsor 與 Fréchet 雙曲質心、混合變異 $\mathbb{Z}_2$-分次張量 $T^{(r,s)}(V_{m\mid n})$、Yang–Baxter 編織、音樂同構、仿射聯絡（含撓率 contorsion）、Riemann/Ricci 曲率與 Bianchi 恆等式 |
| `pope.mbt` | **(3) PoPE 位置編碼函數**：極座標位置編碼（Gopalakrishnan et al., 2025）內容-位置雅可比正交解耦、Bochner–Mercer 正定核、以及 $\mathcal{M}^{m\mid 2k}_c$ 上之 Pauli 互補 `super_pope_score` |
| `ncg_supermatrix.mbt` | **(4) 非交換幾何與超矩陣方程**：$\mathrm{Mat}(m\mid n,\Lambda_N)$、超轉置 $M^{st}$、超跡 $\mathrm{str}$、雙逆元 Frobenius–Banachiewicz 超逆、Berezinian $\mathrm{Ber}(M)$、Super-Liouville 定理、Super-Sylvester / Riccati / Lax 方程、Connes 偶譜三元組與譜距離 $d_{\mathcal{D}}$ |
| `pde_flow.mbt` | **(5) 偏微分演化流**：Wasserstein–Fisher–Rao Fokker–Planck–Beltrami–Berezin 守恆耗散流（自由能 H 定理、可控外生擾動與分離質量／自由能帳本、10⁵ 步穩定性審核）、Witten–Hodge 超對稱熱流 $\partial_t\Psi=-H\Psi$、以及自適應 Poincaré–Ricci–Fisher 曲率流 |
| `super_jacobi.mbt` | **(6) 雅可比與超雅可比恆等式**：$\mathfrak{gl}(m\mid n)$、$\mathfrak{osp}(m\mid 2k)$、$\mathfrak{so}(m)$、相超空間 Super-Poisson 括號 $\{F,G\}_{SP}$、全 8 宇稱扇區驗證與協議 Jacobiator 異常檢測 |
| `super_mass_orbit.mbt` | **(7) 二階超質量張量軌道空間**：偶分次對稱慣量張量 $\mathcal{I}$、超合同規範作用 $g^{st}\mathcal{I}g$、Schur–Berezin 么冪標準形 $M_{\mathrm{eff}}=M+\Xi\Omega^{-1}\Xi^T$、$\mathrm{OSp}$ Casimir 不變量、軌道-穩定子分解與商空間測地距離 $d_{\mathcal{O}}$ |
| `neuro_symbolic_susy.mbt` | **(8) 符號-神經混合之代數合一算子與超對稱變換**：一階項代數、同步安全代換么半群、Robinson MGU + 雙曲上位概念提升 + Pauli–Grassmann 矛盾阻斷之分次合一 $\mathcal{U}_\tau$、以及 $\mathcal{N}=2$ Witten–Hodge 超對稱複形與拓撲 Witten 指數 $\Delta_W$ |
| `fisher_natural_grad.mbt` | **(9) 自然梯度與費雪資訊度量**：分類 Fisher–Rao 度量、高斯流形至 $\mathbb{B}_{1/2}^2$ 之精確 Cayley 等距同構、量子 SLD Bures–Helstrom 度量、Amari 自然梯度協變與 KL 信賴域步進 |
| `universal_functor.mbt` | **(10) 泛性質函子**：Yoneda 引理雙射、$O(1)$ 融合 `Coyoneda`、自由-遺忘伴隨 `UniversalFreeObject`、Grassmann 外代數泛同態提升、張量積泛雙線性分解、MGU 泛餘等化子、有限本體推出 `FinitePushout` 與熱帶/Maslov 左右 Kan 擴張 $\mathrm{Lan}_K\dashv K^*\dashv\mathrm{Ran}_K$ |
| `semitropical_projective.mbt` | **(11) 半熱帶環射影**：熱帶半環 $\mathbb{T}$、Litvinov–Maslov 半環 $\mathbb{S}_\hbar$、Izhakian–Rowen 超熱帶半環 $\mathbb{ST}=\mathcal{T}\cup\mathcal{G}$、熱帶射影空間 $\mathbb{TP}^{n-1}$、Galois 殘差多胞形收縮投影 $\Pi_{\mathcal{V}}$、稀疏圖安全 Karp 熱帶射影特徵對、Maslov 譜夾擠與熱帶 Grassmann 流形 $\mathrm{Trop}\,\mathrm{Gr}(2,N)$ |
| `universal_enveloping.mbt` | **(12a) 萬有展開 I — 李超代數萬有包絡超代數 $U(\mathfrak{g})$**：$\mathfrak{sl}(2)$ 與 $\mathfrak{osp}(1\mid 2)$ 精確結構表、Super-PBW 濾過基拉直演算法（含奇元平方 $F_\alpha^2=\frac{1}{2}\{F_\alpha,F_\alpha\}$）、泛表示提升 $U(\mathfrak{g})\to\mathrm{End}(V)$、超 Hopf 餘積/餘單位/分次對極 $S$ 與二次 Casimir 中心元 $C_2$ |
| `singularity_germs.mbt` | **(12b, 13, 14, 15, 18) 萬有展開 II 與奇點映射胚**：截斷局部環 $\mathcal{O}_{n,0}/\mathfrak{m}^{k+1}$、**Mather 接觸群 $\mathcal{K}=A\ltimes\mathcal{D}$ 等價性**（$T\mathcal{K}_e f$、Tjurina 數 $\tau$、Milnor 數 $\mu$、非擬齊次 $\tau<\mu$ 分離）、**Thom–Mather 萬有 $\mathcal{K}$-開折**（含維度／有限參數 checked fiber API）與泛參數誘導、**孤立完備相交奇點胚（ICIS）**（Koszul $H_1=0$、Lê–Greuel 遞推與零維 Gorenstein 一維 Socle 對偶）、**正規環胚**（Serre $R_1+S_2$ 判準與半群曲線胚正規化 $c=2\delta$）及**等價類映射胚**（芽等價、商胚泛分解 $h=\bar{h}\circ\pi$ 與 ADE 接觸等價分類；scalar function germ 以 Hessian corank 判別 ADE） |
| `mora_tangent_cone.mbt` | **(27, M4.2, M6.2) Mora 切線錐算法**：局部環 $\mathcal{O}_{n}$ 上的 **Mora 弱正規形**（ecart $=\deg f-\deg \mathrm{lm}$ 最小化、`ecart(g) > ecart(h)` 時插入當前 $h$，使 $x<1$ 之非良序局部序仍終止）、**Buchberger–Mora 局部標準基**與反覆 `NF(S(g_i,g_j))` 認證、**切線錐** $TC_0(V(I))=V(\mathrm{in}(I))$ 的重數／維數／Hilbert 函數／錐方程／conical／lineality 報表、**牛頓多面體與法扇**（凸包、原始外法向、原型單項賦值）與 **toric/Koszul 二分**（混合二項初始形 vs 單項初始形）、**錐認證的 catastrophe 選型 M4.2**（A3 臨界簇 `2x(2x^2 - a)`：2 線錐、非 conical；D4 兩條二次方程：4 線錐、conical），以及 **M6.2 錐認證四層閉環**（`audit_four_layer_tangent_cone_loop`：錐重數＋隔離壓力決定記憶頻帶，`0 -> band -> 0` 可逆） |
| `singularity_germs.mbt`（本輪強化） | **ADE 接觸類分類器 v3**：`scalar_tjurina_hilbert` / `hilbert_socle_degree` 以 Tjurina 代數 $\mathcal{O}/(f,f_x,f_y)$ 的 Hilbert 函數作真判據（$E_6$ socle 度 $3$ vs $D_6$ socle 度 $4$，兩者 $(\mu,\tau,\mathrm{corank})=(6,6,2)$ 完全相同）；`audit_truncation_adequacy` 以 $k$ 與 $k+1$ 兩次 $\mu,\tau$ 比較審查截斷充分性（$E_8$ 在 `max_deg=4` 高估 $\mu=9$，$\ge 5$ 才穩定為 $8$）；`classify_contact_equiv_class` 現覆蓋 $A_1$、$A_k$、$D_4$–$D_6$、$E_6$–$E_8$、$T_{3,3,3}$，全部 label 唯一 |
| `meromorphic_microfunction.mbt`（本輪強化） | **M5.2 Hörmander 乘積判據**：`hormander_sigma_condition` 判定「**不存在** $(x,\xi)\in WF(u)$ 與 $(x,-\xi)\in WF(v)$」，即 $WF(u)\oplus WF(v)$ 避開零截面 — 這是全稱否定命題，可**放行**乘積（舊 `microlocal_attention_event` 只能證明存在碰撞）；`ConormalBundle` + `hormander_sigma_conormal` 把 chirality 折算為角度 $+\pi$，支援任意多方向 conormal；`audit_microlocal_leibniz_consistency` 對 36 對 fixture 窮舉驗證 Σ-條件與 `micro_product` 同向，並檢查 $\mathrm{ord}(u v)=\mathrm{ord}\,u+\mathrm{ord}\,v$ |
| `unified_categories.mbt`（**新增**） | **M7 統一範疇 + M8 K₀ 複雜度**：三腿範疇契約（`SemitropicalCat` 熱帶仿射映射／`SymplecticCat` 辛 Euler 步／`ParaconsistentCat` Belnap–Dunn 一元映射）逐條公理機檢；沿 **Maslov 相位**嘅纖維積 `UnifiedObject`/`UnifiedMorphism` 檢查單位律、結合律（**up to tie tolerance**，半環值範疇）、相位一致 ⇒ `verify_m7_unified_category().is_category = true`。**M8**：角色 = 四元數代數模，K₀ 類 = 投影子秩，`mdl = log₂|K₀| + 不可約和項數`；加性（塊對角 `k0_direct_sum_index`）、單調、可分辨三條件機檢 ⇒ 可作角色複雜度計量（**但秩單獨分唔開 explorer/connector**；mdl 逐個為 `[1,1,3,2]`，connector 曾因 `summands=max(k0,1)` 被錯算成 1） |
| `emergence_falsifiability.mbt`（**新增**） | **M9 湧現可證偽性**：`Pcg32` 跨後端逐位一致的 LCG；結構化環形耦合 vs **獨立隨機遊走零假設**（同等評估預算，刻意不弱化）；觀測量 = **Kuramoto 型同步序參數** `r = 1 − Var(x)/Var(x₀)`；量得 `fpr = 0.047`、`power = 1.000` ⇒ 陳述本身可證偽（`power ≤ fpr` 則 PASS = false） |
| `subcolony_consensus.mbt`（**新增**） | **M10 副相容共識**：四規則對照量度 —— `NaiveJoin`(爆炸 3/6)、`QuarantineFirst`(**爆炸 4/6，比唔處理更差**，因為 `epistemic_quarantine_map` 把 Fv/Tv/Bv 全映到 Bv)、`Scoped`(仍爆炸 2/6，因為 `join(Tv,Fv)=Bv`)、**`Weighted`(爆炸 0、空洞 0、忠實 4/6)**。正解 = 信心加權投票 + `contested` 旗標，平局報 `Nv` 而非 `Bv` |
| `four_layer_feedback.mbt` — M6.4 | **角色覆蓋可達性掃描** `audit_m6_role_coverage_sweep`：喺四角色權重嘅**開單純形**上決定性掃描 42 點（近頂點／近邊中點／對稱中心／van der Corput 填點），判定「覆蓋 2 of 4」係**結構上限**定**亞穩態**。實測 `max=4`（對稱中心可達 4 叢）、`hist=[31,10,0,1]`；另有 **並列最大值家族** `m6_tie_family_weights`（k 個 1.0 + 其餘 1e-4）直接驗證 `tie_family_coverage=[1,2,3,4]` ⇒ **覆蓋數 = 並列最大值個數**，`hist[3]=0` 純屬取樣盲區（非不穩定平衡） |
| `four_layer_feedback.mbt`（本輪強化） | **M6.3 局部收縮與步長細化**：把一次完整層傳遞抽成 `m6_layer_pass`（迭代器與 Jacobian 探針**共用同一映射**），`audit_m6_refinement_and_local_contraction` 以 $r$ 與 $r/2$ 的細化一致性 + 有限差分估 $\|DT\|_{\max}$ 得 Jacobian 譜半徑 $\rho=(1-r)+r\|DT\|_{\max}$；實測 $\rho=0.65<1$、權重差 $1.81\times10^{-4}$ |
| `meromorphic_microfunction.mbt` | **(16, 17) 亞純函數胚與佐藤微函數胚**：Laurent 亞純函數胚域 $\mathcal{M}_{1,0}$（熱帶賦值、Cauchy 留數、輻角原則、Mittag–Leffler 分解）、全域 Euler–Jacobi 留數消失定理、二維 Weierstrass 預備定理 $f=u\cdot W$、多變元亞純胚 $\mathcal{M}_{n,0}$、**Sato 超函數與微函數胚** $0\to\mathcal{A}_0\to\mathcal{B}_0\xrightarrow{\mathrm{sp}}\mathcal{C}_0\to 0$（Sokhotski–Plemelj、奇異譜 $SS(u)$、Köthe 對偶、同基點反對徑碰撞隔離及具 stalk/log 檢查的微函數乘積）與 **SKK 微微分算子環 $\mathcal{E}_{X,(0,+idx)}$**（Leibniz 符號合成與雙邊橢圓擬逆 $P\circ P^{-1}=P^{-1}\circ P=1$） |
| `memory.mbt` | **(19) 長期記憶細胞狀態轉移與馬可夫吸收半群**：$f^t$ 記憶轉移半群閉式解（$O(\log t)$ 二冪快取）、平穩分佈冪迭代、吸收時間 Neumann 基本矩陣線性求解（零主元防護、純函式） |
| `universal.mbt` | **(20) 有限範疇極限**：終物件唯一性、乘積泛性質窮舉見證、笛卡爾函子律、**有限拉回（fiber product limit）`FinitePullback`** 與唯一中介映射 |
| `complex_field.mbt` | **(21) 複數域強基數**：Hamel 強基座標 $\varphi:\mathbb{C}\to\mathbb{R}^2$、複數域公理計算驗證器、Cantor 配對 $O(1)$ 反演、Gaussian 整數範數篩 |
| `synergetic.mbt` | **(22) 協同學函子神經網絡**：ReLU 編碼層之推前函子律、Haken 奴役不動點 $\xi^2-1$ 指數收斂、序參數 Winner-Take-All 競爭動力學 |
| `symplectic.mbt` | **(23) 神經偏微分辛相調恆等式方程**：可分離神經哈密頓量、辛 Euler 與顯式 Euler 對照、$M^{\mathsf T}\Omega M=\Omega$ 變分殘差、離散 Liouville 面積守恆 |
| `bundle.mbt` | **(24) 湧現算子叢**：Čech 轉移上邊條件 $g_{\alpha\beta}g_{\beta\gamma}=g_{\alpha\gamma}$、截面拼接 $s_\beta=g_{\alpha\beta}s_\alpha g_{\alpha\beta}^{-1}$、交換子跡共軛不變與量變不變譜隙 |
| `quaternion_ktheory.mbt` | **(25) 希爾伯特四元數與非交換圖 $K_0$ 譜對象**：Hamilton 四元數除環、$K_0$ 譜投影恆等式（退化譜 $0/0$ 已修）、Cayley–Hamilton、任意 $n$ 四元數非交換圖、**實四維嵌入 $\iota:\mathbb{H}\hookrightarrow\mathrm{Mat}_4(\mathbb{R})$** 與整數 $K_0$ 直接和指標 |
| `para_universe.mbt` | **(26) 仿宇宙與 Belnap 四值雙格 $B_4$**：$\mathrm{Nv}/\mathrm{Fv}/\mathrm{Tv}/\mathrm{Bv}$ 資訊序與真值序、副相容不爆炸、Knaster–Tarski 最小不動點、跨世界逐點融合 |
| `unified_bridges.mbt` | **統一橋接層（第 4 層）**：Schur-質量 Metriplectic 保守-耗散流、Belnap–Grassmann–Poincaré 副相容統一、Čech 超算子叢餘擺與 Kramers 四重實嵌入、角色閘控記憶半群（保留率依環境 Hurst 指數調整）與 Haken–超熱帶對偶、有限雙完全性與 Cantor Gödel 引擎 |
| `emergence.mbt` | **四層類智能體湧現與驗證主引擎**：微觀 **`SGNE-Flow`**（A1–A4；等權相容入口與 M6 角色超質量回饋入口）、半熱帶泛函宏觀蒸餾 **`SGNE-Trop-Kan`**（A5–A6；可選角色加權蒸餾）、奇點胚-微局部相變認證 **`SGNE-Germ-Micro`**（A7–A8）、**跨層蒸餾 `SGNE-Syn-Mem-Para`（A9–A10）**，以及統一 **18 大定理**數值證明器 `verify_all_theorems()` |
| `catastrophe_unfolding.mbt` | **M4 開折選擇器**：有限 A3 cusp／D4 umbilic miniversal 原型、角色分支目標配對、infinitesimal K-versality 與重建／駐點殘差證據 |
| `role_weights.mbt` | 四角色權重的穩定正規化，共用於 Flow 與 Trop-Kan 回饋入口 |
| `four_layer_feedback.mbt` | **M6 四層閉環**：阻尼 Flow–Trop-Kan–Germ-Micro–Syn-Mem 固定點迭代、吸收時間雙權重回饋及經驗殘差收縮報告 |
| `extends.mbt` | MoonBit v0.10.21 顯式 `pub extend Type with Trait::{...}` 方法掛載宣告 |
| `super_emergence_test.mbt` | 涵蓋 18 大模組、18 條複合定理、邊界迴歸及 M1.1–M1.4 長時穩定、Hurst 單調記憶與可逆四叢驗收之黑盒測試套件 |
| `catastrophe_unfolding_test.mbt` | M4 正常形選擇、開折 versality、checked fiber 與 ADE 分類回歸 |
| `microlocal_attention_test.mbt` | M5 同基點反對徑隔離、stalk、pole 支撐與未支援 log-product／anti-derivative 邊界測試 |
| `euler_jacobi_residue_test.mbt` | Euler–Jacobi 簡根留數、冪次範圍與有限乘積邊界測試 |
| `four_layer_feedback_test.mbt` | M6 Flow／Trop-Kan 權重、相容性、極端浮點輸入與固定點驗收 |
| `math_structures_test.mbt` | 涵蓋 8 大基礎模組、31 條基礎定理與 12 項編號缺陷回歸測試之黑盒測試套件 |
| `cmd/main/main.mbt` | 可執行 18 大定理、四層湧現及 **M1.1–M10** 路線圖驗收 CLI（11 條 `PASS = true` 驗收線：M4 / M4.2 / M4.3 / M5.2 / M6.2 / M6.3 / M6.4 / M7 / M8 / M9 / M10） |
| `THEOREMS_AND_ALGORITHMS.md` | 完整數學形式化、18 條複合定理嚴格證明、四層演算法偽代碼、31 條基礎定理附錄與工程重構審計專論 |
| `MERGE_ANALYSIS.md` | 合併前利弊分析、僅合併可得之數學紅利、合併方案選擇與損害最小化對策 |
| `AGENT_EMERGENCE_PLAN.md` | 數理類智能體（**非 LLM**）湧現之後續路線圖與前端 NL2Math 小模型規格 |
| `EMERGENCE_PROBLEM_SET.md` / `benchmarks/emergence_problem_set.json` | 迫出類智能體之問題集（可機器讀取） |
| `.github/workflows/ci.yml` | GitHub Actions 七道正式驗收門檻（格式、`--deny-warn`、`.mbti` 介面一致性、三後端測試、18 定理與 M1–M10 CLI — 共 11 條 grep 鎖定的驗收線，以及併入 Gate 7 的問題集 JSON 驗證） |

## 快速執行與持續整合門檻

```bash
moon fmt --check                        # 零格式漂移檢查
moon check --deny-warn                  # 零警告、零錯誤嚴格型別檢查
moon info && git diff --exit-code       # 公開介面 pkg.generated.mbti 一致性檢查
moon test --target wasm-gc              # 本地開發：單一後端全部測試與文件測試
moon run cmd/main                       # 執行 18 大定理、四層湧現與 M1–M10 驗收報告

# 以下僅在 CI 執行（本地迭代不跑，避免四倍時間成本）
moon test --target wasm                 # Wasm 線性記憶體後端交叉驗證
moon test --target js                   # JavaScript (V8) 後端交叉驗證
```

## M1.1–M1.4：自持動力學與 Hurst 調節記憶

截至 2026-11-18，路線圖 M1.1–M1.4 均已實作並納入常駐測試與 CLI 驗收。

- **外生 WFR 擾動**：使用 `WFRExogenousPerturbation::new(sigma, xi)` 與 `SuperBeltramiPDE::step_with_exogenous_perturbation(dt, perturbation)`。`xi` 是每格的時間局部加性密度率；擾動會投影到 Berezinian 加權零質量空間，並透過保正的單純形回縮保持總質量。回傳的 `WFRPerturbedStep` 含 `state` 與 `WFRFlowStepLedger`，分開記錄確定性耗散、擾動作功、總自由能變化及質量誤差；若 forcing 格數不符或含非有限值，帳本會由 `input_shape_valid`／`input_values_valid` 明示並退回未擾動步。
- **譜驅動角色再配置**：`canonical_role_mass_orbits()` 提供 Coordinator、Sensor、Planner、Executor 的四個標準軌道。`reassign_roles_by_orbit_distance(agent_masses, role_orbits, disturbance_spectrum)` 先依最大功率頻帶索引模 4 循環平移軌道—角色對應，再以 `d_O` 最近距離指派；回傳結果含指派、叢大小、最大叢內距、最小叢間距與四叢證書。輸入頻譜回復時指派會精確回復，無隱藏狀態或遲滯。
- **M1.3 長時穩定性**：`SuperBeltramiPDE::audit_long_time_stability(dt, steps)` 以能量回溯、質量回縮及串流帳本執行長時程審核；小於自由能的離散步才接受，近固定點時只有在候選密度位移 `< 1e-8` 且能量差處於 roundoff 界內才作 stationary hold。32 格、`dt = 0.0005` 連續 100,000 步的 CLI 證據包含軌跡最大 `ΔF = 0`、質量誤差及 Gibbs 平衡距離。
- **M1.4 Hurst 記憶**：`role_memory_profiles_for_hurst(H)` 用 `f(H)=f(1/2)+2(H-1/2)(1-f(1/2))` 同步調整 forget gate 與 retention（`0 < H < 1`；`H=0.5` 精確還原原始四角色）。`distill_synergetic_memory_para_agent(..., hurst=...)` 可將環境 H 直接帶入記憶蒸餾；四階段鏈吸收時間使用精確值 `4/(1-f)`，避免 retention 趨近 1 時截斷尾和造成偏差。`audit_hurst_memory_monotonicity` 檢查每角色吸收時間隨 H 嚴格上升及角色內排序不變。
- **本地 CLI 見證**：M1.1 的 32 格 mass error 為 `2.22e-16`；M1.2 的八個置換軌道形成 `[2, 2, 2, 2]` 四叢、分離間隙 `1.53`，dominant band `0 → 1 → 0` 可逆。M1.3/M1.4 的長時穩定與 Hurst 單調性亦由 CI Gate 7 驗收。

## M4–M6：開折選擇、微局部隔離與四層閉環

- **M4**：`learn_catastrophe_for_role_branches` 在明確限定的 A3 cusp 與 D4 umbilic scalar normal forms 中，依需求 3／4 個實臨界分支選型；以 miniversal K-unfolding、infinitesimal K-versality 及商空間重建／駐點殘差作有限原型證據。報告另區分臨界分支數與穩定局部極小值數；不宣稱完整 ADE 或任意 ICIS 自動分類。
- **M5**：`microlocal_attention_event` 僅當兩微函數皆有限、位於同一基點且具有反對徑奇異方向時，才把現值與 `Bv` 做 Belnap 資訊 join 並標記隔離。`micro_product` 檢查 stalk 基點及輸入有限性；未支援的對數乘積回報錯誤，不靜默忽略項。
- **M6**：`audit_four_layer_closed_loop` 從固定殖民地重跑加權 SGNE-Flow、Trop-Kan、M4/M5 與 Hurst-conditioned Syn-Mem，以吸收時間阻尼更新兩組角色權重。`empirical_fixed_point_certified` 僅表示該有限確定性迭代在所報告容差內有殘差收縮、正規化及 no-explosion 證據，不是完整非線性引擎的全域收斂定理。三項 acceptance 納入 `moon run cmd/main` 與 CI Gate 7。

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

## M7–M10：統一範疇、K₀ 複雜度、可證偽性、副相容共識

以下四節的每一個數字都由 `moon run cmd/main` 直接印出，並由 CI Gate 7 的 grep 鎖定；括號內為對應的測試名。

### M7 — 超熱帶 × 辛 × 副相容三者之統一範疇：合成是否仍為範疇？

**答案：是。** 沿 Maslov 相位的纖維積仍是範疇。三條腿的公理逐條機檢，不是宣稱：

| 腿 | 物件 | 態射 | 合成 | 額外公理（實測） |
| :--- | :--- | :--- | :--- | :--- |
| `SemitropicalCat` | $\mathbb{ST}=\mathcal{T}\cup\mathcal{G}\cup\{-\infty\}$ | 熱帶仿射 $x\mapsto a\ast x\oplus b$ | 代入 | $\oplus,\ast$ 結合律；**ghost 理想只對乘法吸收**；平局 $a\oplus a=a^\nu$ |
| `SymplecticCat` | 相空間 $(q,p)$ | 辛 Euler 步 | 迭代 | 零步單位；$\|M^{\mathsf T}\Omega M-\Omega\|_F=0$；explicit Euler 則 $>0$（故非此範疇態射） |
| `ParaconsistentCat` | $B_4=\{\mathrm{Nv},\mathrm{Fv},\mathrm{Tv},\mathrm{Bv}\}$ | `join`/`meet` 生成之一元映射 | 函數合成 | De Morgan 對合；非爆炸；$join$/$meet$ 在全部 64 個三元組上結合 |

```text
[M7] unified category | semitropical=true symplectic=true paraconsistent=true
       fiber=true id=true assoc(up to tie tol)=true | IS CATEGORY = true
```

> **限定（必須講清楚）**：結合律**只在平局容差下**成立。用 `Double` 嚴格 `Eq` 判會得到 `false`，因為 $(0.1-0.04)-0.04$ 與 $0.1+(-0.04-0.04)$ 在最後一個 bit 不同。這不是建構缺陷，而是說明統一範疇是**半環值範疇**（semiring-valued），故只 up to tie tolerance 結合。CLI 直接印 `assoc(up to tie tol)`，不遮。

### M8 — K₀ 指標能否定義角色的最小描述長度？

**答案：可以，但只限於「秩 + 不可約和項數」這個組合不變量。**

| 角色 | K₀ 類 | 不可約和項 | 本原 | $\mathrm{mdl}$（bits） |
| :--- | :--: | :--: | :--: | :--: |
| coordinator | 1 | 1 | ✓ | 1 |
| explorer | 1 | 1 | ✓ | 1 |
| exploiter | 2 | 2 | ✗ | 3 |
| connector | 1 | 2 | ✗ | 2 |

```text
[M8] K_0 complexity | additive=true monotone=true distinguishable=true | 4 roles
```

三個判據全部計算：直和下**加性**（塊對角 `Mat₁₆(R)`，即 `k0_direct_sum_index`）、真和項下**嚴格單調**、四角色**可分辨**。

> **限制（已寫入測試，不可偷偷改）**：秩**單獨**分不開四角色 —— `explorer` 與 `connector` 秩皆為 1；而 `coordinator` 與 `explorer` 連 $\mathrm{mdl}$ 都相同（皆 1），**在此計量下不可分辨**。
>
> **範圍誠實**：本節用的是**單點 K₀**（投影子秩）。K-理論作為**函子**還有空間 K、等變 K（$K_G$）、扭曲 K（$K^\alpha$）、相對 K 等變體，本輪**沒有**建立。`coordinator` 與 `explorer` 的分不開，是**選錯 K-理論層次**的後果，不是數學必然 —— 等變 K 很可能分得開（兩者在 Flow 置換群下穩定子不同）。故 M8 結論應讀作「秩 + 和項數可用」，而非「K₀ 理論可用」。

### M9 — 湧現之可證偽性：如何使「湧現」與「偽裝隨機搜尋」可區分？

**答案：可以區分**，且這個陳述本身可證偽。

設計三要素：**零假設**（同目標、同步數、同等評估預算的獨立隨機遊走，刻意不弱化）、**分離觀測量**（Kuramoto 型同步序參數 $r=1-\mathrm{Var}(x)/\mathrm{Var}(x_0)$；獨立遊走永遠擴大方差、鄰居耦合永遠收縮方差）、**檢定力**（報 power 而非只報 p 值）。

```text
[M9] falsifiability | null_mean=-0.163 alt_mean=0.851 thr=0.348
       fpr=0.047 power=1.000 | separates=true
```

$\mathrm{fpr}=0.047$（實測吻合名義 5%）、$\mathrm{power}=1.000$（64/64 結構化樣本全超門檻）。**若 $\mathrm{power}\le\mathrm{fpr}$，CLI 該行即變 `PASS = false`** —— 這就是可證偽的具體含義。

> **陷阱（踩過）**：第一版用「耦合項佔比」並追蹤**歷史最佳點** ⇒ 兩臂都飽和到 $+1$，得 $\mathrm{fpr}=0$、$\mathrm{power}=0$、`separates=false`。必須量度**末態**，且觀測量必須是**標準量**（Kuramoto 序參數），不可為令測試通過而砌分數。

### M10 — 多 sub-colony 副相容共識：$\mathrm{Bv}$ 出現時如何不爆炸？

**答案：把「打交」降解成四值雙格 $B_4^n$ 的乘積狀態，而**不是**把每個子群壓成一個因子。**

#### 為何「壓成一個因子」是錯的

$B_4$ **不是**一條真值刻度，而是**兩個格的乘積**：真值序 $\le_t$ 與資訊序 $\le_i$。把一個子群的 $B_4$ 值壓縮成「有冇矛盾」的布林，等於把向量壓成它的範數 —— 丟掉的正是雙格存在的理由。副相容的要點是：**矛盾是局部狀態，系統可以一邊持有它、一邊把事做完**。

#### 正確結構：兩個階段，對應兩個序

| 階段 | 運算 | 含意 |
| :--- | :--- | :--- |
| $\le_i$（資訊序） | 對因子 $\mathrm{join}$ | 群體**知道**什麼。矛盾令聯合資訊成 $\mathrm{Bv}$，但**只在該處**。$\mathrm{join}$ 單調、不遺忘 —— 這就是「一邊持有矛盾、一邊繼續」的具體含義 |
| $\le_t$（真值序） | 投影到仍**可用**的真值 | 把 $\mathrm{Bv}$ 降解成**兩個可操作分支**（$\mathrm{Tv}$ 與 $\mathrm{Fv}$），而**不是**否決票 |

$\mathrm{truth\_available}(\mathrm{Bv}) = [\mathrm{Tv}, \mathrm{Fv}]$ —— 這一行就是「降解」的全部內容：矛盾被**拆成兩支**而非**刪除**。

#### 窮舉：$B_4^4$ 全部 256 個配置，逐個規則點算

「唔爆炸」只有在**窮舉**之後才有意義；否則只代表「我試過嘅例子冇爆」。

| 規則 | 爆炸 /256 | 空洞 | 丟失因子 | 通過 |
| :--- | :--: | :--: | :--: | :--: |
| `NaiveJoin` | **225** | 0 | 0 | ✗ |
| `QuarantineFirst` | **255** | 0 | 0 | ✗ |
| `Scoped` | **110** | 0 | 0 | ✗ |
| `Weighted` | 0 | 0 | **0** | 但**丟失四值結構** |
| **`Bilattice`** | **0** | **0** | **0** | **✓** |

```text
[M10] consensus census (ALL 256 configs of B_4^4)
        naive:expl=225 quarant:expl=255 scoped:expl=110 weighted:expl=0
        bilattice:expl=0 vac=0 lost=0 carrying=65 manufactured=50 | rule=Bilattice
```

**兩個矛盾機制必須分開**（這是本輪的新發現）：

| 機制 | 判據 | 數量 | 含意 |
| :--- | :--- | :--: | :--- |
| **本地持有**（carried） | 聯合資訊 $=\mathrm{Bv}$ 且**某座標本身是** $\mathrm{Bv}$ | 65 | 有主矛盾：某子群自己不一致 |
| **製造**（manufactured） | 聯合資訊 $=\mathrm{Bv}$ 但**冇任何座標是** $\mathrm{Bv}$ | 50 | 由 $join(\mathrm{Tv},\mathrm{Fv})=\mathrm{Bv}$ **無中生有** —— 兩個各自完全古典的子群互相不同意 |

第二個機制正是擊敗所有 join 型規則的原因：`Scoped` 已隔離顯式 $\mathrm{Bv}$，仍爆炸 110 次，全部由此而來。**製造的矛盾沒有主，所以不能靠「隔離有主者」解決。**

#### 接線進 M6：四層 = 四個子群

`[M6]` 行現在直接印出因子：

```text
[M6] ... | colony factor info=B avail=2 carrying=false | PASS = true
```

Flow 與 Trop-Kan 兩層**互相不同意**（$\mathrm{Tv}$ vs $\mathrm{Fv}$），聯合資訊因此是 $\mathrm{Bv}$ —— 而**閉環照樣收斂**（`iterations=13`、`residual=7.30e-04`、`ρ=0.65`）。$\mathrm{available}=2$ 表示兩個分支都仍可操作。這正是「打交佢都會繼續比你完成件事」的實測證據，而**不是**一個旗標。

舊的 `microlocal_quarantined : Bool` 保留為**衍生視圖**，測試斷言它必須等於因子的矛盾清單，不得成為獨立旗標。

## 開發迴圈約定

本地與代理的迭代測試**只跑 `wasm-gc` 單一後端**（`moon test --target wasm-gc`）。四後端交叉驗證交由 CI 執行，避免每次改動都付出四倍時間成本。

## 授權

Apache-2.0（合併自 `vv0101v01/algorithm04` 與 `vv0101v01/algo8`，兩者皆為 Apache-2.0）。
