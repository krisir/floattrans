# FloatTrans

[项目主页](https://krisir.github.io/floattrans/) · [下载 v0.3.0](https://github.com/krisir/floattrans/releases/download/v0.3.0/FloatTrans-0.3.0.dmg) · [GitHub](https://github.com/krisir/floattrans)

FloatTrans 是一款 macOS 菜单栏实时翻译工具。它读取当前应用中支持 Accessibility 的文本输入框，按设置的语言方向翻译，并以低打扰的浮动框显示结果。

## 0.3.0 新功能

- **多语言方向**：源语言与目标语言可独立选择中文、英语、日语、俄语、韩语、法语、德语和西班牙语
- **本地 / API 双引擎**：继续支持 macOS 本地 Translation，也可切换到大语言模型 API
- **多模型故障切换**：支持 OpenAI 兼容接口、Claude、DeepSeek、GLM 和自定义端点；多个模型可拖动排序并按超时自动切换
- **安全保存密钥**：API Key 存入 macOS 钥匙串，应用偏好设置里只保存模型的非敏感配置
- **翻译历史**：默认不记录；可选 1 天、7 天、30 天、6 个月或永久保留，也可确认后删除全部记录
- **导出历史**：支持按日期分组导出 Markdown 或 Excel，列为「序号 / 原文 / 译文」
- **设置体验更新**：更大的默认设置窗口、全宽导航标签、历史记录入口，以及目标语言默认语音朗读
- **设置窗口可达**：打开设置时显示 Dock 图标，可用 Dock 或 Cmd+Tab 回到设置

## 功能

- 翻译页可选择 macOS 本地翻译或大语言模型 API
- 源语言与目标语言可独立选择：中文、英语、日语、俄语、韩语、法语、德语、西班牙语（例如中→日、中→俄、英→中、英→俄）
- 本地翻译会检查当前语言对；缺少系统语言包时可在应用内发起 macOS 下载流程
- 支持 OpenAI 兼容接口、Claude、DeepSeek、GLM 和自定义 API URL；可配置模型名、密钥、提示词和思考/非思考模式
- 可添加多个 API 模型并在设置中拖动排序；首个模型超时或请求失败会按顺序自动切换，切换阈值可配置
- API 密钥保存于 macOS 钥匙串，不会写入应用偏好设置
- 默认不记录翻译历史；需要时可选 1 天、7 天、30 天、6 个月或永久保存，支持确认后删除全部记录，并导出 Markdown 或 Excel
- 实时监听支持 macOS Accessibility 的文本输入框
- 按句子识别，支持所选源语言的文字系统及中英文标点
- 同一句动态更新，新句子显示新的浮动框
- 浮动框自动换行并动态调整高度
- 最多同时保留 3 个浮动框，每个都可手动关闭
- 可选择替换上一句或向下堆叠
- 支持右上角、底部居中、右下角位置
- 可调整屏幕边距、字体大小和自动隐藏时间
- 自动隐藏支持 5–60 秒，或选择永不隐藏
- 三种翻译时机，以及可选的替换原文、复制译文；朗读时机可多选，语音随目标语言自动切换
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
- 翻译：本地 / API 引擎、源语言 / 目标语言、语言包、速度、翻译时机、替换原文、复制译文、朗读时机多选及各自快捷键
- API 模型：多个模型可拖动排序；为每项配置提供商、URL、密钥、模型、提示词和思考模式，设置全局自动切换超时
- 悬浮窗：位置、显示行为、字号、屏幕边距、隐藏时间和预览
- 历史记录：按日期查看原文和译文，默认不记录，可改保存期限，确认后删除全部记录，导出 Markdown 或 Excel
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
├── TranslationHistory.swift 本机翻译历史和 Markdown / Excel 导出
├── UpdateChecker.swift  GitHub 检查更新
└── Diagnostics.swift  本地调试日志
```

## 注意事项

不同应用对 macOS Accessibility API 的支持程度不同。TextEdit、浏览器和部分原生应用通常可以正常读取；使用自绘控件或未暴露文本元素的应用可能无法获取输入内容。
