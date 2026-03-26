---
name: sync
description: Scan your codebase and sync all generated content to your Uprate project
---

# Uprate Sync

Scan your codebase and automatically generate + push App Store and Google Play metadata to your Uprate project. One command to fill most of your submission checklist.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Configure Connection

Read `~/.uprate/config.json` via Bash (`cat ~/.uprate/config.json 2>/dev/null || echo "{}"`).

If the `indie` block is missing (no `indie.url` or `indie.apiKey`):
- Tell the user: "Welcome to Uprate Sync! I'll scan your codebase and fill your Uprate project with generated metadata.\n\nFirst, I need to connect to your Uprate instance. You can create an API key at your instance under Settings > API Keys."
- Use AskUserQuestion to ask for the instance URL (e.g., `https://app.example.com`). Use free text input.
- Use AskUserQuestion to ask for the API key (starts with `uprt_`). Use free text input.
- Validate by running: `curl -s -w "\n%{http_code}" -H "Authorization: Bearer {apiKey}" -H "Accept: application/json" "{url}/api/v1/projects"`
- If valid (last line is `200`), save the config: read existing `~/.uprate/config.json`, merge in `{"indie": {"url": "{url}", "apiKey": "{apiKey}"}}`, write back.
- If not 200, tell the user the key is invalid and ask them to try again.

### Step 2: Select or Create Project

Call `GET {url}/api/v1/projects` with Bearer auth. Parse the `data` array.

If projects exist, use AskUserQuestion with each project as an option (show name + platforms), plus "Create new project" as an option.

If no projects exist or user chose "Create new project":
- Use AskUserQuestion for the app name (free text)
- Use AskUserQuestion for platforms: "iOS only", "Android only", "Both iOS and Android"
- Create via the push agent:
  ```
  Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
  Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
  Operation: create_project
  project_uuid:
  payload: {"name": "<app_name>", "platforms": <platforms_array>}
  ```

### Step 3: Analyze Codebase

Spawn the `uprate-aso-codebase-analyzer` agent:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-aso-codebase-analyzer":
Prompt: Read the agent file at ~/.claude/agents/uprate-aso-codebase-analyzer.md and follow its instructions exactly to analyze this project.
```

Parse the JSON output. Present a summary:

```
Codebase analysis complete:
- **App:** {appName}
- **Platforms:** {platforms}
- **Bundle ID (Apple):** {bundleIdApple or "Not detected"}
- **Bundle ID (Android):** {bundleIdAndroid or "Not detected"}
- **iOS Category:** {primary_category_ios} / {secondary_category_ios}
- **Android Category:** {primary_category_android} / {secondary_category_android}
- **Features:** {features}
- **Developer:** {developerName} ({developerEmail})

I'll now sync this to your Uprate project. You can approve or skip each section.
```

### Step 4: Push Project Metadata

Push detected metadata to the project. Only include fields that were detected (not null):

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
Operation: update_project
project_uuid: {uuid}
payload: {
  "name": "{appName}",
  "bundle_id_apple": "{bundleIdApple}",
  "bundle_id_android": "{bundleIdAndroid}",
  "platforms": {platforms_array},
  "developer_name": "{developerName}",
  "developer_email": "{developerEmail}",
  "developer_website": "{developerWebsite}"
}
```

Show: "Project metadata updated."

### Step 4b: Push Categories

