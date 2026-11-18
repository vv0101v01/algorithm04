# 合併分析報告：`vv0101v01/algorithm04` × `vv0101v01/algo8` 雙親統一合併

> 版本：`arena/super_emergence` v2.0.0
> 雙親：`vv0101v01/algorithm04`（`d85a35f`，18 大結構 / 14 定理）與 `vv0101v01/algo8`（`99bdadf`，8 大結構 / 31 定理）
> 合併策略：**分層正交核心 + 單向橋接層**（Stratified Orthogonal Core + Unidirectional Bridge）

---

## 一、合併前之利弊分析

### 1.1 兩親之結構剖面

| 面向 | `algorithm04` | `algo8` |
| :--- | :--- | :--- |
| 核心領域 | 超幾何・泛性質・半熱帶射影・奇點胚・微局部 | 記憶・泛極限・辛相調・算子叢・$K$ 理論・副相容 |
| 定理數 | 14 條複合定理 | 31 條基礎定理 |
| 模組數 | 18 個數學結構 | 8 個數學結構 |
| 湧現層 | 三層（`SGNE-Flow` / `SGNE-Trop-Kan` / `SGNE-Germ-Micro`） | 無獨立層（僅為可組合元件） |
| 實作風格 | Trait 塔驅動、範疇化抽象優先 | 程序化數值演算法優先 |
| 型別嚴重度 | `moon check --deny-warn` 零警告 | `moon check --deny-warn` 零警告 |
| 測試 | 14/14 | 31/31 |

### 1.2 合併之正面效益

1. **互補而非重疊**：`algorithm04` 的範疇／代數抽象需要「可計算的實例層」，`algo8` 恰好提供八個完全正交的實例模組；反之 `algo8` 的演算法缺少統一的湧現敘事，`algorithm04` 提供三層引擎骨架。
2. **定理數可乘性**：兩親定理集合交集為空（14 ∩ 31 = 0），故理論上可得 45 條定理；其中 31 條基礎定理保持原樣，14 條複合定理升級為 18 條（含 4 條新合併定理）。
3. **單一 CI、單一工具鏈、零外部依賴**：避免雙倉庫版本漂移。
4. **跨後端交叉驗證**：三後端（`wasm-gc` / `wasm` / `js`）對 26 個結構同時驗證，可捕捉純浮點順序敏感之差異。

### 1.3 合併之風險與損害

1. **命名衝突**：`algebra.mbt`（兩親皆有）、`Complex`、`Quat`、`Grassmann`、`DenseMat` 等核心型別重複定義。
2. **方法提升衝突**：`pub extend` 對同一 Trait／同一方法重複掛載會導致 redefinition 編譯錯誤。
3. **API 面積爆炸**：兩親的 `pkg.generated.mbti` 各自數千行，合併後介面檔近 1,700 行，維護成本上升。
4. **概念張力**：`algorithm04` 採「一切從範疇公理推導」的風格，`algo8` 採「先寫可執行驗證器再回溯公理」的風格；直接混合會破壞任一風格之一致性。
5. **隱性缺陷**：跨倉庫審計發現 `algo8` 側存在 6 處實質缺陷（見第六節），若不修正即合併，等於把錯誤 elevate 成「已驗證」。

---

## 二、僅合併可得之六項數學紅利

以下六項結構**在任何單一親代中都不存在**，只有把兩套正交核心在同一嚴格型別宇宙中複合才會湧現；它們已分別被實現為定理 XV–XVIII 的證據鏈。

| # | 紅利 | 複合方式 | 產出定理 |
| :---: | :--- | :--- | :---: |
| 1 | **Belnap–Grassmann 副相容統一** | `para_universe.mbt` 之 $B_4$ 四值雙格 $\times$ `neuro_symbolic_susy.mbt` 之 Pauli–Grassmann 奇元阻斷 | XVI |
| 2 | **Schur–質量 Metriplectic 優化** | `super_mass_orbit.mbt` 之 $M_{\mathrm{eff}}=\Xi\Omega^{-1}\Xi^{\mathsf T}$ $\times$ `symplectic.mbt` 之辛恆等式積分器 | XV |
| 3 | **閘控記憶 × Haken／超熱帶 WTA 對偶** | `memory.mbt` 之吸收半群 $\times$ `synergetic.mbt` 之奴役與 WTA $\times$ `semitropical_projective.mbt` 之超熱帶幽靈相 | XVIII |
| 4 | **Čech 超算子叢餘擺** | `bundle.mbt` 之 Čech 餘擺與截面拼接 $\times$ `ncg_supermatrix.mbt` 之超算子 $\mathrm{str}$/$\mathrm{Ber}$ | XVII |
| 5 | **四元數 Kramers–Connes／$K_0$ 橋接** | `quaternion_ktheory.mbt` 之 $K_0$ 譜投影 $\times$ `ncg_supermatrix.mbt` 之 Connes 譜距離 | XVII |
| 6 | **有限雙完全性 + Cantor Gödel 引擎** | `universal.mbt` 之拉回／推出（極限／餘極限） $\times$ `complex_field.mbt` 之 Cantor 配對 | XVIII |

