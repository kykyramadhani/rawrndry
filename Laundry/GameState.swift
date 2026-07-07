//
//  GameState.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//

import Foundation
import CoreGraphics

enum OrderType: CaseIterable {
    case washOnly
    case washAndDry
    case washDryIron

    var displayName: String {
        switch self {
        case .washOnly: return "Wash"
        case .washAndDry: return "Wash + Dry"
        case .washDryIron: return "Wash + Dry + Iron"
        }
    }
}

enum ClothingType: CaseIterable {
    case clothes

    var displayName: String {
        switch self {
        case .clothes: return "Clothes"
        }
    }

    /// Name of the sprite asset for this clothing type.
    var imageName: String {
        switch self {
        case .clothes: return "washingClothes1"
        }
    }
}

/// Where a single clothing item is in the wash → dry → fold pipeline, and how far
/// along it is at its current stage. Persisted in GameState so switching stations
/// via the arrows never loses progress.
struct LaundryItemProgress {
    var washProgress: CGFloat = 0
    var dryProgress: CGFloat = 0
    /// True while the item sits on the washing stone — either mid-scrub or clean and
    /// awaiting the drag into the clean basket. False means it's in the dirty pile
    /// (washProgress == 0) or already delivered to the clean basket (washProgress >= 1).
    var isOnWashStone: Bool = false
    var isHungToDry: Bool = false

    var isWashed: Bool { washProgress >= 1 }
    var isDried: Bool { dryProgress >= 1 }
}

final class GameState {

    static let shared = GameState()

    var currentDay: Int = 1
    var score: Int = 0
    var coinsEarned: Int = 0
    var orderType: OrderType = .washOnly
    var clothesCount: Int = 1
    var clothesTypes: [ClothingType] = []

    /// Per-item pipeline progress, index-aligned with clothesTypes.
    var itemProgress: [LaundryItemProgress] = []

    /// Number of items torn while washing this order — deducted from the handoff payout.
    var tornItemsCount: Int = 0

    /// Whether the Folding station's leaf-wrap package has been tied off for this order.
    var isPackaged: Bool = false

    /// The day the current order was generated for — lets CustomerScene tell "revisiting
    /// an in-progress order" apart from "starting a new one" without a separate flag.
    var orderGeneratedDay: Int = 0

    private init() {}

    var isFullyWashed: Bool { itemProgress.allSatisfy { $0.isWashed } }
    var isFullyDried: Bool { itemProgress.allSatisfy { $0.isDried } }

    /// Whether every stage this order's type requires has been completed.
    var isReadyForHandoff: Bool {
        guard isFullyWashed else { return false }
        switch orderType {
        case .washOnly: return true
        case .washAndDry: return isFullyDried
        case .washDryIron: return isFullyDried && isPackaged
        }
    }

    /// Generates a fresh order for the current day if one hasn't been generated yet. Called from
    /// CustomerScene normally, but also as a safety net from WashingScene, since some entry
    /// points (the front-desk flow) jump straight into washing without visiting the order scene.
    func generateOrderIfNeeded() {
        guard orderGeneratedDay != currentDay else { return }

        let maxItems: Int
        switch currentDay {
        case 1: maxItems = 1
        case 2: maxItems = 2
        default: maxItems = 3
        }
        let count = currentDay == 1 ? 1 : Int.random(in: 1...maxItems)

        orderType = OrderType.allCases.randomElement() ?? .washOnly
        clothesCount = count
        clothesTypes = (0..<count).map { _ in ClothingType.allCases.randomElement() ?? .clothes }
        itemProgress = Array(repeating: LaundryItemProgress(), count: count)
        tornItemsCount = 0
        isPackaged = false
        orderGeneratedDay = currentDay
    }

    func resetForNewDay() {
        currentDay += 1
        coinsEarned = 0
    }

    func resetAll() {
        currentDay = 1
        score = 0
        coinsEarned = 0
        clothesCount = 1
        clothesTypes = []
        orderType = .washOnly
        tornItemsCount = 0
        itemProgress = []
        isPackaged = false
        orderGeneratedDay = 0
    }
}
