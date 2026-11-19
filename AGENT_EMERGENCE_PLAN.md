# 數理類智能體湧現路線圖與前端 NL2Math 小模型規格

> 適用套件：`arena/super_emergence` v2.0.0
> 對象：承接 26 大數學結構 / 18 條複合定理 / 31 條基礎定理 / 四層湧現引擎之後續工作

---

## 零、術語界定：何謂「數理類智能體」

本專案所稱**數理類智能體**（Mathematical Quasi-Agent, MQA）**不是**語言模型驅動的 agent。它是一個由以下四要素組成的**數值計算實體**：

1. **狀態**：元素於 $\mathcal{M}^{m|n}_c$（超流形）之座標 $(x,\xi,\eta,\mathcal{I})$；
2. **動力學**：SGNE-Flow 之 Wasserstein–Fisher–Rao–Berezin 擴散 + 超對稱熱流，屬於**耗散梯度流**而非離散符號推論；
3. **角色**：由自發對稱破缺湧現之四種軌道物種（Coordinator / Sensor / Planner / Executor），**由超質量軌道距離 $d_{\mathcal{O}}$ 自動分派**，非人工指定；
4. **信念狀態**：Belnap 四值 $\{N,F,T,B\}$ 語意，允許被隔離之矛盾（dialetheism）共存。

因此「智能」在此**不是**語言理解能力，而是：*在嚴格公理系統內，以可證偽的數值不變量維持世界模型，並在相變點自發產生功能分工*。

---

## 一、現況盤點（v2.0.0）

| 維度 | 現況 |
| :--- | :--- |
| 數學結構 | 26 個（含 Tier 0 之正交核心 24 個 + 橋接層衍生結構） |
| 複合定理 | 18 條，全部機器精度驗證（殘差 $\le 10^{-9}$，除定理 XVI 之 `9.68e-01` 為隔離度指標） |
| 基礎定理 | 31 條，黑盒測試覆蓋 |
| 湧現層 | 4 層：`SGNE-Flow` / `SGNE-Trop-Kan` / `SGNE-Germ-Micro` / `SGNE-Syn-Mem-Para` |
| 角色 | 8 個原型單元 → 2 Coordinator / 2 Sensor / 2 Planner / 2 Executor |
| 測試 | 82/82，四個本地 targets 一致（native／wasm-gc／wasm／js；含 M2.1–M2.4、M3.1–M3.3、M4–M6） |
| 後續路線圖 | 見第四節（M7+） |

---

## 二、近期路線圖（M1–M3，v2.1 – v2.3）

### M1 — 把「湧現」變成可持續的動力學（v2.1）

**目標**：現行 `SGNE-Flow` 為**有限步數模擬**，角色分工一旦收斂即停止。要讓智能體持續運行，須引入**自持（self-sustaining）**迴圈。

| 工作項 | 具體內容 | 驗收標準 |
| :--- | :--- | :--- |
| M1.1 | **外生擾動通道**：於 WFR 流中加入可控噪聲項 $\sigma\,\Xi(t)$，並保留守恆量與耗散量之分離計算 | 質量守恆誤差仍 $<10^{-12}$ |
| M1.2 | **角色再配置（re-role）**：當環境訊號（外生擾動頻譜）改變時，以 $d_{\mathcal{O}}$ 重新指派角色，檢驗分工是否可逆 | 分配置換後 $d_{\mathcal{O}}$ 仍分為四叢 |
| M1.3 | **長時程穩定性**：$10^5$ 步連續積分之自由能單調性 | $\dot{\mathfrak{F}}\le 0$ 全程成立 |
| M1.4 | **閘控記憶持久化**：將 `role_memory_profiles` 之保留率與環境 Hurst 指數掛鉤 | 吸收時間序隨 Hurst 單調變動 |

**實作狀態（2026-11-18）**：M1.1–M1.4 全部落地並加入常駐測試、CLI 與 CI Gate 7 驗收；各後續里程碑的完成狀態分別以本文件對應章節為準。

