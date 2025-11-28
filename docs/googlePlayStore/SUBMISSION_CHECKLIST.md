# Google Play Store Submission Checklist

## Prerequisites

### Google Play Console Account
- [ ] Google Play Developer account ($25 one-time fee)
- [ ] Account verification completed
- [ ] Developer profile set up

### App Signing
- [ ] Upload key generated (first upload to Play Console)
- [ ] Or existing keystore prepared for manual signing

---

## Required Assets

### App Icon (512x512 PNG)
- [x] `pics/0_pismo_icon.png` - ✅ Available

### Feature Graphic (1024x500 PNG/JPG)
- [ ] Need to create from existing assets
- Suggestion: Use `6_App_Store_Preview_Poster.png` as base

### Screenshots (Phone)
- [x] `pics/1_Main_Keyboard_View.png` - ✅ Available
- [x] `pics/2_MultiLanguage_Support.png` - ✅ Available
- [x] `pics/3_Live_Conversion_Demo.png` - ✅ Available
- [x] `pics/4_Features_Overview.png` - ✅ Available
- [x] `pics/5_Usage_Example.png` - ✅ Available

**Note:** Screenshots must be 16:9 or 9:16 ratio. May need resizing.

---

## Store Listing

### Basic Information
- [x] App name (30 chars max): `Pismo - Cyrillic Japanese IME`
- [x] Short description (80 chars max): See STORE_LISTING.md
- [x] Full description (4000 chars max): See STORE_LISTING.md

### Translations
- [x] English (US) - Primary
- [x] Japanese (日本語)
- [x] Russian (Русский)

### Contact Details
- [x] Developer email: `pismo.keyboard@gmail.com`
- [x] Website: `https://pismo-web-page.vercel.app`
- [x] Privacy Policy URL: `https://pismo-web-page.vercel.app/privacy`

---

## App Content

### Content Rating
- [ ] Complete IARC questionnaire in Play Console
- Expected rating: **Everyone** (no objectionable content)

### Target Audience
- [ ] Select age groups (recommend: All ages)

### Data Safety
- [x] No data collected
- [x] No data shared
- [ ] Complete Data Safety form in Play Console

---

## App Release

### App Bundle (AAB)
- [ ] Build release AAB: `./gradlew bundleRelease`
- [ ] Sign with upload key
- [ ] Verify bundle with bundletool

### Version Information
- Current version code: Check build.gradle.kts
- Current version name: Check build.gradle.kts

### Release Notes
```
Initial release of Pismo for Android!

Features:
• Full 33-letter Russian Cyrillic keyboard
• Real-time conversion to Japanese Hiragana/Katakana
• Responsive design for all screen sizes
• Complete privacy - all processing on device
• No ads, no data collection
```

---

## Pre-Launch Checklist

### Testing
- [x] Keyboard displays correctly
- [x] All Cyrillic letters present
- [x] Key press/release works properly
- [ ] Conversion to Japanese works
- [ ] Symbol keyboard functions
- [ ] Tested on multiple screen sizes

### Technical
- [ ] minSdkVersion appropriate (21+)
- [ ] targetSdkVersion current (34+)
- [ ] No crashes or ANRs
- [ ] Permissions properly declared

### Legal
- [x] Privacy Policy created
- [ ] Privacy Policy hosted at URL
- [ ] Terms of Service (optional)
- [ ] Open source licenses included

---

## Submission Steps

### 1. Create App in Play Console
1. Go to https://play.google.com/console
2. Click "Create app"
3. Enter app details:
   - App name: Pismo - Cyrillic Japanese IME
   - Default language: English (US)
   - App or game: App
   - Free or paid: Free
4. Accept declarations

### 2. Set Up Store Listing
1. Go to "Main store listing"
2. Upload app icon (512x512)
3. Upload feature graphic (1024x500)
4. Upload phone screenshots (2-8)
5. Enter app name, descriptions
6. Save draft

### 3. Complete App Content
1. Go to "App content"
2. Complete Privacy policy
3. Complete Ads declaration (No ads)
4. Complete App access (No restrictions)
5. Complete Content ratings (IARC)
6. Complete Target audience
7. Complete News apps (Not a news app)
8. Complete Data safety

### 4. Upload App Bundle
1. Go to "Production" > "Create new release"
2. Upload AAB file
3. Add release notes
4. Save and review

### 5. Review and Publish
1. Review all sections for completion
2. Fix any errors or warnings
3. Submit for review
4. Wait for approval (usually 1-7 days)

---

## Post-Submission

### Monitor
- Check review status daily
- Respond to any reviewer feedback
- Monitor crash reports
- Check user reviews

### Updates
- Plan regular updates
- Monitor user feedback
- Track bugs and feature requests

---

## Files in This Directory

| File | Description |
|------|-------------|
| `STORE_LISTING.md` | Store listing text in EN/JA/RU |
| `PRIVACY_POLICY.md` | Privacy policy document |
| `SUBMISSION_CHECKLIST.md` | This checklist |
| `pics/` | Screenshot and icon assets |

---

## Commands Reference

### Build Release AAB
```bash
cd Android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
./gradlew bundleRelease
```

### Build Release APK (for testing)
```bash
cd Android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
./gradlew assembleRelease
```

### Locate Output Files
- AAB: `app/build/outputs/bundle/release/app-release.aab`
- APK: `app/build/outputs/apk/release/app-release.apk`
