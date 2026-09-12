## Why

历史记录的 reload、record、deleteAll 各自启动独立任务，没有序号或取消机制。用户清空历史后，先前已排队的 record 仍可能重新写入并显示记录。

## What Changes

- 由单一串行机制处理 UI 侧的 reload / record / deleteAll。
- 确认清空时推进 generation，丢弃清空前已排队的写入和过期 reload。
- 清空之后新接受的翻译仍可按当前保留策略入账。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `history`: 确认删除历史是可线性化的用户操作；删除前已排队的写入不得再填回列表。

## Impact

- `TranslationHistoryController` 及其 store 调用顺序、删除竞态测试。