- **M1.1**：`SuperBeltramiPDE::step_with_exogenous_perturbation` 對有限體積密度加入可控的 `sigma * Xi(t)` 加性擾動；先投影到 Berezinian 加權零質量切空間，再以加權機率單純形回縮保正。`WFRFlowStepLedger` 分欄記錄質量、確定性耗散、擾動作功及總自由能變化。輸入格數不符或 forcing 非有限值會標記無效並退回確定性步。32 格、`sigma = 0.2` 的 CLI 質量誤差為 `2.22e-16`；自由能分帳為確定性耗散 `9.71e-4`、擾動作功 `1.37e-4`、總變化 `-8.34e-4`。
- **M1.2**：`reassign_roles_by_orbit_distance` 先依非負擾動功率譜最大頻帶（模 4）循環平移軌道—角色對應，再以 `orbit_space_distance`（`d_O`）最近距離匹配。此純函式在頻譜回復時精確恢復原指派；八個置換質量樣本的四叢大小為 `[2, 2, 2, 2]`，叢間最小距離減叢內最大距離為 `1.53`，頻帶 `0 → 1 → 0` 可逆。
- **M1.3**：原始顯式 `step(0.0005)` 在 100,000 步探測中曾因浮點 roundoff 出現 18,807 次極小正向自由能跳動（最大 `1.39e-16`）。新增 `step_energy_monotone` 回溯與近固定點 stationary hold，`audit_long_time_stability(0.0005, 100000)` 串流檢查每一步，不存整條軌跡；驗收包括 100,000 步完成、實際積分時間、最大已接受 `ΔF` 為零、質量誤差 `<1e-12`、正密度及 Gibbs 平衡距離。拒絕候選的 roundoff 增量另行記帳，與實際軌跡分開。
- **M1.4**：`role_memory_profiles_for_hurst(H)` 以 `f(H)=f(1/2)+2(H-1/2)(1-f(1/2))` 調節每個 forget gate 與 retention（`0 < H < 1`；`H=0.5` 精確還原舊 profile）；`distill_synergetic_memory_para_agent(..., hurst=...)` 將環境指數帶入記憶蒸餾。四階段吸收期的精確尾和為 `4/(1-f)`；當 retention 高時改用此閉式避免 100,000 項截斷造成偏差。五個 Hurst 樣本上各角色吸收時間及平均吸收時間均嚴格遞增，角色內排序維持 Coordinator > Planner > Sensor > Executor。

### M2 — 把「信念」變成可推理的（v2.2）

**目標**：現行 $B_4$ 信念僅做逐點融合，尚無推理鏈。

| 工作項 | 具體內容 | 驗收標準 |
| :--- | :--- | :--- |
| M2.1 | **$B_4$ 上的 Gentzen 式推理**：實作三值／四值邏輯之 cut、substitution、modus ponens | 於 $4^{16}$ 組合上窮舉驗證健全性 |
| M2.2 | **隔離區語意**：被 `quarantined = true` 之命題不得參與 cut，但須可被「修復程序」檢視 | 爆炸仍不可能；修復率可度量 |
| M2.3 | **Epistemic 合併算子**：多世界融合擴充為 Belnap–Gärdenfors–Malitz 資訊偏序上的命名命題聚合 | 結合、交換、冪等；空世界為單位；逐點 join 是最小上界 |
| M2.4 | **Gödel 編碼之推論用法**：以 `godel_encode_finite_set` 表示有限命題集合，使 agent 可對信念做集合運算 | 編解碼往返一致、典範／單射編碼及集合代數恆等式 |

**實作狀態（2026-11-18）**：M2.1–M2.4 已落地，與 M3 一同收錄於 `7693b43` 並推送至 `main`；GitHub Hosted CI run `44394929260` 已對該提交通過。初始 M2 驗收為三後端各 67/67；後續里程碑擴充後的測試數量以最新 CI 為準。

