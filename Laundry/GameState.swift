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
    var isHungToDry: Bool = false

    /// True once this item has been dragged from the Folding basket into the package —
    /// lets FoldingScene resume mid-stack if the player leaves via the station arrows.
    var isFolded: Bool = false

    /// Which numbered drying art variant (1...4) this item uses across the hanged/blown/
    /// picked/fallen/basket-pile textures — assigned once per item so it stays consistent.
    var dryingVariant: Int = 1

    var isWashed: Bool { washProgress >= 1 }
    var isDried: Bool { dryProgress >= 1 }
}

final class GameState {

    static let shared = GameState()

    /// What survives closing the app. Everything else in here is either mid-day state that
    /// can't meaningfully resume (the shift clock is wall-clock based, so a day picked up
    /// hours later would already be past closing) or derived from these.
    private enum SaveKey {
        static let currentDay = "save.currentDay"
        static let score = "save.score"
        static let activeBoosts = "save.activeBoosts"
        static let extraShiftDuration = "save.extraShiftDuration"
        static let gemMultiplier = "save.gemMultiplier"
    }

    private static let defaults = UserDefaults.standard

    var currentDay: Int = 1 {
        didSet { Self.defaults.set(currentDay, forKey: SaveKey.currentDay) }
    }

    /// Wall-clock time this day's shift began — drives the front-of-house 8AM–6PM clock.
    /// Set once per day by `CustomerManager.generateCustomers(forDay:)`; nil before the
    /// first day starts.
    var dayStartTime: Date?

    /// How long, in real seconds, a full 8AM–6PM shift takes to play out before any shop
    /// boost. The clock always runs 8AM to 6PM — buying time makes those hours pass more
    /// slowly in real terms, which is what lets more customers through the door.
    static let baseDayShiftRealDuration: TimeInterval = 3 * 60 + 30

    /// Real seconds added to today's shift by the shop's "add more time" boost.
    /// Boosts persist because they were paid for with gems — quitting after buying one and
    /// before playing the day must not quietly swallow the purchase.
    var extraShiftDuration: TimeInterval = 0 {
        didSet { Self.defaults.set(extraShiftDuration, forKey: SaveKey.extraShiftDuration) }
    }

    /// What every payout is multiplied by today — 2 while the shop's gem multiplier is active.
    var gemMultiplier: Int = 1 {
        didSet { Self.defaults.set(gemMultiplier, forKey: SaveKey.gemMultiplier) }
    }

    /// Which shop items are active for today, so the shop can show them as bought and refuse
    /// to sell the same boost twice.
    var activeBoosts: Set<String> = [] {
        didSet { Self.defaults.set(Array(activeBoosts), forKey: SaveKey.activeBoosts) }
    }

    var dayShiftRealDuration: TimeInterval { Self.baseDayShiftRealDuration + extraShiftDuration }

    /// Drops the boosts bought for the day that just ended. Called when the day rolls over,
    /// so a boost never carries into a day it wasn't paid for.
    func clearDailyBoosts() {
        extraShiftDuration = 0
        gemMultiplier = 1
        activeBoosts = []
    }

    private static let shiftOpenMinutes = 8 * 60   // 8:00 AM
    private static let shiftCloseMinutes = 18 * 60 // 6:00 PM

    /// Minutes-from-midnight the in-game clock currently shows, mapped from real elapsed
    /// time since `dayStartTime` and clamped to closing time.
    var currentShiftMinutes: Int {
        guard let dayStartTime else { return Self.shiftOpenMinutes }
        let elapsed = min(max(Date().timeIntervalSince(dayStartTime), 0), dayShiftRealDuration)
        let fraction = elapsed / dayShiftRealDuration
        let totalShiftMinutes = Self.shiftCloseMinutes - Self.shiftOpenMinutes
        return Self.shiftOpenMinutes + Int(fraction * Double(totalShiftMinutes))
    }

    /// True once the in-game clock has reached 6:00 PM — no *new* customer should be handed
    /// out past this point, though whichever order is already in progress still finishes
    /// normally (see `HandoffScene.completeHandoff`).
    var isPastClosingTime: Bool { currentShiftMinutes >= Self.shiftCloseMinutes }

