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

**本輪本地驗證（M4–M6 v1）**：`moon fmt --check`、`moon info`（生成介面雜湊穩定）、`moon check --deny-warn` 及 `native`／`wasm-gc`／`wasm`／`js` 各 82/82 通過；CI Gate 7 腳本（18/18 定理、M1–M6 acceptance 與 36 題 problem-set）亦在本地執行通過。

**M4.2 / M6.2（切線錐算法輪次，最新）**：問題集擴充至 40 題（P37–P40），測試數增至 89；`moon run cmd/main` 之 `[Mora.*]`、`[Newton]`、`[M4.2]`、`[M6.2]` 六行均為 `PASS = true`，Gate 7 已加入對應 grep 檢核。詳見下方「M4.2、M6.2：Mora 切線錐算法」小節。

---

### M4.2、M6.2：Mora 切線錐算法（v2.4.2）

**目標**：把「切線錐」從文件中引用的概念，變成可執行的局部標準基引擎，並讓 M4 選型與 M6 回饋由錐的**機器認證**驅動。

| 工作項 | 具體內容 | 驗收標準 |
| :--- | :--- | :--- |
| M4.2a | **Mora 弱正規形**（LNF）：ecart 最小化、`ecart(g) > ecart(h)` 時把當前 `h` 插入 reducer 集 | 經典非良序例 `x - x^2` 於 2 步內得 NF = 0，且 insertions > 0 |
| M4.2b | **Buchberger–Mora** 標準基 + 切線錐報表（重數、維數、Hilbert 函數、錐方程、conical、lineality） | `<xy, x^2 - y^3>`：basis = 3，standard = true，dim = 0，重數 = 5，H = [1,2,1,1] |
| M4.2c | **牛頓多面體**與 toric/Koszul 二分；以固定原型權重目錄記錄法扇 | `x^2 - y^2` 為混合二項式（rank 2），`x + y^2` 為單項（Koszul 側），

兩者皆與 Mora 錐一致 |
| M4.2d | **切線錐認證的 catastrophe 選型**：A3 臨界簇 `4x^3 - 2ax = 2x(2x^2 - a)`（錐 = 2 線，非 conical，3 個實臨界點）；D4 臨界系統兩條二次方程（錐 = 4 線，conical，4 個實臨界點） | 目標 3/4 選型與 Milnor、τ 交叉檢查全部通過；非法輸入被拒絕 |
| M6.2 | **錐認證的四層閉環**：角色覆蓋 → M4 錐認證（含失敗回退）→ M5 微局部隔離 → Syn-Mem 吸收時間 → Flow／Trop-Kan 權重；頻帶由錐重數與隔離壓力決定，並檢驗 `0 -> band -> 0` 可逆 | 13 步收斂，殘差 7.30e-04 < 1e-3，實測收縮率 0.65，權重歸一化缺陷 < 1e-12，頻帶可逆，非爆炸保持 |

**範圍誠實**：`mora_tangent_cone.mbt` 在截斷局部代數 $O_n^{(k)}$（`max_deg` 有限）上以**數值精確**（coeff 比較用 1e-12 容差，所有輸入為整係數）模擬標準基；這是有限截斷下的機器證據，不宣稱無限階冪級數環的等式證明。`conical` 為**充分**認證：經 `in(generators)` 重新認證成功即回 true，否則 false 不代表已證明非錐。`dimension`/`multiplicity` 對 1 維情形取 Hilbert 函數的穩定值（對齊次初始理想精確）；CRT 截斷下 `multiplicity` 為 ≤ `max_deg` 內的可計算量。頻帶可逆性為**特定質量樣本與頻譜**上的純函數檢驗，非角色分配器的全域可逆性定理。

**本輪本地驗證**：`moon fmt --check`、`moon check --deny-warn`、`moon info`（`.mbti` 已更新）、`moon test`（wasm-gc 89/89；wasm/js 同）以及 Gate 7 腳本（18/18 定理、M1–M6 與 M4.2/M6.2 acceptance、40 題 problem-set）全部通過。

---

### M4.3 / M5.2 / M6.3：把「唔得」的地方逐項量度並修好（v2.4.3）

上一輪（v2.4.2）交付了 Mora 切線錐算法、M4.2、M6.2。但是**「有測試通過」不等於「做法正確」**。本輪先用可執行的量度把三個里程碑的缺口逐個找出來，再逐個修，最後用新的 CLI 驗收線（`[M4.3]` / `[M5.2]` / `[M6.3]`）鎖住。

本次量度方法一律是「**先寫一支會在錯誤前提下失敗的檢查**」：能通過的檢查不算證據；能**區分**兩種情況的檢查才算證據。

---

