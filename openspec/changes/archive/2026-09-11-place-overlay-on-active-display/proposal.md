## Why

输入监控最终总是把结果绑定到 `NSScreen.main`，而不是活动输入窗口所在屏幕。副屏写字时翻译可能出现在主屏。

## What Changes

- 根据焦点窗口或鼠标位置解析目标屏幕。
- 仅在宿主未提供可用几何信息时回退到主屏。
- 设置里的「预览悬浮窗」仍可出现在主屏。

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: 活动输入在副屏时，翻译悬浮窗出现在该副屏。

## Impact

- `AccessibilityMonitor` 的屏幕解析、`InputCoordinator` 传递的 `NSScreen`、`OverlayCoordinator` 布局。
