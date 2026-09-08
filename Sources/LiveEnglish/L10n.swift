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

    static func translationDirection(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译方向" : "Direction"
    }
    static func translationDirectionValue(_ lang: UILanguage) -> String {
        lang == .chinese ? "中文 → 英文" : "Chinese → English"
    }
    static func translationSpeed(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译速度" : "Translation Speed"
    }
    static func translationTiming(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译时机" : "Translation Timing"
    }
    static func timingPause(_ lang: UILanguage) -> String {
        lang == .chinese ? "超时翻译" : "On Pause"
    }
    static func timingCompleteSentence(_ lang: UILanguage) -> String {
        lang == .chinese ? "完整句子翻译" : "Complete Sentence"
    }
    static func timingShortcut(_ lang: UILanguage) -> String {
        lang == .chinese ? "快捷键触发翻译" : "On Shortcut"
    }
    static func translateShortcut(_ lang: UILanguage) -> String {
        lang == .chinese ? "翻译快捷键" : "Translate Shortcut"
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
    static func groupActions(_ lang: UILanguage) -> String {
        lang == .chinese ? "快捷操作" : "Actions"
    }
    static func replaceOriginal(_ lang: UILanguage) -> String {
        lang == .chinese ? "替换原文" : "Replace Original"
    }
    static func replaceShortcut(_ lang: UILanguage) -> String {
        lang == .chinese ? "替换快捷键" : "Replace Shortcut"
    }
    static func copyTranslation(_ lang: UILanguage) -> String {
        lang == .chinese ? "复制译文" : "Copy Translation"
    }
    static func copyShortcut(_ lang: UILanguage) -> String {
        lang == .chinese ? "复制快捷键" : "Copy Shortcut"
    }
    static func shortcutRecording(_ lang: UILanguage) -> String {
        lang == .chinese ? "按下快捷键…" : "Press a shortcut…"
    }
    static func replaceOriginalHint(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "按下快捷键，把当前译文写回输入框。"
            : "Press the shortcut to replace the field with the current translation."
    }
    static func copyTranslationHint(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "按下快捷键把当前英文译文复制到剪贴板。"
            : "Press the shortcut to copy the current English translation."
    }
    static func groupSpeech(_ lang: UILanguage) -> String {
        lang == .chinese ? "朗读" : "Speech"
    }
    static func readTranslationsAloud(_ lang: UILanguage) -> String {
        lang == .chinese ? "朗读翻译结果" : "Read Translations Aloud"
    }
    static func autoSpeakTimingHint(_ lang: UILanguage) -> String {
        lang == .chinese
            ? "超时翻译时不会朗读。请改用完整句子翻译或快捷键触发翻译。"
            : "On Pause does not speak. Use Complete Sentence or On Shortcut to hear translations."
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
    static func version(
        _ lang: UILanguage,
        marketing: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    ) -> String {
        let value = marketing ?? ""
        return lang == .chinese ? "版本 \(value)" : "Version \(value)"
    }
    static func checkForUpdates(_ lang: UILanguage) -> String {
        lang == .chinese ? "检查更新" : "Check for Updates"
    }
    static func checkForUpdatesChecking(_ lang: UILanguage) -> String {
        lang == .chinese ? "正在检查…" : "Checking…"
    }
    static func checkForUpdatesUpToDate(_ lang: UILanguage) -> String {
        lang == .chinese ? "已是最新版本" : "You’re up to date"
    }
    static func checkForUpdatesFailed(_ lang: UILanguage) -> String {
        lang == .chinese ? "检查更新失败" : "Couldn’t check for updates"
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
