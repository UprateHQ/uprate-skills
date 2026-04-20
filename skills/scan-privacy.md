---
name: scan-privacy
description: Scan your codebase for data collection practices and generate Privacy Labels and Data Safety suggestions
---

# Uprate Privacy Scanner

Scan your project for SDKs and data collection patterns to generate Apple Privacy Labels and Google Play Data Safety suggestions.

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

### Step 3: Output the Suggestions

Show the final results in a copyable format:

1. Present a short summary:
   - Total detected SDKs
   - Total detected data types
   - Number of Apple Privacy Label declarations suggested
   - Number of Google Data Safety declarations suggested

2. Show the suggested Apple declarations and Google declarations in markdown code blocks so they can be copied into another tool or saved locally.

3. Use AskUserQuestion with options:
   - "Save as PRIVACY_SCAN.md"
   - "Don't save, I'll copy it"

4. If saving, write a markdown report containing:
   - App name and platform
   - Detected SDKs
   - Detected data types
   - Apple Privacy Label suggestions
   - Google Data Safety suggestions

Done! Do not proceed with any additional steps unless the user asks.
