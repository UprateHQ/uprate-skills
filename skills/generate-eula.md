---
name: generate-eula
description: Generate an End User License Agreement tailored to your app's distribution model, monetization, and user data handling
---

# Uprate EULA Generator

Generate an End User License Agreement tailored to your app, based on your project's context and your input.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Project

Spawn a `general-purpose` subagent to scan the codebase:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-eula-analyzer":
Prompt: Analyze the current project and return a JSON object with the following fields:

1. "appName": The app name (from package.json, Info.plist, AndroidManifest.xml, pubspec.yaml, app.json, or similar config files). null if not found.
2. "platform": One of "iOS", "Android", "Web", "cross-platform", or null.
3. "distributionChannels": An array of detected distribution channels. Use the Glob tool to find project files and the Grep tool to search for keywords:
   - Include "App Store" if any of these exist: *.xcodeproj, Info.plist, StoreKit references, SKProduct, AppStoreConnect
   - Include "Google Play" if any of these exist: build.gradle, AndroidManifest.xml, Google Play Billing, BillingClient
   - Include "Web" if web frameworks are detected: next, react, vue, angular, express, django, rails, flask, fastapi
4. "hasSubscriptions": true/false — search for keywords: subscription, recurring, auto-renew, RevenueCat, StoreKit, BillingClient, stripe subscription, paywall
5. "hasOneTimePurchase": true/false — search for keywords: purchase, buy, unlock, premium, pro, paid (but not subscription-related)
6. "hasAds": true/false — search for keywords: admob, google-mobile-ads, banner, interstitial, rewarded, adview, applovin, unity-ads, ironsource
7. "hasAccounts": true/false — search for keywords: login, signup, auth, user, profile, account
8. "hasUserContent": true/false — search for keywords: post, comment, upload, review, message, chat

Search broadly across source files, config files, and dependency manifests. Return ONLY the JSON object, no other text.
```

Parse the JSON output from the agent. Present the findings to the user:

```
I analyzed your project and found:
- **App:** {appName}
- **Platform:** {platform}
- **Distribution:** {distributionChannels}
- **Subscriptions detected:** {hasSubscriptions}
- **One-time purchases detected:** {hasOneTimePurchase}
- **Ads detected:** {hasAds}
- **User accounts detected:** {hasAccounts}
- **User-generated content detected:** {hasUserContent}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

If the user wants to adjust, incorporate their changes before proceeding.

### Step 2: Ask Clarifying Questions

Use AskUserQuestion for each question, one at a time:

1. **Operator type** — "Who operates this app?"
   Options: "Individual / Sole trader", "Company / LLC", "Non-profit", "Other"

2. **Monetization model** — "Which monetization models apply?"
   Options: "Free", "One-time purchase", "Subscription", "In-app purchases", "Ad-supported"
   Use multiSelect: true (apps can have multiple monetization models).

3. **License scope** — "What is the intended license scope?"
   Options: "Personal use only", "Personal and commercial use"

4. **Governing law** — "Which jurisdiction should govern this agreement?"
   Options: "United States", "European Union", "United Kingdom", "Other"

5. **Contact email** — "What email address should users contact for legal inquiries?"
   Use AskUserQuestion with free text input (no predefined options).

### Step 3: Generate the EULA

Based on the codebase analysis from Step 1 and the answers from Step 2, generate a complete End User License Agreement in markdown.

Include all applicable sections from this list:

**Always include:**
- **Agreement to Terms** — acceptance by downloading, installing, or using the app
- **License Grant** — scope based on monetization model and license scope answer; specify whether the license is limited, non-exclusive, non-transferable, and revocable
- **License Restrictions** — no reverse engineering, decompilation, modification, redistribution, sublicensing, or rental
- **Intellectual Property** — all rights, title, and interest remain with the operator
- **Disclaimers** — software provided "as is" with no warranties, express or implied
- **Limitation of Liability** — cap on damages, exclusion of consequential damages
- **Termination** — conditions under which the license may be terminated by either party
- **Changes to Agreement** — how users will be notified of updates
- **Governing Law** — based on the chosen jurisdiction, including dispute resolution
- **Contact Information** — using the provided email
- **Effective Date** — using today's date

