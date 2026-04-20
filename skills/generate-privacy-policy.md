---
name: generate-privacy-policy
description: Generate a legally-sound privacy policy for a mobile app by analyzing the project codebase
---

# Uprate Privacy Policy Generator

Generate a ready-to-publish privacy policy for your mobile app, based on your project's context.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Analyze the Project

Spawn a general-purpose subagent to scan the codebase and detect data collection practices:

```
Use the Agent tool with subagent_type "general-purpose" and name "uprate-privacy-analyzer":
Prompt:
Analyze the current project to detect data collection practices for privacy policy generation. Do the following:

1. **Detect app name and platform:**
   - Use the Glob tool to find project config files: package.json, pubspec.yaml, build.gradle, Podfile, *.csproj, *.xcodeproj/project.pbxproj, app.json, expo.json, Info.plist, AndroidManifest.xml
   - Extract the app name from whichever config file exists
   - Determine the platform: iOS, Android, Web, or cross-platform (React Native, Flutter, .NET MAUI, etc.)

2. **Scan for third-party SDKs that collect data:**
   - Use the Glob tool to find dependency files: package.json, Podfile, Podfile.lock, build.gradle, pubspec.yaml, pubspec.lock, *.csproj, Gemfile, requirements.txt, go.mod
   - Read each dependency file found
   - Flag any of these known data-collecting SDKs/packages (check for partial name matches):
     - Analytics: firebase-analytics, firebase_analytics, google-analytics, mixpanel, amplitude, segment, flurry, appsflyer, adjust, branch, heap, posthog, plausible, matomo
     - Crash reporting: sentry, crashlytics, firebase-crashlytics, firebase_crashlytics, bugsnag, instabug, datadog
     - Advertising: admob, google-mobile-ads, facebook-ads, applovin, unity-ads, ironsource, mopub
     - Social/Auth: facebook-sdk, react-native-fbsdk, google-sign-in, sign-in-with-apple, auth0, firebase-auth, firebase_auth
     - Payments: revenuecat, purchases_flutter, stripe, braintree, in-app-purchase, store_kit
     - Push notifications: firebase-messaging, firebase_messaging, onesignal, pushwoosh, airship
     - Maps/Location: google-maps, mapbox, react-native-maps, location, geolocator
     - Other: intercom, zendesk, freshchat, hotjar, fullstory, smartlook

3. **Search for explicit data collection in code:**
   - Use the Grep tool to search source code files for these keywords (case-insensitive): email, location, CLLocationManager, FusedLocationProvider, camera, AVCaptureSession, microphone, AVAudioSession, contacts, CNContactStore, healthkit, HKHealthStore, tracking, ATTrackingManager, AppTrackingTransparency, analytics, purchase, payment, biometric, FaceID, TouchID, photo library, PHPhotoLibrary, calendar, EKEventStore, bluetooth, CoreBluetooth
   - Note which keywords matched and in which files

4. **Check for target markets:**
   - Use the Grep tool to search for locale/region configurations: NSLocale, Locale, i18n, l10n, intl, localization, GDPR, CCPA, regionCode
   - Check for region-specific config files or directories (e.g., values-de, lproj files)

Return your findings as a JSON object with this exact structure:
{
  "appName": "string or null",
  "platform": "iOS | Android | Web | cross-platform | unknown",
  "detectedSDKs": [
    { "name": "SDK name", "category": "analytics|crash-reporting|advertising|social-auth|payments|push-notifications|maps-location|other", "dataCollected": "brief description of what this SDK typically collects" }
  ],
  "detectedDataTypes": ["list of data types found in code, e.g. email, location, camera"],
  "targetMarkets": ["any detected regions or locales, or empty array"],
  "dependencyFiles": ["list of dependency files found"]
}
```

Parse the JSON output from the agent.

Present the findings to the user:

