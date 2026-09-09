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
      eyebrow: "macOS 菜单栏工具 · 本地与 API 翻译",
      heroTitle1: "选择语言",
      heroTitle2: "即时翻译",
      heroLede:
        "浮译会读取当前支持辅助功能的文本框，按你选择的源语言和目标语言翻译，并以低打扰的浮动框显示。可使用 macOS 本地翻译，也可切换到带故障切换的大语言模型 API。",
      ctaPrimary: "下载 FloatTrans 0.3.0",
      ctaSecondary: "查看源码",
      ctaDownload: "下载 DMG",
      ctaDownloadDmg: "下载 FloatTrans-0.3.0.dmg",
      downloadMeta: "macOS · v0.3.0 · FloatTrans-0.3.0.dmg",
      downloadTitle: "下载安装包",
      downloadBody: "打开 DMG，把 FloatTrans.app 拖进 Applications。当前为 ad-hoc 签名、未经公证，首次打开请右键 → 打开。",
      point1: "实时按句翻译",
      point2: "浮动字幕低打扰",
      point3: "本地或自选 API",
      demoHeading: "产品演示",
      demoWindowTitle: "备忘录",
      demoFieldLabel: "正在输入",
      demoCaption: "停下输入片刻后，英文会出现在浮动框里。",
      howEyebrow: "工作方式",
      howTitle: "三步闭环，全程自动",
      step1Title: "捕获当前句",
      step1Body: "通过辅助功能读取当前输入框，按中文及中英文标点识别正在编辑的句子。",
      step2Title: "选择翻译引擎",
      step2Body: "使用 macOS Translation 本地语言包，或切换到 OpenAI 兼容、Claude、DeepSeek、GLM 和自定义 API。",
      step3Title: "浮动显示",
      step3Body: "译文以字幕式浮动框出现，不抢焦点、可手动关闭，支持位置、字号与自动隐藏。",
      featuresEyebrow: "功能",
      featuresTitle: "为长时间写作而设计",
      feat1Title: "按句实时更新",
      feat1Body: "同一句会动态刷新；新句子可叠放新浮动框。最多同时保留 3 个，每个都可关闭。",
      feat2Title: "可调 Overlay",
      feat2Body: "右上角、底部居中、右下角；边距、字号、自动隐藏 5–60 秒或永不隐藏。",
      feat3Title: "应用排除",
      feat3Body: "通过文件选择器添加不想翻译的 App，密码等安全输入框始终跳过。",
      feat4Title: "模型配置",
      feat4Body: "API 密钥存入 macOS 钥匙串；模型、端点、提示词、思考模式和排序可在设置中编辑。",
      feat5Title: "隐私优先",
      feat5Body: "默认可走系统本地能力；切换 API 时，文本只发送到你配置的服务商。调试日志只留在本机，且不记录密码内容。",
      privacyEyebrow: "隐私",
      privacyTitle: "本地优先，自选 API",
      privacyBody:
        "浮译需要辅助功能权限才能读取当前文本框的内容，但不会读取密码字段。本地翻译不会上传文本；切换 API 翻译时，文本会发送到你配置的服务商。",
      privacy1: "跳过 SecureTextField / 密码框",
      privacy2: "API Key 存入 macOS 钥匙串",
      privacy3: "历史记录保存在本机 SQLite",
      privacy4: "可选排除敏感应用",
      startEyebrow: "开始使用",
      startTitle: "安装与首次设置",
      reqTitle: "系统要求",
      req1: "macOS 15 或更高版本",
      req2: "Accessibility（辅助功能）权限",
      req3: "本地翻译需要对应语言包；API 翻译需要服务商密钥",
      installTitle: "从源码构建",
      installHint: "磁盘上的应用包名为 FloatTrans.app；用户可见显示名是「浮译」。也可打 DMG：",
      setup1: "启动后在引导页打开辅助功能设置并授权。",
      setup2: "在设置中选择源语言、目标语言和本地或 API 翻译引擎。",
      whatsNewEyebrow: "v0.3.0",
      whatsNewTitle: "这次更新了什么",
      whats1Title: "多语言翻译方向",
      whats1Body: "源语言和目标语言可独立选择中文、英语、日语、俄语、韩语、法语、德语和西班牙语。",
      whats2Title: "本地 / API 双引擎",
      whats2Body: "可使用 macOS 本地翻译，或配置多个大语言模型端点并按顺序自动故障切换。",
      whats3Title: "本机历史记录",
      whats3Body: "成功翻译会保存到本机 SQLite，可设置保留时间，并按日期查看。",
      whats4Title: "Markdown / Excel 导出",
      whats4Body: "历史记录可导出为 Markdown 或 Excel，包含「序号 / 原文 / 译文」三列。",
      setup3: "在 TextEdit、浏览器等支持辅助功能的输入框中输入所选源语言。默认停下片刻即可看到译文浮动框；也可改成完整句子或快捷键触发。",
      ctaRepo: "打开 GitHub 仓库",
      ctaReadme: "阅读完整文档",
      footerTag: "开源的 macOS 实时翻译菜单栏工具。",
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
      eyebrow: "macOS menu bar · local and API translation",
      heroTitle1: "Pick languages.",
      heroTitle2: "Translate instantly.",
      heroLede:
        "FloatTrans reads Accessibility-capable text fields, translates from your selected source language to your selected target language, and shows the result in a quiet floating overlay. Use macOS local translation or switch to ordered LLM API failover.",
      ctaPrimary: "Download FloatTrans 0.3.0",
      ctaSecondary: "View source",
      ctaDownload: "Download DMG",
      ctaDownloadDmg: "Download FloatTrans-0.3.0.dmg",
      downloadMeta: "macOS · v0.3.0 · FloatTrans-0.3.0.dmg",
      downloadTitle: "Download the installer",
      downloadBody:
        "Open the DMG and drag FloatTrans.app into Applications. This build is ad-hoc signed and not notarized—first launch with Control-click → Open.",
      point1: "Sentence-aware live translation",
      point2: "Low-interruption floating overlay",
      point3: "Local or your own API",
      demoHeading: "Product demo",
      demoWindowTitle: "Notes",
      demoFieldLabel: "Typing",
      demoCaption: "Pause briefly and the English overlay appears.",
      howEyebrow: "How it works",
      howTitle: "A closed loop—fully automatic",
      step1Title: "Capture the current sentence",
      step1Body:
        "Reads the focused field via Accessibility and extracts the sentence you’re editing using Chinese and Latin punctuation.",
      step2Title: "Choose the translation engine",
      step2Body:
        "Use macOS Translation packs, or switch to OpenAI-compatible, Claude, DeepSeek, GLM, or a custom API endpoint.",
      step3Title: "Show a floating overlay",
      step3Body:
        "The translation appears like a subtitle: non-activating, closable, with position, size, and auto-hide controls.",
      featuresEyebrow: "Features",
      featuresTitle: "Built for long writing sessions",
      feat1Title: "Live sentence updates",
      feat1Body:
        "The same sentence refreshes in place; new sentences can stack. Keep up to three overlays, each closable.",
      feat2Title: "Tunable overlay",
      feat2Body: "Top-right, bottom-center, or bottom-right. Edge inset, text size, hide after 5–60s or never.",
      feat3Title: "App exclusions",
      feat3Body: "Add apps via the file picker. Password and secure fields are always skipped.",
      feat4Title: "Model configuration",
      feat4Body: "API keys live in macOS Keychain. Edit endpoints, model IDs, prompts, thinking mode, and failover order in Settings.",
      feat5Title: "Privacy first",
      feat5Body:
        "Local translation stays on-device. In API mode, text is sent only to the provider you configure. Debug logs stay local and never capture passwords.",
      privacyEyebrow: "Privacy",
      privacyTitle: "Local first, API by choice",
      privacyBody:
        "FloatTrans needs Accessibility permission to read the focused text field, but it never reads password fields. Local translation does not upload text; API mode sends text to the provider you configure.",
      privacy1: "Skips SecureTextField / passwords",
      privacy2: "API keys are stored in macOS Keychain",
      privacy3: "History is stored locally in SQLite",
      privacy4: "Optional exclusion for sensitive apps",
      startEyebrow: "Get started",
      startTitle: "Install & first-run setup",
      reqTitle: "Requirements",
      req1: "macOS 15 or later",
      req2: "Accessibility permission",
      req3: "Local translation needs language packs; API translation needs provider keys",
      installTitle: "Build from source",
      installHint: "On-disk bundle name is FloatTrans.app; the display name is 浮译. Or build a DMG with:",
      setup1: "On first launch, open Accessibility settings from onboarding and grant access.",
      setup2: "Choose source language, target language, and local or API translation in Settings.",
      whatsNewEyebrow: "v0.3.0",
      whatsNewTitle: "What's new",
      whats1Title: "Independent language directions",
      whats1Body:
        "Choose Chinese, English, Japanese, Russian, Korean, French, German, or Spanish as source and target languages.",
      whats2Title: "Local / API backends",
      whats2Body:
        "Use macOS local translation, or configure multiple LLM endpoints with ordered failover.",
      whats3Title: "Local history",
      whats3Body: "Successful translations are saved in local SQLite history with configurable retention.",
      whats4Title: "Markdown / Excel export",
      whats4Body: "Export history by day with Index / Source / Translation columns.",
      setup3:
        "Type your selected source language in TextEdit, a browser, or another Accessibility-capable field. Pause to see the overlay, or switch to complete-sentence or shortcut timing.",
      ctaRepo: "Open the GitHub repo",
      ctaReadme: "Read the full docs",
      footerTag: "An open-source macOS live translation menu bar app.",
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
