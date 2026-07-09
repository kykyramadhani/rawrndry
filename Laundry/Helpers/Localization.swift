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
    case yes
    case cancel
    case homeConfirmMessage

    // Onboarding, shown once before the player's very first day
    case onboardingStep1
    case onboardingStep2
    case onboardingStep3

    // Spotlight tutorial captions, shown once automatically (Day 1, first customer only)
    case tutorialFrontDeskDirtyClothes
    case tutorialWashingBasket
    case tutorialWashingSoap
    case tutorialWashingScrub
    case tutorialWashingCleanBasket
    case tutorialWashingNextArrow
    case tutorialDryingBasket
    case tutorialDryingBlow
    case tutorialDryingLeafSwipe
    case tutorialDryingToBasket
    case tutorialFoldingBasket
    case tutorialFoldingDirection
    case tutorialFoldingRope

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

    // Customer order speech bubble, per requested soap fragrance
    case soapDisplayNameRose
    case soapDisplayNameSoapFruit
    case customerOrderQuickWait
    case customerOrderCleanGood
    case customerOrderSmellRose
    case customerOrderSmellSoapFruit
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
        .yes: [.en: "YES", .id: "YA"],
        .cancel: [.en: "CANCEL", .id: "BATAL"],
        .homeConfirmMessage: [
            .en: "Are you sure you want to go back?",
            .id: "Apakah kamu yakin ingin kembali?"
        ],

        .onboardingStep1: [
            .en: "rawr rawrrr rawrr (hi i'm raptor)",
            .id: "rawr rawrrr rawrr (hai aku raptor)"
        ],
        .onboardingStep2: [
            .en: "rawrr rawrr rawr rawrr (help me manage my laundry business)",
            .id: "rawrr rawrr rawr rawrr (bantu aku mengelola bisnis cucian)"
        ],
        .onboardingStep3: [
            .en: "Rawrrrrrrrr (the customer will came, take their dirty clothes, wash it, dry it, and fold it)",
            .id: "Rawrrrrrrrr (pelanggan akan datang, ambil baju kotor mereka, cuci, keringkan, dan lipat dengan rapi)"
        ],

        .tutorialFrontDeskDirtyClothes: [
            .en: "Customer came! Click the dirty clothes to proceed to washing",
            .id: "Pelanggan datang! Tekan baju kotornya untuk lanjut mencuci"
        ],
        .tutorialWashingBasket: [
            .en: "Drag the clothes from the basket onto the stone to wash them",
            .id: "Geser baju dari keranjang ke batu untuk mencuci"
        ],
        .tutorialWashingSoap: [
            .en: "Pick and drag the right soap variant",
            .id: "Pilih dan geser varian sabun yang tepat"
        ],
        .tutorialWashingScrub: [
            .en: "Rub the clothes to wash them clean",
            .id: "Usap baju untuk mencuci sampai bersih"
        ],
        .tutorialWashingCleanBasket: [
            .en: "Put the clean clothes into the clean basket!",
            .id: "Masukkan baju yang sudah bersih ke keranjang bersih!"
        ],
        .tutorialWashingNextArrow: [
            .en: "Tap the arrow to move to the next scene!",
            .id: "Klik panah untuk berganti scene!"
        ],
        .tutorialDryingBasket: [
            .en: "Drag the clothes from the basket onto the line to dry them!",
            .id: "Geser baju dari keranjang ke penjemuran untuk mengeringkan!"
        ],
        .tutorialDryingBlow: [
            .en: "Blow into the microphone to dry the clothes! Don't blow too hard",
            .id: "Tiup dari microphone untuk mengeringkan baju! Jangan tiup terlalu keras"
        ],
        .tutorialDryingLeafSwipe: [
            .en: "Use the leaf to swipe and dry the clothes!",
            .id: "Gunakan daun untuk geser dan mengeringkan!"
        ],
        .tutorialDryingToBasket: [
            .en: "Drag the clothes from the line into the basket for the next step!",
            .id: "Geser baju dari penjemuran ke keranjang untuk step berikutnya!"
        ],
        .tutorialFoldingBasket: [
            .en: "Drag the clothes from the basket onto the banana leaf to wrap them!",
            .id: "Geser baju dari keranjang ke daun pisang untuk membungkus!"
        ],
        .tutorialFoldingDirection: [
            .en: "Swipe to fold, following the arrow",
            .id: "Lipat dengan geser sesuai tanda panah"
        ],
        .tutorialFoldingRope: [
            .en: "Use the rope to tie up the package",
            .id: "Gunakan tali untuk membungkus"
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
        ],

        .soapDisplayNameRose: [.en: "ROSE", .id: "MAWAR"],
        .soapDisplayNameSoapFruit: [.en: "SOAPFRUIT", .id: "BUAH LERAK"],
        .customerOrderQuickWait: [.en: "%@. QUICK. ME WAIT.", .id: "%@. CEPAT. SAYA TUNGGU."],
        .customerOrderCleanGood: [.en: "%@. CLEAN GOOD.", .id: "%@. CUCI BERSIH."],
        .customerOrderSmellRose: [.en: "ROSE. SMELL NICE.", .id: "MAWAR. HARUM."],
        .customerOrderSmellSoapFruit: [.en: "SOAPFRUIT. SMELL FRESH.", .id: "BUAH LERAK. SEGAR."]
    ]

    static func t(_ key: LocKey) -> String {
        table[key]?[SettingsManager.shared.language] ?? key.rawValue.uppercased()
    }
}
