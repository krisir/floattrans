## Why

模型编辑器对 draft 的每个变化立即写入 `SettingsStore`，随后重配翻译服务、取消请求、清空缓存、隐藏悬浮窗并停止朗读。填写 API Key 或提示词时体验会跳，并产生频繁 Keychain 写入。

## What Changes

- 模型编辑保持本地 draft；在失焦或显式保存时才提交。
- 未提交的按键不得取消进行中的翻译、隐藏悬浮窗，或写入 Keychain。
- 丢弃 draft 不得改动已存储的模型配置。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `settings`: 编辑 LLM 模型时，未提交的按键不得反复打断翻译或写入密钥。

## Impact

- `LLMModelEditor`、`SettingsStore.llmModels`、`AppState.applyTranslationSettings`、Keychain 持久化及其测试。
