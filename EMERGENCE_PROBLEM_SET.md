# 數理類智能體 emergence 問題集

> 目的：**迫出**（而非僅描述）數理類智能體之能力。
> 對應套件：`arena/super_emergence` v2.0.0
> 機器可讀版本：`benchmarks/emergence_problem_set.json`

---

## 零、命題原則

本問題集刻意**不**採「已解／未解」二分。每題皆以**可執行的斷言**表述，並標註：

| 標記 | 意義 |
| :--- | :--- |
| `EXACT` | 恆等式，須在機器精度內精確成立 |
| `INEQUALITY` | 嚴格不等式，須有可觀察的間隔 |
| `LAW` | 恆等式加條件（例如 Lipschitz 常數 $\le 1$） |
| `METRIC` | 距離／度量公理 |
| `EXISTENCE` | 存在性（須給出構造） |
| `COUNTEREXAMPLE` | 須找到一個**否定**某命題之具體反例 |

**核心原則**：一道題若能被「看起來合理但其實錯」的程式蒙混過，則不合格。因此所有題目皆附**反例方向**（若為 `COUNTEREXAMPLE`）或**雙向交叉驗證**（兩個獨立實作給出同一數值）。

---

## 一、Schur–Berezin 超質量軌道（P1–P6）

### P1 — 舒爾–貝雷津有效質量恆等式 `EXACT`

給定 SPD 玻色質量 $M$ 與奇 Yukawa 耦合 $\Xi$，Schur–貝雷津標準形給出

$$M_{\mathrm{eff}} = M + \Xi\,\Omega^{-1}\,\Xi^{\mathsf T}.$$

**斷言**：$\|M_{\mathrm{eff}} - M - \Xi\Omega^{-1}\Xi^{\mathsf T}\|_F < 10^{-13}$。

**關聯**：`super_mass_orbit.mbt`、`unified_bridges.mbt::schur_effective_mass_identity`。

### P2 — 靈魂修正之純費米性 `EXACT`

**斷言**：$\Delta M = M_{\mathrm{eff}} - M$ 之偶體（body）投影為零矩陣，且 $\|\Delta M\|_{\mathrm{soul}} > 0$。

> **陷阱**：奇–奇 Schur 修正之偶體恆為零，故**不可**用 $\Delta M$ 之經典特徵值最小值作為「位移非零」之證據。

### P3 — Schur 重心為 MGU 不變量 `EXACT`

**斷言**：對任意 $\mathrm{OSp}(m|2k)$ 變換 $U$，$U^{\mathrm{st}}\mathcal{I}U$ 之特徵值集合與 $\mathcal{I}$ 相同。

### P4 — Metriplectic 恆等式 `EXACT`

**斷言**：$A^{\mathsf T}\Omega + \Omega A = -\gamma\Omega$，其中 $A=\begin{pmatrix}0 & -K(q)\\ K(q) & -\gamma\mathbb{I}\end{pmatrix}$。

### P5 — 保守子流之辛保持 `EXACT`

**斷言**：$J^{\mathsf T}\Omega J = \Omega$ 且 $\det J = 1$，$J = \exp(\Delta t\,A_c)$。

### P6 — 能障逃逸之相對性 `INEQUALITY`

**斷言**：同一雙阱實例下，保守流逃逸數為 $0$，metriplectic 流逃逸數 $>0$，且保守流之最大能量嚴格小於能障高度。

---

## 二、Belnap $B_4$ 副相容邏輯（P7–P12）

### P7 — 資訊序格律 `EXACT`

**斷言**：對 $B_4$ 全部 $16$ 對 $(a,b)$，$\text{meet}(a,\text{join}(a,b))=a$ 且 $\text{join}(a,\text{meet}(a,b))=a$。

### P8 — 真值序格律 `EXACT`

**斷言**：對全部 $16$ 對，$\text{land}(a,\text{lor}(a,b))=a$、$\text{lor}(a,\text{land}(a,b))=a$，且 $\text{land}$ 為真值序之 glb、$\text{lor}$ 為其 lub。

