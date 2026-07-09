import Foundation

/// UserDefaults keys for the one-time-ever spotlight tutorials. Centralized so the debug reset
/// in GameViewController can't drift out of sync with the string literals each scene checks.
enum TutorialFlag: String, CaseIterable {
    case frontDeskSpotlight = "hasSeenFrontDeskSpotlightTutorial"
    case washingSpotlight = "hasSeenWashingSpotlightTutorial"
    case dryingSpotlight = "hasSeenDryingSpotlightTutorial"
    case foldingSpotlight = "hasSeenFoldingSpotlightTutorial"
}
