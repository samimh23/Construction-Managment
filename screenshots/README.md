# Screenshots Guide

## 📸 How to Add Screenshots

### 1. Take Screenshots

Run your app and capture screenshots of:

**Required Screenshots:**
- [ ] `login.png` - Login screen
- [ ] `dashboard.png` - Owner dashboard with charts
- [ ] `manager_home.png` - Manager home page
- [ ] `attendance.png` - Attendance tracking screen
- [ ] `workers_list.png` - Worker list view
- [ ] `profile.png` - User profile page

**Optional Screenshots:**
- [ ] `face_recognition.png` - Face recognition feature
- [ ] `geofence_warning.png` - Geofence warning
- [ ] `offline_mode.png` - Offline queue indicator
- [ ] `analytics.png` - Analytics charts

### 2. Screenshot Methods

#### Android Emulator
1. Run your app: `flutter run`
2. Click the camera icon in the emulator toolbar
3. Or use keyboard: `Ctrl + S` (Windows) / `Cmd + S` (Mac)
4. Screenshots saved to: Desktop by default

#### iOS Simulator
1. Run your app: `flutter run`
2. Use: `Cmd + S` 
3. Screenshots saved to: Desktop

#### Real Device
- **Android**: Power + Volume Down
- **iOS**: Power + Volume Up (or Side + Volume Up on newer models)

### 3. Optimize Screenshots

**Recommended Tools:**
- **TinyPNG** (https://tinypng.com/) - Compress images
- **Squoosh** (https://squoosh.app/) - Google's image optimizer

**Target Size:**
- Width: 1080px or less
- Format: PNG or JPG
- File size: < 500KB per image

### 4. Create Demo GIF/Video

**Option 1: Screen Recording**
```bash
# Android
adb shell screenrecord /sdcard/demo.mp4
adb pull /sdcard/demo.mp4

# iOS Simulator
xcrun simctl io booted recordVideo demo.mov
```

**Option 2: Use Tools**
- **Screen to GIF** (Windows): https://www.screentogif.com/
- **LICEcap** (Mac/Windows): https://www.cockos.com/licecap/
- **Kap** (Mac): https://getkap.co/

**GIF Tips:**
- Keep it under 10 seconds
- Show key features: login → dashboard → attendance
- Optimize size: < 5MB
- Frame rate: 10-15 fps is enough
- Resolution: 720p is fine

### 5. Add to Repository

1. **Add images to screenshots folder**
   ```bash
   # Place your images here
   screenshots/
     ├── login.png
     ├── dashboard.png
     ├── manager_home.png
     ├── attendance.png
     ├── workers_list.png
     └── demo.gif
   ```

2. **Update README.md**
   
   The README is already configured to show screenshots in a table format.
   Just add your images and they'll appear automatically!

3. **Commit and push**
   ```bash
   git add screenshots/
   git commit -m "docs: add screenshots and demo"
   git push
   ```

### 6. Alternative: Create a Comparison Table

For before/after UI improvements:

```markdown
## UI Improvements

| Before | After |
|--------|-------|
| ![Before](screenshots/before_dashboard.png) | ![After](screenshots/after_dashboard.png) |
```

### 7. Host Videos Elsewhere (Optional)

If GIF is too large:
- Upload to YouTube (unlisted)
- Use GitHub releases to attach video
- Use Imgur or similar

Then link in README:
```markdown
## 🎥 Demo Video

[![Watch Demo](https://img.youtube.com/vi/YOUR_VIDEO_ID/0.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)
```

---

## 💡 Pro Tips

1. **Clean Screenshots**
   - Use consistent demo data
   - Hide sensitive information
   - Use the same device/emulator for all screenshots
   - Take screenshots in light mode for consistency

2. **Device Frames**
   Use tools to add device frames:
   - https://mockuphone.com/
   - https://deviceframes.com/
   - Figma with device mockups

3. **Annotation**
   Add arrows or highlights to important features:
   - Use Paint, Preview, or online tools
   - Highlight new features
   - Add captions if needed

4. **Layout Ideas**
   ```markdown
   ### Feature Showcase
   
   <p align="center">
     <img src="screenshots/feature1.png" width="30%">
     <img src="screenshots/feature2.png" width="30%">
     <img src="screenshots/feature3.png" width="30%">
   </p>
   ```

---

## ✅ Checklist Before Pushing

- [ ] All screenshots are clear and high quality
- [ ] Images are optimized (compressed)
- [ ] No sensitive data visible (emails, real names, etc.)
- [ ] GIF/video shows smooth app flow
- [ ] File sizes are reasonable (< 500KB per image)
- [ ] Images are named descriptively
- [ ] README.md updated (if using custom layout)

---

**Need help?** Check the [README.md](../README.md) for the current screenshot layout.