> **陷阱**：舊實作回傳 $\text{land}(\mathrm{Nv},\mathrm{Tv})=\mathrm{Tv}$，違反 $\mathrm{Fv}\le_t\mathrm{Tv}$。

### P9 — De Morgan 對偶 `EXACT`

**斷言**：$\neg(a\vee b) = \neg a \wedge \neg b$（資訊序）與 $\neg(a\wedge b)=\neg a\vee\neg b$（真值序）皆成立。

### P10 — 不爆炸 `COUNTEREXAMPLE`

**斷言**：存在賦值使前提皆為指定值（$\mathrm{Tv}$ 或 $\mathrm{Bv}$）而結論為非指定值（$\mathrm{Fv}$ 或 $\mathrm{Nv}$）。

**關聯**：`para_universe.mbt::explosion_counterexample_exists`。

### P11 — 融合正交性 `EXACT`

**斷言**：多世界融合後，原本在**每個**世界皆一致非指定之命題，融合後仍為非指定。

> **陷阱**：兩世界 fixture 無法維持正交假命題穿越融合——需至少三條命題。

### P12 — Knaster–Tarski `EXISTENCE`

**斷言**：$B_4$ 上每一 $\le_i$-單調映射皆有最小不動點；窮舉驗證 `all_monotone_maps_have_fixed_point`。

---

## 三、Čech 算子叢（P13–P17）

### P13 — 餘擺律 `EXACT`

**斷言**：$g_{\alpha\beta}g_{\beta\gamma}=g_{\alpha\gamma}$ 對所有三元組成立。

### P14 — 截面拼接 `EXACT`

**斷言**：相容局部截面可拼接（`patch_sections` 回 `true`）；不相容者被拒絕（回 `false`）。

### P15 — 餘擺為恆等 `EXACT`

**斷言**：閉合路徑之餘擺 $\prod g \equiv \mathbb{I}$。

### P16 — 交換子跡共軛不變 `EXACT`

**斷言**：$\operatorname{tr}(gAg^{-1}B^{-1}g^{-1}BA) = \operatorname{tr}([A,B])$，對任意可逆 $g$ 成立。

### P17 — 湧現譜隙 `INEQUALITY`

**斷言**：對 $\operatorname{diag}(4,1)$ 型轉移，譜隙為 $3$；加入小量非對角項後譜隙嚴格介於 $2$ 與 $4$ 之間。

---

## 四、辛相調與奴役（P18–P21）

### P18 — 辛恆等式 `EXACT`

**斷言**：$\|M^{\mathsf T}\Omega M - \Omega\|_F < 10^{-9}$（辛 Euler），而顯式 Euler 之同量 $> 10^{-3}$。

### P19 — 面積守恆 `EXACT`

**斷言**：辛 Euler 之相空間面積變化 $<10^{-6}$。

### P20 — 能量漂移序 `INEQUALITY`

**斷言**：同一步長、同一步數下，辛積分之能量漂移**嚴格小於**顯式積分。

### P21 — 奴役收斂 `EXACT`

**斷言**：Haken 奴役迭代之極限與閉式穩定根差 $<10^{-9}$，且誤差比恰為 $|1-\eta\gamma|$。

---

## 五、記憶半群與雙曲範疇（P22–P27）

### P22 — 閉式等於迭代 `EXACT`

**斷言**：$c_t = \dfrac{i\kappa(1-f^t)}{1-f}$ 與 $t$ 次迭代之差 $<10^{-9}$。

### P23 — 吸收時間雙演算法 `EXACT`

**斷言**：Neumann 線性求解 $(I-Q)t=\mathbf{1}$ 與存活機率尾和 $\sum_k\Pr(X_k\neq\text{absorbed})$ 之差 $<10^{-6}$。

### P24 — 終物件唯一性 `EXACT`

**斷言**：任一物件至終物件之箭頭數為 $1$，且該箭頭唯一。

### P25 — 拉回之中介映射 `EXACT`

**斷言**：相容錐有唯一中介映射；不相容錐**無**中介映射（必須回 `Err`，不得回 `Ok`）。

### P26 — Cantor 配對往返 `EXACT`

