## Why

同一句的校正翻译只更新悬浮窗内容，保留原先的 hide task。用户刚看到更新结果就可能立即消失。

## What Changes

- 更新已有悬浮窗文本时，取消当前自动隐藏计时器，并按当前「隐藏时间」设置重新计时。
- 「永不隐藏」仍然不启动自动隐藏。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: 校正译文出现后，悬浮窗按完整隐藏时长重新计时。

## Impact

- `OverlayCoordinator.show` 对已有 entry 的更新路径及其测试。