- **M2.1**：新增型別化 B₄ 命題樹、指定值語意 `{Tv, Bv}`、單後件 sequent、cut、同步公式替換與 MP。`Imp` 使用明確的 MP-健全四值條件式；它在 `{Fv,Tv}` 上等同經典蘊涵，但刻意不等同 FDE 材料式 `¬A ∨ B`（後者在 `Bv → Fv` 上會使 MP 失效）。替換依結構遞迴，並保持 sequent 之隔離標記。
- **窮舉策略**：不執行 4,294,967,296 次 CI 迴圈；對 MP 完整列舉 16 個 `(A,B)` 真值類，對 cut 列舉 64 個 `(A,B,C)` 類，並對替換影像的三個 B₄ 值列舉 64 類。其餘自由原子槽以 `16×4^14` 或 `64×4^13` 精確計數，三條路徑各涵蓋 `4^16 = 4,294,967,296` 個 schema-local 組合。複合公式的有效性由其 B₄ 評值歸約至這些類；替換另以公式語意律與 sequent 語意不變性檢查。報表明確標示這是完整的真值類商集，不是假稱實際跑過 43 億次迴圈。
- **M2.2**：`quarantined = true` 的 cut 中介結論、cut 公式出現及 MP 輸入均被拒絕；非相關隔離前提不會被啟用。修復器可逐筆檢視記錄；只有附非空外部證據且提出非 `Bv` 值才解除隔離，仍為 `Bv` 或未提交決定者會保持隔離。修復率定義為「成功解除隔離數／已檢視隔離記錄數」，分母為零時回報 `0.0`；此外保留可執行的 FDE 爆炸反模型。外部證據由呼叫者提供，核心只記錄、不驗真。
- **M2.3**：`MultiWorld::aggregate` 驗證每個 world 的命題和值對齊、名稱唯一；於各命題的 `B₄` 資訊序上逐點取最小上界，未出現命題補 `Nv`，並以字典序典範排序命題名稱。`ParaUniverse::information_join` 與 `paraconsistent_no_explosion` 共用該實作；舊 `merge_pointwise` 保持首個 world 的欄位順序以維持相容。有限稽核窮舉 `B₄` join 的 64 個結合、16 個交換、4 個冪等及 64 個最小上界檢查，另檢查命名聯集的交換、空單位、冪等、結合與錯誤輸入拒絕。名稱比較明確採字典序（而非 MoonBit `String` 預設的短字典序），避免 canonical order 被誤判。
- **M2.4**：`GodelFiniteSet` 將 `{0,…,14}` 子集存為 15-bit mask，再以 `π(|S|, mask)` Cantor 配對作典範 Gödel code；此 API 是明確有界的有限命題全集，不宣稱表示任意有限整數集合。checked API 拒絕越界元素及無效／非典範碼；集合類別支援聯集、交集、差集、對稱差、子集及 array 轉換。稽核對 9 個輸入樣本檢查典範化，並窮舉有界全集的 32,768 個子集做 code→set 往返（因此亦檢查該域上的單射性）；另檢查聯集與交集半格律、單位／零元／吸收、分配律、差集分解、對稱差律、子集律及無效輸入。有限雙完備性證書重用同一稽核。
- **驗證**：M2 初始交付時 `moon fmt`、`moon check --deny-warn`、`wasm-gc`／`wasm`／`js` 各 67/67 與 CLI acceptance 通過；其後 Hosted CI run `44394929260` 對合併 M2/M3 commit `7693b43` 成功。

### M3 — 把「叢」變成可組合的（v2.3）

**目標**：Čech 叢目前是單一固定 patch（3 patch）fixture。

| 工作項 | 具體內容 | 驗收標準 |
| :--- | :--- | :--- |
| M3.1 | **任意 patch 數之 Čech 神經網** | $n=2..6$ 之餘擺與拼接皆滿足 |
| M3.2 | **叢之 Čech 餘擺與超算子 $B$ 的合成** | $\operatorname{hol}(B\circ\text{holonomy}) = \operatorname{hol}(B)\circ\operatorname{holonomy}$ |
| M3.3 | **Čech 叢上之 Čech 範疇** | 範疇公理（結合、單位）機器檢驗 |

**實作狀態（2026-11-18）**：M3.1–M3.3 已落地，接入 Theorem XVII、常駐測試、CLI Gate 7 與 CI 工作流程；與 M2 一同收錄於 `7693b43`，Hosted CI run `44394929260` 已通過。