#### M4 的問題（三項，全部已修）

| # | 症狀（實測） | 為什麼這是真問題 | 修法 | 修正後實測 |
| :--: | :--- | :--- | :--- | :--- |
| M4-a | `A1 (x²)` 回傳 `"Map-Germ K-Class (p=1, crk=0, tau=1)"` | 非退化臨界點是 ADE 的 `A_1`，被 fallback 吸走等於分類器在最基礎的一類上失效 | 加入 `crk == 0` 分支 → `"A_1 (Nondegenerate)"` | `corank=0`、label = `A_1 (Nondegenerate)` |
| M4-b | `E6 = x³+y⁴` 與 `D6 = x²y+y⁵` 都回 `"E_6 / D_6"` | 兩者 `(μ, τ, corank) = (6, 6, 2)` **完全相同**，舊版用表格硬編碼，等於承認分不開。分類器必須用真正的不變量 | 用 **Tjurina 代數的 Hilbert 函數**（`O/(f, f_x, f_y)` 逐次數維度）區分：E6 = `[1,2,2,1,0,…]`（socle 度 3）、D6 = `[1,2,1,1,1,0,…]`（socle 度 4） | E6 → `"E_6 (x^3 + y^4)"`、D6 → `"D_6 (x^2 y + y^5)"`，兩者 label 不同 |
| M4-c | `E7 = x³+xy³` → `"Corank-2 QH (tau=7)"`；`E8 = x³+y⁵` → `"Corank-2 QH (tau=8)"`；`T_{3,3,3} = x³+y³+z³` → `"Map-Germ K-Class"` | 三類都有名字、都是標準表上的條目，回傳無名 fallback 等於「唔知」卻照樣過測試 | 以 `(crk, n_vars, μ)` 判 E7/E8，以 `(crk=3, n=3, μ=8)` 判 `T_{3,3,3}` | 三者 label 正確；`T_{3,3,3}` 的 `μ = 8 = 2³` |

**M4 最嚴重的一項（第 4 項，機制性）**：**截斷充分性從未被審查**。

`MapGerm` 在 `O_n^{(k)}`（jet 階 `k`）上做運算；`μ` 只在 `k` 足夠大時才等於真值。實測 `E8 = x³+y⁵`：

| `max_deg` | 4 | 5 | 6 | 7 | 8+ |
| :--- | :--: | :--: | :--: | :--: | :--: |
| `μ` | **9** ❌ | 8 | 8 | 8 | 8 |
| `τ` | **9** ❌ | 8 | 8 | 8 | 8 |

也就是說：**同一個 `E8`，換一個 `max_deg` 就得到不同的 Milnor 數，而舊代碼照樣回一個 label**。這不是精度問題，是**答案會錯**。

修法：新增 `audit_truncation_adequacy(f) -> TruncationAuditReport`，在 `k` 與 `k+1` 各算一次 `μ`、`τ`，只有兩次相等才回 `stable = true`；`stable = false` 時附上 `mu_at_next`／`tau_at_next` 供呼叫者加大 `max_deg`。CLI `[M4.3]` 同時驗證 `k=4` 的 `μ=9`（不穩定）與 `k=8` 的 `μ=8`（穩定），確保這條檢查**真係會失敗**，而不是永遠 `true`。

> **範圍誠實**：`x³+y³+x²y²` 的**仿射** Milnor 數是 7（sympy 在仿射環上算），但**局部** `μ = dim_R O₂/(f_x, f_y) = 4`（`O₂` 在 `(0,0)` 的局部化），與奇點表 D5=5、D6=6、E7=7、E8=8 全部吻合。repo 計的是局部量，這是正確的；我在核對時先後三次用錯工具（lex 取領項、`Monomial` 索引、仿射環），特此記錄，避免把「交叉檢核工具的 bug」誤當成「產品的 bug」。

---

#### M5 的問題（兩項，全部已修）

| # | 症狀 | 為什麼是問題 | 修法 | 修正後實測 |
| :--: | :--- | :--- | :--- | :--- |
| M5-a | `microlocal_attention_event` 只判斷「**存在**一對相反的 conormal」，回 `antipodal_collision = true` | 它能證明**有**碰撞，永遠不能證明**沒有**碰撞。而 Hörmander 乘積定理要的正是後者：乘積可定義 ⟺ 對**所有** `(x,ξ)∈WF(u)`，`(x,−ξ)∉WF(v)`。這是「存在 vs 全稱」的邏輯方向錯誤 | 新增 `hormander_sigma_condition(u, v)`：枚舉兩個 germ 的 conormal 全集，回報 `sigma_hits`（碰撞數）、`forbidden_pairs`（具體碰撞對）、`zero_sum_only_trivial`（Hörmander 條件）、`leibniz_safe` | 反向 chirality：`hits=1`、`product_admissible=false`；同向：`hits=0`、`admissible=true` |
| M5-b | 只有 `±i dx` 兩個方向，多方向 conormal（例如 `xy` 的兩支）無法表示 | 真實 germ 可以有任意多個 wavefront 方向；固定在兩個方向等於把 Hörmander 條件偷換成特例 | 新增 `ConormalBundle`（角度 + chirality 的有限集）與 `hormander_sigma_conormal`：把 chirality **折算成角度 + π**（`+i dx` 與 `−i dx` 是相反 covector），再判「相差 π 即碰撞」 | 4 方向 fixture 正確判別 |