**斷言**：$\pi^{-1}(\pi(a,b)) = (a,b)$ 對所有抽樣成立；配對為單射。

### P27 — Gödel 集合編碼之集合不變性 `EXACT`

**斷言**：$\mathrm{code}(S)$ 只依賴集合 $S$，與其呈現次序無關；且 $\mathrm{decode}(\mathrm{code}(S)) = S$。

> **陷阱**：位數展開 $\sum (s_i+1)(n+2)^i$ 依賴次序，且與解碼不一致。

---

## 六、類智能體湧現層（P28–P33）

### P28 — 角色分工 `EXACT`

**斷言**：$8$ 個原型單元於 SGNE-Flow 後分為 $2+2+2+2$ 四叢，且每叢之超質量軌道距離 $d_{\mathcal{O}}$ 與策略概率 $p$ 具明顯分離。

### P29 — 自由能單調性 `EXACT`

**斷言**：$\dot{\mathfrak{F}} \le 0$ 全程成立；質量守恆誤差 $<10^{-12}$。

### P30 — 幽靈相變 `INEQUALITY`

**斷言**：臨界平手初態下幽靈比例為 `8/8`，SGNE-Flow 後為 `0/8`。

### P31 — 角色吸收時間嚴格序 `INEQUALITY`

**斷言**：$t_{\mathrm{Coord}} > t_{\mathrm{Plan}} > t_{\mathrm{Sense}} > t_{\mathrm{Act}}$。

### P32 — WTA Tangible/Ghost 對偶 `EXACT`

**斷言**：嚴格極大 $\Rightarrow$ Tangible；極大並列 $\Rightarrow$ Ghost；二相互斥且窮盡。

> **陷阱**：幽靈偵測若只比較「最大值 vs 次大值」，並列極大將被誤判為 Tangible。

### P33 — 有限雙完全性 `EXACT`

**斷言**：有限範疇之極限（拉回）與餘極限（推出）皆存在且唯一；Gödel 編碼為單射。

---

## 七、跨層整合（P34–P36）

### P34 — 定理總數 `EXACT`

**斷言**：`verify_all_theorems().length() == 18`，且每一報告之 `passed == true`。

### P35 — 跨後端一致性 `EXACT`

**斷言**：同一輸入下，`wasm-gc` / `wasm` / `js` 三後端之輸出在 $10^{-9}$ 內一致。

### P36 — 介面零漂移 `EXACT`

**斷言**：`moon info` 後 `pkg.generated.mbti` 與 `cmd/main/pkg.generated.mbti` 均無變更。

---

## 七之二、Mora 切線錐算法（P37–P40）

### P37 — Mora 弱正規形於非良序局部序上終止 `EXACT`

**斷言**：在 `x < 1` 的局部序下，以單一生成元 $x - x^2$ 化簡 $x$，Mora 弱正規形在有限步內回傳 $0$，且 `inserted_reducers > 0`（ecart 插入機制確實啟動）。

> **陷阱**：樸素除法會產生 $x 	o x^2 	o x^3 	o \cdots$ 的無限下降；任何「看起來終止」的實作都必須能報出插入次數。

### P38 — 標準基與切線錐重數 `EXACT`

**斷言**：對 $I = \langle xy,\ x^2 - y^3 
angle$，Buchberger–Mora 給出 3 個元素的標準基、`standard = true`；切線錐維數 $0$、重數 $5$、Hilbert 函數 $[1,2,1,1,0,\dots]$。

> **陷阱**：只用生成元的最低次齊次部分作錐（$\langle xy, x^2 
angle$）會誤判為一維並漏掉嵌入分量；正確錐由標準基 $\{xy,\ x^2 - y^3,\ y^4\}$ 的初始單項 $\langle xy, x^2, y^4
angle$ 決定。

### P39 — 牛頓多面體之 toric／Koszul 二分 `EXACT`

**斷言**：$x^2 - y^2$ 的總次數初始形為混合二項式（`mixed_toric_face = true`、`semigroup_rank = 2`）；$x + y^2$ 的總次數初始形為單項 $x$（`monomial_cone = true`）。兩者與 Mora 錐報表一致。

