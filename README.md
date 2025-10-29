# Speckit - 規範驅動開發工具集

Speckit 是一個規範驅動開發（Spec-Driven Development）的工作流程工具集，用於協助開發者從功能描述到實現的完整過程。

## 概述

Speckit 通過一系列命令來組織和管理開發流程，確保每個功能都有清晰的規範、計劃和任務分解：

1. **speckit.specify** - 創建或更新功能規範
2. **speckit.clarify** - 澄清規範中的模糊部分
3. **speckit.plan** - 生成實施計劃
4. **speckit.tasks** - 生成任務列表
5. **speckit.checklist** - 生成自定義清單
6. **speckit.analyze** - 分析規範品質
7. **speckit.implement** - 執行實施計劃

## 安裝

```bash
# 使用 pip 安裝依賴
pip install -r requirements.txt
```

## 使用方法

### 1. 創建功能規範
```bash
python spec_implement.py --help
```

要開始一個新功能，首先運行：
```bash
# 這將創建新功能分支和規範文件
# 使用 .specify/scripts/powershell/create-new-feature.ps1
```

### 2. 澄清規範
運行 `/speckit.clarify` 命令以識別規範中的模糊領域。

### 3. 生成實施計劃
運行 `/speckit.plan` 命令以基於規範生成技術計劃。

### 4. 生成任務列表
運行 `/speckit.tasks` 命令以基於設計文檔生成可執行的任務。

### 5. 執行實施
使用 Python 實現執行實施：
```bash
python spec_implement.py
```

## 目錄結構

```
.specify/                    # Speckit 核心目錄
├── memory/                 # 憲法和記憶體文件
│   └── constitution.md     # 專案憲法
├── scripts/                # 腳本文件
│   └── powershell/         # PowerShell 腳本
├── templates/              # 模板文件
│   ├── spec-template.md    # 規範模板
│   ├── plan-template.md    # 計劃模板
│   ├── tasks-template.md   # 任務模板
│   └── checklist-template.md # 檢查清單模板
gemini/                     # Gemini 特定命令
└── qwen/                   # Qwen 特定命令
```

## speckit.implement 特性

`speckit.implement` 命令執行以下功能：

- 檢查先決條件和依賴關係
- 驗證檢查清單狀態
- 載入實施上下文（spec.md, plan.md, tasks.md 等）
- 執行專案設定驗證
- 解析 tasks.md 結構
- 按階段執行任務（設置、基礎、用戶故事、完善階段）
- 遵循 TDD 方法（測試優先）
- 平行和順序任務協調
- 更新任務文件狀態

## 命令行參數

```bash
python spec_implement.py --feature-dir /path/to/feature --skip-checklists
```

參數：
- `--feature-dir` - 指定功能目錄
- `--tasks-file` - 指定任務文件路徑
- `--skip-checklists` - 跳過檢查清單檢查

## 憲法原則

Speckit 遵循以下核心原則：
- Library-First：每個功能先作為獨立庫開發
- CLI Interface：提供 CLI 介面
- Test-First：強制執行 TDD
- Integration Testing：關注整合測試
- Observability：確保可調試性

## 貢獻

歡迎提交 PR 來改善 Speckit 工具集。

## 許可

此項目採用 MIT 許可證。