    /// "8:00 AM"–"6:00 PM"-style clock string, snapped down to the current half-hour (8:00,
    /// 8:30, 9:00, ...) rather than showing an exact minute — reads like a clock face ticking
    /// forward instead of a stopwatch.
    var formattedShiftTime: String {
        let totalMinutes = (currentShiftMinutes / 30) * 30
        let hour24 = totalMinutes / 60
        let minute = totalMinutes % 60
        let isPM = hour24 >= 12
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        return String(format: "%d:%02d %@", hour12, minute, isPM ? "PM" : "AM")
    }

    var score: Int = 0 {
        didSet { Self.defaults.set(score, forKey: SaveKey.score) }
    }
    var coinsEarned: Int = 0
    var orderType: OrderType = .washOnly
    var clothesCount: Int = 1
    var clothesTypes: [ClothingType] = []

    /// Per-item pipeline progress, index-aligned with clothesTypes.
    var itemProgress: [LaundryItemProgress] = []

    /// The current order's actual clothes (pattern, stain, requested soap), index-aligned
    /// with `itemProgress`. The persistent source of truth for WashingScene's queue — scenes
    /// are recreated on every navigation, so this is what lets picking up where you left off
    /// work when leaving Washing mid-order (e.g. to peek at Drying) and coming back.
    var currentOrderItems: [LaundryItem] = []

    /// Times the player reached for the wrong fragrance on this order — deducted from the
    /// handoff payout, and what keeps every order from silently scoring three stars.
    var wrongSoapCount: Int = 0
    
    //Times the player blows too hard and the clothes fell
    var clothesFlownCount: Int = 0

    /// Whether the Folding station's leaf-wrap package has been tied off for this order.
    var isPackaged: Bool = false

    /// The day the current order was generated for — lets CustomerScene tell "revisiting
    /// an in-progress order" apart from "starting a new one" without a separate flag.
    var orderGeneratedDay: Int = 0

    /// The character art and payout for whichever customer is currently being served —
    /// carried from CustomerModel through Washing/Drying/Folding (which only ever read
    /// GameState) so HandoffScene hands back to the *same* customer who dropped the order off.
    var currentCustomerImage: String = AssetName.Character.customer1
    var currentOrderReward: Int = 0

    // MARK:  Daily Cumulative Stats (for the end of the day)
        var dailyClothesFinishedCount: Int = 0
        var dailyBaseIncome: Int = 0
        var dailyWrongSoapCount: Int = 0
        var dailyClothesFlownCount: Int = 0
        var dailyPenaltyPoints: Int = 0

        // Calculated net profit earned today (Base income minus total penalties)
        var dailyNetEarned: Int {
            return max(0, dailyBaseIncome - dailyPenaltyPoints)
    }

    /// Extra gems the shop's multiplier adds on top of the day's net. Deliberately kept out
    /// of `dailyNetEarned` so the summary's base-minus-penalties breakdown still adds up, and
    /// so `starCount()` still rates how well the day was *played* rather than what was bought.
    var dailyMultiplierBonus: Int { dailyNetEarned * (gemMultiplier - 1) }

    /// What actually reaches the purse at the end of the day — the net plus any boost.
    var dailyTotalEarned: Int { dailyNetEarned + dailyMultiplierBonus }
    
    //MARK: Calculated costs of losses
    // Daily loss of wrong soap
    var dailyWrongSoapLoss: Int {
        return dailyWrongSoapCount * LevelDesign.penaltyWrongSoap
    }

    // Daily loss of clothes that fell
    var dailyClothesFlownLoss: Int {
        return dailyClothesFlownCount * LevelDesign.penaltyClothesFlown
    }
    /// Reads back the last session. Property observers don't fire during initialisation, so
    /// loading here can't write the same values straight back out again.
    private init() {
        let defaults = Self.defaults
        // A fresh install has no key at all, which reads back as 0 — day 1 is the floor.
        currentDay = max(1, defaults.integer(forKey: SaveKey.currentDay))
        score = defaults.integer(forKey: SaveKey.score)
        extraShiftDuration = defaults.double(forKey: SaveKey.extraShiftDuration)
        gemMultiplier = max(1, defaults.integer(forKey: SaveKey.gemMultiplier))
        activeBoosts = Set(defaults.stringArray(forKey: SaveKey.activeBoosts) ?? [])
    }