> **陷阱**：$x^2 - y^3$ 的總次數最小面是單獨的 $x^2$（度 2 < 度 3），不可誤報為混合二項式。

### P40 — 錐認證的 M4/M6 `INEQUALITY`

**斷言**：`audit_four_layer_tangent_cone_loop(flow_steps=3, ...)` 收斂且 `fixed_point_residual <= 1e-3`、`empirical_contraction_factor < 1`、`cone_dimension == 1`、`band_cycle_reversible = true`；A3 臨界簇錐重數 $2$（非 conical），D4 臨界系統錐重數 $4$（conical）。

> **陷阱**：角色覆蓋必須來自實際 Flow/Trop-Kan 末態；以 Flow 末態原始質量作 $d_{\mathcal{O}}$ 會退化為單叢，不可宣稱四叢。

---

## 七之三、ADE 分類、截斷審查、微局部乘積（P41–P45）

這一節的五道題全部由「**先證明會失敗**」而來：每一道都附一個具體的錯誤版本輸出，說明為什麼舊的檢查不夠。

### P41 — ADE 分類器完整性 `EXACT`

**斷言**：`classify_contact_equiv_class` 對下列 germ 回傳下列 label：

| germ | 多項式 | label | (μ, τ, corank) |
| :--- | :--- | :--- | :--- |
| $A_1$ | $x^2$ | `A_1 (Nondegenerate)` | (1, 1, 0) |
| $D_4$ | $x^2y+y^3$ | `D_4 (Umbilic)` | (4, 4, 2) |
| $D_5$ | $x^2y+y^4$ | `D_5 (Parabolic Umbilic)` | (5, 5, 2) |
| $D_6$ | $x^2y+y^5$ | `D_6 (x^2 y + y^5)` | (6, 6, 2) |
| $E_6$ | $x^3+y^4$ | `E_6 (x^3 + y^4)` | (6, 6, 2) |
| $E_7$ | $x^3+xy^3$ | `E_7 (x^3 + x y^3)` | (7, 7, 2) |
| $E_8$ | $x^3+y^5$ | `E_8 (x^3 + y^5)` | (8, 8, 2) |
| $T_{3,3,3}$ | $x^3+y^3+z^3$ | `T_{3,3,3} (Triangle)` | (8, 8, 3) |

> **陷阱（實測過）**：$E_6$ 與 $D_6$ 的 $(\mu,\tau,\text{corank})$ **完全相同** $(6,6,2)$。任何只憑這三個數的分類器都不可能分開它們。必須用 **Tjurina 代數** $\mathcal{O}/(f,f_x,f_y)$ 的 Hilbert 函數：$E_6$ 為 $[1,2,2,1,0,\dots]$（socle 度 $3$），$D_6$ 為 $[1,2,1,1,1,0,\dots]$（socle 度 $4$）。
>
> 另外三種舊輸出已記錄為反例：$A_1 \to$ `Map-Germ K-Class`（corank 0 落入 fallback）、$E_7 \to$ `Corank-2 QH (tau=7)`、$E_8 \to$ `Corank-2 QH (tau=8)`、$T_{3,3,3} \to$ `Map-Germ K-Class`（全部是「有標準名字卻回無名 fallback」）。

### P42 — 截斷充分性審查 `COUNTEREXAMPLE`

**斷言**：`audit_truncation_adequacy` 對 $E_8 = x^3+y^5$ 必須回報

| `max_deg` | `mu_at_max_deg` | `mu_at_next` | `stable` |
| :--: | :--: | :--: | :--: |
| 4 | **9** | 11 | **false** |
| 8 | 8 | 8 | **true** |

