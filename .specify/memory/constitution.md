<!--
Sync Impact Report:
- Version change: 1.3.0 → 1.4.0
- Modified principles: None
- Added sections:
    - III. 性能與計算效率 (Performance & Efficiency)
    - IV. 程式碼品質與測試 (Code Quality & Testing)
- Removed sections: None
- Templates requiring updates:
    - ⚠ .specify/templates/plan-template.md
    - ⚠ .specify/templates/spec-template.md
    - ⚠ .specify/templates/tasks-template.md
- Follow-up TODOs:
    - TODO(SECTION_2_NAME): Define section name.
    - TODO(SECTION_2_CONTENT): Define section content.
    - TODO(SECTION_3_NAME): Define section name.
    - TODO(SECTION_3_CONTENT): Define section content.
    - TODO(GOVERNANCE_RULES): Define governance rules.
    - TODO(RATIFICATION_DATE): Confirm ratification date.
-->
# Stock_test Constitution

## Core Principles

### I. 資料完整性與準確性 (Data Integrity & Accuracy)
數據來源： 必須明確標註所有歷史數據的確切來源（例如：Yahoo Finance, Quandl, 客製化 API）。
時區處理： 所有時間戳記必須轉換並標準化為 UTC 時區進行內部處理。
資料清理： 任何 NaN/缺失值/異常值處理必須被顯式記錄和參數化。預設應使用前值填充 (Forward Fill)，並將變更記錄於日誌。
資料延遲： 回測中使用的價格和指標必須嚴格遵守資料延遲原則（例如：禁止使用未來數據，必須模擬真實交易發生時的數據時間點）。

### II. 回測邏輯與架構 (Backtesting Logic & Architecture)
程式語言與版本： 必須使用 Python 3.11。
核心框架： 核心回測引擎必須基於 Zipline 或 VectorBT (或您指定的主流框架)。
核心抽象： 必須嚴格分離資料層 (Data Layer)、策略層 (Strategy Layer) 和回測執行層 (Execution Layer)。
交易成本： 交易邏輯必須包含可配置的交易成本（手續費和滑價）。預設手續費設為萬分之二 (0.02%)。

### III. 性能與計算效率 (Performance & Efficiency)
資料庫選型： 歷史數據必須儲存在 Parquet 格式或優化的 time-series 資料庫 (e.g., InfluxDB)，以確保快速載入。
向量化優先： 核心指標計算必須優先使用 NumPy 或 Pandas 進行向量化運算，以避免慢速的 for 迴圈。
計算效率： 單次回測執行時間（回測一年數據）不得超過 60 秒。

### IV. 程式碼品質與測試 (Code Quality & Testing)
測試驅動開發 (TDD)： 所有新功能和回測指標必須先撰寫單元測試，測試通過後才實作程式碼。
覆蓋率： 回測邏輯層的單元測試覆蓋率必須維持在 90% 以上。
風格規範： 程式碼必須嚴格遵守 PEP 8 規範，並使用 Black 進行格式化。

## [SECTION_2_NAME]
<!-- Example: Additional Constraints, Security Requirements, Performance Standards, etc. -->

[SECTION_2_CONTENT]
<!-- Example: Technology stack requirements, compliance standards, deployment policies, etc. -->

## [SECTION_3_NAME]
<!-- Example: Development Workflow, Review Process, Quality Gates, etc. -->

[SECTION_3_CONTENT]
<!-- Example: Code review requirements, testing gates, deployment approval process, etc. -->

## Governance
<!-- Example: Constitution supersedes all other practices; Amendments require documentation, approval, migration plan -->

[GOVERNANCE_RULES]
<!-- Example: All PRs/reviews must verify compliance; Complexity must be justified; Use [GUIDANCE_FILE] for runtime development guidance -->

**Version**: 1.4.0 | **Ratified**: 2025-10-29 | **Last Amended**: 2025-10-29
