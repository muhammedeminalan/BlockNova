// 📁 Scenes/GameScene+Delegates.swift
// Grid ve GameManager delegate eventlerini tek yerde toplar.

import SpriteKit

// MARK: - GridDelegate

extension GameScene: GridDelegate {

    func gridDidClearLines(_ count: Int, clearedCellWorldPositions: [CGPoint]) {
        didClearLineInCurrentPlacement = true
        comboChainCount += 1

        let linePoints = manager.previewPointsForLines(count)
        manager.addScore(forLines: count)
        HapticManager.impact(.heavy)
        // Çizgi temizlenince long-pop sesi çal
        SoundManager.shared.playClear(on: self)
        if count >= 2 {
            SoundManager.shared.playCombo(on: self)
        }
        if count >= 3 {
            // Neden: Mega combo anında daha güçlü ödül hissi için.
            HapticManager.notification(.success)
        }

        showCellScorePopups(totalPoints: linePoints, at: clearedCellWorldPositions)

        guard shouldShowLargeComboEffect(chain: comboChainCount) else { return }
        let effect = ComboEffectPresentation(
            level: effectLevel(forClearedLineCount: count, chain: comboChainCount),
            points: linePoints,
            streak: comboChainCount,
            customTitle: comboTitle(forChain: comboChainCount),
        )
        onComboEffectTriggered?(effect)
    }

    func gridDidPlaceCells(_ count: Int) {
        manager.addScore(forCells: count)
    }

    func gridDidFinishPlacement() {
        // Satir/sutun temizleme bittikten sonra: tepsi bosaldiysa yeni parcalar dagit,
        // sonra game over kontrolu yap. Grid verisi artik gunceldir.
        if trayPieces.allSatisfy({ $0 == nil }) {
            run(SKAction.wait(forDuration: 0.25)) { [weak self] in
                self?.dealNewPieces()
                self?.run(SKAction.wait(forDuration: 0.3)) {
                    self?.checkGameOver()
                }
            }
        } else {
            checkGameOver()
        }
    }
}

// MARK: - GameManagerDelegate

extension GameScene: GameManagerDelegate {

    func didUpdateScore(_ score: Int, highScore: Int, isNewRecord: Bool) {
        notifyScoreChanged(score: score, highScore: highScore)

        if isNewRecord {
            // Yeni rekor kırılınca achievement sesi çal — her skor artışında değil, sadece rekorda
            SoundManager.shared.playRecord(on: self)
            showNewRecordEffect()
        }
    }

    func didChangeState(_ state: GameState) {
        if state == .gameOver {
            comboChainCount = 0
            didClearLineInCurrentPlacement = false
            HapticManager.notification(.error)
            // Oyun bitince game-over sesi çal
            SoundManager.shared.playGameOver(on: self)

            // Game over olunca kaydı sil — devam edilecek oyun kalmadı
            GameSaveManager.shared.deleteSavedGame()

            // Skoru Game Center'a gönder — her bitişte çağrılır, sadece rekorda değil
            GameManager.submitScore(manager.score)

            run(SKAction.wait(forDuration: 0.45)) { [weak self] in
                guard let self else { return }
                let score = self.manager.score
                let highScore = self.manager.highScore
                let presentation = GameOverPresentation(
                    score: score,
                    highScore: highScore,
                    isNewRecord: self.manager.newRecordAchieved,
                )
                self.onGameOverChanged?(presentation)
            }
        }
    }

    /// "YENİ REKOR!" uçan yazısı
    private func showNewRecordEffect() {
        let lbl = makeLabel("YENI REKOR!", font: C.fontBold,
                            size: C.screenH * 0.024, color: C.goldColor.sk)
        lbl.position = CGPoint(x: C.screenW / 2,
                               y: effectiveGridCenterY + C.gridTotalHeight / 2 + C.screenH * 0.05)
        lbl.zPosition = C.zUI + 3
        lbl.alpha = 0
        addChild(lbl)

        lbl.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.18),
                    SKAction.scale(to: 1.0, duration: 0.18),
                ]),
            ]),
            SKAction.wait(forDuration: 1.4),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent(),
        ]))
    }

    /// Buyuk ekran combo efektini her patlamada degil, secili adimlarda tetikler.
    /// Neden: Surekli overlay yerine milestone odakli geri bildirim daha temiz hissettirir.
    private func shouldShowLargeComboEffect(chain: Int) -> Bool {
        // Sadece milestone adimlarinda (5/10/15...) buyuk merkez animasyon ciksin.
        // 1/2/4 gibi adimlarda merkez overlay yok; lokal kirilma efektleri devam eder.
        guard chain > 0 else { return false }
        return chain.isMultiple(of: 5)
    }

    /// Cizgi sayisi + combo adimina gore daha guclu efekt seviyesini sec.
    private func effectLevel(forClearedLineCount lineCount: Int, chain: Int) -> ComboEffectPresentation.Level {
        if chain.isMultiple(of: 5) {
            return .mega
        }
        if chain >= 10 {
            return .mega
        }
        if lineCount >= 4 {
            return .mega
        }
        if lineCount == 2 || chain.isMultiple(of: 5) {
            return .double
        }
        return .line
    }

    /// Milestone adimlari icin basligi daha dikkat cekici hale getirir.
    private func comboTitle(forChain chain: Int) -> String? {
        guard chain.isMultiple(of: 5) else { return nil }
        switch chain {
        case 15...:
            return "NOVA STORM x\(chain)!"
        case 10...:
            return "ULTRA SURGE x\(chain)!"
        default:
            return "FRENZY x\(chain)!"
        }
    }

    /// Kirilan hucrelerin ustunde, kazanilan puani hucreye dagitip kisa sureli gosterir.
    private func showCellScorePopups(totalPoints: Int, at worldPositions: [CGPoint]) {
        guard totalPoints > 0, !worldPositions.isEmpty else { return }

        let count = worldPositions.count
        let basePoint = totalPoints / count
        let remainder = totalPoints % count

        for (index, position) in worldPositions.enumerated() {
            let point = max(1, basePoint + (index < remainder ? 1 : 0))
            let label = makeLabel("+\(point)", font: C.fontBold, size: C.screenH * 0.017, color: C.goldColor.sk)
            label.position = position
            label.zPosition = C.zUI + 4
            label.alpha = 0
            addChild(label)

            let driftX = CGFloat.random(in: -8...8)
            let move = SKAction.moveBy(x: driftX, y: C.cellSize * 0.95, duration: 0.38)
            move.timingMode = .easeOut
            let fadeIn = SKAction.fadeIn(withDuration: 0.06)
            let fadeOut = SKAction.fadeOut(withDuration: 0.20)

            label.run(
                SKAction.sequence([
                    fadeIn,
                    SKAction.group([move, SKAction.sequence([SKAction.wait(forDuration: 0.16), fadeOut])]),
                    SKAction.removeFromParent(),
                ])
            )
        }
    }
}
