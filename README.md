# FloatTrans

[项目主页](https://krisir.github.io/floattrans/) · [GitHub](https://github.com/krisir/floattrans)

FloatTrans 是一款 macOS 菜单栏实时中译英工具。它读取当前应用中支持 Accessibility 的文本输入框，将中文句子翻译成英文，并以低打扰的浮动框显示结果。

## 功能

- 实时监听支持 macOS Accessibility 的文本输入框
- 按句子识别，支持中文及中英文标点
- 同一句动态更新，新句子显示新的浮动框
- 浮动框自动换行并动态调整高度
- 最多同时保留 3 个浮动框，每个都可手动关闭
- 可选择替换上一句或保留上一句
- 支持右上角、底部居中、右下角位置
- 可调整屏幕边距、字体大小和自动隐藏时间
- 自动隐藏支持 3–60 秒，或选择永不隐藏
- 支持排除应用和通过文件选择器添加应用
- 提供本地日志，方便排查 Accessibility 兼容性

## 系统要求

- macOS 26 或更高版本
- Swift 6 / Xcode 26
- Accessibility 权限
- macOS 中文 → 英文 Translation 语言包

## 构建和运行

```sh
swift test
zsh Scripts/build-app.sh
open FloatTrans.app
```

也可以直接运行开发版本：

```sh
swift run FloatTrans
```

磁盘上的应用包和可执行文件名为 `FloatTrans`；用户看到的显示名是「浮译」。

以前安装过 `LiveEnglish.app` 的，请删掉旧包再装 `FloatTrans.app`。辅助功能权限按 Bundle ID 记录，换路径或换签名后可能要在「系统设置 → 隐私与安全性 → 辅助功能」里重新打开浮译。

## 打 DMG

需要 [create-dmg](https://github.com/create-dmg/create-dmg)：

```sh
brew install create-dmg
zsh Scripts/build-dmg.sh
```

产物在 `dist/FloatTrans-<version>.dmg`。打开后把 `FloatTrans.app` 拖进 Applications。默认是本机 ad-hoc 签名，**没有公证**；发给别人时，对方需要右键 → 打开。

公开分发（个人或公司 Apple Developer Program 均可）时，先配置 Developer ID，再公证：

```sh
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="notary"
zsh Scripts/build-dmg.sh
```

`CODESIGN_IDENTITY` 用 Developer ID Application 签 `.app`（Hardened Runtime + 时间戳）。`NOTARY_PROFILE` 是事先用 `xcrun notarytool store-credentials` 存进钥匙串的配置名；未设置时仍会打出 DMG，但不会提交公证。

## 首次使用

1. 启动 FloatTrans。
2. 在引导页打开 Accessibility 设置。
3. 在“系统设置 → 隐私与安全性 → 辅助功能”中开启 FloatTrans。
4. 在设置页安装中文 → 英文语言包并等待下载完成。
5. 在 TextEdit、浏览器、企业微信等支持 Accessibility 的文本框中输入中文。
6. 停止输入片刻后，英文翻译会显示在浮动框中。

## 设置

- General：启用翻译、登录时启动、Accessibility 状态
- Translation：源语言、目标语言和翻译速度
- Overlay：位置、显示行为、字号、屏幕边距、隐藏时间和预览
- Privacy：添加或移除排除翻译的应用

点击 `Preview Overlay` 可以预览当前浮动框位置和样式。

## 调试日志

日志写入本地，不会主动上传：

```sh
tail -f /tmp/liveenglish-debug.log
```

日志主要记录文本长度、应用 Bundle ID 和 Accessibility 元素状态。正式发布时应关闭或脱敏用户相关日志。

## 翻译实现

macOS 26+ 使用系统 `Translation` Framework 和本地语言模型。语言包未安装、下载未完成或系统不支持该语言对时，翻译不会返回结果。低版本系统使用 Demo fallback，主要用于开发测试。

## 项目结构

```text
Sources/LiveEnglish/
├── App.swift          应用入口、菜单栏和设置界面
├── Input.swift        Accessibility 监听、文本读取和防抖
├── Models.swift       句子提取、翻译协议和协调器
├── Overlay.swift      浮动框和显示策略
├── Settings.swift     设置模型和持久化
└── Diagnostics.swift  本地调试日志
```

## 注意事项

不同应用对 macOS Accessibility API 的支持程度不同。TextEdit、浏览器和部分原生应用通常可以正常读取；使用自绘控件或未暴露文本元素的应用可能无法获取输入内容。
