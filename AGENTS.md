本仓库是多插件仓库，当前包含：

- `app_market`
- `flutter_native_image`
- `manage_calendar_events`
- `system_shortcuts`

请按以下约定操作：

1. 命令范围

- 默认只在目标插件目录内操作，避免跨插件误改。
- 没有明确目标时，先根据本次任务判断对应插件，再执行命令。

2. Flutter SDK 选择

- 本机有两个 Flutter SDK：`flutter` 和 `flutter_tpc`。
- 普通 Flutter / Dart / Android / iOS 相关命令，默认使用 `flutter`。
- 只要是和 HarmonyOS / `ohos/` / HAP / 鸿蒙示例工程相关的 Flutter 命令，统一使用 `flutter_tpc`。
- 当前仓库中，`manage_calendar_events` 已包含 `ohos/` 实现；其他插件当前按普通 Flutter 插件处理。

3. 鸿蒙相关规则

- 涉及 `manage_calendar_events/ohos` 或 `manage_calendar_events/example/ohos` 的 Flutter 命令，使用 `flutter_tpc`。
- 非 Flutter 的鸿蒙原生命令（如 `hvigor`、`ohpm`）按项目实际需要执行，不强制套用 `flutter_tpc`。

4. 提交规则

- 优先提交源码、配置、文档和确有必要的锁文件变更。
- 不要把本地环境文件、IDE 元数据、缓存和构建产物当作应提交内容，除非用户明确要求。
- 特别注意避免提交这类文件：`.DS_Store`、`.metadata`、`.idea/`、`build/`、`.hvigor/`、`oh_modules/`、`node_modules/`、`local.properties`。
- 提交前先看 `git status`，确认没有把无关插件或本地生成物一起带上。
