//
//  Localization.swift
//  Laundry
//
//  Minimal EN/ID string table. Most of the game's copy is still hardcoded English —
//  this covers the Settings popup and the shared HUD, and is meant to grow key by key.
//

import Foundation

enum LocKey: String {
    case settingsTitle
    case sfx
    case music
    case language
    case microphone
    case on
    case off
    case day
    case ok
    case start

    // Onboarding, shown once before the player's very first day
    case onboardingStep1
    case onboardingStep2
    case onboardingStep3

    // Info-button tip text, per scene
    case infoCustomer
    case infoFolding
    case infoWashing
    case infoDryingMic
    case infoDryingMicFootnote
    case infoDryingLeaf
    case infoDryingLeafFootnote
    case infoHandoff

    // Transient hint banners, per scene
    case washingNoSoap
    case WashingWrongSoap
    case foldingHintNotWashed
    case foldingHintNotDried
    case foldingHintDragClothes
    case foldingHintTieRope
    case foldingHintDragClothesToCenter
    case foldingHintSwipeToFold
    case foldingHintDragRopeToCenter
    case foldingHintPackaged
    case dryingHintSwipeLeaf
    case dryingHintMicPermission
    case dryingHintMicStartFailed
    case washingHintClean
    case washingHintNiceClean
}

enum Loc {
    private static let table: [LocKey: [AppLanguage: String]] = [
        .settingsTitle: [.en: "SETTINGS", .id: "PENGATURAN"],
        .sfx: [.en: "SFX", .id: "SFX"],
        .music: [.en: "MUSIC", .id: "MUSIK"],
        .language: [.en: "LANGUAGE", .id: "BAHASA"],
        .microphone: [.en: "MICROPHONE", .id: "MIKROFON"],
        .on: [.en: "ON", .id: "AKTIF"],
        .off: [.en: "OFF", .id: "MATI"],
        .day: [.en: "DAY", .id: "HARI"],
        .ok: [.en: "OK", .id: "OK"],
        .start: [.en: "START", .id: "MULAI"],

        .onboardingStep1: [
            .en: "Rawr rawrrr rawrr (hi i'm raptor)",
            .id: "Rawr rawrrr rawrr (hai aku raptor)"
        ],
        .onboardingStep2: [
            .en: "Rawrr rawrr rawr rawrr (help me manage my laundry business)",
            .id: "Rawrr rawrr rawr rawrr (bantu aku mengelola bisnis cucian)"
        ],
        .onboardingStep3: [
            .en: "Rawrrrrrrrr (the customer will came, take their dirty clothes, wash it, dry it, and fold it)",
            .id: "Rawrrrrrrrr (pelanggan akan datang, ambil baju kotor mereka, cuci, keringkan, dan lipat dengan rapi)"
        ],

        .infoCustomer: [
            .en: "Press the sack to proceed to washing process",
            .id: "Tekan karungnya untuk lanjut ke proses mencuci"
        ],
        .infoFolding: [
            .en: "Drag your finger based on the arrow direction",
            .id: "Geser jarimu sesuai arah panah"
        ],
        .infoWashing: [
            .en: "Drag the clothes from the dirty piles and scrub it, then put in the clean piles",
            .id: "Seret baju dari tumpukan kotor lalu gosok, kemudian taruh di tumpukan bersih"
        ],
        .infoDryingMic: [
            .en: "Make the blow sound on your microphone, don't blow too hard",
            .id: "Tiup ke mikrofonmu, jangan terlalu keras"
        ],
        .infoDryingMicFootnote: [
            .en: "*you can turn off microphone feature on setting button",
            .id: "*kamu bisa mematikan fitur mikrofon di tombol pengaturan"
        ],
        .infoDryingLeaf: [
            .en: "Swipe the leaf across the clothes to dry them",
            .id: "Geser daunnya di atas baju untuk mengeringkannya"
        ],
        .infoDryingLeafFootnote: [
            .en: "*you can turn on microphone feature on setting button",
            .id: "*kamu bisa menyalakan fitur mikrofon di tombol pengaturan"
        ],
        .infoHandoff: [
            .en: "Drag the finished package to the customer",
            .id: "Seret paket yang sudah jadi ke pelanggan"
        ],
        .washingNoSoap: [
            .en: "Add some soap first!",
            .id: "Tambahkan sabun dulu!"
        ],
        .WashingWrongSoap: [
            .en: "Not the right fragance!",
            .id: "Bukan itu pewanginya!"
        ],
        .foldingHintNotWashed: [
            .en: "Wash the clothes first!",
            .id: "Cuci dulu bajunya!"
        ],
        .foldingHintNotDried: [
            .en: "Dry the clothes first!",
            .id: "Keringkan dulu bajunya!"
        ],
        .foldingHintDragClothes: [
            .en: "Drag the clothes into the package!",
            .id: "Seret bajunya ke dalam paket!"
        ],
        .foldingHintTieRope: [
            .en: "Now tie the package!",
            .id: "Sekarang ikat paketnya!"
        ],
        .foldingHintDragClothesToCenter: [
            .en: "Drag the clothes to the center",
            .id: "Seret bajunya ke tengah"
        ],
        .foldingHintSwipeToFold: [
            .en: "Swipe to fold the package!",
            .id: "Geser untuk melipat paketnya!"
        ],
        .foldingHintDragRopeToCenter: [
            .en: "Drag to the center",
            .id: "Seret ke tengah"
        ],
        .foldingHintPackaged: [
            .en: "Packaged!",
            .id: "Sudah dikemas!"
        ],
        .dryingHintSwipeLeaf: [
            .en: "Swipe the leaf across the clothes to dry them.",
            .id: "Geser daunnya di atas baju untuk mengeringkannya."
        ],
        .dryingHintMicPermission: [
            .en: "Microphone access is required to dry clothes — enable it in Settings.",
            .id: "Akses mikrofon diperlukan untuk mengeringkan baju — aktifkan di Pengaturan."
        ],
        .dryingHintMicStartFailed: [
            .en: "Couldn't start the microphone.",
            .id: "Mikrofon tidak bisa diaktifkan."
        ],
        .washingHintClean: [
            .en: "Clean! Drag it to the basket!",
            .id: "Bersih! Seret ke keranjang!"
        ],
        .washingHintNiceClean: [
            .en: "Nice and clean!",
            .id: "Bersih sekali!"
        ]
    ]

    static func t(_ key: LocKey) -> String {
        table[key]?[SettingsManager.shared.language] ?? key.rawValue.uppercased()
    }
}
