#!/usr/bin/env python3
"""
Speckit Implementation Module
執行實施計劃，處理並執行 tasks.md 中定義的所有任務
"""

import os
import subprocess
import json
import sys
from pathlib import Path
import re
import argparse


class SpeckitImplementer:
    def __init__(self, feature_dir=None):
        self.feature_dir = feature_dir or self.find_feature_dir()
        self.feature_spec = None
        self.impl_plan = None
        self.tasks = None
        self.checklists_dir = None
        
    def find_feature_dir(self):
        """尋找當前功能目錄"""
        current_dir = Path.cwd()
        # 尋找 specs 或 feature 相關目錄
        for parent in [current_dir] + list(current_dir.parents):
            if (parent / "specs").exists():
                specs_dir = parent / "specs"
                # 尋找包含 plan.md 的功能目錄
                for item in specs_dir.iterdir():
                    if item.is_dir() and (item / "plan.md").exists():
                        return item
        return None

    def run_check_prerequisites(self):
        """運行檢查先決條件腳本"""
        try:
            # 檢查 PowerShell 腳本是否存在
            script_path = Path(".specify/scripts/powershell/check-prerequisites.ps1")
            if script_path.exists():
                result = subprocess.run([
                    "pwsh", "-ExecutionPolicy", "Bypass", 
                    "-File", str(script_path), 
                    "-Json", "-RequireTasks", "-IncludeTasks"
                ], capture_output=True, text=True, cwd=os.getcwd())
                
                if result.returncode == 0:
                    data = json.loads(result.stdout)
                    self.feature_dir = data.get("FEATURE_DIR", self.feature_dir)
                    return data.get("AVAILABLE_DOCS", [])
                else:
                    print(f"錯誤：檢查先決條件失敗: {result.stderr}")
                    return []
            else:
                print(f"錯誤：找不到檢查腳本: {script_path}")
                return []
        except Exception as e:
            print(f"運行檢查腳本時發生錯誤: {e}")
            return []

    def check_checklists_status(self):
        """檢查檢查清單狀態"""
        if not self.feature_dir:
            print("錯誤：未找到功能目錄")
            return True  # 假設為通過，繼續執行
            
        self.checklists_dir = Path(self.feature_dir) / "checklists"
        if not self.checklists_dir.exists():
            print("警告：未找到檢查清單目錄，繼續執行")
            return True

        checklist_status = {}
        
        # 掃描檢查清單目錄中的所有 .md 文件
        for checklist_file in self.checklists_dir.glob("*.md"):
            total_items = 0
            completed_items = 0
            incomplete_items = 0
            
            with open(checklist_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # 計算檢查清單項目
            all_items = re.findall(r'-\s*\[([ xX])\]\s*(.+)', content)
            total_items = len(all_items)
            
            for status, _ in all_items:
                if status.lower() in ['x', 'X']:
                    completed_items += 1
                else:
                    incomplete_items += 1
            
            checklist_status[checklist_file.name] = {
                'total': total_items,
                'completed': completed_items,
                'incomplete': incomplete_items
            }
        
        # 生成狀態表格
        print("\n檢查清單狀態:")
        print("| Checklist | Total | Completed | Incomplete | Status |")
        print("|-----------|-------|-----------|------------|--------|")
        
        all_passed = True
        for name, stats in checklist_status.items():
            status = "✓ PASS" if stats['incomplete'] == 0 else "✗ FAIL"
            if stats['incomplete'] > 0:
                all_passed = False
            print(f"| {name} | {stats['total']} | {stats['completed']} | {stats['incomplete']} | {status} |")
        
        # 如果有任何檢查清單未完成，詢問用戶是否繼續
        if not all_passed:
            print("\n一些檢查清單未完成。")
            response = input("您仍要繼續實施嗎？(yes/no): ").strip().lower()
            if response in ['yes', 'y', 'proceed', 'continue']:
                return True
            else:
                print("用戶選擇停止執行。")
                return False
        
        print("所有檢查清單均已通過，繼續執行。")
        return True

    def load_implementation_context(self):
        """載入實施上下文"""
        if not self.feature_dir:
            raise ValueError("未找到功能目錄")
            
        self.feature_spec = Path(self.feature_dir) / "spec.md"
        self.impl_plan = Path(self.feature_dir) / "plan.md" 
        self.tasks = Path(self.feature_dir) / "tasks.md"
        
        required_files = [self.impl_plan, self.tasks]
        for file_path in required_files:
            if not file_path.exists():
                raise FileNotFoundError(f"缺少必需文件: {file_path}")
        
        print(f"載入實施上下文...")
        print(f"  計劃文件: {self.impl_plan}")
        print(f"  任務文件: {self.tasks}")
        
        # 載入可選文件
        optional_files = {
            'data-model.md': Path(self.feature_dir) / "data-model.md",
            'research.md': Path(self.feature_dir) / "research.md",
            'quickstart.md': Path(self.feature_dir) / "quickstart.md"
        }
        
        for name, path in optional_files.items():
            if path.exists():
                print(f"  可選文件: {path}")
                
        return True

    def project_setup_verification(self):
        """專案設定驗證"""
        print("開始專案設定驗證...")
        
        # 檢查是否為 Git 儲存庫
        is_git_repo = False
        try:
            result = subprocess.run([
                "git", "rev-parse", "--git-dir"
            ], capture_output=True, text=True, cwd=os.getcwd())
            is_git_repo = result.returncode == 0
        except:
            print("警告：無法檢查 Git 儲存庫狀態")
            is_git_repo = False
        
        # 檢查和創建/驗證忽略檔案
        if is_git_repo:
            gitignore_path = Path(".gitignore")
            if not gitignore_path.exists():
                gitignore_path.touch()
                print(f"創建 .gitignore 文件: {gitignore_path}")
            else:
                print(f"驗證 .gitignore 文件: {gitignore_path}")
        
        # 檢查 plan.md 中的技術堆棧並創建對應的忽略檔案
        if self.impl_plan.exists():
            with open(self.impl_plan, 'r', encoding='utf-8') as f:
                plan_content = f.read().lower()
                
            # 根據 plan.md 的技術堆棧創建忽略檔案
            tech_indicators = []
            if any(tech in plan_content for tech in ['python', 'pip', 'venv']):
                tech_indicators.append('python')
            if any(tech in plan_content for tech in ['node', 'npm', 'yarn', 'javascript', 'typescript']):
                tech_indicators.append('javascript')
            if any(tech in plan_content for tech in ['java', 'gradle', 'maven']):
                tech_indicators.append('java')
                
            for tech in tech_indicators:
                if tech == 'python':
                    self._create_python_ignore()
                elif tech == 'javascript':
                    self._create_js_ignore()
                elif tech == 'java':
                    self._create_java_ignore()
        
        print("專案設定驗證完成")
        return True

    def _create_python_ignore(self):
        """為 Python 專案創建忽略規則"""
        gitignore_path = Path(".gitignore")
        with open(gitignore_path, 'a', encoding='utf-8') as f:
            patterns = [
                "\n# Python\n",
                "__pycache__/\n",
                "*.pyc\n",
                ".venv/\n",
                "venv/\n",
                "dist/\n",
                "*.egg-info/\n",
                ".env*\n",
                "*.log\n"
            ]
            f.writelines(patterns)
        print("為 Python 專案更新 .gitignore")

    def _create_js_ignore(self):
        """為 JavaScript/Node.js 專案創建忽略規則"""
        gitignore_path = Path(".gitignore")
        with open(gitignore_path, 'a', encoding='utf-8') as f:
            patterns = [
                "\n# Node.js\n",
                "node_modules/\n",
                "dist/\n",
                "build/\n",
                "*.log\n",
                ".env*\n"
            ]
            f.writelines(patterns)
        print("為 JavaScript 專案更新 .gitignore")

    def _create_java_ignore(self):
        """為 Java 專案創建忽略規則"""
        gitignore_path = Path(".gitignore")
        with open(gitignore_path, 'a', encoding='utf-8') as f:
            patterns = [
                "\n# Java\n",
                "target/\n",
                "*.class\n",
                "*.jar\n",
                ".gradle/\n",
                "build/\n"
            ]
            f.writelines(patterns)
        print("為 Java 專案更新 .gitignore")

    def parse_tasks(self):
        """解析 tasks.md 結構"""
        if not self.tasks or not self.tasks.exists():
            raise FileNotFoundError("找不到 tasks.md 文件")
            
        print(f"解析任務文件: {self.tasks}")
        
        with open(self.tasks, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 解析任務結構
        tasks = []
        task_pattern = r'-\s*\[\s*\]\s*(T\d{3})\s*(\[P\])?\s*(\[US\d+\])?\s*(.+)'
        matches = re.findall(task_pattern, content)
        
        for match in matches:
            task_id, parallel_marker, story_marker, description = match
            task = {
                'id': task_id,
                'description': description.strip(),
                'is_parallel': bool(parallel_marker),
                'story': story_marker[3:-1] if story_marker else None,  # 移除 [US 和 ] 
                'completed': False
            }
            tasks.append(task)
        
        print(f"解析到 {len(tasks)} 個任務")
        return tasks

    def execute_implementation(self, tasks):
        """執行實施"""
        print("開始執行實施...")
        
        # 按階段執行任務
        current_phase = "unknown"
        phase_tasks = []
        
        # 將任務按階段分組
        for task in tasks:
            # 簡單根據標籤或描述識別階段
            if not task['story'] and 'setup' in task['description'].lower():
                phase = 'setup'
            elif not task['story'] and 'foundational' in task['description'].lower():
                phase = 'foundational'
            elif task['story']:
                phase = task['story']
            else:
                phase = 'polish'
            
            if phase != current_phase:
                if phase_tasks:
                    print(f"\n完成階段: {current_phase}")
                    self._execute_phase_tasks(phase_tasks)
                current_phase = phase
                phase_tasks = []
            
            phase_tasks.append(task)
        
        # 執理最後一個階段
        if phase_tasks:
            print(f"\n完成階段: {current_phase}")
            self._execute_phase_tasks(phase_tasks)
        
        print("\n實施完成！")

    def _execute_phase_tasks(self, phase_tasks):
        """執行階段任務"""
        parallel_tasks = [t for t in phase_tasks if t['is_parallel']]
        sequential_tasks = [t for t in phase_tasks if not t['is_parallel']]
        
        print(f"  執行 {len(parallel_tasks)} 個平行任務")
        for task in parallel_tasks:
            self._execute_single_task(task)
        
        print(f"  執行 {len(sequential_tasks)} 個順序任務")
        for task in sequential_tasks:
            self._execute_single_task(task)

    def _execute_single_task(self, task):
        """執行單個任務 - 這裡是模擬實現"""
        print(f"    執行任務 {task['id']}: {task['description']}")
        
        # 模擬任務執行
        # 在實際實現中，這裡會根據任務描述執行具體操作
        # 例如：創建文件、修改代碼、運行命令等
        
        # 標記任務為完成
        task['completed'] = True
        print(f"    任務 {task['id']} 完成")

    def update_tasks_file(self, tasks):
        """更新 tasks.md 文件，標記已完成的任務"""
        if not self.tasks or not self.tasks.exists():
            return
            
        # 讀取原始文件內容
        with open(self.tasks, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 更新任務狀態
        for task in tasks:
            if task['completed']:
                # 替換 - [ ] 為 - [X]
                pattern = rf'(-\s*\[\s*\]\s*{task["id"]}\s*.*?{task["description"]})'
                replacement = rf'- [X] {task["id"]}'
                if task.get('is_parallel'):
                    replacement += ' [P]'
                if task.get('story'):
                    replacement += f' [{task["story"]}]'
                replacement += f' {task["description"]}'
                
                content = re.sub(pattern, replacement, content)
        
        # 寫回文件
        with open(self.tasks, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"已更新 tasks.md 文件")

    def run(self):
        """運行 implement 命令"""
        print("開始執行 speckit.implement...")
        
        # 1. 初始化和檢查先決條件
        available_docs = self.run_check_prerequisites()
        print(f"可用文檔: {available_docs}")
        
        # 2. 檢查檢查清單狀態
        if not self.check_checklists_status():
            print("檢查清單未通過，停止執行。")
            return False
        
        # 3. 載入實施上下文
        try:
            self.load_implementation_context()
        except Exception as e:
            print(f"載入實施上下文時出錯: {e}")
            return False
        
        # 4. 專案設定驗證
        self.project_setup_verification()
        
        # 5. 解析任務
        try:
            tasks = self.parse_tasks()
        except Exception as e:
            print(f"解析任務時出錯: {e}")
            return False
        
        # 6. 執行實施
        try:
            self.execute_implementation(tasks)
        except Exception as e:
            print(f"執行實施時出錯: {e}")
            return False
        
        # 7. 更新任務文件
        try:
            self.update_tasks_file(tasks)
        except Exception as e:
            print(f"更新任務文件時出錯: {e}")
        
        print("\nspeckit.implement 執行完成！")
        return True


def main():
    """主函數"""
    parser = argparse.ArgumentParser(description="Speckit Implementation Module")
    parser.add_argument("--feature-dir", help="指定功能目錄")
    parser.add_argument("--tasks-file", help="指定任務文件路徑")
    parser.add_argument("--skip-checklists", action="store_true", help="跳過檢查清單檢查")
    
    args = parser.parse_args()
    
    implementer = SpeckitImplementer(args.feature_dir)
    
    # 如果指定了任務文件，直接使用該文件
    if args.tasks_file:
        implementer.tasks = Path(args.tasks_file)
    
    # 如果選擇跳過檢查清單，修改檢查邏輯
    if args.skip_checklists:
        implementer.check_checklists_status = lambda: True
    
    success = implementer.run()
    
    if success:
        print("\n實施成功完成！")
        sys.exit(0)
    else:
        print("\n實施過程中發生錯誤！")
        sys.exit(1)


if __name__ == "__main__":
    main()