```
I analyzed your project and found:

- **App:** {appName}
- **Platform:** {platform}
- **Third-party SDKs detected:** {list each SDK with its category}
- **Data types detected in code:** {list detected data types}
- **Target markets:** {list or "None detected"}

Does this look right?
```

Use AskUserQuestion with options: "Looks correct" and "I want to adjust" (with Other option for custom input).

If the user wants to adjust, incorporate their changes before proceeding.

### Step 2: Ask Clarifying Questions

Ask the following questions one at a time, in order, using AskUserQuestion for each:

**Question 1 — Business type:**
```
Who operates this app?
```
Options: "Individual / Sole trader", "Company / LLC", "Non-profit", "Other"

**Question 2 — Children:**
```
Does your app target children under 13 (COPPA) or under 16 (GDPR)?
```
Options: "No", "Yes — under 13", "Yes — under 16", "Unsure"

**Question 3 — Data types confirmation:**
```
We detected these data types being collected:

{list each detected SDK and what it collects}
{list each detected data type from code}

Are there any we missed?
```
Options: "Looks complete", "I want to add more"

If the user selects "I want to add more", use AskUserQuestion with free text to collect additional data types.

**Question 4 — Contact email:**
```
What email address should users contact for privacy requests?
```
Use AskUserQuestion with free text input (no predefined options).

**Question 5 — Jurisdiction:**
```
Which privacy laws apply?
```
Options: "GDPR (Europe)", "CCPA (California)", "Both", "Other / Unsure"

### Step 3: Generate the Privacy Policy

Using all collected context (app metadata, detected SDKs, user answers), generate a complete privacy policy as a markdown document.

The policy MUST include all of the following sections in this order:

1. **Title:** "Privacy Policy for {appName}"

2. **Introduction & Who We Are:** State who operates the app (based on business type answer). Explain the purpose of the policy. Keep it warm and direct.

3. **What Data We Collect:** List all data types — both auto-detected from SDKs and confirmed/added by the user. Group them by category (e.g., "Usage Data", "Device Information", "Personal Information"). For each item, briefly explain what is collected and why.

4. **How We Use Your Data:** Explain the purposes: app functionality, analytics, crash reporting, advertising (only if applicable), etc. Match purposes to the actual SDKs and data types detected.

5. **Third-Party Services:** One paragraph per detected SDK or service. For each, state:
   - The service name and provider
   - What data it collects
   - Link to its own privacy policy (use the well-known URL for that service)

6. **Data Retention:** General statement about how long data is kept. Note that third-party services have their own retention policies.

7. **User Rights:** Tailor this section to the selected jurisdiction:
   - If GDPR: right to access, rectification, erasure, restriction, portability, objection
   - If CCPA: right to know, delete, opt-out of sale, non-discrimination
   - If Both: include all rights from both frameworks
   - If Other/Unsure: include a general set of rights covering access, deletion, and opt-out

8. **Children's Privacy:** Include this section only if the user answered "Yes" or "Unsure" to the children question. State the applicable age threshold and what measures are taken.

9. **Changes to This Policy:** Standard section about how users will be notified of changes.

10. **Contact Us:** Include the email address provided by the user.

11. **Last Updated:** Use today's date.

Keep the language plain and readable. Avoid dense legal boilerplate. Write as if a solo developer is publishing this for their app. Use short paragraphs and clear headings.

### Step 4: Output

Show a summary of what was generated:

```
Privacy policy generated for {appName}:
- {N} sections covering {jurisdiction} requirements
- {N} third-party services documented
- Contact: {email}
```

Then ask the user where to save it:

```
Would you like to save this to a file?
```

Use AskUserQuestion with options: "Save as PRIVACY_POLICY.md", "Don't save, I'll copy it"

If the user chooses to save, write the file to the current working directory using the Write tool.

Regardless of the save choice, show the full privacy policy in a markdown code block so it can be easily copied.

Done! Do not proceed with any additional steps unless the user asks.
