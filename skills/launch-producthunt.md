---
name: launch-producthunt
description: Generate launch copy and a checklist for your Product Hunt submission
---

# Product Hunt Launch Prep

Prepare your Product Hunt submission — tagline, description, maker comment, and launch checklist — all from your project context.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Project

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
- **Category:** {category}
- **Platform:** {platform}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

### Step 2: Ask Launch Context Questions

Ask the following questions one at a time using AskUserQuestion:

1. **Tagline vibe** — "What tone should your tagline have?"
   Options: "Bold & direct", "Playful & witty", "Descriptive & clear", "Question format"

2. **Unique angle** — "What makes your product different from alternatives? What's the one thing only you do?"
   Use Other option for free-text input.

3. **Target audience** — "Who is your primary target audience?"
   Options: "Indie developers", "Startup founders", "Designers", "Product managers", "General consumers", with Other option for custom input.

4. **Launch goal** — "What's your main goal for this launch?"
   Options: "Get early users / signups", "Collect feedback", "Build awareness / brand", "Drive traffic to website"

5. **Maker name** — "What name should appear in the maker comment? (your name or handle)"
   Use Other option for free-text input.

### Step 3: Generate All Launch Copy

Using all context from Steps 1 and 2, generate the following five pieces of copy. Present each in a labeled code block so the user can easily copy them.

**Writing style rules — apply to ALL generated copy below:**
- Never use em dashes (—)
- Minimize use of regular dashes (-) — prefer commas, periods, or restructuring the sentence instead

**Tagline**
- Maximum 60 characters
- No trailing punctuation
- Match the tone the user chose in Step 2

**Description**
- 2-3 sentences
- Explain what the product does and why it matters
- Clear and compelling, no jargon

**Topics**
- 3-5 Product Hunt topic tags relevant to the product
- Format as a comma-separated list

**Maker Comment**
- 150-250 words
- First-person, authentic tone
- Include: why you built it, what problem it solves, what's next
- End with a question to invite discussion

**First Comment**
- 50-80 words
- Thank the community
- Highlight one key feature
- End with a call to action

### Step 4: Launch Checklist

Show the following checklist to the user:

```markdown
## Product Hunt Launch Checklist

### Assets
- [ ] App icon (240x240 PNG)
- [ ] Gallery images — at least 3 screenshots or graphics (1270x760 recommended)
- [ ] Optional: demo video or GIF (max 3 minutes)

### Store Listing
- [ ] Tagline added (60 char max)
- [ ] Description added
- [ ] Topics selected (up to 5)
- [ ] Thumbnail uploaded
- [ ] Gallery media uploaded
- [ ] Links: website, App Store / Play Store if applicable

### Copy
- [ ] Maker comment drafted
- [ ] First comment drafted
- [ ] Social share text prepared (Twitter/X, LinkedIn)

### Timing
- [ ] Launch date chosen (Tuesday-Thursday recommended)
- [ ] Schedule set to 12:01 AM PT
- [ ] Support team aware of launch day

### Accounts
- [ ] Product Hunt maker profile complete (bio, avatar, links)
- [ ] Hunter lined up (optional but helps visibility)
- [ ] Notify your network — friends, colleagues, communities
```

Then use AskUserQuestion with options: "Save as PRODUCTHUNT_LAUNCH.md" and "Don't save, I'll copy it".

### Step 5: Save (Conditional)

If the user chose "Save as PRODUCTHUNT_LAUNCH.md":

Write a file called `PRODUCTHUNT_LAUNCH.md` to the project root containing all generated copy from Step 3 (tagline, description, topics, maker comment, first comment) followed by the launch checklist from Step 4.

Show: "Done! Your launch materials are ready. Good luck on Product Hunt!"

If the user chose not to save, show: "Done! Good luck on Product Hunt!"