- **M3.1**：`build_super_operator_bundle(n_sets)` 以逐步 frame $F_i$ 構造 $g_{ij}=F_i^{-1}F_j$ 及 $s_i=F_i^{st}s_0F_i$；驗證器分別儲存 pair 與 genuine triple intersections（不把 pairwise clique 誤當共同交集），並檢查 shape、偶性、對稱／重複頂點一致性、完整 1-cocycle（含 identity／逆轉移）與 patch descent。`glue_section` 在指定共同 trivialization 下回傳拼接截面。固定 canonical fixture 改為同一泛化 builder 的三 patch 呼叫。
- **M3.2**：`coboundary` 實作非交換 Čech 0-cochain 作用 $g'_{ij}=h_i^{-1}g_{ij}h_j$，並同步變換局部截面；閉環 holonomy 按基點 gauge 共軛。常值情形即超算子 $B=\mathrm{Ad}_Q(X)=QXQ^{-1}$，機器檢查逐邊作用與整體 holonomy 作用相容。測試含非平凡四環 holonomy、非均勻且非交換的可逆 gauge，避免只檢查單位 holonomy。
- **M3.3**：`CechCategory` 的物件為 patch、態射攜帶 transition operator；`compose` 按路徑順序作矩陣乘法，`from_bundle` 拒絕不滿足 cocycle、overlap 非傳遞或缺少可合成三重交集的輸入。以所有可合成 patch 四元組窮舉結合律，並對每個態射檢查左右單位律。此有限 patch-pair 類別模型要求 overlap 關係具傳遞性；任意非傳遞覆蓋仍可用 bundle 層的 Čech descent API，但不會被錯誤包裝成此類別。
- **驗證**：M3 commit 的 `moon fmt --check`、`moon info`、`moon check --deny-warn` 與三後端各 70/70 通過；CLI theorem、M3.1–M3.3 acceptance 與 Hosted CI run `44394929260` 均 PASS。其後 M4–M6 已將 Gate 7 擴充為同一 CLI acceptance 門檻（見第三節）。

---

## 三、中期路線圖（M4–M6，v2.4 – v2.6）

### M4 — 奇點胚驅動的「開折」學習

將 Mather 萬有開折（Theorem XII）從**驗證對象**轉為**生成機制**：在有限原型目錄上比較 A3 cusp 與 D4 umbilic 的 miniversal K-unfolding，依需求的角色平衡分支數主動選型，並以 infinitesimal K-versality 與商空間重建殘差驗證控制參數。首版支援 3／4 個**實臨界分支**；回報穩定極小值數，避免把所有臨界分支都誤稱為吸引子。

**實作狀態（本輪）**：`catastrophe_unfolding.mbt` 的 `learn_catastrophe_for_role_branches` 支援 scalar simple-singularity prototypes A3（$\tau=3$）與 D4（$\tau=4$）；目前不宣稱支援任意 ICIS／全 ADE 目錄。A3 slice $x^4-a x^2$ 有 3 個實臨界分支、2 個局部極小；D4 slice $x^3-3xy^2+a(x^2+y^2)$ 有 4 個臨界分支、1 個局部極小。`catastrophe_unfolding_test.mbt` 驗證目標 3／4 的選型、versality、商空間重建與尺度正規化駐點殘差，並拒絕使 A3 分支數值合併的次正規振幅。另修正 `singularity_germs.mbt` 的 scalar germ ADE 分類器，以 Hessian corank 分類，而非把 scalar map differential corank 誤當 ADE corank。

### M5 — 微局部事件驅動的注意機制

以 Sato 微函數之奇異譜 $SS(u)$ 作為「注意力觸發源」：當輸入信號與既有信念在**同一基點**具有反對徑方向時，觸發隔離（`Bv`）而非忽略。不同基點的相反方向不構成碰撞。

**實作狀態（本輪）**：`meromorphic_microfunction.mbt` 的 `microlocal_attention_event` 將同基點相反 conormal 的相交提升為隔離 B₄ 值（`FourVal::join(value, Bv)`），並回報方向、基點一致性及 no-explosion 見證。新增輸入有限性檢查；修正 `micro_product` 未檢查 stalk 基點的錯誤，並在對數微函數乘積尚未支援時明確拒絕，而非靜默丟棄 log 項；另將 microlocal anti-derivative 改為 checked API，對模型無法表示之既有 log 項回傳錯誤。`microlocal_attention_test.mbt` 覆蓋同向／異點不隔離、反向隔離、malformed germ、獨立碰撞 predicate、乘積邊界及積分邊界。

### M6 — 四層引擎之閉環耦合

四層由**串接**（Flow → Trop-Kan → Germ-Micro → Syn-Mem-Para）改成具阻尼的固定點回饋：角色吸收時間調整 Flow 的超質量權重與 Trop-Kan 的蒸餾權重；Flow/Trop-Kan 的觀測決定 Hurst 記憶響應，Germ-Micro 的 catastrophe 類與微局部隔離事件也進入回饋映射。

