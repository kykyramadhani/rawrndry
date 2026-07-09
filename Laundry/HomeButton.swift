//
//  HomeButton.swift
//  Laundry
//
//  The home button + its "go back to start" confirmation popup, shared by every scene
//  that has the "i" instruction button — sits immediately to its left, same convention
//  as showTipPopup/showSettingsPopup ("overlay node named X, removed on close/cancel").
//

import SpriteKit

extension SKScene {

    // MARK: - Button

    /// Sits directly left of the instruction button, at the same scene-center-relative
    /// offset gap the instruction button already keeps from the settings button.
    @discardableResult
    func addHomeButton() -> SKSpriteNode {
        let center = sceneCenter
        return makeButton(
            imageNamed: AssetName.UI.btnHome,
            position: CGPoint(x: center.x + size.width * 0.27, y: center.y + size.height * 0.40),
            scale: 0.8,
            nodeName: "homeButton"
        )
    }

    /// Call alongside handleTipPopupTap/handleSettingsButtonTap from touchesBegan.
    @discardableResult
    func handleHomeButtonTap(nodeName: String?) -> Bool {
        guard nodeName == "homeButton" else { return false }
        guard let button = childNode(withName: "homeButton") else {
            showHomeConfirmPopup()
            return true
        }
        runButtonTapAnimation(on: button) { self.showHomeConfirmPopup() }
        return true
    }

    // MARK: - Popup

    func showHomeConfirmPopup() {
        childNode(withName: "homeConfirmOverlay")?.removeFromParent()

        let center = sceneCenter
        let panelSize = CGSize(width: min(size.width * 0.72, 340), height: 220)

        let overlay = SKNode()
        overlay.name = "homeConfirmOverlay"
        overlay.zPosition = 600
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = Loc.t(.homeConfirmMessage).uppercased()
        label.fontSize = 20
        label.fontColor = .white
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = panelSize.width * 0.82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: center.x, y: center.y + 30)
        label.zPosition = 1
        overlay.addChild(label)

        let buttonSpacing: CGFloat = 120
        let buttonY = center.y - panelSize.height * 0.28

        let yesButton = makeHomeConfirmButton(
            imageNamed: AssetName.UI.buttonMain, text: Loc.t(.yes), textColor: .white,
            nodeName: "homeConfirmYes", position: CGPoint(x: center.x - buttonSpacing / 2, y: buttonY)
        )
        overlay.addChild(yesButton)

        let cancelButton = makeHomeConfirmButton(
            imageNamed: AssetName.UI.btnSecondary, text: Loc.t(.cancel), textColor: .black,
            nodeName: "homeConfirmCancel", position: CGPoint(x: center.x + buttonSpacing / 2, y: buttonY)
        )
        overlay.addChild(cancelButton)
    }

    private func makeHomeConfirmButton(imageNamed name: String, text: String, textColor: SKColor, nodeName: String, position: CGPoint) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: name)
        button.name = nodeName
        button.size = CGSize(width: 96, height: 44)
        button.position = position
        button.zPosition = 1

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text
        label.fontSize = 18
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        return button
    }

    // MARK: - Touch handling

    /// Call alongside handleTipPopupTap/handleSettingsPopupTouchesBegan from touchesBegan.
    /// "Cancel" just dismisses back into the scene; "Yes" restarts the current day and
    /// returns to StartScene.
    @discardableResult
    func handleHomeConfirmPopupTap(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "homeConfirmOverlay") else { return false }
        let name = tappedNodeName(at: location)

        if name == "homeConfirmCancel" {
            overlay.removeFromParent()
            return true
        }

        if name == "homeConfirmYes" {
            GameState.shared.restartCurrentDay()
            goTo(StartScene(size: size))
            return true
        }

        // Tap anywhere else inside the popup just swallows the touch, same as showTipPopup.
        return true
    }
}
