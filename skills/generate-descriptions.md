---
name: generate-descriptions
description: Generate App Store and Google Play descriptions from your codebase
---

# Uprate Description Generator

Generate optimized App Store and Google Play descriptions from your project's context.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Project

Spawn the `uprate-aso-codebase-analyzer` agent to analyze the current project:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-aso-codebase-analyzer":
Prompt: Read the agent file at ~/.claude/agents/uprate-aso-codebase-analyzer.md and follow its instructions exactly to analyze this project.
```

Parse the JSON output. Present findings to the user:

```
I analyzed your project and found:
- **App:** {appName}
- **Description:** {description}
- **Features:** {features list}
- **Platforms:** {platforms}
- **iOS Category:** {primary_category_ios} / {secondary_category_ios}
- **Android Category:** {primary_category_android} / {secondary_category_android}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

### Step 2: Ask Clarifying Questions

Use AskUserQuestion for each question, one at a time:

1. **Tone** — "What tone should the descriptions use?"
   Options: "Professional", "Casual", "Playful", "Technical"

2. **Target audience** — "Who is the primary target audience?"
   Options: "General consumers", "Developers / Technical users", "Business professionals", "Students / Education"
   If the codebase analysis already suggests a clear audience, pre-select that option.

3. **Key differentiators** — "What makes your app unique compared to alternatives?"
   Use AskUserQuestion with free text input.

### Step 3: Generate Descriptions

Using the codebase analysis and user answers, generate ALL of the following fields. Follow the character limits strictly.

**iOS Fields:**
- `app_description_ios` — max 4000 characters. Full app description for the App Store. Lead with the most compelling feature. Use short paragraphs. Include key features as a bulleted list. End with a call to action.
- `subtitle_ios` — max 30 characters. Concise value proposition.
- `keywords_ios` — max 100 characters. Comma-separated keywords. No spaces after commas. Include the most relevant search terms. Do not repeat words from the app name.
- `promotional_text_ios` — max 170 characters. Highlight the latest update or key benefit.

**Android Fields:**
- `app_description_android` — max 4000 characters. Similar to iOS but can differ slightly for Google Play audience. Include relevant keywords naturally for ASO.
- `short_description_android` — max 80 characters. Brief and compelling. This is the most visible text on Google Play.

**Shared Fields:**
- `copyright_text` — format: "© {current_year} {developer_name or app_name}"

Present each field to the user in a labeled section with the character count shown:

```
## iOS App Description ({count}/4000 chars)
{content}

## iOS Subtitle ({count}/30 chars)
{content}

## iOS Keywords ({count}/100 chars)
{content}

## iOS Promotional Text ({count}/170 chars)
{content}

## Android Full Description ({count}/4000 chars)
{content}

## Android Short Description ({count}/80 chars)
{content}

## Copyright
{content}
```

Use AskUserQuestion with options: "Looks good" and "I want to adjust" (with Other option for field-specific feedback). If adjusting, regenerate only the fields the user wants changed.

### Step 4: Output

Use AskUserQuestion with options: "Save to DESCRIPTIONS.md", "Don't save, I'll copy it"

If saving, write all generated descriptions to `DESCRIPTIONS.md` with clear section headings.

Regardless of save choice, show all descriptions in markdown so they can be copied.

Done! Do not proceed with any additional steps unless the user asks.
