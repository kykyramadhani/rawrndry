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

    @discardableResult
    func addStationArrows(current: Station) -> (left: SKSpriteNode, right: SKSpriteNode) {
        let left = makeButton(
            imageNamed: AssetName.UI.chevronLeft,
            position: CGPoint(x: size.width * 0.05, y: size.height * 0.5),
            scale: 0.8,
            nodeName: "stationLeft"
        )
        let right = makeButton(
            imageNamed: AssetName.UI.chevronRight,
            position: CGPoint(x: size.width * 0.95, y: size.height * 0.5),
            scale: 0.8,
            nodeName: "stationRight"
        )
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