**Include only if applicable:**
- **Subscription Terms** — only if subscriptions detected or selected. Cover auto-renewal, cancellation policy, and refund terms.
- **In-App Purchases** — only if one-time purchases or IAP detected/selected. Cover non-transferability and refund via app store.
- **Advertising** — only if ads detected or selected. Disclose third-party ad networks and ad-related data collection.
- **User Accounts** — only if accounts detected. Cover account responsibility, security, and operator's right to terminate accounts.
- **User-Generated Content** — only if user content detected. Cover license grant from user to operator, content standards, and right to remove content.
- **Third-Party Services** — if third-party SDKs or services are detected. Disclaim responsibility for third-party terms and policies.
- **Apple App Store Terms** — only if "App Store" is in distribution channels. Include Apple as third-party beneficiary, compliance with App Store usage rules, and maintenance/support disclaimer.
- **Google Play Terms** — only if "Google Play" is in distribution channels. Include acknowledgment of Google Play terms and refund policy reference.

Rules:
- Skip sections that don't apply (e.g., no Subscription Terms for a free app with no subscriptions)
- Use plain, readable language — avoid excessive legalese
- Use the app name throughout the document
- Format as clean markdown with `#` for the title and `##` for each section

### Step 4: Output

Present a brief summary of what was generated:

```
Generated EULA for {appName}:
- {number} sections
- Covers: {list of included section names}
- Distribution: {distributionChannels}
- Jurisdiction: {governing law}
```

Use AskUserQuestion with options:
- "Push to Uprate project"
- "Save as EULA.md"
- "Both (push + save)"
- "Don't save, I'll copy it"

If the user chooses to save (i.e. "Save as EULA.md" or "Both (push + save)"), write the file to the current working directory using the chosen filename.

Regardless of the save choice, show the full EULA in a markdown code block.

### Step 5: Push to Uprate Indie

If the user chose "Push to Uprate project" or "Both (push + save)" in Step 4:

1. **Read config**: Read `~/.uprate/config.json` via Bash (`cat ~/.uprate/config.json 2>/dev/null || echo "{}"`). Check if `indie.url` and `indie.apiKey` exist.

2. **Setup (if needed)**: If the `indie` block is missing:
   - Tell the user: "To push content to your Uprate project, I need your instance URL and API key. You can create an API key at your Uprate instance under Settings > API Keys."
   - Use AskUserQuestion to ask for the instance URL (e.g., `https://app.example.com`). Use free text input.
   - Use AskUserQuestion to ask for the API key (starts with `uprt_`). Use free text input.
   - Validate by running: `curl -s -w "\n%{http_code}" -H "Authorization: Bearer {apiKey}" -H "Accept: application/json" "{url}/api/v1/projects"`
   - If the last line is `200`, save the config: read existing `~/.uprate/config.json`, merge in `{"indie": {"url": "{url}", "apiKey": "{apiKey}"}}`, write back.
   - If not 200, tell the user the key is invalid and ask them to try again.

3. **Select project**: Call `GET {url}/api/v1/projects` with Bearer auth. Parse the `data` array. Use AskUserQuestion to present each project as an option (show name and platforms). If no projects exist, tell the user to create one in the web app first.

4. **Push EULA**: Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_legal
   project_uuid: {selected_uuid}
   payload: {"content_markdown": "<the full generated EULA>", "source": "cc_skill", "page_type": "eula"}
   ```

   Parse the result. If success, show: "EULA pushed to your Uprate project! Hosted at: {hosted_url}"
   If error, show the error message.

Done! Do not proceed with any additional steps unless the user asks.