**另外加了雙向一致性檢查** `audit_microlocal_leibniz_consistency()`：對 6 個 fixture（`(x+i0)^{-1}`、`(x+i0)^{-2}`、`(x−i0)^{-1}`、`δ`、`Y`、`pv`）窮舉 36 對，逐對比對「Σ-條件判定」與「`micro_product` 實際結果」，並檢查 pole 階數可加性 `ord(u*v) = ord u + ord v`。

實測：`fixtures=36, admissible=5, rejected=31, sigma_agrees_with_product=true, order_additivity_defect=0`。這意味著：**Σ-條件與乘積實作完全一致，冇任何一對「條件話可以、實作拒絕」或反過來的情況**。

> **範圍誠實**：`micro_product` 對 log 型 germ 明確回 `Err`（模型表達不到），所以 31 個被拒配對包含這類情形。Σ-條件只判「乘積是否存在」，不判「本模型能否表示」；兩者已分開回報（`product_admissible` 與 `Err` 是不同欄位語意）。

---

#### M6 的問題（三項，兩項已修、一項明確標為未解）

| # | 症狀 | 為什麼是問題 | 現況 |
| :--: | :--- | :--- | :--- |
| M6-a | `empirical_contraction_factor` 只是**已走過軌跡**的相鄰殘差比最大值 | 它說的是「我走過的這條路收斂」，不是「附近的軌道也收斂」。固定點需要的是**局部收縮**（映射的 Jacobian 譜半徑），不是單條軌跡的觀測 | ✅ 已修：`local_contraction_radius` = `(1−r) + r·‖DT‖_max`，其中 `‖DT‖_max` 由**有限差分**估（逐個權重座標擾動 `h=1e-3`，跑一次完整層傳遞取差商最大值）。實測 `ρ = 0.65 < 1` |
| M6-b | 沒有**步長細化**檢查 | 真正的固定點在 `relaxation → 0` 下不應移動。舊版只報一個 `relaxation` 的結果，細化後收斂到哪裡完全未知 | ✅ 已修：`refinement_consistent` 重跑 `r/2` 的完整迭代，比較兩個不動點的權重差。實測 `r=0.35 → 0.175`、殘差 `7.30e-04 → 9.08e-04`、權重差 `1.81e-04`、判定一致 |
| M6-c | 閉環的**角色覆蓋**只有 2（而非 4 叢） | 這不是 bug，而是如實反映：Flow 末態的 8 個 agent 在 `d_O` 度量下退化為單叢，真正的分工訊號來自 Trop-Kan | ⚠️ **未解，已明確標示**：CLI 報 `role_coverage_count=2`，且在 `[M6.2]` 行如實印出 `cluster_sizes`，**不宣稱**四叢。要真正拿到 2+2+2+2 需要重新設計 Flow 的質量回饋入口（M7 候選） |

**M6 新增診斷的實作要點**：把「一次完整層傳遞」抽成 `m6_layer_pass`（Flow → Trop-Kan → 角色覆蓋 → M4.2 錐認證 → Hurst → Syn-Mem → 目標權重），迭代器 `m6_iterate_to_fixed_point` 與 Jacobian 探針**共用同一個映射**，避免「探針測的映射」與「實際跑的映射」不是同一個東西（這是很常見的自欺）。

---

#### 本輪驗收（新增三條 CLI 線）

```text
[M4.3] ADE classifier | A1/E6/D6/E7/E8/T all named | E6 hilbert-socle separates D6
        | truncation audit: mu=9@k=4 unstable, mu=8@k=8 stable | PASS = true
[M5.2] Hormander Sigma | opposite-chiral hits=1 admissible=false | co-chiral admissible=true
        | Leibniz audit fixtures=36 admissible/rejected=5/31 agree=true | PASS = true
[M6.3] refinement+contraction | r/std r=0.350/0.175 | residual=7.30e-04/9.08e-04
        | weight delta=1.81e-04 | local rho=0.6500 < 1 | PASS = true
```

