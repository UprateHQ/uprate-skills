---
name: aso-audit
description: Run an ASO audit on your app's store listing and get optimization recommendations
---

# Uprate ASO Audit

Run a full App Store Optimization audit on your app's store listing and get actionable recommendations.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Codebase Analysis

Spawn the `uprate-aso-codebase-analyzer` agent to analyze the current project:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-aso-codebase-analyzer":
Prompt: Read the agent file at ~/.claude/agents/uprate-aso-codebase-analyzer.md and follow its instructions exactly to analyze this project.
```

Parse the JSON output from the agent.

### Step 2: Auth Prefetch

Spawn a general-purpose subagent with this exact prompt:

```
Do the following tasks and return ALL results as a single JSON object. Do not stop early.

1. Read auth config:
   cat ~/.uprate/config.json 2>/dev/null || echo "{}"

2. If neither "apiKey" nor "guestToken" exists in the config, create a guest session:
   curl -s -X POST https://app.upratehq.com/api/cli/session \
     -H "Content-Type: application/json" \
     -H "Accept: application/json"
   Save the token: mkdir -p ~/.uprate && echo '{"guestToken":"<token>"}' > ~/.uprate/config.json

Return this JSON (fill in real values):
{
  "token": "<apiKey or guestToken value>"
}
```

Parse the subagent's JSON output to get `token`.

### Step 3: User Confirmation

Use AskUserQuestion to confirm and refine the audit settings. Ask the following questions in order:

**Question 1 — Store:**
"Which store would you like to audit?"
Options: "App Store", "Google Play", "Both" (default: "Both")

**Question 2 — Primary market:**
"What is your primary market?"
Options: "US", "UK", "DE", "FR", "JP", "Other"
- If the user selects "Other": ask a follow-up free text question: "Enter the 2-letter country code (e.g. AU, CA, BR):"

**Question 3 — App details confirmation:**
Present detected app data and ask to confirm:
```
I found the following app details:
- App name: {appName from Step 1, or "Not detected"}
- Apple Bundle ID: {bundleIdApple from Step 1, or "Not detected"}
- App Store ID: {appStoreId from Step 1, or "Not detected"}
- Android Package: {bundleIdAndroid from Step 1, or "Not detected"}

Do these look correct?
```
Options: "Yes, looks correct", "No, I want to adjust"

If the user selects "No, I want to adjust", ask for each missing or incorrect field individually as free text.

### Step 4: Submit Audit

Map the user's store choice to the `platform` field:
- "App Store" → `"app_store"`
- "Google Play" → `"play_store"`
- "Both" → `"both"`

Map the country to a lowercase 2-letter code (e.g. "US" → `"us"`, "UK" → `"uk"`).

Spawn a general-purpose subagent with this exact prompt (substituting all `<placeholders>` with real values):

```
Submit this ASO audit request and return the full JSON response body including HTTP status code.

curl -s -w "\n__HTTP_STATUS__%{http_code}" -X POST https://app.upratehq.com/api/cli/aso/audits \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "codebase_context": <codebase_context_json_object>,
    "platform": "<platform>",
    "country": "<country_code>",
    "bundle_id_apple": "<bundleIdApple or null>",
    "app_store_id": "<appStoreId or null>",
    "bundle_id_android": "<bundleIdAndroid or null>"
  }'

Return a JSON object: { "status": <http_status_as_integer>, "body": <parsed_response_body> }
```

Handle errors from the response:
- Status 401: Tell the user "Invalid API key. Visit https://app.upratehq.com/settings to update your key." and STOP.
- Status 422: Show the validation errors from the response body and STOP.
- Status 429: Tell the user "Rate limit reached. Upgrade at https://app.upratehq.com/settings/billing" and STOP.

On success (status 201 or 200), extract the `uuid` from the response body.

### Step 5: Poll for Results

Loop up to 60 times with a 5-second wait between each attempt:

Spawn a general-purpose subagent for each poll with this exact prompt (substituting `<uuid>` and `<token>`):

```
Fetch this URL and return the full JSON response body including HTTP status code:

curl -s -w "\n__HTTP_STATUS__%{http_code}" https://app.upratehq.com/api/cli/aso/audits/<uuid> \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <token>"

Return a JSON object: { "status": <http_status_as_integer>, "body": <parsed_response_body> }
```

For each poll response:
- If `body.status` is `"completed"`: break the loop and continue to Step 6.
- If `body.status` is `"failed"`: display the error message from the response and STOP.
- If `body.status` is `"pending"` or `"running"`: display "Analyzing your store listing... (attempt N/60)" and wait 5 seconds before next poll.

If 60 attempts are exhausted without completion, tell the user "The audit is taking longer than expected. Log in to view the results at https://app.upratehq.com/aso/audits/{uuid}" and STOP.

### Step 6: Display Scorecard

Parse the completed audit response. Build and display the scorecard using this format:

```
ASO Audit Complete - Overall Score: {overall_score}/100

  Title          {bar}  {title_score}
  Subtitle       {bar}  {subtitle_score}{warning}
  Description    {bar}  {description_score}
  Keywords       {bar}  {keywords_score}{warning}
  What's New     {bar}  {whats_new_score}
  Visuals        {bar}  {visuals_score}
  Ratings        {bar}  {ratings_score}
  Localization   {bar}  {localization_score}{warning}
  Competitive    {bar}  {competitive_score}

Top 3 Quick Wins:
  1. {quick_win_1}
  2. {quick_win_2}
  3. {quick_win_3}

View full report (login required): https://app.upratehq.com/aso/audits/{uuid}
```

For score bars: render a 20-character bar using `█` for filled segments and `░` for empty segments. Calculate filled segments as `round(score / 100 * 20)`.

For `{warning}`: append `  ⚠ Needs attention` if the score is below 40, otherwise leave empty.

### Step 7: Tier Upsell

Check the `tier` field in the audit response. If it equals `"basic"`:

Display:
"Connect your app on Uprate for deeper insights from your reviews and competitors. Visit https://app.upratehq.com"

### Final line

"Done! Do not proceed with any additional steps unless the user asks."
