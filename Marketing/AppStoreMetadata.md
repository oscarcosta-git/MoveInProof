# App Store Metadata - MoveIn Proof

Section 2 of the Required Document: the App Store Connect metadata package and product strategy. Character counts are checked against Apple's limits.

## App identity

| Field | Value | Count / limit |
|---|---|---|
| App Name | MoveIn Proof: Condition Report | 30 / 30 |
| Subtitle | Protect your rental bond | 24 / 30 |
| Bundle ID | com.oscarcosta.MoveInProof | |
| Version | 1.0 | |
| Price | Free | |
| Primary category | Productivity | |
| Secondary category | Lifestyle | |

**Why these categories:** the app's core job is producing a document (a condition report) quickly and accurately, which puts it in **Productivity**. Renters browsing for home and moving tools look in **Lifestyle**, so the secondary category puts it where they look.

**Naming:** "MoveIn Proof" is short and distinctive, and says what the app gives you: proof of the property's condition when you moved in. "Condition Report" after the colon adds the term renters actually search for. The name uses no trademarks, competitor names or generic-only words, in line with App Store Review Guideline 2.3.7.

## Age rating

**Rating: 4+**

| Questionnaire item | Answer | Justification |
|---|---|---|
| Violence, sexual content, profanity, horror, drugs, alcohol, gambling | None | The app contains no such content. |
| Medical or treatment information | None | No health data is collected or shown. |
| Unrestricted web access | No | The app has no web views and makes no network requests. |
| User-generated content shared with others | No | Photos and notes stay on the device. Nothing is published, uploaded or visible to other users, so no moderation is needed (Guideline 1.2). The user can choose to share their own PDF through the system share sheet. |
| Location sharing | No | The app doesn't request or use location. |
| Contests, chat or messaging | No | |

**Content rights:** the app contains no third-party content. All text, icons and illustrations are original or Apple SF Symbols, and there are no third-party packages.

## Keywords

```
tenant,lease,inspection,move in,move out,renter,landlord,deposit,damage,photo,checklist,apartment
```

97 / 100 characters. Words already in the name and subtitle (condition, report, rental, bond, proof, protect) are left out, because Apple indexes those separately and repeating them wastes space.

## Promotional text

> Moving in? Photograph every room with date and time stamps, flag existing damage, and export a professional condition report to protect your bond. No account needed.

165 / 170 characters. Promotional text can be updated without a new app review, so it can mention seasonal moving periods later.

## Description

2,046 / 4,000 characters.

```
Your condition report is your best evidence when your bond is on the line. MoveIn Proof helps you document a rental property properly on the day you move in, so you can prove what was already there when you move out.

WALK EVERY ROOM, IN ORDER
• A guided checklist of rooms, from the entry to the balcony. Add, remove or reorder rooms to match your place.
• See at a glance which rooms are done, which is up next and how many photos you've taken.

TIMESTAMPED PHOTO EVIDENCE
• Take photos in the app with your iPhone's camera. Each one has the date and time stamped into the image itself, so the timestamp stays visible wherever the photo is shared.
• Choose which wall or area you're photographing, and use flash or tap to focus.

FLAG DAMAGE AS YOU GO
• Tap Scuff, Crack, Stain or More before a shot to flag that photo as existing damage.
• Add a damage type, severity (minor, moderate or major) and notes for every issue.
• Flag any earlier photo as an issue later.

NEVER MISS A KEY DATE
• Track when your condition report is due, when your move-out inspection is booked and when your lease ends.
• Add the Tenancy dates widget to your Home Screen to see the days remaining.

A PROFESSIONAL REPORT IN ONE TAP
• Export a clean A4 PDF with a cover summary, every room's issues and a grid of timestamped photos.
• Share it by email, AirDrop or Messages, print it, or save it to Files.
• Include or leave out photos, or export only the rooms with flagged issues.

PRIVATE BY DESIGN
• No account, no sign-up and no cloud. Your tenancy, photos and notes are stored only on your iPhone.
• No ads, no tracking and no analytics.
• Works fully offline.

BUILT FOR IPHONE
• Light and Dark Mode.
• Supports Dynamic Type, including the largest accessibility text sizes.
• Clear guidance if camera access is turned off, with a shortcut to Settings.

MoveIn Proof doesn't replace your state's official condition report form or legal advice. It gives you organised, timestamped evidence to attach to your report and to refer back to at the end of your lease.
```