測試由 89 增至 **94**（新增 5 道：ADE 完整性、截斷充分性、Hörmander Σ、Leibniz 一致性、M6 v3 細化收縮），四後端全綠。

**仍未解、已如實記錄**：M6-c 的 4 叢角色分工；`micro_product` 的 log 型 germ；`tangent_cone_report` 對 `max_deg` 的截斷依賴（`multiplicity` 在 dim≥1 時是穩定值，但 `hilbert_function` 尾部會隨 `max_deg` 變）。這三項已列入 M7 待辦，不再用「PASS」掩蓋。

---

### M6.4 / M7 / M8：三個里程碑的實測答案（v2.4.4）

本輪把 M7、M8 由「路線圖上的一行問題」變成**可執行的判定程式**，並且把 M6 最後一個未解項（角色覆蓋 2 of 4）量度清楚。以下每一節都先寫「點解唔知」，再寫「點判定」，最後寫「實測答案」。

---

#### M6.4 — 角色覆蓋 2 of 4：係結構上限，定係亞穩態？

**問題**：`audit_four_layer_tangent_cone_loop` 報 `role_coverage_count = 2`。呢個數字只係「最後一個快照嘅 policy argmax 佔了幾個角色」，**本身證明唔到**四叢係唔係根本做唔到。如果只講「覆蓋係 2」而唔查，就係用一個輸出掩蓋一個未解問題。

**點判定**：`audit_m6_role_coverage_sweep` 在四角色權重向量嘅**開單純形**上做決定性掃描（4 個近頂點 + 6 個近邊中點 + 對稱中心 + 31 個 van der Corput 低差異填點，共 42 點），每點跑一次完整 Flow + Trop-Kan + argmax，數實際佔用嘅角色數：

- 若 `max_coverage < 4`（整個單純形都達不到 4）⇒ **結構上限**：Flow 嘅 8 個 agent 在任何權重下都無法佔滿四個功能角色，M6 嘅「2」唔係調參失敗。
- 若 `max_coverage == 4` ⇒ **四叢可達**，M6 嘅「2」係**亞穩態分工**（metastable division of labour），係一個更強、亦更唔同嘅陳述。

**實測答案**：

```text
[M6.4] coverage sweep | samples=42 max=4 min=1 hist=[31,10,0,1]
        | four_reachable=true structural_cap=false | PASS = true
```

- `max=4`：**四叢可達**（witness 權重 = 對稱中心 `[0.25,0.25,0.25,0.25]`）。
- `hist=[31,10,0,1]`：31 個取樣只得 1 叢、10 個得 2 叢、**冇任何取樣得 3 叢**、1 個得 4 叢。
- `min=1`：某些權重下完全退化為單叢。

**結論（改寫咗原本的「未解」）**：M6 嘅「2」**唔係結構上限**，而係閉環迭代收斂到嘅**亞穩態分工**。

> ### ⚠️ 更正（v2.4.5）：關於 `hist[3] = 0` 我上一輪講錯咗
>
> 上一版我寫「三個角色嘅分工係不穩定平衡」。**呢個結論係錯嘅，而且錯得可以避免**：我憑一個取樣直方圖嘅空格推論動力學性質，冇做任何驗證就落結論。
>
> 正確做法係**直接構造**剛好 k 個並列最大嘅權重家族（`m6_tie_family_weights`：k 個 1.0 + 其餘 1e-4，正規化），逐個量度：
>
> ```text
> tie_family_coverage = [1, 2, 3, 4]     // k = 1..4
> tie_family_monotone = true
> ```
>
> **即係：並列最大值有幾個，就佔用幾個角色，一個不多一個不少。** 三叢**完全可達**。
>
> 所以 `hist[3] = 0` 嘅真正原因係：**我嘅 van der Corput 低差異填點從來冇產生「剛好三個並列最大」嘅權重**。呢個係**取樣盲區**，唔係動力學性質。
>
> 教訓已寫入測試：`assert_eq(sweep.tie_family_coverage, [1, 2, 3, 4])` 與 `assert_eq(sweep.coverage_histogram[3], 0)` 兩條**並存**，任何未來改動都必須同時滿足「三叢可達」與「隨機掃描掃不到」，唔可以再靠空格推論。

> **一個實作陷阱（我踩過）**：`normalize_four_role_weights` 要求權重**嚴格正**，所以單純形**頂點**（含 0）係非法輸入，我第一次寫 sweep 時用頂點，42 個樣本全部退化為 `input_valid=false`。改為開單純形取樣（頂點用 `eps=1e-3` 逼近）後才跑得通。呢件事寫入文檔，因為「取樣失敗」同「答案係 false」長得一模一樣。

---

