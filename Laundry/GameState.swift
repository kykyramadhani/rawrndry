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
    case shirt
    case pants
    case dress

    var displayName: String {
        switch self {
        case .shirt: return "Shirt"
        case .pants: return "Pants"
        case .dress: return "Dress"
        }
    }

    /// Name of the sprite asset for this clothing type.
    var imageName: String {
        switch self {
        case .shirt: return "shirt"
        case .pants: return "pants"
        case .dress: return "dress"
        }
    }
}

/// One of the four swipe gestures needed to wrap an item in the Folding station.
enum WrapDirection: CaseIterable {
    case swipeDown, swipeRight, swipeUp, swipeLeft
}

/// Where a single clothing item is in the wash → dry → fold pipeline, and how far
/// along it is at its current stage. Persisted in GameState so switching stations
/// via the arrows never loses progress.
struct LaundryItemProgress {
    var washProgress: CGFloat = 0
    var dryProgress: CGFloat = 0
    var isHungToDry: Bool = false
    var wrapDirections: Set<WrapDirection> = []

    var isWashed: Bool { washProgress >= 1 }
    var isDried: Bool { dryProgress >= 1 }
    var isFolded: Bool { wrapDirections.count == WrapDirection.allCases.count }
}

final class GameState {

    static let shared = GameState()

    var currentDay: Int = 1
    var score: Int = 0
    var coinsEarned: Int = 0
    var orderType: OrderType = .washOnly
    var clothesCount: Int = 1
    var clothesTypes: [ClothingType] = []

    /// Which stain sprite each item started with — assigned once per order so it stays
    /// consistent everywhere the item is drawn (customer pile, washboard, etc.).
    var itemStains: [String] = []

    /// Per-item pipeline progress, index-aligned with clothesTypes.
    var itemProgress: [LaundryItemProgress] = []

    /// Number of items torn while washing this order — deducted from the handoff payout.
    var tornItemsCount: Int = 0

    /// The day the current order was generated for — lets CustomerOrderScene tell "revisiting
    /// an in-progress order" apart from "starting a new one" without a separate flag.
    var orderGeneratedDay: Int = 0

    private init() {}

    var isFullyWashed: Bool { itemProgress.allSatisfy { $0.isWashed } }
    var isFullyDried: Bool { itemProgress.allSatisfy { $0.isDried } }
    var isFullyFolded: Bool { itemProgress.allSatisfy { $0.isFolded } }

    /// Whether every stage this order's type requires has been completed.
    var isReadyForHandoff: Bool {
        guard isFullyWashed else { return false }
        switch orderType {
        case .washOnly: return true
        case .washAndDry: return isFullyDried
        case .washDryIron: return isFullyDried && isFullyFolded
        }
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
        itemStains = []
        itemProgress = []
        orderGeneratedDay = 0
    }
}
