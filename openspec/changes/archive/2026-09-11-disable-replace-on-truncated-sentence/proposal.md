## Why

提取器对超过 300 字的句子只保留句尾，但替换逻辑仍把这段截断文本当作原文。开启「替换原文」时只会换掉句尾，留下前半句，造成中英混杂。

## What Changes

- 提取时若因长度上限截断，该次翻译仍可显示和复制，但必须禁用「替换原文」。
- 不把截断后的后缀当作可替换的完整原文范围。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: 被截断的源句不得通过 Replace Original 写入焦点字段。

## Impact

- `SentenceExtractor`、pending replace payload、`FieldReplacement` / `AppState` 替换路径及其测试。