> **陷阱（實測過）**：截斷不足會**高估** $\mu$。這不是浮點誤差而是**答案錯誤**：同一個 germ 在 `max_deg=4` 給 $\mu=9$（$E_8$ 真值 $8$），在 `max_deg=5` 起才穩定。舊代碼直接把 $9$ 拿去查表，於是回一個錯 label 而測試照樣綠。
>
> **反向陷阱**：截斷也可能**低估**（例如設備 `x^3+y^3+x^2y^2` 在有限階模型裡 $\mu=\tau=4$）。因此唯一安全的做法是比較 $k$ 與 $k+1$ 兩次，而不是加大 $k$ 一次就信。
>
> **核對記錄**：`x^3+y^3+x^2y^2` 的 **仿射** Milnor 數是 $7$（sympy 在 $\mathbb{C}[x,y]$ 上算），但 **局部** $\mu = \dim_{\mathbb{R}} \mathcal{O}_2/(f_x,f_y) = 4$。repo 計的是局部量。三次錯誤的交叉檢核過程（lex 取領項、`Monomial` 物件索引、仿射環）已記錄，避免把工具 bug 誤當成產品 bug。

### P43 — Hörmander Σ-條件 `EXACT`

**斷言**：`hormander_sigma_condition(u, v)` 對

- $u = (x+i0)^{-1}$、$v = (x-i0)^{-1}$：`sigma_hits = 1`、`product_admissible = false`、`leibniz_safe = false`、`forbidden_pairs = [("+i dx","-i dx")]`；
- $u = (x+i0)^{-1}$、$v = u$：`sigma_hits = 0`、`product_admissible = true`、`leibniz_safe = true`；
- 不同基點：`input_valid = false`（不在此點相交）。

> **陷阱（邏輯方向）**：Hörmander（Thm 8.2.10）的條件是「**不存在** $(x,\xi)\in WF(u)$ 使 $(x,-\xi)\in WF(v)$」，即 `WF(u) ⊕ WF(v)` 避開零截面。舊的 `microlocal_attention_event` 只判斷「**存在**一對相反 conormal」，這是存在性命題；乘積定理需要的是**全稱否定**。能證明有碰撞 ≠ 能證明沒碰撞；只有後者才可以放行乘積。

### P44 — Leibniz 一致性窮舉 `EXACT`

**斷言**：`audit_microlocal_leibniz_consistency()` 對 6 個 fixture（$(x+i0)^{-1}$、$(x+i0)^{-2}$、$(x-i0)^{-1}$、$\delta$、$Y$、$pv$）窮舉 $6\times 6 = 36$ 對，回報

```text
fixtures = 36
admissible = 5, rejected = 31
sigma_agrees_with_product = true
order_additivity_defect = 0  (< 1e-12)
certified = true
```

> **陷阱**：Σ-條件與 `micro_product` 必須在**每一對**上同向。任何一對「條件話可乘、實作拒絕」或「條件話不可乘、實作照乘」都是模型內部不一致。實測 $31$ 個拒絕中包含 log 型 germ（模型表達不到，回 `Err`），這屬於**表達限制**，與「Σ-條件判定不可乘」是兩件不同的事，必須分開回報（`product_admissible` 與 `Err` 語意不同）。

### P45 — M6 局部收縮與步長細化 `INEQUALITY`

**斷言**：`audit_m6_refinement_and_local_contraction()` 回報

```text
fixed_point_residual        = 7.30e-04  <= 1e-3
refined_fixed_point_residual= 9.08e-04  <= 1e-3
weight_delta                = 1.81e-04  (r = 0.35 -> 0.175)
local_contraction_radius    = 0.6500    < 1
refinement_consistent = true, local_contraction_certified = true, certified = true
```

> **陷阱**：`empirical_contraction_factor` 是**已走過軌跡**的相鄰殘差比最大值。它證明「這條路收斂」，不證明「附近的軌道也收斂」。固定點需要的是映射的 Jacobian 譜半徑；本輪用**有限差分**估 $\|DT\|_{\max}$（逐座標擾動 $h=10^{-3}$，跑一次完整層傳遞），再乘上阻尼因子得 $\rho = (1-r) + r\|DT\|_{\max}$。
>
> **第二個陷阱**：若 Jacobian 探針與迭代器**不是同一個映射**，測到的收縮率毫無意義。因此本輪把「一次完整層傳遞」抽成 `m6_layer_pass`，迭代器與探針共用。

---

## 七之四、統一範疇、覆蓋可達性、K₀ 複雜度（P46–P48）

