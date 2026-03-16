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
- "Save as TERMS_OF_SERVICE.md"
- "Save as terms-of-service.md"
- "Don't save, I'll copy it"

If the user chooses to save, write the file to the current working directory using the chosen filename.

Regardless of the save choice, show the full Terms of Service in a markdown code block.

Done! Do not proceed with any additional steps unless the user asks.
