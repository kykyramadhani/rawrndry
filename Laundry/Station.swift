//
//  Station.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  The left/right arrows on every gameplay scene cycle through these same four
//  stations in a fixed loop, regardless of what the current order needs.

import SpriteKit

enum Station: Int, CaseIterable {
    case customer, washing, drying, folding

    func makeScene(size: CGSize) -> SKScene {
        switch self {
        case .customer: return CustomerScene.makeCurrent(size: size)
        case .washing: return WashingScene(size: size)
        case .drying: return DryingScene(size: size)
        case .folding: return FoldingScene(size: size)
        }
    }

    var next: Station {
        Station(rawValue: (rawValue + 1) % Station.allCases.count)!
    }

    var previous: Station {
        Station(rawValue: (rawValue - 1 + Station.allCases.count) % Station.allCases.count)!
    }
}

extension SKScene {

    /// Positions relative to `sceneCenter` so this lines up correctly whether the scene
    /// anchors at the bottom-left (the default) or the center (CustomerScene, HandoffScene).
    /// Pass `showLeft`/`showRight` false to omit an arrow on scenes that shouldn't offer
    /// that direction (e.g. CustomerScene has no left arrow, HandoffScene has neither).
    @discardableResult
    func addStationArrows(current: Station, showLeft: Bool = true, showRight: Bool = true) -> (left: SKSpriteNode?, right: SKSpriteNode?) {
        let center = sceneCenter
        let edgeOffset = size.width * 0.40

        let left: SKSpriteNode? = showLeft ? makeButton(
            imageNamed: AssetName.UI.chevronLeft,
            position: CGPoint(x: center.x - edgeOffset, y: center.y),
            scale: 0.8,
            nodeName: "stationLeft"
        ) : nil

        let right: SKSpriteNode? = showRight ? makeButton(
            imageNamed: AssetName.UI.chevronRight,
            position: CGPoint(x: center.x + edgeOffset, y: center.y),
            scale: 0.8,
            nodeName: "stationRight"
        ) : nil

        return (left, right)
    }

    /// Handles a station-arrow tap if `nodeName` is one, returning whether it did.
    func handleStationArrowTap(nodeName: String?, current: Station) -> Bool {
        switch nodeName {
        case "stationLeft":
            goTo(current.previous.makeScene(size: size))
            return true
        case "stationRight":
            goTo(current.next.makeScene(size: size))
            return true
        default:
            return false
        }
    }
}
