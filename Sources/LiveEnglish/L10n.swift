import Foundation

enum UILanguage: String, CaseIterable, Identifiable {
    case chinese = "zh"
    case english = "en"

    var id: String { rawValue }

    var pickerLabel: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
}

enum L10n {
    // MARK: - Menu bar

    static func pause(_ lang: UILanguage) -> String {
        lang == .chinese ? "暂停" : "Pause"
    }
    static func resume(_ lang: UILanguage) -> String {
        lang == .chinese ? "继续" : "Resume"
    }
    static func menuSettings(_ lang: UILanguage) -> String {
        lang == .chinese ? "设置…" : "Settings…"
    }
    static func quit(_ lang: UILanguage) -> String {
        lang == .chinese ? "退出" : "Quit"
    }

    // MARK: - Settings chrome

    static func settingsWindowTitle(_ lang: UILanguage) -> String {
        lang == .chinese ? "浮译设置" : "FloatTrans Settings"
    }
    static func tabGeneral(_ lang: UILanguage) -> String {
        lang == .chinese ? "通用" : "General"
    }
    static func tabTranslation(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译" : "Translation"
    }
    static func tabOverlay(_ lang: UILanguage) -> String {
        lang == .chinese ? "悬浮窗" : "Overlay"
    }
    static func tabPrivacy(_ lang: UILanguage) -> String {
        lang == .chinese ? "隐私" : "Privacy"
    }
    static func tabAbout(_ lang: UILanguage) -> String {
        lang == .chinese ? "关于" : "About"
    }

    static func enableLiveTranslation(_ lang: UILanguage) -> String {
        lang == .chinese ? "启用实时翻译" : "Enable Live Translation"
    }
    static func launchAtLogin(_ lang: UILanguage) -> String {
        lang == .chinese ? "登录时启动" : "Launch at Login"
    }
    static func interfaceLanguage(_ lang: UILanguage) -> String {
        lang == .chinese ? "界面语言" : "Interface Language"
    }
    static func accessibility(_ lang: UILanguage) -> String {
        lang == .chinese ? "辅助功能" : "Accessibility"
    }
    static func permissionGranted(_ lang: UILanguage) -> String {
        lang == .chinese ? "✓ 已授权" : "✓ Authorized"
    }
    static func permissionHint(_ lang: UILanguage) -> String {
        lang == .chinese ? "需要辅助功能权限才能读取输入内容" : "Accessibility permission is required to read typed text"
    }
    static func openSystemSettings(_ lang: UILanguage) -> String {
        lang == .chinese ? "打开系统设置" : "Open System Settings"
    }

