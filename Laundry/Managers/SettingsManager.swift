//
//  SettingsManager.swift
//  Laundry
//
//  Persisted player-facing settings: SFX/music volume, language, and whether the
//  Drying station uses the microphone (blow) or the leaf-swipe fallback.
//

import Foundation

enum AppLanguage: String {
    case en
    case id
}

final class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sfxVolume = "settings.sfxVolume"
        static let musicVolume = "settings.musicVolume"
        static let language = "settings.language"
        static let microphoneEnabled = "settings.microphoneEnabled"
    }

    var sfxVolume: Float {
        didSet { defaults.set(sfxVolume, forKey: Keys.sfxVolume) }
    }

    var musicVolume: Float {
        didSet { defaults.set(musicVolume, forKey: Keys.musicVolume) }
    }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    var microphoneEnabled: Bool {
        didSet { defaults.set(microphoneEnabled, forKey: Keys.microphoneEnabled) }
    }

    private init() {
        sfxVolume = defaults.object(forKey: Keys.sfxVolume) as? Float ?? 1.0
        musicVolume = defaults.object(forKey: Keys.musicVolume) as? Float ?? 1.0
        microphoneEnabled = defaults.object(forKey: Keys.microphoneEnabled) as? Bool ?? true
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .en
    }
}
