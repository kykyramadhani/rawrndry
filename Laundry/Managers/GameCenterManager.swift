//
//  GameCenterManager.swift
//  Laundry
//
//  Game Center sign-in plus the game's achievements. Progress is counted locally in
//  UserDefaults first and mirrored to Game Center — so a player who never signs in (or
//  is offline, or is a kid with Game Center switched off) still accumulates progress,
//  and it gets flushed the moment sign-in does succeed.
//

import GameKit

/// Achievement IDs must match the ones created in App Store Connect exactly. Titles and
/// descriptions live there, not here — this is only the identifier + how far you have to get.
enum Achievement: String, CaseIterable {

    /// "First Rinse" — take a dirty item from the basket, scrub it clean at the river, and
    /// drop it in the clean basket.
    case firstWash = "com.Aulia.Rawrndry.firstWash"
    /// "Flawless Order" — finish a customer's whole order without ever reaching for the
    /// wrong fragrance.
    case flawlessOrder = "com.Aulia.Rawrndry.flawlessOrder"
    /// "Three-Star Day" — close out a day with a three-star order at the front desk.
    case threeStarDay = "com.Aulia.Rawrndry.threeStarDay"
    /// "Soap Sommelier" — apply the exact fragrance a customer asked for, 20 times. Orders
    /// with no preference don't count.
    case soapSommelier = "com.Aulia.Rawrndry.soapSommelier"
    /// "Elbow Grease" — scrub through a full run of the laundry, around twenty items by hand.
    case elbowGrease = "com.Aulia.Rawrndry.elbowGrease"
    /// "Rawr Tycoon" — earn 4,000 gems in total from finished orders.
    case rawrTycoon = "com.Aulia.Rawrndry.rawrTycoon"
    /// "Full Cycle" — clear every day the laundry has to offer.
    case fullCycle = "com.Aulia.Rawrndry.fullCycle"

    /// How much progress counts as 100%. One-shot achievements are just a target of 1.
    var target: Double {
        switch self {
        case .firstWash, .flawlessOrder, .threeStarDay, .fullCycle: return 1
        // Calibrated against LevelDesign: one full playthrough is 22 items, ~11 of them for
        // customers who actually named a fragrance, ~19,800 scrub distance, and 4,400 gems.
        case .soapSommelier: return 20
        case .elbowGrease: return 20_000
        case .rawrTycoon: return 4_000
        }
    }
}

final class GameCenterManager {

    static let shared = GameCenterManager()

    private(set) var isAuthenticated = false
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Sign-in

    /// Kicks off Game Center sign-in. Safe to call once at launch and forget: GameKit
    /// handles the "already signed in" case itself, and everything below degrades to
    /// local-only counting if this never succeeds.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }

            if let viewController {
                self.presentAuthentication(viewController)
                return
            }

            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            if let error, !self.isAuthenticated {
                print("Game Center sign-in failed: \(error.localizedDescription)")
            }
            if self.isAuthenticated { self.flushLocalProgress() }
        }
    }

    private func presentAuthentication(_ viewController: UIViewController) {
        guard let root = Self.topViewController() else { return }
        root.present(viewController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    // MARK: - Achievements

    /// Completes a one-shot achievement. No-op once it's already been earned.
    func unlock(_ achievement: Achievement) {
        advance(achievement, by: achievement.target)
    }

    /// Adds to a counting achievement (`by` is in the achievement's own units — items,
    /// gems, scrub distance) and reports the new percentage. No-op once it's at 100%.
    func advance(_ achievement: Achievement, by amount: Double) {
        guard amount > 0 else { return }

        let current = defaults.double(forKey: achievement.rawValue)
        guard current < achievement.target else { return }

        let updated = min(current + amount, achievement.target)
        defaults.set(updated, forKey: achievement.rawValue)
        report(achievement, progress: updated)
    }

    private func report(_ achievement: Achievement, progress: Double) {
        guard isAuthenticated else { return }

        let report = GKAchievement(identifier: achievement.rawValue)
        report.percentComplete = progress / achievement.target * 100
        report.showsCompletionBanner = true

        GKAchievement.report([report]) { error in
            if let error { print("Achievement report failed: \(error.localizedDescription)") }
        }
    }

    /// Pushes everything counted while signed out up to Game Center, once sign-in lands.
    private func flushLocalProgress() {
        let earned = Achievement.allCases.compactMap { achievement -> GKAchievement? in
            let progress = defaults.double(forKey: achievement.rawValue)
            guard progress > 0 else { return nil }

            let report = GKAchievement(identifier: achievement.rawValue)
            report.percentComplete = min(progress / achievement.target, 1) * 100
            // Silent: these were earned in an earlier session, so banners here would be
            // a pile of pop-ups the moment the player signs in.
            report.showsCompletionBanner = false
            return report
        }

        guard !earned.isEmpty else { return }
        GKAchievement.report(earned) { error in
            if let error { print("Achievement flush failed: \(error.localizedDescription)") }
        }
    }
}
