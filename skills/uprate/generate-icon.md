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

### Step 2: Fetch Available Styles

Run this command to get available styles:

```bash
curl -s https://uprate.app/api/cli/styles
```

Parse the JSON response. Present styles to the user via AskUserQuestion. Each style should be an option with its name as the label and a short description.

If the API call fails, use the styles from `~/.claude/commands/uprate/references/icon-styles.md` as fallback and note that the exact style IDs will be needed later.

### Step 3: Generate Icon Ideas

Run this command with the app description:

```bash
curl -s -X POST https://uprate.app/api/cli/generate/ideas \
  -H 'Content-Type: application/json' \
  -d '{"description": "<app_description>"}'
```

Parse the `ideas` array from the response. Present them to the user via AskUserQuestion with each idea as an option. The user can also write their own via the "Other" option.

### Step 4: Get Access Token

Check `~/.uprate/config.json` for an existing token:

```bash
cat ~/.uprate/config.json 2>/dev/null || echo "{}"
```

**If `apiKey` is present** — use it as the Bearer token. Skip to Step 5.

**If `guestToken` is present** — use it as the Bearer token. Skip to Step 5.

**If neither exists** — create a guest session automatically:

```bash
RESPONSE=$(curl -s -X POST https://app.upratehq.com/api/cli/session \
  -H "Content-Type: application/json" \
  -H "Accept: application/json")

TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Could not connect to Uprate. Please check your internet connection and try again."
  exit 1
fi

mkdir -p ~/.uprate
echo "{\"guestToken\": \"$TOKEN\"}" > ~/.uprate/config.json
```

Use `$TOKEN` as the Bearer token for Step 5.

### Step 5: Generate the Icon

Read the API key from config:

```bash
cat ~/.uprate/config.json
```

Submit the generation request:

```bash
curl -s -X POST https://uprate.app/api/cli/generate \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <api_key>' \
  -d '{
    "app_description": "<app_description>",
    "icon_description": "<chosen_idea>",
    "style_id": "<style_uuid>",
    "colors": [<hex_colors>]
  }'
```

If the response is 401, tell the user their API key is invalid and ask them to create a new one (go back to Step 4).

If the response is 429, tell the user they've reached their monthly limit and suggest upgrading at https://uprate.app/settings/billing.

### Step 6: Show the Result

Parse the response for `view_url` and `request_id`.

Show the user:

```
Your icon is generating! It will be ready in about 30 seconds.

View it here: {view_url}

💡 Sign in or create a free Uprate account at that link to save this icon to your library.
```

Done! Do not proceed with any additional steps unless the user asks.
