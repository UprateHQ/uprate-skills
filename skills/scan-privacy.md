---
name: scan-privacy
description: Scan your codebase for data collection practices and pre-fill Privacy Labels and Data Safety forms
---

# Uprate Privacy Scanner

Scan your project for SDKs and data collection patterns to pre-fill Apple Privacy Labels and Google Play Data Safety forms.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Scan the Codebase

Spawn a general-purpose subagent to perform a deep scan:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-privacy-scanner":
Prompt:
Analyze the current project to detect data collection practices. Do the following:

1. **Detect app name and platform** — Use the Glob tool to find project config files: package.json, pubspec.yaml, build.gradle, Podfile, *.csproj, *.xcodeproj/project.pbxproj, app.json, expo.json, Info.plist, AndroidManifest.xml. Extract the app name and determine the platform (iOS, Android, Web, or cross-platform).

2. **Scan for third-party SDKs** — Use the Glob tool to find dependency files: package.json, Podfile, Podfile.lock, build.gradle, pubspec.yaml, pubspec.lock, *.csproj, Gemfile, requirements.txt, go.mod. Flag any of these known data-collecting SDKs (check for partial name matches):
   - Analytics: firebase-analytics, firebase_analytics, google-analytics, mixpanel, amplitude, segment, flurry, appsflyer, adjust, branch, heap, posthog
   - Crash reporting: sentry, crashlytics, firebase-crashlytics, firebase_crashlytics, bugsnag, instabug, datadog
   - Advertising: admob, google-mobile-ads, facebook-ads, applovin, unity-ads, ironsource, mopub
   - Social/Auth: facebook-sdk, react-native-fbsdk, google-sign-in, sign-in-with-apple, auth0, firebase-auth, firebase_auth
   - Payments: revenuecat, purchases_flutter, stripe, braintree, in-app-purchase, store_kit
   - Push notifications: firebase-messaging, firebase_messaging, onesignal, pushwoosh, airship
   - Maps/Location: google-maps, mapbox, react-native-maps, location, geolocator

3. **Search for data collection in code** — Use the Grep tool to search source code files (case-insensitive) for: email, location, CLLocationManager, FusedLocationProvider, camera, AVCaptureSession, microphone, AVAudioSession, contacts, CNContactStore, healthkit, HKHealthStore, tracking, ATTrackingManager, AppTrackingTransparency, analytics, purchase, payment, biometric, FaceID, TouchID, photo library, PHPhotoLibrary, calendar, EKEventStore, bluetooth, CoreBluetooth

4. **Map findings to Apple Privacy Label categories** — For each detected SDK/data type, determine which of Apple's 14 data categories are affected:
   - contact_info (name, email, phone, physical_address, other_contact_info)
   - health_fitness (health, fitness)
   - financial_info (payment_info, credit_info, other_financial_info)
   - location (precise_location, coarse_location)
   - sensitive_info
   - contacts (contacts_list)
   - user_content (emails_or_messages, photos_or_videos, audio_data, gameplay_content, customer_support, other_user_content)
   - browsing_history
   - search_history
   - identifiers (user_id, device_id)
   - purchases (purchase_history)
   - usage_data (product_interaction, advertising_data, other_usage_data)
   - diagnostics (crash_data, performance_data, other_diagnostic_data)
   - other_data

   For each affected data type, determine:
   - purposes: array of "third_party_advertising", "developers_advertising", "analytics", "product_personalization", "app_functionality", "other"
   - linked_to_identity: true if the data can be tied to user identity
   - used_to_track: true if used for tracking across apps

5. **Map findings to Google Play Data Safety categories** — Same 14 categories, but for each determine:
   - collected: true
   - shared: true if data is shared with third parties
   - purposes: array of "app_functionality", "analytics", "developer_communications", "advertising_marketing", "fraud_prevention", "personalization", "account_management"
   - required_or_optional: "required" or "optional"

Return a JSON object with this exact structure:
{
  "appName": "string or null",
  "platform": "string",
  "detected_sdks": [{"name": "...", "category": "...", "data_collected": "..."}],
  "detected_data_types": ["email", "location", ...],
  "apple_suggestions": {
    "data_category_id": {
      "data_type_id": {
        "collected": true,
        "purposes": ["analytics"],
        "linked_to_identity": false,
        "used_to_track": false
      }
    }
  },
  "google_suggestions": {
    "data_category_id": {
      "data_type_id": {
        "collected": true,
        "shared": false,
        "purposes": ["analytics"],
        "required_or_optional": "required"
      }
    }
  }
}
```

### Step 2: Present Findings

Show the user what was detected:

```
I scanned your project and found:

**SDKs detected:** {list each SDK with its category}
**Data types detected:** {list}

**Apple Privacy Labels — suggested declarations:**
{For each category with findings, show a brief summary}

**Google Data Safety — suggested declarations:**
{For each category with findings, show a brief summary}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option).

If the user wants to adjust, incorporate their changes before proceeding.

### Step 3: Push to Uprate Indie

1. **Read config**: Read `~/.uprate/config.json` via Bash (`cat ~/.uprate/config.json 2>/dev/null || echo "{}"`). Check if `indie.url` and `indie.apiKey` exist.

2. **Setup (if needed)**: If the `indie` block is missing:
   - Tell the user: "To push content to your Uprate project, I need your instance URL and API key. You can create an API key at your Uprate instance under Settings > API Keys."
   - Use AskUserQuestion to ask for the instance URL (e.g., `https://app.example.com`). Use free text input.
   - Use AskUserQuestion to ask for the API key (starts with `uprt_`). Use free text input.
   - Validate by running: `curl -s -w "\n%{http_code}" -H "Authorization: Bearer {apiKey}" -H "Accept: application/json" "{url}/api/v1/projects"`
   - If the last line is `200`, save the config: read existing `~/.uprate/config.json`, merge in `{"indie": {"url": "{url}", "apiKey": "{apiKey}"}}`, write back.
   - If not 200, tell the user the key is invalid and ask them to try again.

3. **Select project**: Call `GET {url}/api/v1/projects` with Bearer auth. Parse the `data` array. Use AskUserQuestion to present each project as an option (show name and platforms). If no projects exist, tell the user to create one in the web app first.

4. **Push Apple Privacy Labels scan data**: Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_scan_privacy
   project_uuid: {selected_uuid}
   payload: {"cc_scan_data": {"detected_sdks": [<sdks>], "detected_data_types": [<types>], "suggested_declarations": {<apple_suggestions>}}}
   ```

5. **Push Google Data Safety scan data**: Spawn the `uprate-indie-push` agent:
   ```
   Use the Agent tool with subagent_type "general-purpose" and name "uprate-indie-push":
   Prompt: Read the agent instructions at ~/.claude/agents/uprate-indie-push.md and follow them.
   Operation: push_scan_data_safety
   project_uuid: {selected_uuid}
   payload: {"cc_scan_data": {"detected_sdks": [<sdks>], "detected_data_types": [<types>], "suggested_declarations": {<google_suggestions>}}}
   ```

Show results:
- If both succeeded: "Scan data pushed! Your Privacy Labels and Data Safety forms will be pre-filled in your Uprate project."
- If either failed, show the specific error.

Done! Do not proceed with any additional steps unless the user asks.
