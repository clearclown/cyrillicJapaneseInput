# Google Play Store CLI Publishing Setup

## Overview

This project uses [gradle-play-publisher](https://github.com/Triple-T/gradle-play-publisher) to publish to Google Play Store from the command line.

## Prerequisites

1. Google Play Developer Account ($25 one-time fee)
2. App created in Google Play Console (at least one manual upload)
3. Google Cloud Service Account with API access

---

## Step 1: Create App in Google Play Console (First Time Only)

**IMPORTANT:** Before CLI publishing works, you must manually create the app once.

1. Go to https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - App name: `Pismo - Cyrillic Japanese IME`
   - Default language: English (US)
   - App or game: App
   - Free or paid: Free
4. Accept declarations
5. **Upload the first AAB manually** (required for API access)
   - Go to Testing > Internal testing > Create new release
   - Upload `docs/googlePlayStore/pismo-v1.0.0.aab`
   - Save (don't need to roll out yet)

---

## Step 2: Create Service Account

### A. Google Cloud Console

1. Go to https://console.cloud.google.com
2. Create new project or select existing
3. Enable "Google Play Android Developer API"
   - Go to APIs & Services > Enable APIs
   - Search for "Google Play Android Developer API"
   - Click Enable

4. Create Service Account
   - Go to IAM & Admin > Service Accounts
   - Click "Create Service Account"
   - Name: `play-publisher`
   - Click "Create and Continue"
   - Skip roles (we'll set in Play Console)
   - Click "Done"

5. Create Key
   - Click on the service account
   - Go to Keys tab
   - Add Key > Create new key > JSON
   - Download the JSON file

### B. Google Play Console

1. Go to https://play.google.com/console
2. Go to Settings > API access
3. Link to your Google Cloud project
4. Under "Service accounts", find your service account
5. Click "Manage Play Console permissions"
6. Grant permissions:
   - **Admin** (all permissions) OR
   - At minimum:
     - View app information
     - Create, edit, and publish releases
     - Manage store listing
7. Click "Invite user"
8. Accept the invitation (check email)

---

## Step 3: Configure Project

1. Place the service account JSON file at:
   ```
   Android/app/play-service-account.json
   ```

2. Add to `.gitignore`:
   ```
   play-service-account.json
   ```

3. Also backup to `important/` folder

---

## Step 4: CLI Commands

### Publish to Internal Testing
```bash
./gradlew publishReleaseBundle --track internal
```

### Publish to Alpha/Beta
```bash
./gradlew publishReleaseBundle --track alpha
# or
./gradlew publishReleaseBundle --track beta
```

### Publish to Production
```bash
./gradlew publishReleaseBundle --track production
```

### Upload as Draft
```bash
./gradlew publishReleaseBundle --release-status draft
```

### Update Store Listing Only
```bash
./gradlew publishListing
```

### Promote Release
```bash
./gradlew promoteReleaseArtifact --from-track internal --to-track production
```

---

## File Structure

```
Android/app/
├── src/main/play/
│   ├── listings/
│   │   ├── en-US/
│   │   │   ├── title.txt
│   │   │   ├── short-description.txt
│   │   │   ├── full-description.txt
│   │   │   └── graphics/
│   │   │       └── phone-screenshots/
│   │   ├── ja-JP/
│   │   │   └── ...
│   │   └── ru-RU/
│   │       └── ...
│   └── release-notes/
│       ├── en-US/
│       │   └── default.txt
│       ├── ja-JP/
│       │   └── default.txt
│       └── ru-RU/
│           └── default.txt
├── play-service-account.json  (DO NOT COMMIT)
└── build.gradle.kts
```

---

## Quick Start (After Setup)

```bash
# Build and publish to internal testing
cd Android
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew publishReleaseBundle

# Check available tasks
./gradlew tasks --group publishing
```

---

## Troubleshooting

### "App not found"
- Make sure you've uploaded at least one APK/AAB manually first

### "Permission denied"
- Check service account permissions in Play Console
- Make sure JSON file path is correct

### "API not enabled"
- Enable "Google Play Android Developer API" in Cloud Console

### "Invalid credentials"
- Re-download the service account JSON key
- Make sure it's the correct project

---

## Security Notes

- NEVER commit `play-service-account.json` to version control
- Store backup in `important/` folder (also gitignored)
- Rotate keys periodically
- Use minimal permissions in production

---

## References

- [gradle-play-publisher Documentation](https://github.com/Triple-T/gradle-play-publisher)
- [Google Play Developer API](https://developers.google.com/android-publisher)
- [Service Account Setup](https://cloud.google.com/iam/docs/service-accounts-create)