紅利 #3 與 #6 尤其關鍵：前者要求**同一個**序參數同時被超熱帶射影與 Haken 奴役共享，後者要求集合編碼與範疇極限共享同一套集合語意——兩者在單一親代中皆無宿主。

---

## 三、合併方案之比較與選擇

| 方案 | 描述 | 優點 | 缺點 | 結論 |
| :--- | :--- | :--- | :--- | :--- |
| **A. 保留雙倉庫 + 交叉引用** | 各自 CI，互相以 git submodule 引用 | 零衝突、風險最低 | 無法產生任何合併紅利；雙份 CI 與版本漂移 | ✗ |
| **B. 單向移植（algo8 → algorithm04）** | 把 8 個模組搬進 `algorithm04` 倉庫 | 衝突面小、歷史線性 | 落後的一方無逆轉機會；`algo8` 之 31 定理與 README 語境將被降級為子目錄 | ✗ |
| **C. 扁平化合併（兩邊模組平鋪）** | 直接把所有 `.mbt` 放進同一套件 | 最快 | `Complex`／`Quat`／`Grassmann`／`DenseMat` 直接撞名；`algebra.mbt` 幾乎全部重複；`extends.mbt` 重複掛載即編譯失敗 | ✗ |
| **D. 分層正交核心 + 單向橋接層** | 核心層保持雙親正交不變，所有跨域耦合集中到單一橋接模組 `unified_bridges.mbt` | 核心零耦合、衝突面可控、紅利可完整保留、橋接層可獨立審計 | 需人工設計橋接層介面 | ✓ **採用** |

### 3.1 採用方案 D 之分層設計

```text
Tier 0  基礎層（雙親共用，零耦合）
        algebra.mbt（Trait 塔、Grassmann、Complex、DenseMat）
        supermanifold / affine_tensor / pope / ncg_supermatrix / pde_flow
        super_jacobi / super_mass_orbit / neuro_symbolic_susy
        fisher_natural_grad / universal_functor / semitropical_projective
        universal_enveloping / singularity_germs / meromorphic_microfunction
        memory / universal / complex_field / synergetic / symplectic
        bundle / quaternion_ktheory / para_universe

Tier 1  單層湧現引擎
        emergence.mbt（SGNE-Flow / SGNE-Trop-Kan / SGNE-Germ-Micro）

Tier 2  跨層橋接層（唯一允許跨域耦合之處）
        unified_bridges.mbt（定理 XV–XVIII 之全部證據鏈）

Tier 3  驗證與介面
        super_emergence_test.mbt（18 複合定理）
        math_structures_test.mbt（31 基礎定理 + 6 缺陷回歸）
        extends.mbt（顯式方法掛載）
        cmd/main/main.mbt（CLI 報告）
```

**單向性**：Tier 0 不得 import Tier 2；Tier 2 可 import Tier 0/1；Tier 1 可 import Tier 0。此約束由 `moon check --deny-warn` 之零警告與 CI 之 `.mbti` 介面漂移檢查共同守護。

---

## 四、損害最小化對策

| 損害類型 | 對策 | 驗證方式 |
| :--- | :--- | :--- |
| 核心型別撞名 | 保留單一 `Complex`／`Quat`／`Grassmann`／`DenseMat` 定義於 `algebra.mbt`，刪除 `algo8` 側重複定義 | `moon check --deny-warn` 零警告 |
| `pub extend` 重複掛載 | 移除 `extends.mbt` 中 `Complex::norm_sq`／`Complex::scale` 之重複提升（內建方法已存在） | 編譯期 redefinition 錯誤清零 |
| `util.mbt` 與 `algebra.mbt` 皆定義 `approx` | `git rm -f util.mbt`，統一由 `algebra.mbt` 提供 `approx` | 編譯期重複定義清零 |
| 工具鏈版本漂移 | 統一 `moon.mod` 至 MoonBit v0.10.21 + `moonc v0.10.21+06da1ed44` | `moon version --all` |
| 公開介面漂移 | 以 `moon info` 重新生成根與 CLI 兩份 `pkg.generated.mbti`，移除所有衝突標記 | `moon info && git diff --exit-code pkg.generated.mbti` |
| 格式漂移 | `moon fmt` 全域格式化，`moon fmt --check` 零漂移 | CI Gate 1 |
| 隱性缺陷 elevate | 審計並修復 6 處 `algo8` 側缺陷 + 5 處橋接層缺陷（見第六節） | `math_structures_test.mbt` 之 6 項回歸測試 + `super_emergence_test.mbt` 層 4 測試 |
| 舊 README／文件與新程式碼不符 | 全面改寫 `README.mbt.md`、`THEOREMS_AND_ALGORITHMS.md`，補入定理 XV–XVIII 與第四層 | 文件與 `moon run cmd/main` 實測輸出逐項對照 |

---

## 五、合併後之量化成果

