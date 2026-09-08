(() => {
  const strings = {
    zh: {
      skip: "跳到主要内容",
      brandSubtitle: "浮译",
      navDemo: "演示",
      navWhatsNew: "更新",
      navFeatures: "功能",
      navPrivacy: "隐私",
      navStart: "开始使用",
      navGitHub: "GitHub",
      eyebrow: "macOS 菜单栏工具 · 本地翻译",
      heroTitle1: "输入中文",
      heroTitle2: "看见英文",
      heroLede:
        "浮译会读取当前支持辅助功能的文本框，把正在输入的中文句子翻译成英文，并以低打扰的浮动框显示。默认无需复制或粘贴；需要时可以打开「替换原文」（⌥⇧[）或「复制译文」（⌥⇧]）。",
      ctaPrimary: "下载 FloatTrans 0.2.0",
      ctaSecondary: "查看源码",
      ctaDownload: "下载 DMG",
      ctaDownloadDmg: "下载 FloatTrans-0.2.0.dmg",
      downloadMeta: "macOS · v0.2.0 · FloatTrans-0.2.0.dmg",
      downloadTitle: "下载安装包",
      downloadBody: "打开 DMG，把 FloatTrans.app 拖进 Applications。当前为 ad-hoc 签名、未经公证，首次打开请右键 → 打开。",
      point1: "实时按句翻译",
      point2: "浮动字幕低打扰",
      point3: "系统本地模型，不上云",
      demoHeading: "产品演示",
      demoWindowTitle: "备忘录",
      demoFieldLabel: "正在输入",
      demoCaption: "停下输入片刻后，英文会出现在浮动框里。",
      howEyebrow: "工作方式",
      howTitle: "三步闭环，全程自动",
      step1Title: "捕获当前句",
      step1Body: "通过辅助功能读取当前输入框，按中文及中英文标点识别正在编辑的句子。",
      step2Title: "本地翻译",
      step2Body: "使用 macOS Translation 框架与本地语言模型。默认停顿后触发，也可改成打完标点再译，或按快捷键再译。",
      step3Title: "浮动显示",
      step3Body: "英文以字幕式浮动框出现，不抢焦点、可手动关闭，支持位置、字号与自动隐藏。",
      featuresEyebrow: "功能",
      featuresTitle: "为长时间写作而设计",
      feat1Title: "按句实时更新",
      feat1Body: "同一句会动态刷新；新句子可叠放新浮动框。最多同时保留 3 个，每个都可关闭。",
      feat2Title: "可调 Overlay",
      feat2Body: "右上角、底部居中、右下角；边距、字号、自动隐藏 5–60 秒或永不隐藏。",
      feat3Title: "应用排除",
      feat3Body: "通过文件选择器添加不想翻译的 App，密码等安全输入框始终跳过。",
      feat4Title: "中英界面",
      feat4Body: "菜单栏与设置页支持简体中文 / English，切换后立即生效。",
      feat5Title: "隐私优先",
      feat5Body: "翻译走系统本地能力，无需 API Key、无需自建服务器。调试日志只留在本机，且不记录密码内容。",
      privacyEyebrow: "隐私",
      privacyTitle: "你的输入留在本机",
      privacyBody:
        "浮译需要辅助功能权限才能读取当前文本框的内容，但不会读取密码字段，也不会把原文或译文上传到我们的服务器——因为我们根本没有服务器。",
      privacy1: "跳过 SecureTextField / 密码框",
      privacy2: "使用 macOS 本地 Translation 语言包",
      privacy3: "可选排除敏感应用",
      privacy4: "Release 日志不输出用户原文",
      startEyebrow: "开始使用",
      startTitle: "安装与首次设置",
      reqTitle: "系统要求",
      req1: "macOS 15 或更高版本",
      req2: "Accessibility（辅助功能）权限",
      req3: "中文 → 英文 Translation 语言包",
      installTitle: "从源码构建",
      installHint: "磁盘上的应用包名为 FloatTrans.app；用户可见显示名是「浮译」。也可打 DMG：",
      setup1: "启动后在引导页打开辅助功能设置并授权。",
      setup2: "在设置中安装中文 → 英文语言包并等待下载完成。",
      whatsNewEyebrow: "v0.2.0",
      whatsNewTitle: "这次更新了什么",
      whats1Title: "三种翻译时机",
      whats1Body: "超时翻译、完整句子翻译，或快捷键触发（默认 ⌃⇧T）。翻译速度只影响超时模式。",
      whats2Title: "替换原文与复制译文",
      whats2Body: "打开开关后，⌥⇧[ 把当前英文写回输入框，⌥⇧] 复制到剪贴板。快捷键可改。",
      whats3Title: "可选朗读",
      whats3Body: "朗读翻译结果。超时翻译时不会出声，请改用完整句子或快捷键。",
      whats4Title: "检查更新",
      whats4Body: "设置 → 关于对照 GitHub Releases。有新版本就打开对应发布页。",
      setup3: "在 TextEdit、浏览器等支持辅助功能的输入框中输入中文。默认停下片刻即可看到英文浮动框；也可改成完整句子或快捷键触发。",
      ctaRepo: "打开 GitHub 仓库",
      ctaReadme: "阅读完整文档",
      footerTag: "开源的 macOS 实时中译英菜单栏工具。",
      footerIcon: "图标来自 Tabler Icons（MIT）",
      pageTitle: "FloatTrans · 浮译",
      demoZh: "我觉得这个功能还可以再优化一下",
      demoEn: "I think this feature could still be improved.",
    },
    en: {
      skip: "Skip to main content",
      brandSubtitle: "Floating Translator",
      navDemo: "Demo",
      navWhatsNew: "What's new",
      navFeatures: "Features",
      navPrivacy: "Privacy",
      navStart: "Get started",
      navGitHub: "GitHub",
      eyebrow: "macOS menu bar · on-device translation",
      heroTitle1: "Write in Chinese.",
      heroTitle2: "See it in English.",
      heroLede:
        "FloatTrans reads Accessibility-capable text fields, translates the sentence you’re typing into English, and shows it in a quiet floating overlay. Copy and paste are optional: turn on Replace Original (⌥⇧[) or Copy Translation (⌥⇧]) when you need them.",
      ctaPrimary: "Download FloatTrans 0.2.0",
      ctaSecondary: "View source",
      ctaDownload: "Download DMG",
      ctaDownloadDmg: "Download FloatTrans-0.2.0.dmg",
      downloadMeta: "macOS · v0.2.0 · FloatTrans-0.2.0.dmg",
      downloadTitle: "Download the installer",
      downloadBody:
        "Open the DMG and drag FloatTrans.app into Applications. This build is ad-hoc signed and not notarized—first launch with Control-click → Open.",
      point1: "Sentence-aware live translation",
      point2: "Low-interruption floating overlay",
      point3: "System local models, no cloud",
      demoHeading: "Product demo",
      demoWindowTitle: "Notes",
      demoFieldLabel: "Typing",
      demoCaption: "Pause briefly and the English overlay appears.",
      howEyebrow: "How it works",
      howTitle: "A closed loop—fully automatic",
      step1Title: "Capture the current sentence",
      step1Body:
        "Reads the focused field via Accessibility and extracts the sentence you’re editing using Chinese and Latin punctuation.",
      step2Title: "Translate on device",
      step2Body:
        "Uses the macOS Translation framework and local language models. Default is pause-to-translate; you can also translate on punctuation or a shortcut.",
      step3Title: "Show a floating overlay",
      step3Body:
        "English appears like a subtitle: non-activating, closable, with position, size, and auto-hide controls.",
      featuresEyebrow: "Features",
      featuresTitle: "Built for long writing sessions",
      feat1Title: "Live sentence updates",
      feat1Body:
        "The same sentence refreshes in place; new sentences can stack. Keep up to three overlays, each closable.",
      feat2Title: "Tunable overlay",
      feat2Body: "Top-right, bottom-center, or bottom-right. Edge inset, text size, hide after 5–60s or never.",
      feat3Title: "App exclusions",
      feat3Body: "Add apps via the file picker. Password and secure fields are always skipped.",
      feat4Title: "Chinese & English UI",
      feat4Body: "Menu bar and Settings support Simplified Chinese / English and update immediately.",
      feat5Title: "Privacy first",
      feat5Body:
        "Translation stays on-device—no API keys, no servers of ours. Debug logs stay local and never capture passwords.",
      privacyEyebrow: "Privacy",
      privacyTitle: "Your typing stays on your Mac",
      privacyBody:
        "FloatTrans needs Accessibility permission to read the focused text field, but it never reads password fields and never uploads text to our servers—because there are none.",
      privacy1: "Skips SecureTextField / passwords",
      privacy2: "Uses macOS on-device Translation packs",
      privacy3: "Optional exclusion for sensitive apps",
      privacy4: "Release logs omit user source text",
      startEyebrow: "Get started",
      startTitle: "Install & first-run setup",
      reqTitle: "Requirements",
      req1: "macOS 15 or later",
      req2: "Accessibility permission",
      req3: "Chinese → English Translation language pack",
      installTitle: "Build from source",
      installHint: "On-disk bundle name is FloatTrans.app; the display name is 浮译. Or build a DMG with:",
      setup1: "On first launch, open Accessibility settings from onboarding and grant access.",
      setup2: "Install the Chinese → English language pack in Settings and wait for the download.",
      whatsNewEyebrow: "v0.2.0",
      whatsNewTitle: "What's new",
      whats1Title: "Three translation timings",
      whats1Body:
        "On Pause, Complete Sentence, or On Shortcut (default ⌃⇧T). Translation speed only affects On Pause.",
      whats2Title: "Replace and copy",
      whats2Body:
        "Turn the actions on, then ⌥⇧[ writes English back into the field and ⌥⇧] copies it. Shortcuts are customizable.",
      whats3Title: "Optional speech",
      whats3Body: "Read translations aloud. On Pause stays silent—use Complete Sentence or On Shortcut to hear them.",
      whats4Title: "Check for updates",
      whats4Body: "Settings → About compares GitHub Releases and opens the release page when a newer version exists.",
      setup3:
        "Type Chinese in TextEdit, a browser, or another Accessibility-capable field. Pause to see the overlay, or switch to complete-sentence or shortcut timing.",
      ctaRepo: "Open the GitHub repo",
      ctaReadme: "Read the full docs",
      footerTag: "An open-source macOS live Chinese→English menu bar translator.",
      footerIcon: "Icon from Tabler Icons (MIT)",
      pageTitle: "FloatTrans · Floating Translator",
      demoZh: "我觉得这个功能还可以再优化一下",
      demoEn: "I think this feature could still be improved.",
    },
  };

  const root = document.documentElement;
  const zhEl = document.getElementById("typed-zh");
  const enEl = document.getElementById("typed-en");
  const bubble = document.querySelector(".overlay-bubble");
  const langButtons = document.querySelectorAll("[data-set-lang]");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  let lang = localStorage.getItem("ft-lang") || (navigator.language?.startsWith("zh") ? "zh" : "zh");
  let demoTimer = 0;
  let demoToken = 0;

  function t(key) {
    return strings[lang][key] ?? strings.zh[key] ?? key;
  }

  function applyLanguage(next) {
    lang = next in strings ? next : "zh";
    localStorage.setItem("ft-lang", lang);
    root.lang = lang === "zh" ? "zh-CN" : "en";
    root.dataset.lang = lang;
    document.title = t("pageTitle");

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (!key) return;
      const value = t(key);
      if (el.tagName === "INPUT" || el.tagName === "TEXTAREA") {
        el.value = value;
      } else {
        el.textContent = value;
      }
    });

    langButtons.forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.getAttribute("data-set-lang") === lang));
    });

    restartDemo();
  }

  function sleep(ms, token) {
    return new Promise((resolve, reject) => {
      demoTimer = window.setTimeout(() => {
        if (token !== demoToken) reject(new Error("cancelled"));
        else resolve();
      }, ms);
    });
  }

  async function runDemo(token) {
    if (!zhEl || !enEl || !bubble) return;

    const zh = t("demoZh");
    const en = t("demoEn");

    zhEl.textContent = "";
    enEl.textContent = "";
    bubble.classList.remove("is-visible");

    if (reduceMotion) {
      zhEl.textContent = zh;
      enEl.textContent = en;
      bubble.classList.add("is-visible");
      return;
    }

    try {
      for (let i = 1; i <= zh.length; i += 1) {
        zhEl.textContent = zh.slice(0, i);
        await sleep(70 + (i % 3 === 0 ? 40 : 0), token);
      }

      await sleep(520, token);
      enEl.textContent = en;
      bubble.classList.add("is-visible");
      await sleep(3200, token);
      bubble.classList.remove("is-visible");
      await sleep(400, token);

      if (token === demoToken) runDemo(token);
    } catch {
      /* cancelled */
    }
  }

  function restartDemo() {
    demoToken += 1;
    window.clearTimeout(demoTimer);
    runDemo(demoToken);
  }

  langButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      const next = btn.getAttribute("data-set-lang");
      if (next) applyLanguage(next);
    });
  });

  applyLanguage(lang);
})();
