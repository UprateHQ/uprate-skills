---
name: indie-api
description: Uprate Indie API reference for pushing generated content to your App Store Submission Hub
---

# Uprate Indie API Reference

Reference for skills that push content to an Uprate Indie instance.

## Configuration

Auth credentials are stored in `~/.uprate/config.json` under the `indie` key:

```json
{
  "indie": {
    "url": "https://your-uprate-instance.com",
    "apiKey": "uprt_..."
  }
}
```

To get an API key, visit your Uprate Indie instance at `/settings/api-keys` and create one.

## Setup Flow

When a skill needs to push to Uprate Indie and the `indie` block is missing from config:

1. Ask the user: "To push content to your Uprate project, I need your instance URL and API key."
2. Ask for the URL (e.g., `https://app.example.com`)
3. Ask for the API key (starts with `uprt_`)
4. Validate by calling `GET {url}/api/v1/projects` with the Bearer token
5. If valid, save to `~/.uprate/config.json` (merge with existing config, don't overwrite other keys)
6. If invalid (401), ask the user to check their key

## Project Selection Flow

When a skill needs to target a specific project:

1. Call `GET {url}/api/v1/projects` with Bearer auth
2. Parse the `data` array — each project has `uuid`, `name`, `slug`, `platforms`
3. Present projects to user via AskUserQuestion (each as an option with name + platforms)
4. If no projects exist, offer to create one via `POST {url}/api/v1/projects`
5. Use the selected project's `uuid` in all subsequent API calls

## API Endpoints

All endpoints require `Authorization: Bearer {apiKey}` header and `Content-Type: application/json`.

Base URL: `{indie.url}/api/v1`

### List Projects
```
GET /projects
```
Response: `{ "data": [{ "uuid": "...", "name": "...", "slug": "...", "platforms": [...], ... }] }`

### Create Project
```
POST /projects
Body: { "name": "My App", "platforms": ["ios", "android"], "bundle_id_apple": "...", "bundle_id_android": "..." }
```
Response: `{ "data": { "uuid": "...", ... } }` (201)

### Update Project Metadata
```
PATCH /projects/{uuid}
Body: { "name": "...", "bundle_id_apple": "...", "bundle_id_android": "...", "platforms": [...], "developer_name": "...", "developer_email": "...", "developer_website": "..." }
```
Only include fields you want to update. Response: `{ "data": { ...project... } }`

### Push Legal Page
```
PUT /projects/{uuid}/legal/{type}
Types: privacy_policy, terms_of_service, eula
Body: { "content_markdown": "# Privacy Policy\n\n...", "source": "cc_skill" }
```
Response: `{ "data": { ..., "hosted_url": "/p/{slug}/privacy-policy" } }`
Note: Auto-publishes the page. The `hosted_url` is the public URL where the page is hosted.

### Push Descriptions
```
POST /projects/{uuid}/descriptions
Body: {
  "app_description_ios": "...",
  "subtitle_ios": "...",
  "keywords_ios": "...",
  "promotional_text_ios": "...",
  "whats_new_ios": "...",
  "app_description_android": "...",
  "short_description_android": "...",
  "whats_new_android": "...",
  "copyright_text": "...",
  "tone": "professional",
  "app_features": ["feature1", "feature2"],
  "target_audience": "...",
  "key_benefits": "...",
  "primary_category_ios": "...",
  "secondary_category_ios": "...",
  "primary_category_android": "...",
  "secondary_category_android": "..."
}
```
All fields are optional — only include what you want to update. Response: `{ "data": { ...description... } }`

### Push Icon URL
```
POST /projects/{uuid}/icon
Body: { "icon_url": "https://..." }
```
Response: `{ "data": { "icon_url": "..." } }`

### Push Privacy Labels Scan Data
```
POST /projects/{uuid}/privacy-labels/scan
Body: { "cc_scan_data": { "detected_sdks": [...], "detected_data_types": [...], "suggested_declarations": {...} } }
```
Response: `{ "data": { ...privacy_label... } }`

### Push Data Safety Scan Data
```
POST /projects/{uuid}/data-safety/scan
Body: { "cc_scan_data": { "detected_sdks": [...], "detected_data_types": [...], "suggested_declarations": {...} } }
```
Response: `{ "data": { ...data_safety... } }`

### Get Checklist
```
GET /projects/{uuid}/checklist
```
Response: `{ "data": { "ios": [...items], "android": [...items] } }`
Each item: `{ "field": "...", "label": "...", "status": "complete|missing|optional", "required": bool, "cc_command": "..." }`

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Invalid or expired API key | Ask user to check their key at `/settings/api-keys` |
| 403 | Project not owned by this user | Ask user to select a different project |
| 404 | Project or resource not found | Verify the project UUID is correct |
| 422 | Validation error | Show the error details from response body |
| 429 | Rate limit exceeded | Wait and retry, or ask user to try again later |

## Curl Template

```bash
curl -s -X {METHOD} "{url}/api/v1/{endpoint}" \
  -H "Authorization: Bearer {apiKey}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{json_body}'
```
