# MouseRecorder

MouseRecorder 是一个 macOS SwiftUI 鼠标点击录制与回放工具。它可以记录鼠标点击坐标、按键类型和触发间隔，之后按原始节奏回放，也可以手动编辑事件、导入导出 JSON，并设置定时运行。

## 功能特性

- 录制左键、右键和中键点击事件
- 自动记录事件间隔，回放时还原点击节奏
- 在事件列表中编辑名称、按键、坐标和延迟
- 支持全屏坐标拾取器，便于精确选择点击位置
- 支持 JSON 导入和导出，方便保存或复用点击流程
- 支持指定本地时间定时回放，并可设置毫秒级提前或延后偏移
- 录制和回放时自动切换为悬浮迷你窗口，减少遮挡目标界面

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15 或更高版本
- Swift 5
- 需要在系统设置中授予辅助功能权限

## 快速开始

1. 克隆项目并进入目录：

   ```bash
   git clone <your-repo-url>
   cd mouse_record
   ```

2. 使用 Xcode 打开项目：

   ```bash
   open MouseRecorder.xcodeproj
   ```

3. 选择 `MouseRecorder` scheme，点击 Run。

4. 首次启动后，根据提示打开：

   `System Settings > Privacy & Security > Accessibility`

   然后允许 `MouseRecorder` 控制电脑。权限生效后重新启动应用会更稳定。

## 命令行构建

```bash
xcodebuild \
  -project MouseRecorder.xcodeproj \
  -scheme MouseRecorder \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 使用方式

- 开始录制：点击工具栏中的“开始录制”，或使用 `Command + R`
- 停止录制：点击迷你窗口中的“停止录制”，或使用 `Shift + Command + R`
- 回放事件：点击“回放”，或使用 `Command + P`
- 停止回放：点击迷你窗口中的“停止回放”，或使用 `Shift + Command + P`
- 手动添加事件：点击工具栏 `+`，填写坐标、按键和延迟
- 修改坐标：选择一个或多个事件后使用坐标拾取器
- 定时运行：进入“定时运行”页面，设置本地触发时间和偏移
- 导入导出：通过“更多”菜单导入或导出 `MouseRecorderEvents.json`

回放会真实点击当前屏幕位置。运行前请确认目标窗口、坐标和数据状态，避免触发不可撤销操作。

## 项目结构

```text
mouse_record/
├── MouseRecorder.xcodeproj/          # Xcode 工程
├── MouseRecorder/
│   ├── App/                          # 应用入口和窗口生命周期
│   ├── Models/                       # 鼠标事件与按键模型
│   ├── Services/                     # 录制、回放、定时、导入导出等服务
│   ├── Views/                        # SwiftUI 页面与组件
│   └── Resources/                    # Info.plist、entitlements、Assets
├── Examples/                         # 可导入的示例事件文件
├── docs/                             # 使用说明和架构说明
└── .github/                          # GitHub 工作流与协作模板
```

## JSON 数据格式

事件文件是一个 JSON 数组，每个元素表示一次鼠标点击：

```json
[
  {
    "id": "F4A9C6B1-2A1D-4C3A-9A5F-816C2C2C0C22",
    "name": "Click Login",
    "x": 640,
    "y": 420,
    "button": "Left",
    "delayBeforeFire": 0.5,
    "timestamp": "2026-01-01T12:00:00Z"
  }
]
```

可参考 [Examples/MouseRecorderEvents.sample.json](Examples/MouseRecorderEvents.sample.json)。

## 文档

- [使用指南](docs/USAGE.md)
- [架构说明](docs/ARCHITECTURE.md)
- [贡献指南](CONTRIBUTING.md)
- [更新日志](CHANGELOG.md)

## 开发计划

- 增加单元测试和 UI 测试
- 支持录制拖拽、滚轮和键盘事件
- 支持循环回放和多组脚本管理
- 增加截图或录屏辅助校准坐标
- 提供打包发布脚本

## 许可证

当前仓库尚未指定开源许可证。正式公开发布前建议根据你的发布意图添加 `LICENSE` 文件。
