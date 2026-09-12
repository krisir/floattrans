## Why

「替换原文」用 `.backwards` 字符串查找定位原文。字段里出现重复句子时，会命中最后一次出现，而不是光标所在的那一句，可能改掉别处内容。

## What Changes

- 句子提取时记下光标所在处的精确 UTF-16 范围，并一路传到替换动作。
- 替换前再读取焦点字段，校验该范围内容仍是捕获的原文。
- 禁止再用向后字符串搜索作为替换定位的回退。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: Replace Original 只改光标捕获的那一处范围；重复文本不得改到另一处。

## Impact

- `SentenceExtractor`、`InputCoordinator`、`FieldReplacement`、`AppState` 及其替换相关测试。
