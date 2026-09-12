## Why

更换语言对会话 `configure` 不会清理旧方向的 continuations。新会话 `attach` 后会把旧请求也用新语言会话恢复，或至少让被取消任务滞留 8 秒。

## What Changes

- 按语言对（配置世代）保存本地翻译等待者。
- 配置变更时立即以取消/不可用错误恢复旧等待者。
- 新会话只恢复当前语言对的等待者。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: 本地会话换向立即作废旧请求，不得用新语言对翻译旧文本，也不得空等就绪超时。

## Impact

- `TranslationSessionHolder`、`TranslationCoordinator` 与本地会话取消测试。
