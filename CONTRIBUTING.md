# 贡献指南

欢迎为 MouseRecorder 提交问题、建议和代码改进。

## 开发流程

1. Fork 仓库并创建功能分支。
2. 使用 Xcode 打开 `MouseRecorder.xcodeproj`。
3. 保持改动聚焦，一次 PR 只解决一个明确问题。
4. 提交前至少运行一次 macOS 构建。

```bash
xcodebuild \
  -project MouseRecorder.xcodeproj \
  -scheme MouseRecorder \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 代码风格

- 遵循现有 SwiftUI 组件组织方式。
- 与系统交互的逻辑优先放在 `Services/`。
- 可序列化数据结构放在 `Models/`。
- 保持 UI 文案简洁，并与现有中文界面一致。
- 只在复杂逻辑处添加必要注释。

## 提交 PR 前检查

- 项目可以编译。
- README 或 docs 已随行为变化同步更新。
- 没有提交 `.DerivedData`、`.DS_Store`、`xcuserdata` 等本地文件。
- 对需要辅助功能权限的改动，说明测试环境和验证方式。

## 报告问题

提交 bug 时请尽量包含：

- macOS 版本和 Xcode 版本
- 问题发生的操作步骤
- 期望结果和实际结果
- 是否已授予辅助功能权限
- 如有可能，附上示例事件 JSON