    static func translationBackend(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译方式" : "Translation Engine"
    }
    static func backendLocal(_ lang: UILanguage) -> String {
        lang == .chinese ? "macOS 本地翻译" : "macOS On-device"
    }
    static func backendLanguageModel(_ lang: UILanguage) -> String {
        lang == .chinese ? "大语言模型 API" : "Language Model API"
    }
    static func sourceLanguage(_ lang: UILanguage) -> String {
        lang == .chinese ? "源语言" : "Source Language"
    }
    static func targetLanguage(_ lang: UILanguage) -> String {
        lang == .chinese ? "目标语言" : "Target Language"
    }
    static func languagePair(_ source: Language, _ target: Language, _ lang: UILanguage) -> String {
        let sourceName = lang == .chinese ? source.chineseName : source.englishName
        let targetName = lang == .chinese ? target.chineseName : target.englishName
        return "\(sourceName) → \(targetName)"
    }
    static func modelSettings(_ lang: UILanguage) -> String {
        lang == .chinese ? "大语言模型" : "Language Models"
    }
    static func modelSettingsHint(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "按顺序尝试已启用的模型。当前模型超时或失败时自动切换到下一项。"
            : "Enabled models are tried in order. A timeout or failure advances to the next model."
    }
    static func addModel(_ lang: UILanguage) -> String {
        lang == .chinese ? "添加模型" : "Add Model"
    }
    static func removeModel(_ lang: UILanguage) -> String {
        lang == .chinese ? "删除模型" : "Remove Model"
    }
    static func modelName(_ lang: UILanguage) -> String {
        lang == .chinese ? "名称" : "Name"
    }
    static func provider(_ lang: UILanguage) -> String {
        lang == .chinese ? "服务商" : "Provider"
    }
    static func providerName(_ provider: LLMProvider, _ lang: UILanguage) -> String {
        switch provider {
        case .openAICompatible: return lang == .chinese ? "OpenAI 兼容" : "OpenAI compatible"
        case .anthropic: return lang == .chinese ? "Claude（Anthropic）" : "Claude (Anthropic)"
        case .deepSeek: return "DeepSeek"
        case .glm: return lang == .chinese ? "GLM（智谱）" : "GLM (Zhipu)"
        case .custom: return lang == .chinese ? "自定义" : "Custom"
        }
    }
    static func endpointURL(_ lang: UILanguage) -> String {
        lang == .chinese ? "API URL" : "API URL"
    }
    static func apiKey(_ lang: UILanguage) -> String {
        lang == .chinese ? "API 密钥" : "API Key"
    }
    static func modelID(_ lang: UILanguage) -> String {
        lang == .chinese ? "模型名称" : "Model ID"
    }
    static func prompt(_ lang: UILanguage) -> String {
        lang == .chinese ? "提示词" : "Prompt"
    }
    static func thinkingMode(_ lang: UILanguage) -> String {
        lang == .chinese ? "思考模式" : "Reasoning Mode"
    }
    static func thinkingAutomatic(_ lang: UILanguage) -> String {
        lang == .chinese ? "自动" : "Automatic"
    }
    static func thinkingOff(_ lang: UILanguage) -> String {
        lang == .chinese ? "非思考" : "Non-thinking"
    }
    static func thinkingOn(_ lang: UILanguage) -> String {
        lang == .chinese ? "思考" : "Thinking"
    }
    static func failoverTimeout(_ lang: UILanguage) -> String {
        lang == .chinese ? "切换超时" : "Fail-over Timeout"
    }
    static func timeoutSeconds(_ lang: UILanguage, _ value: Int) -> String {
        lang == .chinese ? "超过 (value) 秒切换" : "Switch after (value) sec"
    }
    static func apiKeyKeychainHint(_ lang: UILanguage) -> String {
        lang == .chinese ? "密钥保存在此 Mac 的钥匙串中。" : "Keys are stored in this Mac's Keychain."
    }
    static func modelPlaceholder(_ lang: UILanguage) -> String {
        lang == .chinese ? "例如：DeepSeek 主模型" : "For example: Primary DeepSeek"
    }
    static func urlPlaceholder(_ lang: UILanguage) -> String {
        lang == .chinese ? "https://api.example.com/v1" : "https://api.example.com/v1"
    }
    static func modelIDPlaceholder(_ lang: UILanguage) -> String {
        lang == .chinese ? "例如：deepseek-chat" : "For example: deepseek-chat"
    }
    static func promptPlaceholder(_ lang: UILanguage) -> String {
        lang == .chinese ? "留空使用默认翻译提示词" : "Leave empty to use the default translation prompt"
    }
    static func noModels(_ lang: UILanguage) -> String {
        lang == .chinese ? "还没有配置模型。" : "No models configured."
    }
    static func modelEnabled(_ lang: UILanguage) -> String {
        lang == .chinese ? "启用" : "Enabled"
    }
    static func localTranslationPrivacy(_ lang: UILanguage) -> String {
        lang == .chinese ? "本地翻译不会把输入内容发送到网络。" : "On-device translation does not send typed text over the network."
    }
    static func llmTranslationPrivacy(_ lang: UILanguage) -> String {
        lang == .chinese ? "大模型模式会把输入内容发送到所选 API 服务商。" : "Language-model mode sends typed text to the selected API provider."
    }

    static func translationDirection(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译方向" : "Direction"
    }
    static func translationDirectionValue(_ lang: UILanguage) -> String {
        lang == .chinese ? "中文 → 英文" : "Chinese → English"
    }
    static func translationDirectionValue(_ source: Language, _ target: Language, _ lang: UILanguage) -> String {
        languagePair(source, target, lang)
    }
    static func translationSpeed(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译速度" : "Translation Speed"
    }
    static func speedFast(_ lang: UILanguage) -> String {
        lang == .chinese ? "快速" : "Fast"
    }
    static func speedBalanced(_ lang: UILanguage) -> String {
        lang == .chinese ? "均衡" : "Balanced"
    }
    static func speedRelaxed(_ lang: UILanguage) -> String {
        lang == .chinese ? "舒缓" : "Relaxed"
    }
    static func languageResources(_ lang: UILanguage) -> String {
        lang == .chinese ? "语言资源" : "Language Pack"
    }
    static func languagesReady(_ lang: UILanguage) -> String {
        lang == .chinese ? "中文 → 英文 · 已就绪 ✓" : "Chinese → English · Ready ✓"
    }
    static func languagesUnsupported(_ lang: UILanguage) -> String {
        lang == .chinese ? "此 Mac 不支持中文 → 英文" : "Chinese → English is not supported on this Mac"
    }
    static func downloadLanguage(_ lang: UILanguage) -> String {
        lang == .chinese ? "下载语言" : "Download Languages"
    }
    static func languagesChecking(_ lang: UILanguage) -> String {
        lang == .chinese ? "正在检查…" : "Checking…"
    }
    static func languagesPreparing(_ lang: UILanguage) -> String {
        lang == .chinese ? "正在准备下载…" : "Preparing download…"
    }
    static func languagesDownloading(_ lang: UILanguage) -> String {
        lang == .chinese ? "正在下载语言…" : "Downloading languages…"
    }
    static func languagesStillDownloading(_ lang: UILanguage) -> String {
        lang == .chinese ? "下载仍在进行，请稍后在系统设置中查看。" : "Download still in progress. Check Language & Region."
    }
    static func languagesDownloadFailed(_ lang: UILanguage) -> String {
        lang == .chinese ? "语言下载未完成。" : "Language download was not completed."
    }
    static func languagesReady(_ source: Language, _ target: Language, _ lang: UILanguage) -> String {
        "\(languagePair(source, target, lang)) · " + (lang == .chinese ? "已就绪 ✓" : "Ready ✓")
    }
    static func languagesUnsupported(_ source: Language, _ target: Language, _ lang: UILanguage) -> String {
        lang == .chinese
            ? "此 Mac 不支持\(languagePair(source, target, lang))"
            : "\(languagePair(source, target, lang)) is not supported on this Mac"
    }
    static func languagesStillDownloading(_ source: Language, _ target: Language, _ lang: UILanguage) -> String {
        lang == .chinese
            ? "\(languagePair(source, target, lang)) 下载仍在进行，请稍后在系统设置中查看。"
            : "Download for \(languagePair(source, target, lang)) is still in progress. Check Language & Region."
    }