## What's New (version 1.0)

```
First release. Photograph each room with timestamped photos, flag existing damage, track your key lease dates and export a PDF condition report.
```

## URLs

| Field | URL |
|---|---|
| Support URL | https://oscarcosta-git.github.io/MoveInProof/support |
| Marketing URL | https://oscarcosta-git.github.io/MoveInProof |
| Privacy Policy URL | https://oscarcosta-git.github.io/MoveInProof/privacy |

These are planned GitHub Pages addresses for the project. They aren't live yet; a real submission would publish these pages first, because App Review checks that the support and privacy URLs load.

## Privacy

### Privacy policy (summary for the policy page)

MoveIn Proof doesn't collect any personal data. Everything you enter (tenancy details, room photos, issues and notes) is stored only on your iPhone, in the app's private storage, with iOS file protection. Nothing is sent to us or to any third party. The app has no accounts, no analytics, no advertising and makes no network requests. Deleting the app, or using "Delete all data" in the app, removes everything. If you choose to share a PDF report, it goes only where you send it using the iOS share sheet.

### App Privacy "nutrition label"

| Section | Declaration |
|---|---|
| Data Used to Track You | None |
| Data Linked to You | None |
| Data Not Linked to You | None |
| **Overall label** | **Data Not Collected** |

**Storage:** on-device only (SwiftData store and photo files in Application Support), not synced. The Home Screen widget reads a small summary (address, three dates and the issue count) from an App Group shared only between the app and its own widget on the same device.

### Permission usage strings

| Key | Used | String shown to the user |
|---|---|---|
| NSCameraUsageDescription | Yes | "MoveIn Proof uses the camera to photograph the condition of each room." |
| NSPhotoLibraryUsageDescription | No | Photos are taken in the app and stored privately, never read from the photo library. |
| NSLocationWhenInUseUsageDescription | No | Location isn't used. The address is typed by the user. |
| NSFaceIDUsageDescription | No | Not used. |

If camera access is denied, the app shows "Camera access is off" with an **Open Settings** button, and it never crashes or loops on the permission prompt.

### Privacy manifest

`PrivacyInfo.xcprivacy` is included in both the app and the widget extension:
- `NSPrivacyTracking`: false, with no tracking domains
- `NSPrivacyCollectedDataTypes`: none
- Required reason API: `UserDefaults`, reason `1C8F.1` (reading and writing data in an App Group shared only with the app's own widget)

## App Review notes

```
No account or login is required. All features work offline in the Simulator or on a device.
To try the app, complete the short setup screen (enter any street address and tap Start move-in report), then use Report > Start a room to take photos.
The Simulator has no camera, so the capture screen shows a drawn wall that is saved and timestamped like a real photo. On a device, the back camera is used.
```

## Product strategy

- **Business model:** free in version 1.0, to build a user base and reviews among renters during the high-turnover moving season. A possible future one-off "Pro" in-app purchase could add move-out comparison and multiple tenancies. The core move-in report stays free, which is also a reason renters would pick it over subscription competitors.
- **Target audience:** Australian renters, especially first-time and student renters, moving into a new rental property who need to complete and return a condition report within the deadline.
- **Positioning:** a renter-first, private, offline tool. Unlike property-manager inspection apps, it's built for the tenant's side, needs no account and keeps the evidence on the tenant's own phone.
- **Screenshots:** six framed 1320×2868 images in `Marketing/AppStoreScreenshots/`, in this order: key dates, timestamped photos, room checklist, flag damage, PDF report, private by design (dark mode).
