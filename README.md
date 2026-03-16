<p align="center">
  <a href="https://upratehq.com">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg" />
      <source media="(prefers-color-scheme: light)" srcset="assets/logo.svg" />
      <img src="assets/logo.svg" alt="Uprate" width="260" height="58" />
    </picture>
  </a>
</p>

<p align="center">
  AI-powered tools for mobile app developers, right in your terminal.
</p>

---

## Install

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```bash
curl -fsSL https://raw.githubusercontent.com/cleevio-agents/uprate-skills/main/install.sh | bash
```

## Skills

| Command | Description |
|---|---|
| [`/uprate generate-icon`](#uprate-generate-icon--icon-generator) | Generate a production-ready app icon |
| [`/uprate generate-changelog`](#uprate-generate-changelog--release-notes-generator) | Release notes from git history |
| [`/uprate generate-privacy-policy`](#uprate-generate-privacy-policy--privacy-policy-generator) | Privacy policy from codebase context |
| [`/uprate generate-terms-of-service`](#uprate-generate-terms-of-service--terms-of-service-generator) | Terms of Service for your mobile app |
| [`/uprate launch-producthunt`](#uprate-launch-producthunt--product-hunt-launch) | Product Hunt submission copy |

---

### 🎨 `/uprate generate-icon` - Icon Generator

Generate a production-ready app icon from your codebase context:

1. Analyzes your project: name, colors, platform
2. Proposes 4 icon concepts tailored to your app
3. Generates a high-quality icon via AI
4. Returns a shareable preview URL

Guests can generate up to 2 icons without an account. [Sign up free](https://app.upratehq.com/register) to save and download.

---

### 📝 `/uprate generate-changelog` - Release Notes Generator

Generate user-facing release notes from your git history:

1. Detects your latest tag and commit range
2. Summarizes changes in plain English (no dev jargon)
3. Formats for App Store, Google Play, and/or GitHub Release
4. Outputs copy-ready text with character limits respected

---

### 🔒 `/uprate generate-privacy-policy` - Privacy Policy Generator

Generate a ready-to-publish privacy policy from your codebase context:

1. Scans your project for data collection practices and third-party SDKs
2. Asks targeted questions about your business and jurisdiction
3. Generates a plain-language privacy policy tailored to your app
4. Saves or displays the result, ready for App Store or Google Play

---

### 📄 `/uprate generate-terms-of-service` - Terms of Service Generator

Generate a customized Terms of Service for your mobile app:

1. Analyzes your project: platform, payments, accounts, content
2. Asks clarifying questions about your app and business
3. Generates a plain-language Terms of Service as markdown
4. Saves the document to your project directory

---

### 🚀 `/uprate launch-producthunt` - Product Hunt Launch

Prepare your Product Hunt submission without leaving the terminal:

1. Analyzes your project: name, description, category
2. Asks targeted questions about your goals and audience
3. Generates all copy: tagline, description, topics, maker comment, first comment
4. Provides a launch-day checklist and optionally saves everything to a file

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/cleevio-agents/uprate-skills/main/uninstall.sh | bash
```

---

<p align="center">
  <a href="https://upratehq.com">Uprate</a> ·
  <a href="https://github.com/cleevio-agents/uprate-skills/issues">Report an issue</a> ·
  <a href="LICENSE">MIT License</a>
</p>