#### M7 — 超熱帶 × 辛 × 副相容：合成是否仍為範疇？

**問題**：三者各自係範疇（超熱帶半環、辛相空間、Belnap–Dunn 四值格），但**合成**係唔係範疇，冇人證明過。

**點判定**：`verify_m7_unified_category()` 唔係「宣稱」，而係逐條 axiom 機檢：

| 腿 | 物件 | 態射 | 合成 | 額外公理 |
| :--- | :--- | :--- | :--- | :--- |
| `SemitropicalCat` | `ST = T ∪ G ∪ {−∞}` 的元素 | 熱帶仿射映射 `x ↦ a (∗) x (+) b` | 代入 | `(+)`、`(∗)` 結合律；**ghost 理想只對乘法吸收**；平局 `a (+) a = a^ν` |
| `SymplecticCat` | 相空間點 `(q,p)` | 辛 Euler 步 | 迭代 | 零步為單位；`‖MᵀΩM − Ω‖_F = 0`（辛）；explicit Euler 則 `> 0`（故非此範疇態射） |
| `ParaconsistentCat` | `B₄ = {Nv,Fv,Tv,Bv}` | 由 `join`/`meet` 生成的一元映射 | 函數合成 | De Morgan 對合；**非爆炸**；`join`/`meet` 在全部 64 個三元組上結合 |

統一範疇 = **沿 Maslov 相位的纖維積**：物件係三元組 `(trop, q, p, belief, maslov_phase)`，態射係三元組，且三者嘅相位位移**必須同一個**（否則纖維積對合成不封閉，答案就會係「否」）。

**實測答案**：

```text
[M7] unified category | semitropical=true symplectic=true paraconsistent=true
      | fiber=true id=true assoc(up to tie tol)=true | IS CATEGORY = true | PASS = true
```

**答案：三者合成係一個範疇。** 但有一個**必須講清楚嘅限定**：

> **只在平局容差下成範疇。** 我第一次用 `Double` 嘅嚴格 `Eq` 測結合律，結果 `associativity = false`。查根因：`(0.1 − 0.04) − 0.04` 與 `0.1 + (−0.04 − 0.04)` 在最後一個 bit 唔同。呢個**唔係建構嘅缺陷**，而係說明呢個統一範疇係**半環值範疇**（semiring-valued），所以只 up to tie tolerance 結合。文檔如實記錄，並用 `unified_morphism_nearly_eq(…, 1e-12)` 判。

**第二個踩過嘅陷阱**：我第一版嘅「ghost 吸收」公理寫成 `Ghost (+) Tangible` 應該係 Ghost —— **錯**。`st_add` 只在**平局**（`tie_tol` 內）才生 ghost；ghost 理想 `G` 只對**乘法**吸收（`T∗G ⊆ G`、`G∗G ⊆ G`）。呢個係「直覺對但定律錯」嘅典型，已寫入測試註釋。

---

#### M8 — K₀ 指標能否定義角色嘅最小描述長度？

**問題**：能否用 K₀ 指標做智能體角色嘅複雜度計量？

**點判定**：`verify_m8_k0_complexity_measure()` 分三步，每步都係可計算嘅判據：

1. **角色 = K₀ 類**：角色係四元數代數 `H` 嘅有限維模，其 K₀ 類 = 正投影子嘅秩（整數）。
2. **最小描述長度**：`mdl(r) = log₂|K₀ class| + 不可約和項數`。角色係**本原**（primitive）若且僅若佢唔可以分解成兩個非零角色嘅直和 —— 呢個係 mdl 良定義嘅前提，否則可以用加零對嘅方式假造短描述。
3. **判定**：K₀ 指數係真計量 ⟺ (a) 直和下**加性**、(b) 真子模下**嚴格單調**、(c) 四個角色**可分辨**。三者全部計算，每個都有具名失敗模式。

**實測答案**：

```text
[M8] K_0 complexity | additive=true monotone=true distinguishable=true | 4 roles | PASS = true
```

角色檔案：

| 角色 | K₀ 類 | 不可約和項 | 本原 | mdl (bits) |
| :--- | :--: | :--: | :--: | :--: |
| coordinator | 1 | 1 | ✓ | 1 |
| explorer | 1 | 1 | ✓ | 1 |
| exploiter | **2** | **2** | ✗ | **3** |
| connector | 1 | 2 | ✗ | **2** |

**答案：可以，但有明確限制。**

