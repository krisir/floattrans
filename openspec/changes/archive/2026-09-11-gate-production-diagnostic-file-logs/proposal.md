## Why

生产环境同步写 `/tmp/liveenglish-debug.log`。每个输入快照和防抖触发都会创建 formatter、打开文件、写入、关闭文件；轮询每 0.5 秒一次，日志既不轮转也不受 debug 开关控制，持续消耗 I/O 且无上限。

## What Changes

- Release 构建默认不再写该文件；仅 Debug 构建或显式调试开关启用文件日志。
- 例行诊断继续走系统日志（OSLog）。
- 若文件日志开启，写入离开输入热路径，并做容量限制或轮转。

This change has no spec-level product behavior; it is a runtime/reliability implementation fix (`skip_specs: true`).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- None.

## Impact

- `DiagnosticLog` 与 `Input.swift` / `App.swift` / `Models.swift` 中的调用点。
