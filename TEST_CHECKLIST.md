# BlockNova Test Checklist

## SwiftUI Flow
- [ ] App launch -> `LoadingView` appears and animates smoothly.
- [ ] Loading completes once and navigates to Home (no repeat transitions).
- [ ] Return to app from background during loading does not cause duplicate loading animations.

## Home
- [ ] Home renders without stutter.
- [ ] High score value updates when `highScoreUpdated` notification is posted.
- [ ] `Play` opens the game screen.
- [ ] `Settings` opens full screen and closes correctly.
- [ ] `Leaderboard` opens Game Center UI when available.

## Game Integration (Gameplay unchanged)
- [ ] Drag/drop still works as before.
- [ ] Score updates correctly after placements and line clears.
- [ ] Game Over shows SwiftUI overlay (not SpriteKit legacy overlay).
- [ ] `Replay` restarts game in place.
- [ ] `Home` returns to SwiftUI Home screen.
- [ ] In-game top-left `Ana Menu` button opens exit confirmation modal.
- [ ] Exit modal `Iptal` resumes game without state loss.
- [ ] Exit modal `Kaydet ve Cik` returns Home and restores from save on next game open.

## Settings
- [ ] Sound toggle persists across app relaunch.
- [ ] Haptic toggle persists across app relaunch.
- [ ] Closing Settings returns to previous screen cleanly.

## Regression / Stability
- [ ] No duplicated animations after repeated Home <-> Game navigation.
- [ ] No unexpected memory growth during repeated Loading/Home/Game cycles.
- [ ] No force unwrap crash paths triggered in basic navigation.