    static func groupPosition(_ lang: UILanguage) -> String {
        lang == .chinese ? "位置" : "Position"
    }
    static func groupAppearance(_ lang: UILanguage) -> String {
        lang == .chinese ? "外观" : "Appearance"
    }
    static func groupBehavior(_ lang: UILanguage) -> String {
        lang == .chinese ? "行为" : "Behavior"
    }
    static func displayPosition(_ lang: UILanguage) -> String {
        lang == .chinese ? "显示位置" : "Placement"
    }
    static func textSize(_ lang: UILanguage) -> String {
        lang == .chinese ? "文字大小" : "Text Size"
    }
    static func edgeDistance(_ lang: UILanguage) -> String {
        lang == .chinese ? "距顶部距离" : "Edge Distance"
    }
    static func newTranslationBehavior(_ lang: UILanguage) -> String {
        lang == .chinese ? "新翻译出现时" : "When a new translation appears"
    }
    static func hideAfter(_ lang: UILanguage) -> String {
        lang == .chinese ? "隐藏时间" : "Hide After"
    }
    static func seconds(_ lang: UILanguage, _ value: Int) -> String {
        lang == .chinese ? "\(value) 秒" : "\(value) sec"
    }
    static func neverHide(_ lang: UILanguage) -> String {
        lang == .chinese ? "永不隐藏" : "Never hide"
    }
    static func previewOverlay(_ lang: UILanguage) -> String {
        lang == .chinese ? "预览悬浮窗" : "Preview Overlay"
    }

    static func positionTopRight(_ lang: UILanguage) -> String {
        lang == .chinese ? "右上" : "Top Right"
    }
    static func positionBottomCenter(_ lang: UILanguage) -> String {
        lang == .chinese ? "底部居中" : "Bottom Center"
    }
    static func positionBottomRight(_ lang: UILanguage) -> String {
        lang == .chinese ? "右下" : "Bottom Right"
    }
    static func sizeSmall(_ lang: UILanguage) -> String {
        lang == .chinese ? "小" : "Small"
    }
    static func sizeMedium(_ lang: UILanguage) -> String {
        lang == .chinese ? "中" : "Medium"
    }
    static func sizeLarge(_ lang: UILanguage) -> String {
        lang == .chinese ? "大" : "Large"
    }
    static func behaviorReplace(_ lang: UILanguage) -> String {
        lang == .chinese ? "替换上一条" : "Replace Previous"
    }
    static func behaviorStack(_ lang: UILanguage) -> String {
        lang == .chinese ? "向下堆叠" : "Stack Below"
    }

    static func privacyExplanation(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "浮译不会读取或翻译以下应用内的文本。"
            : "FloatTrans will not read or translate text inside these apps."
    }
    static func addApplication(_ lang: UILanguage) -> String {
        lang == .chinese ? "＋ 添加应用…" : "+ Add Application…"
    }
    static func unknownApp(_ lang: UILanguage) -> String {
        lang == .chinese ? "未知应用" : "Unknown App"
    }

    // MARK: - About

    static func productName(_ lang: UILanguage) -> String {
        "浮译"
    }
    static func version(_ lang: UILanguage) -> String {
        lang == .chinese ? "版本 0.1.0" : "Version 0.1.0"
    }
    static func aboutBody(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "一款安静、实时的中译英菜单栏工具。\n读取当前文本框内容，并在不打扰工作的情况下显示翻译结果。\n翻译在本机完成。\n\nMIT 开源许可证"
            : "A quiet, real-time Chinese-to-English menu bar tool.\nIt reads the current text field and shows translations without interrupting your work.\nTranslation runs on-device.\n\nMIT License"
    }
    static func aboutRepo(_ lang: UILanguage) -> String {
        lang == .chinese ? "仓库：github.com/krisir/floattrans" : "Repo: github.com/krisir/floattrans"
    }
    static func aboutDeveloper(_ lang: UILanguage) -> String {
        lang == .chinese ? "开发者：psychicsirk@gmail.com" : "Developer: psychicsirk@gmail.com"
    }
}