> **已修嘅真 bug（v2.4.5）**：`role_mdl` 原本寫 `summands = max(k0_class, 1)`，把「和項數」同「秩」綁死。結果 `connector`（K₀ 秩 1、**兩個**和項）嘅 mdl 被算成 **1** 而唔係 2，令佢同 `coordinator` 完全重合，反而把「秩單獨唔夠」呢個限制**掩蓋**咗。現已拆出 `role_irreducible_summands` 獨立計算，測試逐個斷言 `mdl == [1, 1, 3, 2]`。
>
> **限制（已寫入測試，唔可以偷偷改）**：**秩本身分唔開四個角色** —— `explorer` 與 `connector` 嘅 K₀ 秩都係 1。所以 K₀ 秩**單獨**唔夠，必須連同**不可約和項數**（`exploiter` 係 2 項、`connector` 係 2 項）一齊用。測試 `"M8: K_0 gives a genuine role complexity measure"` 明確斷言 `rank_one >= 2`，即**四個角色中最少兩個秩相同**；若未來有人把角色改成秩全異，呢條測試會失敗，迫使重新審視呢個限制。

**我踩過嘅兩個建模錯誤（都已修）**：

| 錯誤 | 症狀 | 根因 |
| :--- | :--- | :--- |
| `role_direct_sum` 用**生成元數值相加** | `additive=false` | `diag(1,0) + diag(0.5,0.5) = diag(1.5,0.5)` **唔係投影子**（秩 2 而非 1.5），所以圓整後嘅 trace 唔係 K₀ 類。正確做法係**塊對角** `Mat₁₆(R)`，即 repo 原有嘅 `k0_direct_sum_index`。 |
| 單調性用「生成元減半」 | `monotone=false`（假失敗） | 投影子減半**唔再係投影子**，所以「half 嘅 K₀ 更細」呢個測試在數學上無意義。正確做法：只在有定義嘅地方測（真直和項），加埋「加同一個 C 保序」。 |

---

#### 本輪新增驗收

```text
[M7]  unified category | IS CATEGORY = true
[M8]  K_0 complexity   | additive/monotone/distinguishable = true/true/true
[M6.4] coverage sweep  | max=4 min=1 hist=[31,10,0,1]
       | tie_family(k=1..4)=[1,2,3,4] monotone=true | four_reachable=true
```

測試由 94 增至 **101**，四後端 101/101。

**仍未解、如實記錄**：
- ~~`hist[3] = 0` 係不穩定平衡~~ → **已推翻**（見上面更正）。三叢完全可達；空格係取樣盲區。**取代它的新問題**：角色覆蓋數 = 並列最大值個數，呢個係 **Flow 嘅 softmax 結構性質**，唔係「分工複雜度」本身。即係話 M6 嘅覆蓋指標**只反映權重設計**。要量度真正嘅分工，需要一個唔依賴權重並列結構嘅指標（M9 候選）。
- `coordinator` 與 `explorer` 連 mdl 都相同（皆 1），在本計量下**不可分辨**。
- `micro_product` 對 log 型 germ 仍回 `Err`（模型表達限制，非 Σ-條件判定）。
- K₀ 秩單獨不足以分辨四角色（見上表）。

---

### M9 / M10：可證偽性與副相容共識（v2.4.6）

---

#### M9 — 湧現之可證偽性：如何使「湧現」與「偽裝隨機搜尋」可區分？

**問題的難處**：呢個 repo 每一個觀測量（policy entropy、role coverage、hyperbolic distance、Hurst）都**可以**由一個完全冇結構嘅隨機搜尋產生。如果一個「湧現指標」分唔開「有結構」同「冇結構」，佢量度嘅係**零**，唔係湧現。

**點做才叫可證偽**：三個要素缺一不可。

1. **零假設（null model）**：一個**結構化**嘅隨機搜尋 —— 同一個目標函數、同樣步數、同樣評估預算，但每一個 agent **獨立**隨機遊走。呢個係「呢個結果可能只係隨機搜尋」嘅誠實版本。
2. **分離觀測量**：由軌跡算出、且**在零假設下有已知分佈**嘅量。咁「湧現」就係**拒絕零假設**，唔係描述數據。
3. **檢定力（power），唔止 p 值**：單次拒絕冇意義；誠實嘅陳述係「在固定假陽性率下，幾常能偵測到」。

**實作**：

- `Pcg32`：32 位 LCG，**跨四個後端逐位一致**（唔用平台 RNG）。
- `m9_structured_step`：每個 agent 向其**左右鄰居均值**移動（環形拓樸）—— 最小關係結構。
- `m9_null_step`：同一目標、同一步長、獨立隨機遊走 —— **刻意唔弱化**，同樣評估預算。
- **觀測量 = Kuramoto 型同步序參數** `r = 1 − Var(x)/Var(x₀)`。獨立隨機遊走**永遠擴大**方差（r < 0）；鄰居耦合**永遠收縮**方差（r → 1）。

**實測**：

