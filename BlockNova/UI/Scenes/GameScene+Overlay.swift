import SpriteKit
import UIKit

extension GameScene {

    // MARK: - Public

    func showGameOverOverlay(score: Int, highScore: Int, isNewRecord: Bool) {
        overlayNode?.removeFromParent()
        overlayNode = nil

        let screenW = C.screenW
        let screenH = C.screenH
        let minSide = min(screenW, screenH)

        // Overlay background
        let overlay = SKSpriteNode(
            color: UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 0.92).sk,
            size: CGSize(width: screenW, height: screenH)
        )
        overlay.position = CGPoint(x: screenW / 2, y: screenH / 2)
        overlay.zPosition = 200
        overlay.name = "gameOverOverlay"
        overlay.alpha = 0
        addChild(overlay)
        overlayNode = overlay

        overlay.run(SKAction.fadeIn(withDuration: 0.25))

        // MARK: Card sizing
        let cardW = screenW * 0.86
        let cardH = screenH * 0.72
        let cornerRadius = cardH * 0.08

        let cardContainer = SKNode()
        cardContainer.position = .zero
        cardContainer.zPosition = 201
        overlay.addChild(cardContainer)

        // Real rounded card background
        let cardRect = CGRect(
            x: -cardW / 2,
            y: -cardH / 2,
            width: cardW,
            height: cardH
        )

        let cardPath = UIBezierPath(
            roundedRect: cardRect,
            cornerRadius: cornerRadius
        ).cgPath

        let cardBackground = SKShapeNode(path: cardPath)
        cardBackground.fillColor = UIColor(red: 0.06, green: 0.07, blue: 0.18, alpha: 1).sk
        cardBackground.strokeColor = .clear
        cardBackground.alpha = 0
        cardContainer.addChild(cardBackground)

        let cardBorder = SKShapeNode(path: cardPath)
        cardBorder.fillColor = .clear
        cardBorder.strokeColor = UIColor(red: 0.00, green: 0.80, blue: 1.00, alpha: 0.28).sk
        cardBorder.lineWidth = max(1.0, screenW * 0.0025)
        cardBorder.alpha = 0
        cardContainer.addChild(cardBorder)