三題都由「路線圖上一行模糊問題」變成「可執行判定」。每題都先講**點解本來唔知**，再講**點判定**，最後係**實測答案**。

### P46 — M6.4 角色覆蓋可達性掃描 `EXACT`

**斷言**：`audit_m6_role_coverage_sweep(samples=42, flow_steps=3)` 回報

```text
input_valid = true, samples = 42
max_coverage = 4, min_coverage = 1
coverage_histogram = [0, 31, 10, 0, 1]     // 索引 = 覆蓋數
four_reachable = true, structural_cap = false
```

**點解本來唔知**：`role_coverage_count = 2` 只係最後快照嘅 policy argmax 佔了幾個角色。呢個數字**唔能夠**區分兩種完全唔同嘅情況：

1. **結構上限**：8 個 agent 在任何權重下都佔不滿四角色；
2. **亞穩態**：四叢可達，但閉環收斂到 2。

**點判定**：在權重嘅開單純形上做決定性掃描（4 近頂點 + 6 近邊中點 + 對稱中心 + 31 個 van der Corput 填點）。`max_coverage < 4` ⇒ 結構上限；`= 4` ⇒ 亞穩態。

> **陷阱（我踩過）**：`normalize_four_role_weights` 要求權重**嚴格正**。單純形**頂點**含 0 ⇒ 非法輸入。我第一版用頂點取樣，42 個樣本**全部**回 `input_valid = false`——同「答案係 false」長得一模一樣。必須用開單純形（`eps = 1e-3` 逼近頂點）。

**實測答案**：四叢**可達**（witness = 對稱中心 `[0.25,0.25,0.25,0.25]`），所以 M6 嘅「2」係**亞穩態分工**，唔係結構上限。

> ### ⚠️ 更正（v2.4.5）：`hist[3] = 0` 唔係「三叢不穩定」
>
> 本節初版寫「三叢分工係不穩定平衡」——**錯**。憑直方圖空格推論動力學，冇驗證就落結論。
>
> 正確做法：直接構造剛好 k 個並列最大嘅權重家族（`m6_tie_family_weights`：k 個 1.0 + 其餘 1e-4，正規化），逐個量度：
>
> ```text
> tie_family_coverage = [1, 2, 3, 4]   // k = 1..4
> tie_family_monotone = true
> ```
>
> **並列最大值有幾個，就佔用幾個角色。三叢完全可達。** `hist[3] = 0` 純粹係低差異填點嘅**取樣盲區**。
>
> 測試同時斷言 `tie_family_coverage == [1,2,3,4]` 與 `coverage_histogram[3] == 0`，兩者必須並存。
>
> **由此得出嘅新問題（更根本）**：覆蓋數 = 並列最大值個數 ⇒ M6 嘅覆蓋指標係 **Flow 嘅 softmax 結構性質**，唔係「分工複雜度」本身。要量度真分工，需要一個唔依賴權重並列結構嘅指標。

### P47 — M7 統一範疇（纖維積） `EXACT`

**斷言**：`verify_m7_unified_category()` 回報三腿公理全真、纖維積封閉、單位律、結合律、相位一致，`is_category = true`。

| 腿 | 物件 | 態射 | 合成 | 額外公理 |
| :--- | :--- | :--- | :--- | :--- |
| `SemitropicalCat` | `ST = T ∪ G ∪ {−∞}` | 熱帶仿射 `x ↦ a (∗) x (+) b` | 代入 | `(+)`/`(∗)` 結合；**ghost 理想只對乘法吸收**；平局 `a (+) a = a^ν` |
| `SymplecticCat` | `(q,p)` | 辛 Euler 步 | 迭代 | 零步單位；`‖MᵀΩM − Ω‖_F = 0`；explicit Euler 則 `> 0` |
| `ParaconsistentCat` | `B₄` | `join`/`meet` 生成之一元映射 | 函數合成 | De Morgan 對合；非爆炸；64 三元組結合 |

統一範疇 = 沿 **Maslov 相位**嘅纖維積；態射係三元組，三者相位位移必須相同（否則纖維積對合成不封閉）。