**實作狀態（本輪）**：`four_layer_feedback.mbt` 的 `audit_four_layer_closed_loop` 每次迭代從共同初始殖民地重跑有限步 Flow，執行加權 Trop-Kan、M4 選型與 M5 注意事件，再以 Syn-Mem 精確吸收時間更新兩組角色權重。`role_weights.mbt` 共用穩定正規化；Flow 與 Trop-Kan 的原等權入口保持相容。報告固定點殘差與**實測**相鄰殘差收縮率；這是特定有限模擬軌跡的數值證據，**不是**完整非線性模擬器的全域收斂定理。`four_layer_feedback_test.mbt` 驗證相容、極端權重與固定點，並回放迭代預算耗盡時回報的 Flow 權重以確認它與殘差／能量同屬最後一次已評估軌跡；CLI 3-step 測例以容差 $10^{-3}$ 收斂，M4/M5/M6 acceptance 與 problem-set 驗證同列 Gate 7。

**本輪本地驗證**：`moon fmt --check`、`moon info`（生成介面雜湊穩定）、`moon check --deny-warn` 及 `native`／`wasm-gc`／`wasm`／`js` 各 82/82 通過；CI Gate 7 腳本（18/18 定理、M1–M6 acceptance 與 36 題 problem-set）亦在本地執行通過。Hosted CI 尚未執行；本輪變更尚未提交或推送。

---

## 四、長期路線圖（M7+，v2.7+）

| 編號 | 主題 | 關鍵未解問題 |
| :--- | :--- | :--- |
| M7 | **超熱帶 × 辛幾何 × 副相容三者之統一範疇** | 三者各自為範疇，其合成是否仍為範疇？ |
| M8 | **$K_0$ 指標作為智能體「複雜度計量」** | 能否以 $K_0$ 指標定義角色的最小描述長度？ |
| M9 | **湧現之可證偽性** | 如何設計外部可觀測量，使「湧現」與「偽裝隨機搜尋」可區分？ |
| M10 | **多智能體間之副相容共識** | 不同 sub-colony 對同一命題給出 $\mathrm{Bv}$ 時，如何達成不爆炸的共識？ |

---

## 五、前端 NL2Math 小模型規格（**非**本 MQA 核心，屬外掛）

### 5.1 定位

NL2Math 小模型**只是**把自然語言陳述翻譯成本專案之**形式化物件**（例如「$2\times2$ 厄米四元數矩陣的特徵值」→ `Hermitian2::hermitian2_eigs`）。它**不參與**任何數值推理——所有推理由 MoonBit 之機器精度驗證器執行。

此設計之三個好處：
1. **可證偽性不受污染**：模型輸出只影響「要驗什麼」，不影響「驗得過不過」；
2. **小模型足夠**：目標是**結構抽取**而非數學推理，數百 M 參數即可；
3. **失敗可觀察**：解析失敗率是一個明確指標。

### 5.2 任務定義

```text
輸入：自然語言數學敘述 s（繁體中文 / 英文）
輸出：形式化查詢 q = (module, function, arguments, expected_property)
```

| 產出欄位 | 型別 | 說明 |
| :--- | :--- | :--- |
| `module` | `String` | `arena/super_emergence` 之模組名（如 `quaternion_ktheory`） |
| `function` | `String` | 公開函式／方法名 |
| `arguments` | `Array[Literal]` | 僅允許**可解析字面量**（數字、布爾、字串、具名結構） |
| `expected_property` | `enum` | `EQUALS` / `APPROX` / `INEQUALITY` / `METRIC` / `LAW` |
| `tolerance` | `Double?` | 僅 `APPROX` 與 `METRIC` 需要 |
| `confidence` | `Double` | 解析器對自身解析之把握度 |

### 5.3 禁止事項（硬性）

1. **禁止**輸出任意程式碼片段——只允許**白名單**之 `module::function` 配對；
2. **禁止**輸出 `Float` 以外之非字面量表達式；
3. **禁止**模型自行判定「驗證通過」——判定權歸 MoonBit 測試框架；
4. **禁止**將模型輸出直接寫入任何 `.mbt` 檔案（僅可寫入 `benchmarks/` 之 JSON）。