        cardContainer.setScale(0.90)
        cardContainer.alpha = 0
        cardContainer.run(
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.28),
                SKAction.scale(to: 1.0, duration: 0.28)
            ])
        )
        cardBorder.run(SKAction.fadeIn(withDuration: 0.28))

        // MARK: Layout values
        let topY = cardH * 0.34
        let titleLineY = cardH * 0.28
        let scoreCardY = cardH * 0.09
        let scoreCardW = cardW * 0.62
        let scoreCardH = cardH * 0.22
        let scoreSectionBottomY = -cardH * 0.08
        let separatorY = -cardH * 0.15
        let primaryButtonY = -cardH * 0.26
        let secondaryButtonY = -cardH * 0.37

        // MARK: Title
        let titleLabel = SKLabelNode(text: "OYUN BİTTİ")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = screenH * 0.026
        titleLabel.fontColor = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 1.0)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: topY)
        titleLabel.alpha = 0
        cardContainer.addChild(titleLabel)

        let titleLine = SKSpriteNode(
            color: UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.22).sk,
            size: CGSize(width: cardW * 0.70, height: max(1, screenH * 0.0016))
        )
        titleLine.position = CGPoint(x: 0, y: titleLineY)
        titleLine.alpha = 0
        cardContainer.addChild(titleLine)

        // MARK: Score card
        let scoreRect = CGRect(
            x: -scoreCardW / 2,
            y: -scoreCardH / 2,
            width: scoreCardW,
            height: scoreCardH
        )
        let scoreCardPath = UIBezierPath(
            roundedRect: scoreRect,
            cornerRadius: scoreCardH * 0.30
        ).cgPath

        let scoreGlow = SKShapeNode(path: scoreCardPath)
        scoreGlow.fillColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.06).sk
        scoreGlow.strokeColor = .clear
        scoreGlow.position = CGPoint(x: 0, y: scoreCardY)
        scoreGlow.alpha = 0
        cardContainer.addChild(scoreGlow)

        let scoreCard = SKShapeNode(path: scoreCardPath)
        scoreCard.fillColor = UIColor(red: 0.04, green: 0.05, blue: 0.14, alpha: 1.0).sk
        scoreCard.strokeColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.30).sk
        scoreCard.lineWidth = max(1.0, screenW * 0.0025)
        scoreCard.position = CGPoint(x: 0, y: scoreCardY)
        scoreCard.alpha = 0
        cardContainer.addChild(scoreCard)

        let scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Heavy"
        scoreLabel.fontSize = min(scoreCardH * 0.58, minSide * 0.12)
        scoreLabel.fontColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.0)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: scoreCardY + scoreCardH * 0.06)
        scoreLabel.alpha = 0
        cardContainer.addChild(scoreLabel)

        let pointLabel = SKLabelNode(text: "PUAN")
        pointLabel.fontName = "AvenirNext-Medium"
        pointLabel.fontSize = screenH * 0.014
        pointLabel.fontColor = UIColor(white: 1.0, alpha: 0.42)
        pointLabel.horizontalAlignmentMode = .center
        pointLabel.verticalAlignmentMode = .center
        pointLabel.position = CGPoint(x: 0, y: scoreCardY - scoreCardH * 0.24)
        pointLabel.alpha = 0
        cardContainer.addChild(pointLabel)

        // MARK: Record / High Score
        if isNewRecord {
            let badgeW = cardW * 0.46
            let badgeH = cardH * 0.07
            let badgeRect = CGRect(x: -badgeW / 2, y: -badgeH / 2, width: badgeW, height: badgeH)
            let badgePath = UIBezierPath(
                roundedRect: badgeRect,
                cornerRadius: badgeH / 2
            ).cgPath

            let recordBadge = SKShapeNode(path: badgePath)
            recordBadge.fillColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.14).sk
            recordBadge.strokeColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 0.34).sk
            recordBadge.lineWidth = max(1.0, screenW * 0.002)
            recordBadge.position = CGPoint(x: 0, y: scoreSectionBottomY)
            recordBadge.alpha = 0
            cardContainer.addChild(recordBadge)

            let recordLabel = SKLabelNode(text: "YENİ REKOR!")
            recordLabel.fontName = "AvenirNext-Heavy"
            recordLabel.fontSize = screenH * 0.019
            recordLabel.fontColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.0)
            recordLabel.horizontalAlignmentMode = .center
            recordLabel.verticalAlignmentMode = .center
            recordLabel.position = CGPoint(x: 0, y: scoreSectionBottomY)
            recordLabel.alpha = 0
            cardContainer.addChild(recordLabel)

            recordBadge.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.60),
                SKAction.fadeIn(withDuration: 0.20)
            ]))

            recordLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.65),
                SKAction.fadeIn(withDuration: 0.20),
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.scale(to: 1.04, duration: 0.45),
                        SKAction.scale(to: 1.0, duration: 0.45)
                    ])
                )
            ]))
        } else {
            let highLabel = SKLabelNode(text: "EN YÜKSEK: \(highScore)")
            highLabel.fontName = "AvenirNext-Medium"
            highLabel.fontSize = screenH * 0.018
            highLabel.fontColor = UIColor(white: 1.0, alpha: 0.48)
            highLabel.horizontalAlignmentMode = .center
            highLabel.verticalAlignmentMode = .center
            highLabel.position = CGPoint(x: 0, y: scoreSectionBottomY)
            highLabel.alpha = 0
            cardContainer.addChild(highLabel)

            highLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.65),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
        }

        // MARK: Separator
        let separator = SKSpriteNode(
            color: UIColor(white: 1.0, alpha: 0.08).sk,
            size: CGSize(width: cardW * 0.80, height: max(1, screenH * 0.0016))
        )
        separator.position = CGPoint(x: 0, y: separatorY)
        separator.alpha = 0
        cardContainer.addChild(separator)

        // MARK: Buttons
        let primaryButtonWidth = cardW * 0.80
        let primaryButtonHeight = cardH * 0.105

        let primaryRect = CGRect(
            x: -primaryButtonWidth / 2,
            y: -primaryButtonHeight / 2,
            width: primaryButtonWidth,
            height: primaryButtonHeight
        )
        let primaryPath = UIBezierPath(
            roundedRect: primaryRect,
            cornerRadius: primaryButtonHeight / 2
        ).cgPath

        let playButton = SKShapeNode(path: primaryPath)
        playButton.fillColor = UIColor(red: 0.08, green: 0.78, blue: 0.33, alpha: 1.0).sk
        playButton.strokeColor = .clear
        playButton.position = CGPoint(x: 0, y: primaryButtonY)
        playButton.name = "tekrarOyna"
        playButton.alpha = 0
        cardContainer.addChild(playButton)

        let playLabel = SKLabelNode(text: "TEKRAR OYNA")
        playLabel.fontName = "AvenirNext-Heavy"
        playLabel.fontSize = screenH * 0.020
        playLabel.fontColor = .white
        playLabel.horizontalAlignmentMode = .center
        playLabel.verticalAlignmentMode = .center
        playLabel.name = "tekrarOyna"
        playButton.addChild(playLabel)

        let secondaryButtonWidth = cardW * 0.80
        let secondaryButtonHeight = cardH * 0.090

        let secondaryRect = CGRect(
            x: -secondaryButtonWidth / 2,
            y: -secondaryButtonHeight / 2,
            width: secondaryButtonWidth,
            height: secondaryButtonHeight
        )
        let secondaryPath = UIBezierPath(
            roundedRect: secondaryRect,
            cornerRadius: secondaryButtonHeight / 2
        ).cgPath

        let menuButton = SKShapeNode(path: secondaryPath)
        menuButton.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.03).sk
        menuButton.strokeColor = UIColor(white: 1.0, alpha: 0.18).sk
        menuButton.lineWidth = max(1.0, screenW * 0.002)
        menuButton.position = CGPoint(x: 0, y: secondaryButtonY)
        menuButton.name = "anaMenu"
        menuButton.alpha = 0
        cardContainer.addChild(menuButton)

        let menuLabel = SKLabelNode(text: "Ana Menü")
        menuLabel.fontName = "AvenirNext-Medium"
        menuLabel.fontSize = screenH * 0.018
        menuLabel.fontColor = UIColor(white: 1.0, alpha: 0.60)
        menuLabel.horizontalAlignmentMode = .center
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "anaMenu"
        menuButton.addChild(menuLabel)

        // MARK: Entrance animations
        let animatedElements: [(SKNode, TimeInterval)] = [
            (titleLabel, 0.18),
            (titleLine, 0.24),
            (scoreGlow, 0.30),
            (scoreCard, 0.30),
            (scoreLabel, 0.36),
            (pointLabel, 0.40),
            (separator, 0.54),
            (playButton, 0.60),
            (menuButton, 0.68)
        ]

        for (node, delay) in animatedElements {
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
        }

        // Score count animation
        if score > 0 {
            let totalDuration: TimeInterval = 0.75
            let steps = max(1, min(score, 45))
            let stepDuration = totalDuration / Double(steps)
            let increment = max(1, score / steps)
            var displayScore = 0

            let countAction = SKAction.repeat(
                SKAction.sequence([
                    SKAction.wait(forDuration: stepDuration),
                    SKAction.run {
                        displayScore = min(displayScore + increment, score)
                        scoreLabel.text = "\(displayScore)"
                    }
                ]),
                count: steps
            )

            scoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.42),
                countAction,
                SKAction.run { scoreLabel.text = "\(score)" }
            ]))
        } else {
            scoreLabel.text = "0"
        }

        // Soft pulse on score card
        let pulseAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.03, duration: 0.7),
                SKAction.fadeAlpha(to: 0.75, duration: 0.7)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.7),
                SKAction.fadeAlpha(to: 1.0, duration: 0.7)
            ])
        ])

        scoreGlow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.45),
            SKAction.repeatForever(pulseAction)
        ]))
    }

    func showGameOverOverlay() {
        let score = manager.score
        let highScore = manager.highScore
        let isNewRecord = score >= highScore
        showGameOverOverlay(score: score, highScore: highScore, isNewRecord: isNewRecord)
    }

    func hideGameOverOverlay() {
        overlayNode?.removeAllActions()
        overlayNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.22),
            SKAction.removeFromParent()
        ]))
        overlayNode = nil
    }

    func handleOverlayTap(_ node: SKNode) {
        switch node.name {
        case "tekrarOyna":
            butonBasAnimasyonu(node) { [weak self] in
                HapticManager.impact(.medium)
                self?.hideGameOverOverlay()
                self?.restartGame()
            }

        case "anaMenu":
            butonBasAnimasyonu(node) { [weak self] in
                HapticManager.impact(.light)
                self?.hideGameOverOverlay()
                self?.goToHome()
            }

        default:
            break
        }
    }

    // MARK: - Private

    private func butonBasAnimasyonu(_ node: SKNode, tamamlanma: @escaping () -> Void) {
        let target: SKNode = {
            if let name = node.name, let parent = node.parent, parent.name == name {
                return parent
            }
            return node
        }()

        target.removeAllActions()
        target.run(SKAction.sequence([
            SKAction.scale(to: 0.96, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08),
            SKAction.run(tamamlanma)
        ]))
    }
}