> **陷阱一（數值）**：結合律**必須用容差**判。`Double` 嚴格 `Eq` 對 `(0.1−0.04)−0.04` vs `0.1+(−0.04−0.04)` 給 `false`。呢個唔係建構缺陷，而係說明統一範疇係**半環值範疇**，只 **up to tie tolerance** 結合。
>
> **陷阱二（定律）**：ghost 理想 `G` 只對**乘法**吸收（`T∗G ⊆ G`、`G∗G ⊆ G`）。加法**只在平局**（`tie_tol` 內）才生 ghost。我第一版把「Ghost (+) Tangible = Ghost」當公理 ⇒ `extra_axioms = false`。典型「直覺對但定律錯」。

**實測答案**：**是**，三者合成係一個範疇（up to tie tolerance）。

### P48 — M8 K₀ 角色複雜度計量 `EXACT`

**斷言**：`verify_m8_k0_complexity_measure()` 回報 `additive = monotone = distinguishable = true`、`is_complexity_measure = true`。

**建構**：角色 = 四元數代數 `H` 嘅有限維模，K₀ 類 = 正投影子秩。`mdl(r) = log₂|K₀ class| + 不可約和項數`。角色**本原** ⟺ 不可分解為兩個非零直和。

**判定三條件**（全部計算，非假設）：(a) 直和下加性、(b) 真子模下嚴格單調、(c) 四角色可分辨。

| 角色 | K₀ 類 | 不可約和項 | 本原 | mdl (bits) |
| :--- | :--: | :--: | :--: | :--: |
| coordinator | 1 | 1 | ✓ | 1 |
| explorer | 1 | 1 | ✓ | 1 |
| exploiter | 2 | 2 | ✗ | 3 |
| connector | 1 | 2 | ✗ | **2** |

> **已修嘅真 bug（v2.4.5）**：`role_mdl` 原本 `summands = max(k0_class, 1)`，把和項數與秩綁死 ⇒ `connector` 嘅 mdl 被算成 1 而非 2，令佢同 `coordinator` 完全重合，反而**掩蓋**咗「秩單獨不夠」。現已拆出 `role_irreducible_summands`，測試逐個斷言 `mdl == [1,1,3,2]`。注意 `coordinator` 與 `explorer` 連 mdl 都相同（皆 1），在此計量下**不可分辨**。
>
> **陷阱一（直和）**：**唔可以**用生成元數值相加做直和。`diag(1,0) + diag(0.5,0.5) = diag(1.5,0.5)` **唔係投影子**，秩崩 ⇒ `additive = false`。必須用**塊對角** `Mat₁₆(R)`（即 repo 原有 `k0_direct_sum_index`）。
>
> **陷阱二（單調性）**：**唔可以**用「生成元減半」測單調性。投影子減半**唔再係投影子**，該測試在數學上無意義，只會給假失敗。要在有定義嘅地方測（真直和項），加埋「加同一 C 保序」。
>
> **已寫入測試嘅限制**：`explorer` 與 `connector` **秩皆為 1**，所以**秩單獨分唔開四角色**，必須連同不可約和項數。測試明確斷言 `rank_one >= 2`，若未來角色改成秩全異，呢條測試會失敗，逼使重新審視。

**實測答案**：**可以**，K₀ 指數係真計量——但**只**在同時使用「秩 + 不可約和項數」時才分得開四個角色。

---

## 七之五、可證偽性與副相容共識（P49–P50）

### P49 — M9 湧現可證偽性 `INEQUALITY`

**斷言**：`audit_m9_emergence_falsifiability(ensemble=64)` 回報

```text
null_mean = -0.163    alt_mean = +0.851    threshold = +0.348
false_positive_rate = 0.047    power = 1.000
separates = true, has_discriminating_power = true
```

**為何這叫可證偽**：三個要素缺一不可 ——

1. **零假設**：同一目標、同一步數、同等評估預算的**獨立隨機遊走**（刻意不弱化）；
2. **分離觀測量**：`r = 1 − Var(x)/Var(x₀)`（Kuramoto 型同步序參數）。獨立遊走永遠擴大方差（`r < 0`），鄰居耦合永遠收縮方差（`r → 1`）；
3. **檢定力**：報 `power` 而非只報 p 值。若 `power ≤ fpr`，CLI 直接變 `PASS = false`。