Always push the inferred categories from the codebase analysis (do not ask the user — these are just initial suggestions they can adjust in the web app):

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
Operation: push_descriptions
project_uuid: {uuid}
payload: {
  "primary_category_ios": "<from codebase analysis>",
  "secondary_category_ios": "<from codebase analysis>",
  "primary_category_android": "<from codebase analysis>",
  "secondary_category_android": "<from codebase analysis>"
}
```

Show: "Categories set: iOS — {primary_category_ios} / {secondary_category_ios}, Android — {primary_category_android} / {secondary_category_android}"

### Step 5: Generate and Push Descriptions

Use AskUserQuestion: "Generate app descriptions for the store listings?" with options: "Yes, generate descriptions", "Skip"

If yes:
1. Ask tone via AskUserQuestion: "What tone should the descriptions use?" Options: "Professional", "Casual", "Playful", "Technical"
2. Using the codebase analysis (app name, description, features, category), generate:
   - `app_description_ios` (max 4000 chars) — lead with most compelling feature, short paragraphs, bulleted features, call to action
   - `subtitle_ios` (max 30 chars) — concise value proposition
   - `keywords_ios` (max 100 chars, comma-separated, no spaces after commas)
   - `promotional_text_ios` (max 170 chars) — highlight latest update or key benefit
   - `app_description_android` (max 4000 chars) — similar to iOS, include keywords naturally for ASO
   - `short_description_android` (max 80 chars) — brief and compelling
   - `copyright_text` — format: "© {current_year} {developerName or appName}"
3. Show all fields with character counts
4. Use AskUserQuestion: "Push these descriptions?" with options: "Yes, push", "I want to adjust", "Skip"
5. If adjust, let the user provide feedback and regenerate
6. If pushing, spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_descriptions
   project_uuid: {uuid}
   payload: {
     "app_description_ios": "<generated>",
     "subtitle_ios": "<generated>",
     "keywords_ios": "<generated>",
     "promotional_text_ios": "<generated>",
     "app_description_android": "<generated>",
     "short_description_android": "<generated>",
     "copyright_text": "<generated>",
     "tone": "<selected_tone>",
     "primary_category_ios": "<from codebase analysis>",
     "secondary_category_ios": "<from codebase analysis>",
     "primary_category_android": "<from codebase analysis>",
     "secondary_category_android": "<from codebase analysis>"
   }
   ```

### Step 6: Generate and Push Legal Pages

**Privacy Policy:**
Use AskUserQuestion: "Generate a privacy policy?" with options: "Yes", "Skip"

If yes:
1. Ask the following clarifying questions one at a time using AskUserQuestion:
   - "Who operates this app?" Options: "Individual / Sole trader", "Company / LLC", "Non-profit", "Other"
   - "Does your app target children under 13 (COPPA) or under 16 (GDPR)?" Options: "No", "Yes — under 13", "Yes — under 16", "Unsure"
   - "Are there any data types we missed?" (show detected SDKs and types from Step 3) Options: "Looks complete", "I want to add more"
   - "What email address should users contact for privacy requests?" Free text input.
   - "Which privacy laws apply?" Options: "GDPR (Europe)", "CCPA (California)", "Both", "Other / Unsure"