```text
[M9] null_mean=-0.163 alt_mean=0.851 thr=0.348 | fpr=0.047 power=1.000 | separates=true | PASS = true
```

| 量 | 值 | 意義 |
| :--- | :--: | :--- |
| `null_mean` | **−0.163** | 隨機搜尋令方差**擴大**（r 為負） |
| `alt_mean` | **+0.851** | 結構化耦合趨向同步 |
| `threshold` | +0.348 | 零假設分佈嘅 95 百分位 |
| `false_positive_rate` | **0.047** | 量得嘅假陽性率（名義 5%，實測吻合） |
| `power` | **1.000** | 64/64 結構化樣本全部超過門檻 |

**答案**：**可以區分**。而且呢個陳述**本身可證偽**：若 `power ≤ fpr`，或者 `separates = false`，CLI 嗰條線就變 `PASS = false`。`caveat` 欄位明寫「有限頻率派檢查；證明此模型上嘅判別力，唔證明湧現在任何地方存在」。

> **我踩過嘅兩個坑（都記錄在案）**：
> 1. **第一版觀測量飽和**：用「耦合項佔比」做觀測量，兩臂都飽和到 +1，`fpr = 0`、`power = 0`、`separates = false`。根因：追蹤「歷史最佳點」令兩臂都揀到耦合主導嘅點。改為量度**末態**、並改用同步序參數。
> 2. **觀測量必須係標準量**：序參數係 Kuramoto 意義下嘅標準量，唔係我為令測試通過而砌嘅分數。

---

#### M10 — 多 sub-colony 副相容共識：B_4^n 降解，而非壓成一個因子（v2.4.7 重寫）

**v1 的錯誤**：把每個 sub-colony 壓成一個純量因子（「有冇矛盾」）。呢個丟失咗 $B_4$ 存在的理由 —— $B_4$ 唔係真值刻度，係**兩個格的乘積**（真值序 $\le_t$、資訊序 $\le_i$）。副相容的要點正是：**矛盾係局部狀態，系統可以一邊持有、一邊把事做完**。壓成純量 = 把向量壓成範數。

**v2 的結構**：每個 sub-colony 貢獻一個完整 $B_4$ 值到**因子**，群體狀態係因子乘積 $B_4^n$。共識係**兩階段降解**，對應兩個序：

| 階段 | 運算 | 含意 |
| :--- | :--- | :--- |
| $\le_i$ | 對因子 $\mathrm{join}$ | 群體**知道**什麼。矛盾令聯合資訊成 $\mathrm{Bv}$，但只在該處。單調、不遺忘 ⇒ 這就是「繼續完成件事」 |
| $\le_t$ | 投影到仍可用真值 | $\mathrm{truth\_available}(\mathrm{Bv})=[\mathrm{Tv},\mathrm{Fv}]$ —— 矛盾被**拆成兩支**，唔係刪除 |

**窮舉（這是關鍵）**：「唔爆炸」只有在窮舉 $B_4^4$ 全部 256 個配置後才有意義。否則只代表「我試過嘅例子冇爆」。

| 規則 | 爆炸 /256 | 空洞 | 丟失因子 | 通過 |
| :--- | :--: | :--: | :--: | :--: |
| `NaiveJoin` | **225** | 0 | 0 | ✗ |
| `QuarantineFirst` | **255** | 0 | 0 | ✗ |
| `Scoped` | **110** | 0 | 0 | ✗ |
| `Weighted` | 0 | 0 | 0 | 但**丟失四值結構**（因子被投票結果覆蓋） |
| **`Bilattice`** | **0** | **0** | **0** | **✓** |

```text
[M10] consensus census (ALL 256 configs of B_4^4)
        naive:expl=225 quarant:expl=255 scoped:expl=110 weighted:expl=0
        bilattice:expl=0 vac=0 lost=0 carrying=65 manufactured=50 | rule=Bilattice
```

**新發現：兩個矛盾機制必須分開**

| 機制 | 判據 | 數量 | 意義 |
| :--- | :--- | :--: | :--- |
| 本地持有 carried | 聯合 $=\mathrm{Bv}$ 且**某座標本身是** $\mathrm{Bv}$ | 65 | 有主矛盾，某子群自己不一致 |
| 製造 manufactured | 聯合 $=\mathrm{Bv}$ 但**冇座標是** $\mathrm{Bv}$ | 50 | $join(\mathrm{Tv},\mathrm{Fv})=\mathrm{Bv}$ 無中生有 |

第二個機制**正是擊敗所有 join 型規則的原因**：`Scoped` 已隔離顯式 $\mathrm{Bv}$，仍爆炸 110 次，全部由此而來。**製造的矛盾冇主，所以唔可以靠「隔離有主者」解決** —— 這解釋了為何 v1 的三個修法全部失敗。