### 5.4 訓練資料來源

| 來源 | 用途 | 數量級 |
| :--- | :--- | :---: |
| `THEOREMS_AND_ALGORITHMS.md` 之 18 條定理敘述 | 正樣本（敘述 → 查詢） | ~18 × 3 變體 |
| `README.mbt.md` 之 26 結構表列 | 正樣本 | ~26 |
| `THEOREMS.md` 之 31 條基礎定理 | 正樣本 | ~31 × 2 |
| `EMERGENCE_PROBLEM_SET.md` 之問題集 | 混合正／負樣本 | 見該文件 |
| 人工撰寫之 26 條模組之誤導敘述 | **負樣本**（不可解析之敘述） | ~50 |

### 5.5 評估指標

| 指標 | 定義 | 目標 |
| :--- | :--- | :---: |
| **Executable Accuracy (EA)** | 產生之查詢在 MoonBit 中**可編譯且通過**之比例 | ≥ 85% |
| **Property Accuracy (PA)** | `expected_property` 與真實性質一致之比例 | ≥ 90% |
| **Abstention Rate (AR)** | 正確拒答（誠實輸出「無法解析」）之比例 | ≥ 95% |
| **Hallucination Rate (HR)** | 輸出不存在之 `module::function` 之比例 | ≤ 1% |

**關鍵**：AR 與 HR 為**優先於** EA 之指標。一個誠實說「我不確定」的模型，比一個 60% EA 但 20% HR 的模型更有價值——因為後者會把錯誤屬性寫入測試，污染證據鏈。

### 5.6 模型規格建議

| 項目 | 建議 |
| :--- | :--- |
| 架構 |  encoder-only Transformer（BERT-small 級）或 seq2seq（T5-small 級） |
| 參數量 | 30M – 120M |
| 產出格式 | 受限文法（constrained decoding）＋ JSON schema |
| 微調 | LoRA（QLoRA, rank 16）於指令微調之上 |
| 量化 | INT8 / 4-bit |
| 執行 | 本地 GPU 即可；不需雲端 |

### 5.7 整合方式（雙向）

```text
自然語言 ──► NL2Math 小模型 ──► 形式化查詢 JSON ──► MoonBit 測試產生器
     ▲                                                          │
     └────────────── 失敗回饋（編譯錯誤 / 性質不符） ◄────────┘
```

失敗回饋是**唯一**的訓練訊號來源：編譯失敗 → 對齊標籤錯；性質不符 → 對齊 `expected_property` 錯。

---

## 六、里程碑總覽

| 版本 | 目標 | 主要交付 |
| :--- | :--- | :--- |
| v2.0.0 | 雙親統一合併 | 26 結構 / 18 定理 / 31 基礎定理 / 4 層 / 53 測試 |
| v2.1 | 自持動力學 | 外生擾動、再配置、長時程穩定性、動態保留率 |
| v2.2 | 可推理信念 | $B_4$ 推理、隔離修復、Epistemic 聚合、Gödel 指稱 |
| v2.3 | 可組合叢 | 任意 patch 數 Čech 神經網、餘擺合成、叢上範疇 |
| v2.4 – v2.6 | 開折學習、微局部注意、四層閉環 | M4 / M5 / M6 |
| v2.7+ | 統一範疇、複雜度計量、可證偽性、多殖民共識 | M7 – M10 |

---

## 七、工程紀律

1. **定理證據鏈**：任何新增定理都必須有機器精度證據鏈，並納入 `verify_all_theorems()`；未有證據鏈的定理不得寫入文件。
2. **CI 為唯一驗收事實來源**：CI workflow 的七個 gates 為唯一正式驗收紀錄；本地通過不得表述為 CI 通過。格式及公開介面漂移須由完整 CI 偵測。
3. **橋接層單向性**：Tier 0 不得依賴 Tier 2；違反即退回。
4. **常駐回歸測試**：每項已修復缺陷均須有對應的常駐回歸測試（另參見 `MERGE_ANALYSIS.md` 第六節）。
5. **範圍誠實**：M4 僅為有限 A₃／D₄ scalar 正常形原型；M6 的收斂結論僅限實測殘差軌跡，不得寫成完整非線性系統全域定理。
