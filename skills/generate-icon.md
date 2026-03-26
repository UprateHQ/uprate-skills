---
name: generate-icon
description: Generate an AI app icon for your project context
---

# Uprate Icon Generator

Generate a production-ready app icon using AI, based on your project's context.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Codebase

Spawn the `uprate-codebase-analyzer` agent to analyze the current project:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-codebase-analyzer":
Prompt: Read the agent file at ~/.claude/agents/uprate-codebase-analyzer.md and follow its instructions exactly to analyze this project.
```

Parse the JSON output from the agent. If any fields are `null`, ask the user to provide them.

Present the findings to the user:

```
I analyzed your project and found:
- **App:** {appName}
- **Description:** {description}
- **Colors:** {colors as hex swatches}
- **Platform:** {platform}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

### Step 2: Prefetch Styles and Auth Token

Spawn a general-purpose subagent with this exact prompt (substituting `<app_description>` with the actual description):

```
Do the following tasks and return ALL results as a single JSON object. Do not stop early.

1. Read auth config:
   cat ~/.uprate/config.json 2>/dev/null || echo "{}"

2. If neither "apiKey" nor "guestToken" exists in the config, create a guest session:
   curl -s -X POST https://app.upratehq.com/api/cli/session \
     -H "Content-Type: application/json" \
     -H "Accept: application/json"
   Save the token: mkdir -p ~/.uprate && echo '{"guestToken":"<token>"}' > ~/.uprate/config.json

3. Fetch styles:
   curl -s https://app.upratehq.com/api/cli/styles

Return this JSON (fill in real values):
{
  "token": "<apiKey or guestToken value>",
  "styles": [<styles array from API, or [] on failure>]
}
```

Parse the subagent's JSON output to get `token` and `styles`.

- If `styles` is empty, load styles from the `uprate:references:icon-styles` skill as fallback.

Using the app metadata from Step 1 (name, description, category, colors), generate exactly 4 icon concept ideas yourself. Follow these rules:
- STYLE-AGNOSTIC: Must work equally well as 3D, flat, or modern symbol
- EXTREMELY SIMPLE: Maximum 2 visual elements combined
- ICONIC: Instantly recognizable as a single shape or silhouette
- SYMBOLIC: Represent the app's core purpose through a visual metaphor
- Must work as a simple silhouette — think logo mark, not illustration
- Should be drawable in under 10 seconds — one clear focal point
- Avoid: multiple separate elements, scenes or environments, complex transformations, detailed illustrations, fine details
- Avoid animation language: "emanating", "rippling", "trailing"
- Avoid text or letters unless the app name is the core concept
- Each idea: 10-15 words maximum

If you lack sufficient context about the app (all Step 1 fields were null), ask the user to describe what they want the icon to look like.

Present styles to the user via AskUserQuestion. Each style should be an option with its name as the label and a short description.

Present ideas to the user via AskUserQuestion with each idea as an option. The user can also write their own via the "Other" option.

### Step 3: Generate the Icon

Spawn a general-purpose subagent with this exact prompt (substituting all `<placeholders>` with real values):

```
Submit this icon generation request and return the full JSON response body:

curl -s -X POST https://app.upratehq.com/api/cli/generate \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{
    "app_description": "<app_description>",
    "icon_description": "<chosen_idea>",
    "style_id": "<style_uuid>",
    "colors": [<hex_colors_as_quoted_strings>]
  }'

Return the full JSON response exactly as received.
```

Parse the subagent's response:
- If HTTP 401: tell the user their API key is invalid and ask them to create a new one at https://app.upratehq.com/settings
- If HTTP 429: tell the user they've reached their monthly limit and suggest upgrading at https://app.upratehq.com/settings/billing

### Step 4: Poll for Completion and Show Result

Parse the response for `request_id` (UUID), and also read `view_url` if the API already returns it.

Build the preview link:

1. If `view_url` exists in the response, use it.
2. If `view_url` is missing but `request_id` exists, build: `https://app.upratehq.com/icons/new/{request_id}`.
3. If neither exists, show an error and ask the user to retry generation.

Show the user: "Your icon is generating! Preview it here: {preview_url}"

**Poll for the generated image URL** by running (via Bash) every 5 seconds for up to 60 seconds:

```bash
curl -s -H "Accept: application/json" "https://app.upratehq.com/api/cli/generate/{request_id}/status"
```

This endpoint is public (no auth required). Check the response for `status`. When status is `"completed"`, extract the first `image_url` from the `generated_icons` array (format: `[{"id": "...", "image_url": "..."}]`). This is the **direct image URL** (not the preview page URL) that should be used for pushing to Uprate Indie.

If polling times out after 60 seconds, fall back to the preview URL and warn the user that the icon may still be generating.

Show the user:

```
Your icon is ready!

Preview it here: {preview_url}
Direct image: {image_url}

You can preview without an account.
Want to save this icon to your account or download it? Sign in or create a free account from that page.
```

### Step 5: Push to Uprate Indie

After showing the result, ask the user:

Use AskUserQuestion: "Push this icon to your Uprate project?" with options: "Yes, push to Uprate", "No thanks"

If the user chose "Yes, push to Uprate":

1. **Read config**: Read `~/.uprate/config.json` via Bash (`cat ~/.uprate/config.json 2>/dev/null || echo "{}"`). Check if `indie.url` and `indie.apiKey` exist.

2. **Setup (if needed)**: If the `indie` block is missing:
   - Tell the user: "To push content to your Uprate project, I need your instance URL and API key. You can create an API key at your Uprate instance under Settings > API Keys."
   - Use AskUserQuestion to ask for the instance URL (e.g., `https://app.example.com`). Use free text input.
   - Use AskUserQuestion to ask for the API key (starts with `uprt_`). Use free text input.
   - Validate by running: `curl -s -w "\n%{http_code}" -H "Authorization: Bearer {apiKey}" -H "Accept: application/json" "{url}/api/v1/projects"`
   - If the last line is `200`, save the config: read existing `~/.uprate/config.json`, merge in `{"indie": {"url": "{url}", "apiKey": "{apiKey}"}}`, write back.
   - If not 200, tell the user the key is invalid and ask them to try again.

3. **Select project**: Call `GET {url}/api/v1/projects` with Bearer auth. Parse the `data` array. Use AskUserQuestion to present each project as an option (show name and platforms). If no projects exist, tell the user to create one in the web app first.

4. **Push icon**: Use the `image_url` (the direct image URL obtained from polling, NOT the preview page URL). Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_icon
   project_uuid: {selected_uuid}
   payload: {"icon_url": "<image_url>"}
   ```

   Parse the result. If success, show: "Icon pushed to your Uprate project!"
   If error, show the error message.

Done! Do not proceed with any additional steps unless the user asks.