| 指標 | 合併前（`algorithm04`） | 合併前（`algo8`） | 合併後 |
| :--- | :---: | :---: | :---: |
| 數學結構 | 18 | 8 | **26** |
| 複合定理 | 14 | 0 | **18** |
| 基礎定理 | 0 | 31 | **31** |
| 湧現層 | 3 | 0 | **4** |
| 測試（`wasm-gc`） | 14 | 31 | **53** |
| 跨後端 | 3 | 3 | **3** |
| 編譯警告 | 0 | 0 | **0** |
| 格式漂移 | 0 | 0 | **0** |
| 公開介面漂移 | 0 | 0 | **0** |
| 合併專屬紅利 | — | — | **6** |

---

## 六、跨倉庫審計所發現並修復之缺陷

### 6.1 `algo8` 側（6 項）

| 編號 | 位置 | 缺陷 | 影響 |
| :--- | :--- | :--- | :--- |
| `BUG-06` | `quaternion_ktheory.mbt` | `hermitian2_projector_plus` 於退化譜除以零產生 `NaN`；`k0_spectral_identity` 因 `NaN > eps` 恆假而**靜默回傳 `true`** | 定理被「假通過」證偽 |
| `BUG-07` | `memory.mbt` | `absorption_time_linear_solve` 之 `let rhs = r` 別名污染，就地覆寫呼叫端右端向量 | 呼叫端陣列遭破壞 |
| `BUG-08` | `symplectic.mbt` | `variational_jacobian` 誤傳 `eps` 為積分步長 `dt` | 辛恆等式殘差量測的是另一條流 |
| `BUG-09` | `bundle.mbt` | `conjugate` 之矩陣求逆無奇異防護 | 奇異框架變換產生 `NaN` |
| `BUG-10` | `algebra.mbt` | `Complex::div` 無零除子防護 | $0^{-1}$ 產生 `NaN/Inf` |
| `BUG-11` | `para_universe.mbt` | `FourVal::land` / `FourVal::lor` 與其**自身文件化之真值序矛盾** | 真值序之 glb/lub 定義被違反 |

### 6.2 橋接層（5 項，合併過程中產生）

| 編號 | 位置 | 缺陷 | 對策 |
| :--- | :--- | :--- | :--- |
| `BUG-13` | `unified_bridges.mbt` | Gödel 編碼非集合不變，且解碼反轉邏輯與編碼不一致 | 改為二進位特徵掩碼 $\sum_{k\in S}2^k$ + Cantor 配對 |
| `BUG-14` | `unified_bridges.mbt` | 幽靈偵測僅比較最大值與次大值，**並列極大被誤判為 Tangible** | 改為計數全體極大者 |
| `BUG-15` | `unified_bridges.mbt` | 以 $\Delta M$ 之經典特徵值最小值作為 Schur 位移證據（奇–奇修正偶體恆零） | 改以靈魂範數 + 零偶體跡 + 顯式 Grassmann 恆等式聯合認證 |
| `BUG-16` | `unified_bridges.mbt` | 有限範疇 fixture 之餘錐／錐映射方向錯誤；兩世界 fixture 無法維持正交假命題 | 修正映射方向並加入第三條正交假命題 |
| `BUG-17` | `unified_bridges.mbt` | 角色記憶 profile 未依保留率排序，導致吸收時間序顛倒 | 依保留率重排 |

---

## 七、合併後之驗證矩陣

| 門檻 | 內容 | 狀態 |
| :--- | :--- | :--- |
| Gate 1 | `moon fmt --check` 零格式漂移 | ✓ |
| Gate 2 | `moon check --deny-warn` 零錯誤零警告 | ✓ |
| Gate 3 | `moon info && git diff --exit-code pkg.generated.mbti` 零介面漂移 | ✓ |
| Gate 4 | `moon test --target wasm-gc`（53/53） | ✓ |
| Gate 5 | `moon test --target wasm`（53/53） | ✓ |
| Gate 6 | `moon test --target js`（53/53） | ✓ |
| Gate 7 | `moon run cmd/main` 輸出 `18 / 18 theorems verified.` 且含 `SGNE-Syn-Mem-Para` 與 `26 structures` | ✓ |
| Gate 8 | `benchmarks/emergence_problem_set.json` 機器驗證（36 題、ID 唯一、kind/layer 合法） | ✓ |

---

## 八、後續維護建議

1. **橋接層單一職責守恆**：任何新的跨域耦合必須先進 `unified_bridges.mbt` 並附定理證據鏈，不得下沉至 Tier 0。
2. **回歸測試常駐**：`math_structures_test.mbt` 之 6 項缺陷回歸測試必須永久保留，任何重構若使其失敗即為回歸。
3. **定理數目單一來源**：`verify_all_theorems()` 之長度即權威；CI 與文件表格須以之為準。
4. **合併前先審計**：任何未來之雙親合併，應先於合併分支執行跨倉庫缺陷審計，以避免缺陷被 elevate 為「已驗證」。