2. Generate the full privacy policy markdown (see generate-privacy-policy skill for structure)
3. Push via the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_legal
   project_uuid: {uuid}
   payload: {"content_markdown": "<generated privacy policy>", "source": "cc_skill", "page_type": "privacy_policy"}
   ```
4. Show: "Privacy policy pushed! Hosted at: {hosted_url}"

**Terms of Service:**
Use AskUserQuestion: "Generate Terms of Service?" with options: "Yes", "Skip"

If yes:
1. Ask clarifying questions one at a time using AskUserQuestion (same as generate-terms-of-service skill):
   - "Who operates this app?" Options: "Individual / Sole trader", "Company / LLC", "Non-profit", "Other"
   - "Does your app have user accounts?" Options: "Yes", "No"
   - "Which monetization models apply?" Options: "Free", "One-time purchase", "Subscription", "In-app purchases", "Ad-supported" (multiSelect: true)
   - "Which jurisdiction should govern this agreement?" Options: "United States", "European Union", "United Kingdom", "Other"
   - "What email address should users contact for legal inquiries?" Free text input.
   - "What is the app's support or contact website?" Free text input.
2. Generate the full Terms of Service markdown
3. Push via the `uprate-indie-push` agent with `page_type: "terms_of_service"`
4. Show: "Terms of Service pushed! Hosted at: {hosted_url}"

**EULA:**
Use AskUserQuestion: "Generate an EULA?" with options: "Yes", "Skip"

If yes:
1. Ask clarifying questions one at a time using AskUserQuestion (same as generate-eula skill):
   - "Who operates this app?" Options: "Individual / Sole trader", "Company / LLC", "Non-profit", "Other"
   - "Which monetization models apply?" Options: "Free", "One-time purchase", "Subscription", "In-app purchases", "Ad-supported" (multiSelect: true)
   - "What is the intended license scope?" Options: "Personal use only", "Personal and commercial use"
   - "Which jurisdiction should govern this agreement?" Options: "United States", "European Union", "United Kingdom", "Other"
   - "What email address should users contact for legal inquiries?" Free text input.
2. Generate the full EULA markdown
3. Push via the `uprate-indie-push` agent with `page_type: "eula"`
4. Show: "EULA pushed! Hosted at: {hosted_url}"

### Step 7: Scan and Push Privacy Labels

Spawn a privacy scanner subagent to detect SDKs and map to Apple/Google data categories:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-privacy-scanner":
Prompt:
Analyze the current project to detect data collection practices. Do the following:

1. **Detect app name and platform** — Use the Glob tool to find project config files: package.json, pubspec.yaml, build.gradle, Podfile, Info.plist, AndroidManifest.xml. Extract the app name and determine the platform.

2. **Scan for third-party SDKs** — Use the Glob tool to find dependency files and flag any known data-collecting SDKs: firebase-analytics, mixpanel, amplitude, segment, sentry, crashlytics, admob, facebook-sdk, revenuecat, stripe, firebase-messaging, onesignal, google-maps, mapbox, etc.

3. **Search for data collection in code** — Use the Grep tool to search for: email, location, camera, microphone, contacts, healthkit, tracking, analytics, payment, biometric, photo library, calendar, bluetooth

4. **Map findings to Apple Privacy Label categories** (contact_info, health_fitness, financial_info, location, sensitive_info, contacts, user_content, browsing_history, search_history, identifiers, purchases, usage_data, diagnostics, other_data). For each data type, produce a declaration with: collected (boolean), purposes (array of: third_party_advertising, developers_advertising, analytics, product_personalization, app_functionality, other), linked_to_identity (boolean), used_to_track (boolean).

5. **Map findings to Google Play Data Safety categories** (location, personal_info, financial_info, health_fitness, messages, photos_videos, audio, files_docs, calendar, contacts, app_activity, web_browsing, app_info_performance, identifiers). For each data type, produce a declaration with: collected (boolean), shared (boolean), purposes (array of: app_functionality, analytics, developer_communications, advertising_marketing, fraud_prevention, personalization, account_management), required_or_optional ("required" or "optional").

**IMPORTANT — declaration key format:**
- Apple: keys are `"{category_id}.{data_type_id}"` — e.g. `"contact_info.email_address"`, `"identifiers.device_id"`, `"usage_data.product_interaction"`, `"diagnostics.crash_data"`
- Google: keys are `"{category_id}.{data_type_id}"` — e.g. `"personal_info.email_address"`, `"identifiers.device_id"`, `"app_info_performance.crash_logs"`

Return a JSON object:
{
  "appName": "string or null",
  "platform": "string",
  "detected_sdks": [{"name": "...", "category": "...", "data_collected": "..."}],
  "detected_data_types": ["email", "location", ...],
  "apple_declarations": { "category_id.data_type_id": { "collected": true, "purposes": ["analytics"], "linked_to_identity": false, "used_to_track": false } },
  "google_declarations": { "category_id.data_type_id": { "collected": true, "shared": false, "purposes": ["analytics"], "required_or_optional": "required" } }
}
```

Present a summary of what was detected:

```
### Privacy Scan Results

**Detected SDKs:** {list detected_sdks with name and category}
**Detected data types:** {list detected_data_types}

**Apple Privacy Labels:** {count of collected data types} data types will be declared
**Google Data Safety:** {count of collected data types} data types will be declared

These declarations will be pushed to your Uprate project and marked as complete.
```

Push results to both endpoints. The payload includes both raw scan data (`cc_scan_data`) and the generated declarations, plus `completed_at` to auto-mark as complete:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
Operation: push_scan_privacy
project_uuid: {uuid}
payload: {
  "cc_scan_data": {"detected_sdks": [<sdks>], "detected_data_types": [<types>], "suggested_declarations": {<apple_declarations>}},
  "declarations": {<apple_declarations>},
  "completed_at": "<current ISO 8601 datetime>"
}
```

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
Operation: push_scan_data_safety
project_uuid: {uuid}
payload: {
  "cc_scan_data": {"detected_sdks": [<sdks>], "detected_data_types": [<types>], "suggested_declarations": {<google_declarations>}},
  "declarations": {<google_declarations>},
  "encrypted_in_transit": true,
  "deletion_mechanism": false,
  "completed_at": "<current ISO 8601 datetime>"
}
```

Show: "Privacy Labels and Data Safety forms generated and pushed — both marked as complete. You can review and adjust them in the web app."