> **陷阱一（觀測量飽和）**：第一版用「耦合項佔比」，並追蹤**歷史最佳點** ⇒ 兩臂都飽和到 `+1`，`fpr = 0`、`power = 0`、`separates = false`。必須量度**末態**。
>
> **陷阱二（自訂分數）**：觀測量必須是**標準量**（Kuramoto 序參數），不可為了令測試通過而砌分數。

### P50 — M10 多 sub-colony 副相容共識 `EXACT`

**斷言**：`verify_m10_subcolony_consensus()` 在固定 fixture 家族（0/1/2/幾乎全部/全部 矛盾 + 全 Nv）上量度四條規則：

| 規則 | 爆炸 | 空洞 | 忠實 | 通過 |
| :--- | :--: | :--: | :--: | :--: |
| `NaiveJoin` | **3** | 0 | 1/6 | ✗ |
| `QuarantineFirst` | **4** | 0 | 0/6 | ✗ |
| `Scoped` | **2** | 0 | 2/6 | ✗ |
| `Weighted` | **0** | **0** | **4/6** | ✓ |

> **陷阱一（全域 join）**：`join(Bv, x) = Bv`，單一矛盾子群永久污染全群。
>
> **陷阱二（反直覺）**：`epistemic_quarantine_map` 把 `Fv`、`Tv`、`Bv` **全部**映到 `Bv`。所以「每個輸入先做副相容處理，再古典聚合」會把**一致意見變成矛盾** —— 比唔處理更差（爆炸 4 次 vs 3 次）。這是標準錯答。
>
> **陷阱三（最關鍵）**：只隔離**顯式** `Bv` 仍然爆炸，因為 `join(Tv, Fv) = Bv` —— 兩個**古典但相反**的子群一碰就生矛盾，而**冇任何子群報過** `Bv`。所以問題不是「隔離矛盾」，而是**古典分歧本身不能用格上 join 解決**。這條是我第一版的真實錯誤（`scoped` 仍 `exploded=2`）。
>
> **陷阱四（判準）**：`vacuity` 不可把「平局 → Nv」當空洞。真正的空洞是「古典子群**一致**卻仍報 Nv」。誤判會令正解 `weighted` 得 `vacuous=2`、`passes=false`。

**正解形狀**：信心加權投票 + `contested` 旗標。單一矛盾子群或單一高分異見者都**不能否決**；平局報 `Nv` 而唔係 `Bv`（「冇多數」≠「兩者皆真」）。

**誠實代價**：加權規則**不是**格同態，**不是**對 `join` 單調 —— 向 Fv 多數群加一個 Tv 子群可以反轉結果。這對投票是正確的，對格是不可能的。測試同時斷言能力與限制。

---

## 八、評分方式

| 維度 | 權重 | 說明 |
| :--- | :---: | :--- |
| **可執行性** | 40% | 題目可被轉寫為 MoonBit 斷言並通過 |
| **雙向性** | 25% | 有反例方向或雙演算法交叉驗證 |
| **陷阱覆蓋** | 20% | 涵蓋本專案實際修復之缺陷類型（見 `MERGE_ANALYSIS.md` 第六節） |
| **層次覆蓋** | 15% | 覆蓋 Tier 0 至 Tier 2 全部三層 |

---

## 九、機器可讀格式

見 `benchmarks/emergence_problem_set.json`。每題含：

```json
{
  "id": "P01",
  "title": "...",
  "kind": "EXACT",
  "module": "arena/super_emergence",
  "function": "schur_effective_mass_identity",
  "expected": { "op": "<", "value": 1e-13 },
  "trap": "不可使用 ΔM 的經典特徵值最小值作為位移非零之證據",
  "related_bugs": ["BUG-15"]
}
```

`related_bugs` 欄位使每一題可回溯至其對應之已修復缺陷，使本問題集同時充當**回歸測試之規格來源**。