**接線進 M6**：四層 = 四個子群。

```text
[M6] ... | colony factor info=B avail=2 carrying=false | PASS = true
```

Flow 與 Trop-Kan 互相不同意（$\mathrm{Tv}$ vs $\mathrm{Fv}$），聯合資訊成 $\mathrm{Bv}$，而**閉環照樣收斂**（`iterations=13`、`residual=7.30e-04`、$\rho=0.65$）。$\mathrm{available}=2$ ⇒ 兩支都仍可操作。這是「打交都繼續完成件事」的實測證據，唔係一個旗標。

舊 `microlocal_quarantined : Bool` 降為**衍生視圖**，測試斷言它必須等於因子矛盾清單，不得獨立。

**是否「起貨」**：$B_4^4$ 全 256 配置窮舉、`Bilattice` 零爆炸零空洞零丟失因子 ⇒ **可以起貨**。但範圍誠實：窮舉係 $n=4$；$n\le 5$（1024）亦已支援並在測試中跑過；再大的 $n$ 係 $4^n$ 增長，唔係「已證對所有 $n$ 成立」。

---

### 附：關於 M8 的 K₀ 只用了「投影子秩」這件事（v2.4.6 自我更正）

**批評**：K₀ 係**函子**，可以係好多變體 —— 空間、流形、叢、等變 K、扭曲 K。用「投影子秩」係**單點 K₀**，冇用到 K-理論作為函子的結構。

**這個批評是對的。** M8 目前做的是：

```
K₀(H) = Z        單一環 H 的 Grothendieck 群
role ↦ rank       一個函子 Obj(H-Mod) → Z 的物件映射
```

**冇做**的部分：

| 變體 | 缺少什麼 | 若要做 |
| :--- | :--- | :--- |
| 空間 K（`K⁰(X)`） | 冇拓樸空間基底；角色只是孤立模，冇「底空間」 | 把角色族視為 `X` 上的向量叢，`K⁰(X)` 的類由覆蓋與粘合決定 |
| 等變 K（`K_G`） | 冇群 `G` 作用；現時四個角色係平權的，冇對稱性 | 引入 Flow/Trop-Kan 的置換群 `G`，角色變成 `G`-模，`K_G` 分得開現時分不開的 `coordinator`/`explorer` |
| 扭曲 K（`K^α`） | 冇 twisting；所有角色在同一 trivial 類裡 | 用 Hurst/相位作 twisting cocycle，`K^α` 可能有 torsion 部分 |
| 相對 K（`K(X,A)`） | 冇 pair `(X,A)` | 把「已浮現」與「未浮現」子族當成 pair，取相對群 |

**對現有結論的直接影響**：M8 中 `coordinator` 與 `explorer` 的 `mdl` 都是 1，**在此計量下不可分辨**。這不是數學上的必然，而是**選錯了 K-理論層次**的後果。等變 K 很可能分得開它們（因為兩者在 Flow 的置換群下有不同的穩定子）。

**已列入 M7+ 待辦，並在測試中留了絆線**：`assert_eq(report.profiles[0].mdl, report.profiles[1].mdl)` —— 若日後升級到等變 K 而這兩者變得可分辨，該測試會失敗，迫使重新審視整個計量。

> **範圍誠實**：現時的 M8 結論應讀作「**秩 + 和項數**這個組合不變量可用作角色複雜度計量」，而**不是**「K₀ 理論可用作角色複雜度計量」。後者需要真的建立一個函子，本輪沒有做。

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
| v2.4.2 | Mora 切線錐算法 | 局部標準基、牛頓多面體 toric/Koszul、錐認證 M4.2 / M6.2 |
| v2.7+ | 統一範疇、複雜度計量、可證偽性、多殖民共識 | M7 – M10 |

---

## 七、工程紀律

1. **定理證據鏈**：任何新增定理都必須有機器精度證據鏈，並納入 `verify_all_theorems()`；未有證據鏈的定理不得寫入文件。
2. **CI 為唯一驗收事實來源**：CI workflow 的七個 gates 為唯一正式驗收紀錄；本地通過不得表述為 CI 通過。格式及公開介面漂移須由完整 CI 偵測。
3. **橋接層單向性**：Tier 0 不得依賴 Tier 2；違反即退回。
4. **常駐回歸測試**：每項已修復缺陷均須有對應的常駐回歸測試（另參見 `MERGE_ANALYSIS.md` 第六節）。
5. **範圍誠實**：M4 僅為有限 A₃／D₄ scalar 正常形原型；M6 的收斂結論僅限實測殘差軌跡，不得寫成完整非線性系統全域定理。
