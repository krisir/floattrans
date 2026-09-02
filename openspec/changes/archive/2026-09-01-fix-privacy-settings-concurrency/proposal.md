## Why

当前版本虽然能够构建并通过测试，但隐私排除逻辑在读取文本之后才生效，可能读取用户明确排除的应用内容；同时翻译速度修改不会跨重启保存，定时器还会触发 Swift 并发隔离警告。修复这些问题可以使设置行为符合界面承诺，并消除潜在的隐私与未来编译兼容性风险。

## What Changes

- 在读取辅助功能文本前，根据当前前台应用的 bundle identifier 判断是否被排除；被排除的应用不读取、不翻译其文本。
- 将翻译速度作为持久化设置保存，并在启动时恢复，保持现有速度选项和默认值不变。
- 调整 Accessibility 轮询定时器与快照读取的执行方式，确保主 actor 隔离正确且不再产生编译警告。
- 补充隐私、速度持久化和定时器行为的自动化测试。

## Capabilities

### New Capabilities

### Modified Capabilities

- `settings`: 强化隐私排除的读取语义，确保排除应用在文本读取前被拦截；翻译速度设置必须跨应用启动持久化。

## Impact

- 主要影响 `Sources/LiveEnglish/Input.swift`、`Settings.swift`、`App.swift` 和 `SettingsUI.swift`，以及相关测试。
- 不改变用户可见的翻译速度选项、设置界面结构或持久化键的兼容性；现有设置应继续可迁移。
- 不引入新的第三方依赖或外部 API。
