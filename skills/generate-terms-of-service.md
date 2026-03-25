---
name: generate-terms-of-service
description: Generate a customized Terms of Service for your mobile app based on codebase analysis
---

# Uprate Terms of Service Generator

Generate a customized Terms of Service document based on your project's context and your input.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Project

Spawn a `general-purpose` subagent to scan the codebase:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-tos-analyzer":
Prompt: Analyze the current project and return a JSON object with the following fields:

1. "appName": The app name (from package.json, Info.plist, AndroidManifest.xml, pubspec.yaml, app.json, or similar config files). null if not found.
2. "platform": One of "iOS", "Android", "Web", "cross-platform", or null.
3. "hasPayments": true/false — search for keywords: purchase, subscription, payment, RevenueCat, StoreKit, Billing, stripe, paywall, premium, pro
4. "hasAccounts": true/false — search for keywords: login, signup, auth, user, profile, account
5. "hasUserContent": true/false — search for keywords: post, comment, upload, review, message, chat

Search broadly across source files, config files, and dependency manifests. Return ONLY the JSON object, no other text.
```

Parse the JSON output from the agent. Present the findings to the user:

```
I analyzed your project and found:
- **App:** {appName}
- **Platform:** {platform}
- **Payments detected:** {hasPayments}
- **User accounts detected:** {hasAccounts}
- **User-generated content detected:** {hasUserContent}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

### Step 2: Ask Clarifying Questions

Use AskUserQuestion for each question, one at a time:

1. **Operator type** — "Who operates this app?"
   Options: "Individual", "Company", "Non-profit", "Other"

2. **Payment model** — "What is the payment model?"
   Options: "Free", "One-time purchase", "Subscription", "In-app purchases", "Multiple payment types"

3. **User accounts** — "Does the app require user accounts?"
   Options: "No accounts", "Email and password", "Social login", "Both email and social login"

4. **User-generated content** — "Can users create content?"
   Options: "No user content", "Only visible to the user themselves", "Visible to other users"

5. **Governing law** — "Which jurisdiction should govern these terms?"
   Options: "United States", "European Union", "United Kingdom", "Other"

6. **Contact email** — "What email address should users contact for legal inquiries?"
   Use AskUserQuestion with free text input (no predefined options).

### Step 3: Generate the Terms of Service

Based on the codebase analysis from Step 1 and the answers from Step 2, generate a complete Terms of Service document in markdown.

Include all applicable sections from this list:
- **Acceptance of Terms** — always include
- **Description of Service** — always include, using app name and platform
- **User Accounts** — only if the app has accounts
- **Payment Terms** — only if the app has payments
- **User-Generated Content** — only if users can create content
- **Prohibited Uses** — always include
- **Intellectual Property** — always include
- **Disclaimers and Limitation of Liability** — always include
- **Governing Law** — always include, using the chosen jurisdiction
- **Changes to Terms** — always include
- **Contact Information** — always include, using the provided email
- **Effective Date** — always include, using today's date

Rules:
- Skip sections that don't apply (e.g., no Payment Terms section for a free app)
- Use plain, readable language — avoid excessive legalese
- Use the app name throughout the document
- Format as clean markdown with `#` for the title and `##` for each section

### Step 4: Output

Present a brief summary of what was generated:

```
Generated Terms of Service for {appName}:
- {number} sections
- Covers: {list of included section names}
- Jurisdiction: {governing law}
```

Use AskUserQuestion with options:
- "Push to Uprate project"
- "Save as TERMS_OF_SERVICE.md"
- "Both (push + save)"
- "Don't save, I'll copy it"

If the user chooses to save (i.e. "Save as TERMS_OF_SERVICE.md" or "Both (push + save)"), write the file to the current working directory using the chosen filename.

Regardless of the save choice, show the full Terms of Service in a markdown code block.

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

4. **Push Terms of Service**: Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_legal
   project_uuid: {selected_uuid}
   payload: {"content_markdown": "<the full generated Terms of Service>", "source": "cc_skill", "page_type": "terms_of_service"}
   ```

   Parse the result. If success, show: "Terms of Service pushed to your Uprate project! Hosted at: {hosted_url}"
   If error, show the error message.

Done! Do not proceed with any additional steps unless the user asks.
