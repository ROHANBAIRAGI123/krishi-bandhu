# 🎵 Single Audio File

This directory contains **one audio file** for the Farmer Dashboard.

## 📁 Audio File

- **Filename:** `audio.mp3`
- **Current Size:** ~337 KB
- **Location:** `assets/audio/audio.mp3`
- **Usage:** Plays when farmer clicks the 🎧 button on dashboard top-right

## 🎤 How to Replace the Audio

### Step 1: Prepare Your Audio
- Record your audio content (any length)
- Ensure it's in **MP3 format**
- Keep quality high (128-192 kbps recommended)

### Step 2: Replace the File
1. Locate the current `assets/audio/audio.mp3` file
2. Delete it or replace it with your new audio file
3. Name your file exactly: `audio.mp3`
4. Place it in the `assets/audio/` directory

### Step 3: Test
```bash
flutter clean
flutter pub get
flutter run
```

## 📋 Audio File Requirements

| Property | Value |
|----------|-------|
| **Format** | MP3 |
| **Filename** | `audio.mp3` |
| **Sample Rate** | 44.1 kHz or higher |
| **Bitrate** | 128-192 kbps |
| **Size** | Recommended under 10 MB |
| **Location** | `/assets/audio/` |

## 🎯 How It's Used

1. **Dashboard Access:** 
   - Location: Top-right corner of Farmer Dashboard
   - Icon: 🎧 (Headset microphone)
   - Button text: "Play Audio"

2. **User Interaction:**
   - Farmer clicks 🎧 button
   - Audio player dialog opens
   - Farmer can Play/Pause/Stop audio
   - Progress shows playback status

## 📝 Notes

- The audio file is bundled with the app
- Farmers can play it anytime from the dashboard
- No internet required (audio is local)
- Works offline

## 🔄 Updating the Audio

To update with new audio:
1. Record/create new MP3 audio
2. Replace `assets/audio/audio.mp3`
3. Rebuild the app: `flutter build apk --release`
4. Deploy to app store

---

**Current Status:** Ready for your audio content  
**File Path:** `assets/audio/audio.mp3`

