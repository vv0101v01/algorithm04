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
