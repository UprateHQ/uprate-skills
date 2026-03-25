---
name: generate-changelog
description: Generate user-facing release notes from git commits for App Store, Google Play, and GitHub Release
---

# Uprate Changelog Generator

Generate copy-ready release notes from your git history, formatted for App Store, Google Play, and GitHub Release.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Detect Context

Check if the current directory is a git repository:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

If **not** a git repo, use AskUserQuestion to ask the user to paste their commits manually as free text. Skip the range selection and proceed to Step 2 with the pasted commits.

If it **is** a git repo, detect the latest tag:

```bash
git describe --tags --abbrev=0 2>/dev/null
```

Use AskUserQuestion to ask how to select the commit range. Provide these options:

- **"Since last tag (`<tag_name>`)"** — only if a tag was found; show the actual tag name
- **"Last N commits"** — follow up with another AskUserQuestion asking how many (default 20)
- **"Custom range"** — follow up with another AskUserQuestion asking for `from..to` refs

### Step 2: Analyze Commits

Spawn a general-purpose subagent to analyze the commits:

```
Use the Agent tool with subagent_type "general-purpose":
Prompt:
1. Run: git log --oneline <from>..<to>  (substituting the chosen range)
2. Group commits by conventional commit type (feat, fix, perf, refactor, etc.)
3. Filter out chore, ci, docs, and test commits — these are not user-facing
4. Rewrite each remaining commit as a plain-English bullet point a non-technical user would understand
5. Strip ticket numbers, PR references, and technical jargon
6. Return the results grouped by category in this format:

**New Features**
- bullet point

**Bug Fixes**
- bullet point

**Performance**
- bullet point

If a category has no commits, omit it entirely.
```

Present the summarized changes to the user for review. Use AskUserQuestion with options: "Looks good" and "I want to adjust" (with Other option for custom input). If the user wants to adjust, apply their feedback and present again.

### Step 3: Choose Output Format

Use AskUserQuestion to ask which format(s) to generate. Provide these options:

- **"App Store"**
- **"Google Play"**
- **"GitHub Release"**
- **"All three"**

Then use AskUserQuestion to ask for the app version/build number. Provide these options:

- **"Skip"** — omit version from the output
- Let the user type a version string via the "Other" option (e.g. `1.2.0 (42)`)

### Step 4: Generate Release Notes

Produce output for each selected format, respecting these rules:

**App Store** (recommended under 500 characters):
- Conversational, friendly tone
- 3-6 bullet points maximum
- Start with a brief intro sentence (e.g. "Here's what's new in this update:")
- No markdown formatting — plain text only

**Google Play** (hard limit: 500 characters):
- Ultra-concise bullet points
- No intro sentence — just the bullets
- Plain text only, no markdown
- Count characters and warn if approaching the limit

**GitHub Release** (no limit):
- Full markdown with sections: `## What's New`, `## Bug Fixes`, `## Performance`, etc.
- Include the version as a heading if provided (e.g. `# v1.2.0`)
- Each item as a markdown bullet point

Show each format in a labeled code block for easy copy-paste. Include a character count for App Store and Google Play formats.

### Step 5: Offer to Save

Use AskUserQuestion to ask: "Save to file?" with these options:

- **"Push to Uprate project"**
- **"Save to RELEASE_NOTES.md"**
- **"Both (push + save)"**
- **"No thanks"**

If the user chooses to save (i.e. "Save to RELEASE_NOTES.md" or "Both (push + save)"), write all generated formats to `RELEASE_NOTES.md` in the current working directory, separated by clear headings.

### Step 6: Push to Uprate Indie

If the user chose "Push to Uprate project" or "Both (push + save)" in Step 5:

1. **Read config**: Read `~/.uprate/config.json` via Bash (`cat ~/.uprate/config.json 2>/dev/null || echo "{}"`). Check if `indie.url` and `indie.apiKey` exist.

2. **Setup (if needed)**: If the `indie` block is missing:
   - Tell the user: "To push content to your Uprate project, I need your instance URL and API key. You can create an API key at your Uprate instance under Settings > API Keys."
   - Use AskUserQuestion to ask for the instance URL (e.g., `https://app.example.com`). Use free text input.
   - Use AskUserQuestion to ask for the API key (starts with `uprt_`). Use free text input.
   - Validate by running: `curl -s -w "\n%{http_code}" -H "Authorization: Bearer {apiKey}" -H "Accept: application/json" "{url}/api/v1/projects"`
   - If the last line is `200`, save the config: read existing `~/.uprate/config.json`, merge in `{"indie": {"url": "{url}", "apiKey": "{apiKey}"}}`, write back.
   - If not 200, tell the user the key is invalid and ask them to try again.

3. **Select project**: Call `GET {url}/api/v1/projects` with Bearer auth. Parse the `data` array. Use AskUserQuestion to present each project as an option (show name and platforms). If no projects exist, tell the user to create one in the web app first.

4. **Push release notes**: Build the payload based on which formats were generated in Step 4:
   - If App Store format was generated: include `"whats_new_ios": "<app_store_text>"`
   - If Google Play format was generated: include `"whats_new_android": "<google_play_text>"`
   - If both were generated: include both fields

   Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_descriptions
   project_uuid: {selected_uuid}
   payload: {<payload built above>}
   ```

   Parse the result. If success, show: "What's New text pushed to your Uprate project!"
   If error, show the error message.

Done! Do not proceed with any additional steps unless the user asks.