    /// Folding and Handoff treat the order as one bundle rather than item-by-item, so the
    /// first item's pattern (already carried through from washing/drying via `dryingVariant`)
    /// stands in for the whole bundle's look at those two stations.
    var currentOrderPatternID: Int { itemProgress.first?.dryingVariant ?? 1 }

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

    /// Whether the clothes have actually reached the basket Folding pulls from — fully washed,
    /// and also fully dried unless this order skips drying entirely. Gates FoldingScene's basket
    /// so clothes can't be folded before they're actually clean (and dry, if the order needs it).
    var isReadyForFolding: Bool {
        guard isFullyWashed else { return false }
        switch orderType {
        case .washOnly: return true
        case .washAndDry, .washDryIron: return isFullyDried
        }
    }

    /// Seeds a fresh order from the customer's *actual* clothes list — this is the single
    /// source of truth for the wash → dry → fold pipeline now. Each item's `dryingVariant`
    /// is copied straight from its `patternID`, so the exact same clothing item (same
    /// pattern) flows through washing, drying, and folding instead of being re-randomized
    /// independently at each stage.
    func startOrder(items: [LaundryItem], orderType: OrderType = .washDryIron, customerImage: String? = nil, reward: Int? = nil) {
        self.orderType = orderType
        clothesCount = items.count
        clothesTypes = Array(repeating: .clothes, count: items.count)
        currentOrderItems = items
        itemProgress = items.map { item in
            var progress = LaundryItemProgress()
            progress.dryingVariant = item.patternID
            return progress
        }
        wrongSoapCount = 0
        isPackaged = false
        orderGeneratedDay = currentDay

        if let customerImage { currentCustomerImage = customerImage }
        if let reward { currentOrderReward = reward }
    }

    /// Clears the just-finished order so the next `CustomerScene` starts a fresh customer
    /// instead of `resumingCustomer()` mistaking the completed order for one still in progress.
    func completeCurrentOrder() {
        wrongSoapCount = 0
        clothesFlownCount = 0
        itemProgress = []
        currentOrderItems = []
        isPackaged = false
        orderGeneratedDay = 0
    }
    
    // MARK:  Transfer Daily Earnings to Global Score
    // Deposits total net earnings of the day into player's global balance (`score`)
    func commitDailyEarnings() {
        score += dailyTotalEarned
    }
    
    // MARK: Reset Daily Cumulative Stats
    // Resets all accumulated stats for the day (Call when starting a new day)
    func resetDailyStats() {
        dailyClothesFinishedCount = 0
        dailyBaseIncome = 0
        dailyWrongSoapCount = 0
        dailyClothesFlownCount = 0
        dailyPenaltyPoints = 0
    }

    /// Wipes the current day's in-progress order and re-queues its customers from the start —
    /// used by the home-button "are you sure you want to go back?" confirm. Leaves `currentDay`
    /// and any already-banked `score` untouched, since only *this* day is starting over.
    func restartCurrentDay() {
        resetDailyStats() // Resets daily accumulated stats on restart
        completeCurrentOrder() // reuse code
        coinsEarned = 0
        CustomerManager.shared.generateCustomers(forDay: currentDay)
    }

    func resetAll() {
        currentDay = 1
        dayStartTime = nil
        clearDailyBoosts()
        score = 0
        coinsEarned = 0
        clothesCount = 1
        clothesTypes = []
        orderType = .washOnly
        resetDailyStats() // Resets daily stats on full game reset
        completeCurrentOrder() // reuse code
        currentCustomerImage = AssetName.Character.customer1
        currentOrderReward = 0

        // A brand-new game replays the raptor's intro, same as a first install would.
        UserDefaults.standard.set(false, forKey: TutorialFlag.onboarding.rawValue)
    }
}
