---
name: setup-pricing-keys
description: Walk through getting the App Store Connect + Google Play credentials Uprate needs to change app pricing
---

# Uprate Pricing Keys Setup

Walk the user through gathering every credential Uprate needs to push pricing changes to App Store Connect and Google Play, then validate the connection ends up green inside Uprate.

This skill is interactive. Apple and Google credentials must be generated in their consoles by the signed-in account holder. Your job is to open the right pages, tell the user exactly what to click, collect each credential, and verify Uprate validates them.

## Instructions

Follow these steps exactly in order. Use AskUserQuestion for all user choices.

### Step 1: Pick Platform(s)

Use AskUserQuestion:

> Which platforms do you want to connect for pricing?
> - "App Store Connect (iOS)" — needed to change iOS app + IAP + subscription prices
> - "Google Play (Android)" — needed to change Android app + IAP + subscription prices
> - "Both" (Recommended)

Run Step 2 for App Store Connect if selected. Run Step 3 for Google Play if selected. Both can run in either order.

### Step 2: App Store Connect

The official guide at https://upratehq.notion.site/guide-app-store-connect covers **Reviews Only** (Individual API Key). For **pricing** you need a **Team API Key** with Admin role. The steps below override the Notion guide.

**Step 2.1 — Generate Team API Key**

Open https://appstoreconnect.apple.com/access/integrations/api in a new tab and tell the user to:

1. Confirm the **Team Keys** tab is selected (top of page; second tab is "Individual Keys" — do not use that one).
2. Copy the **Issuer ID** shown at the top (UUID, team-wide, shared by all keys). Save it.
3. Click the **+** button next to "Active (N)".
4. In the dialog:
   - **Name**: anything, e.g. `uprate-pricing` (30 char limit)
   - **Access**: **Admin**. App Manager is the minimum for pricing reads, but Admin is what Uprate's Broad API Access validation expects.
5. Click **Generate**.
6. In the new row, click **Download** then confirm **Download** in the second dialog. Apple only lets you download the .p8 **once** — if lost, the key must be revoked and a new one generated.
7. The downloaded file is named `AuthKey_<KEYID>.p8`. The 10-character `<KEYID>` is the **Key ID** (also shown in the row).

Ask the user to paste:
- **Issuer ID** (UUID, e.g. `fc850782-4e26-4a5c-9ad7-cfa0525123f4`)
- **Key ID** (10 chars, e.g. `G9UZ577ZQM`)
- **Absolute path to the .p8 file** (default: `~/Downloads/AuthKey_<KEYID>.p8`)

**Step 2.2 — Vendor Number**

Open https://appstoreconnect.apple.com/itc/payments_and_financial_reports. The **Vendor #** shows at the top of the page (8 digits). Ask the user to copy it.

**Step 2.3 — App Apple ID**

Open https://appstoreconnect.apple.com/apps. The user clicks the app they want to manage. The numeric ID in the URL (`/apps/<APP_APPLE_ID>/distribution/info`) is the App Apple ID (e.g. `6764249797`).

If the user already added this app to Uprate via the in-store search, Uprate already stored its App Apple ID — they can skip this. If Uprate has the wrong App Apple ID stored on an app (e.g. they want to repoint an existing row), it can only be fixed via DB; flag this and stop unless they have backend access.

**Step 2.4 — Paste into Uprate**

Open https://app.upratehq.com/apps. Tell the user to:

1. Find their app card and click **Connect** on the **App Store Connect** tile.
2. Switch the **Access Profile** radio to **Broad API Access** (default is Reviews Only — does not work for pricing).
3. Fill:
   - **Vendor Number**: from Step 2.2
   - **Issuer ID**: from Step 2.1
   - **Key ID**: auto-extracts from filename if it follows `AuthKey_<KEYID>.p8`; otherwise paste manually
   - Upload the **.p8 file** from Step 2.1
4. Tab out of the Key ID field to trigger validation.
5. Wait for green **"App Store access verified"** banner with all 5 capabilities passing (Read Reviews, Reply to Reviews, Read Pricing, Read Catalog, Read Store Metadata).
6. Click **Connect App Store**.