### Step 8: Generate and Push App Icon

Use AskUserQuestion: "Generate an app icon?" with options: "Yes", "Skip"

If yes:
1. Read auth from `~/.uprate/config.json`. Check for top-level `apiKey` or `guestToken` (the Uprate SaaS auth, separate from `indie.apiKey`).
2. If no Uprate SaaS auth, create a guest session via `POST https://app.upratehq.com/api/cli/session` and save the returned token.
3. Fetch styles from `GET https://app.upratehq.com/api/cli/styles`.
4. Using the app metadata from Step 3 (name, description, category), generate 4 icon concept ideas. Rules:
   - EXTREMELY SIMPLE: maximum 2 visual elements combined
   - ICONIC: instantly recognizable as a single shape or silhouette
   - SYMBOLIC: represent the app's core purpose through a visual metaphor
   - Each idea: 10-15 words maximum
5. Present styles to the user via AskUserQuestion (each style as an option with its name and short description).
6. Present the 4 icon concepts via AskUserQuestion with each as an option (plus "Other" for custom input).
7. Submit to `POST https://app.upratehq.com/api/cli/generate` with `app_description`, `icon_description`, `style_id`, and `colors`.
8. Parse the response for `request_id` and build the preview URL: `https://app.upratehq.com/icons/new/{request_id}` (or use `view_url` if returned).
9. Show: "Your icon is generating! Preview it here: {preview_url}"
10. Poll for the generated image URL by running (via Bash) every 5 seconds for up to 60 seconds:
    ```bash
    curl -s -H "Accept: application/json" "https://app.upratehq.com/api/cli/generate/{request_id}/status"
    ```
    This endpoint is public (no auth required). Check the response for `status`. When status is `"completed"`, extract the first `image_url` from the `generated_icons` array (format: `[{"id": "...", "image_url": "..."}]`). If polling times out after 60 seconds, fall back to using the preview URL and warn the user.
11. Push the **direct image URL** (not the preview page URL) to the project:
    ```
    Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
    Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
    Operation: push_icon
    project_uuid: {uuid}
    payload: {"icon_url": "<image_url>"}
    ```

### Step 9: Generate and Push What's New

Check if this is a git repo: `git rev-parse --is-inside-work-tree 2>/dev/null`

If yes, check for tags: `git describe --tags --abbrev=0 2>/dev/null`

If tags or recent commits exist, use AskUserQuestion: "Generate What's New / release notes from git history?" with options: "Yes", "Skip"

If yes:
1. Use AskUserQuestion to ask the commit range:
   - "Since last tag (`{tag_name}`)" — only if a tag was found
   - "Last 20 commits"
   - "Custom range" — follow up asking for `from..to` refs
2. Spawn a general-purpose subagent to analyze the commits:
   ```
   Use the Agent tool with subagent_type "general-purpose":
   Prompt:
   1. Run: git log --oneline <from>..<to>
   2. Group commits by conventional commit type (feat, fix, perf, etc.)
   3. Filter out chore, ci, docs, and test commits
   4. Rewrite each remaining commit as a plain-English bullet point a non-technical user would understand
   5. Strip ticket numbers, PR references, and technical jargon
   6. Return grouped results as plain text (New Features, Bug Fixes, Performance sections)
   ```
3. Generate App Store format (under 500 chars, conversational, 3-6 bullets, plain text) and Google Play format (under 500 chars, bullets only, plain text)
4. Show both with character counts via AskUserQuestion: "Push these release notes?" with options: "Yes, push", "I want to adjust", "Skip"
5. If pushing, spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_descriptions
   project_uuid: {uuid}
   payload: {"whats_new_ios": "<app_store_text>", "whats_new_android": "<google_play_text>"}
   ```

### Step 10: Summary

Call the checklist API to show final status:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
Operation: get_checklist
project_uuid: {uuid}
payload: {}
```

Parse the checklist response. Count complete vs missing items for both iOS and Android.

Show a summary:

```
## Sync Complete!

**iOS:** {complete}/{total} items ready ({percentage}%)
**Android:** {complete}/{total} items ready ({percentage}%)

### Remaining items (fill manually in the web app):
{For each missing/required item, show: "- {label} — {action_hint}"}

Open your project: {url}/projects
```

Done! Do not proceed with any additional steps unless the user asks.
