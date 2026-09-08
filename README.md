# FloatTrans

[项目主页](https://krisir.github.io/floattrans/) · [下载 v0.2.0](https://github.com/krisir/floattrans/releases/download/v0.2.0/FloatTrans-0.2.0.dmg) · [GitHub](https://github.com/krisir/floattrans)

FloatTrans 是一款 macOS 菜单栏实时翻译工具。它读取当前应用中支持 Accessibility 的文本输入框，按设置的语言方向翻译，并以低打扰的浮动框显示结果。

## 0.2.0 新功能

- **翻译时机**：超时翻译（默认）、完整句子翻译，或快捷键触发翻译（默认 ⌃⇧T）
- **替换原文 / 复制译文**：默认 ⌥⇧[ 写回输入框，⌥⇧] 复制当前英文；快捷键可在设置里改
- **朗读翻译**：可选朗读译文；超时翻译模式下不会朗读，需改用完整句子或快捷键
- **检查更新**：设置 → 关于里对照 GitHub Releases，有新版本则打开对应发布页
- **中英界面**：菜单栏和设置支持简体中文 / English
- 支持 macOS 15 及以上（系统 Translation 语言包）

## 功能

- 翻译页可选择 macOS 本地翻译或大语言模型 API
- 源语言与目标语言可独立选择：中文、英语、日语、俄语、韩语、法语、德语、西班牙语（例如中→日、中→俄、英→中、英→俄）
- 本地翻译会检查当前语言对；缺少系统语言包时可在应用内发起 macOS 下载流程
- 支持 OpenAI 兼容接口、Claude、DeepSeek、GLM 和自定义 API URL；可配置模型名、密钥、提示词和思考/非思考模式
- 可添加多个 API 模型并在设置中拖动排序；首个模型超时或请求失败会按顺序自动切换，切换阈值可配置
- API 密钥保存于 macOS 钥匙串，不会写入应用偏好设置
- 实时监听支持 macOS Accessibility 的文本输入框
- 按句子识别，支持所选源语言的文字系统及中英文标点
- 同一句动态更新，新句子显示新的浮动框
- 浮动框自动换行并动态调整高度
- 最多同时保留 3 个浮动框，每个都可手动关闭
- 可选择替换上一句或向下堆叠
- 支持右上角、底部居中、右下角位置
- 可调整屏幕边距、字体大小和自动隐藏时间
- 自动隐藏支持 5–60 秒，或选择永不隐藏
- 三种翻译时机，以及可选的替换原文、复制译文、朗读
- 设置关于页可检查 GitHub 更新
- 支持排除应用和通过文件选择器添加应用
- 提供本地日志，方便排查 Accessibility 兼容性

## 系统要求

- macOS 15 或更高版本
- Swift 6 / Xcode 16 或更高版本
- Accessibility 权限
- 选择 macOS 本地翻译时，对应语言对的系统 Translation 语言包

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
4. 在设置 → 翻译中选择本地翻译与源语言、目标语言；缺语言包时点击下载并等待完成。
5. 如需 API 翻译，切换到「大语言模型 API」，添加一个模型并填写 URL、密钥和模型名称。
6. 在 TextEdit、浏览器、企业微信等支持 Accessibility 的文本框中输入所选源语言。
7. 默认在停止输入片刻后显示译文；也可在设置里改成打完标点再译，或按 ⌃⇧T 再译。
8. 如需写回输入框或复制译文，在设置的翻译页打开「替换原文」或「复制译文」，再用对应快捷键（默认 ⌥⇧[ / ⌥⇧]）。
9. 设置 → 关于可检查是否有新版本。

## 设置

- 通用：启用翻译、登录时启动、界面语言、Accessibility 状态
- 翻译：本地 / API 引擎、源语言 / 目标语言、语言包、速度、翻译时机、替换原文、复制译文、朗读及各自快捷键
- API 模型：多个模型可拖动排序；为每项配置提供商、URL、密钥、模型、提示词和思考模式，设置全局自动切换超时
- 悬浮窗：位置、显示行为、字号、屏幕边距、隐藏时间和预览
- 隐私：添加或移除排除翻译的应用
- 关于：版本、仓库链接、检查更新

点击「预览悬浮窗」可以预览当前浮动框位置和样式。

## 调试日志

日志写入本地，不会主动上传：

```sh
tail -f /tmp/liveenglish-debug.log
```

日志主要记录文本长度、应用 Bundle ID 和 Accessibility 元素状态。正式发布时应关闭或脱敏用户相关日志。

## 翻译实现

macOS 本地翻译使用系统 `Translation` Framework 和本地下载的语言包。语言包未安装、下载未完成或系统不支持该语言对时，应用会提示下载，翻译不会返回 Demo 占位英文。大语言模型模式使用用户指定的 API，输入内容会发送到选中的服务商。

## 项目结构

```text
Sources/LiveEnglish/
├── App.swift          应用入口、菜单栏和关于页
├── SettingsUI.swift   设置窗口
├── HotKey.swift       替换 / 复制 / 翻译快捷键
├── Input.swift        Accessibility 监听、文本读取和防抖
├── Models.swift       句子提取、翻译协议和协调器
├── Overlay.swift      浮动框和显示策略
├── Settings.swift     设置模型和持久化
├── Speech.swift       朗读策略
├── L10n.swift         中英界面文案
├── LLMTranslation.swift 多模型 API 请求、提示词和故障切换
├── KeychainStore.swift  API 密钥钥匙串存储
├── UpdateChecker.swift  GitHub 检查更新
└── Diagnostics.swift  本地调试日志
```

## 注意事项

不同应用对 macOS Accessibility API 的支持程度不同。TextEdit、浏览器和部分原生应用通常可以正常读取；使用自绘控件或未暴露文本元素的应用可能无法获取输入内容。