If validation fails with **"Verify the App Apple ID belongs to the same Apple team as this API key"**: the Apple App ID stored in Uprate doesn't match the team this API key was generated in. The user generated the key in the right team but Uprate has the wrong `app_store_id` for this app. Flag this and stop.

### Step 3: Google Play

The official guide at https://upratehq.notion.site/guide-google-play-console grants only **Reviews Only** permissions. For **pricing** the service account needs **Admin (all permissions)**. The steps below override the Notion guide.

**Step 3.1 — Enable Google Play Android Developer API**

Open https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com in the user's Google Cloud project that will host the service account.

If they don't have a project yet: tell them to create one at https://console.cloud.google.com/projectcreate first, then come back.

Click **Enable** if not already enabled.

**Step 3.2 — Create Service Account + JSON Key**

Open https://console.cloud.google.com/iam-admin/serviceaccounts and have the user:

1. Click **Create service account**.
2. Step 1 (Service account details):
   - **Name**: e.g. `uprate-pricing`
   - **ID**: auto-fills
   - Click **Create and continue**
3. Step 2 (Permissions) and Step 3 (Principals) are optional — click **Done**.
4. Click on the newly created service account in the list.
5. Switch to the **Keys** tab.
6. Click **Add key → Create new key**.
7. Pick **JSON** (default) and click **Create**. The JSON file downloads.

Ask the user to paste:
- **Service account email** (visible in the SA list, format `<name>@<project-id>.iam.gserviceaccount.com`, e.g. `uprate-pricing@my-project-123.iam.gserviceaccount.com`)
- **Absolute path to the downloaded JSON** (default: `~/Downloads/<project-id>-<hash>.json`)

**Step 3.3 — Grant Access in Play Console**

Open https://play.google.com/console/u/0/developers and have the user pick the right developer account, then navigate **Users and permissions → Invite new users**.

In the invite form:

1. **Email address**: paste the service account email from Step 3.2.
2. Switch to the **Account permissions** tab (the second tab, not "App permissions").
3. Check **Administrator (all permissions)**. A confirmation dialog may flash; if a Použít/Apply button appears in a side panel, click it to confirm.
4. Click **Invite user** at the bottom.
5. In the final **"Send invitation?"** dialog, click **Send invitation**.

If you see error **55EB201D**, **402E2CA1**, or similar "Unexpected error" codes: close the tab, open it fresh, and retry. Play Console's invite form is flaky.

Verify the service account email appears in the users list at https://play.google.com/console/u/0/developers/<DEV_ID>/users-and-permissions. If it doesn't appear after retry, stop and tell the user to add it manually later — Uprate's GP connection will fail validation until then.

**Step 3.4 — Paste into Uprate**

On the same https://app.upratehq.com/apps page:

1. Find the app card and click **Connect** on the **Google Play Store** tile.
2. Switch the **Access Profile** radio to **Broad API Access**.
3. Upload the **JSON key file** from Step 3.2.
4. Wait for validation (all pricing capabilities should pass green).
5. Click **Connect Google Play**.

### Step 4: Verify

Reload https://app.upratehq.com/apps. The app's tiles should now show **Connected** for the platforms you set up (with sync status underneath).

Optional smoke test: navigate to https://app.upratehq.com/pricing-intelligence. The price tables should populate with the app's real prices pulled from the stores. If they don't load within ~30 seconds, the connection isn't fully working.

## Notes for the implementer

- **Apple's .p8 download is one-shot.** If the user loses the file, they must revoke the key in App Store Connect and create a new one. Don't waste their time troubleshooting — point them at "create a new key".
- **Apple's filename convention is `AuthKey_<KEYID>.p8`** (underscore). If a user renamed the file, Key ID auto-detection in Uprate breaks; tell them to paste the Key ID manually.
- **Google's JSON key contains the full private key in plaintext.** Store it like a password. Tell the user not to commit it to git.
- **Service account email format** is always `<name>@<project-id>.iam.gserviceaccount.com`. If the user pastes a wrong-looking email, double-check they grabbed it from the Service accounts list, not from elsewhere.
- **Play Console invite is the most failure-prone step.** Be patient. Closing and reopening the tab clears Angular form state.
