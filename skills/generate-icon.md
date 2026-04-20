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

This endpoint is public (no auth required). Check the response for `status`. When status is `"completed"`, extract the first `image_url` from the `generated_icons` array (format: `[{"id": "...", "image_url": "..."}]`). This is the **direct image URL** for the generated icon.

If polling times out after 60 seconds, fall back to the preview URL and warn the user that the icon may still be generating.

Show the user:

```
Your icon is ready!

Preview it here: {preview_url}
Direct image: {image_url}

You can preview without an account.
Want to save this icon to your account or download it? Sign in or create a free account from that page.
```

Done! Do not proceed with any additional steps unless the user asks.
