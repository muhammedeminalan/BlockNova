<p align="center">
  <img src="BlockNova/Assets.xcassets/AppIcon.appiconset/app_icon_fixed.png" width="120" alt="BlockNova Icon"/>
</p>

<h1 align="center">BlockNova</h1>

<p align="center">
  <strong>Sürükle. Yerleştir. Patlat!</strong><br/>
  A minimalist block puzzle game for iPhone.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5"/>
  <img src="https://img.shields.io/badge/iOS-15%2B-000000?logo=apple&logoColor=white" alt="iOS 15+"/>
  <img src="https://img.shields.io/badge/SpriteKit-Game%20Engine-5AC8FA" alt="SpriteKit"/>
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License"/>
</p>

<p align="center">
  <a href="https://lnkd.in/d_kaxwAf">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="50" alt="Download on the App Store"/>
  </a>
</p>

---

<p align="center">
  <img src="screenshot/home-screen.png" width="180" alt="Home Screen"/>
  &nbsp;
  <img src="screenshot/game-start.png" width="180" alt="Game Start"/>
  &nbsp;
  <img src="screenshot/gameplay.png" width="180" alt="Gameplay"/>
  &nbsp;
  <img src="screenshot/game-over.png" width="180" alt="Game Over"/>
</p>

---

## About

**BlockNova** is a drag-and-drop block puzzle game built with **SpriteKit**. Drag colorful pieces onto an 8×8 grid, clear full rows and columns to score, and survive as long as you can. No timers, no rotation — pure spatial reasoning.

## Features

- **11 unique shapes** — Lines, squares, L/J/T/S/Z tetrominos and more
- **Smart piece distribution** — Shuffle bag + history-based rejection keeps the game fair and varied
- **Combo scoring** — Clear multiple lines at once for bonus multipliers
- **Haptic feedback** — Distinct vibrations for placement, clears, and game over
- **Responsive layout** — All UI scales dynamically to any iPhone screen size
- **Persistent high scores** — Best score saved locally and displayed in-game

## Architecture

```
BlockNova/
├── Scenes/
│   ├── HomeScene.swift              # Animated main menu
│   ├── GameScene.swift              # Core game loop & touch handling
│   ├── GameScene+Layout.swift       # Responsive layout
│   └── GameScene+Overlay.swift      # Game over modal
├── Nodes/
│   ├── GridNode.swift               # 8×8 grid rendering & logic
│   ├── BlockNode.swift              # Individual cell
│   └── PieceNode.swift              # Draggable piece
├── Models/
│   ├── BlockShape.swift             # Shape definitions
│   ├── GameManager.swift            # Score & state management
│   └── ShapeDispenser.swift         # Balanced shape distribution
├── ViewModels/
│   └── GameViewModel.swift          # Presentation formatting
└── Utils/
    ├── Constants.swift              # Layout constants
    └── HapticManager.swift          # Haptic feedback
```

**Patterns:** MVC + ViewModel · Delegate-based event propagation · Zero hardcoded pixel values · Safe area-aware on all iPhones

## Build from Source

```bash
git clone https://github.com/muhammedeminalan/BlockNova.git
open BlockNova.xcodeproj
# Build & run on a physical device or simulator (iOS 15+)
```

> Requires **Xcode 14+** and **iOS 15.0+**

## License

This project is proprietary. All rights reserved.

---

<p align="center">
  Built with Swift & SpriteKit<br/>
  <a href="https://lnkd.in/d_kaxwAf">App Store'dan İndir</a>
</p>
