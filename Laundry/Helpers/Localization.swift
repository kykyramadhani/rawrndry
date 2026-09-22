//
//  Localization.swift
//  Laundry
//
//  EN/ID/ES string table. Most of the game's copy is still hardcoded English —
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
    case reward
    case startOver
    case newGameConfirmMessage
    case homeConfirmMessage
    case next

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
    case customerOrderAnySoap

    // The paper order slip pinned in the washing HUD
    case orderNoteTitle
    case orderNoteSoap
    case orderNoteAnySoap
    case orderNoteClothes
    case skip

    // Shop
    case shopTitle
    case shopSelectPrompt
    case shopBuy
    case shopNotEnoughGems
    case shopAlreadyActive
    case shopActiveToday
    case shopItemAddTimeName
    case shopItemAddTimeDesc
    case shopItemGemMultiplierName
    case shopItemGemMultiplierDesc
    
    // Handoff thank you lines, spoken once the package is handed to the customer
    case handoffThankYouClean
    case handoffThankYouFresh
    case handoffThankYouPay
    case handoffThankYouSmell
    
    // StartScene
    case startContinueDay
    case startMoreLevelsComingSoon
    case startNewGame

    // DryingScene
    case dryingAllDry
    case dryingTooHardFell

    // PackagingScene
    case packagingSwipeToFoldLeaf
    
    //Reward
    case dayReward
    case clothesFinished
    case baseIncome
    case mistakes
    case wrongFragrance
    case clothesFlewAway
    case totalIncome
}

enum Loc {
    private static let table: [LocKey: [AppLanguage: String]] = [
        .settingsTitle: [.en: "SETTINGS", .id: "PENGATURAN", .es: "AJUSTES"],
        .sfx: [.en: "SFX", .id: "SFX", .es: "SFX"],
        .music: [.en: "MUSIC", .id: "MUSIK", .es: "MÚSICA"],
        .language: [.en: "LANGUAGE", .id: "BAHASA", .es: "IDIOMA"],
        .microphone: [.en: "MICROPHONE", .id: "MIKROFON", .es: "MICRÓFONO"],
        .on: [.en: "ON", .id: "AKTIF", .es: "ENCENDIDO"],
        .off: [.en: "OFF", .id: "MATI", .es: "APAGADO"],
        .day: [.en: "DAY", .id: "HARI", .es: "DÍA"],
        .ok: [.en: "OK", .id: "OK", .es: "OK"],
        .start: [.en: "START", .id: "MULAI", .es: "EMPEZAR"],
        .yes: [.en: "YES", .id: "YA", .es: "SÍ"],
        .cancel: [.en: "CANCEL", .id: "BATAL", .es: "CANCELAR"],
        .reward: [.en: "REWARD", .id: "HADIAH", .es: "RECOMPENSA"],
        .startOver: [
            .en: "START OVER",
            .id: "MULAI ULANG",
            .es: "REINICIAR"
        ],
        .newGameConfirmMessage: [
            .en: "Start over from the beginning? Your current laundry progress will be lost",
            .id: "Mulai dari awal lagi? Progres cucian kamu saat ini akan hilang",
            .es: "¿Empezar de nuevo desde el principio? Se perderá tu progreso actual de lavandería"
        ],
        .homeConfirmMessage: [
            .en: "Are you sure you want to go back?",
            .id: "Apakah kamu yakin ingin kembali?",
            .es: "¿Seguro que quieres volver?"
        ],
        .next: [
            .en: "NEXT",
            .id: "SELANJUTNYA",
            .es: "SIGUIENTE"
        ],
        .onboardingStep1: [
            .en: "rawr rawrrr rawrr (hi I'm raptor)",
            .id: "rawr rawrrr rawrr (hai aku raptor)",
            .es: "rawr rawrrr rawrr (hola, soy raptor)"
        ],
        .onboardingStep2: [
            .en: "rawrr rawrr rawr rawrr (help me manage my laundry business)",
            .id: "rawrr rawrr rawr rawrr (bantu aku mengelola bisnis cucian)",
            .es: "rawrr rawrr rawr rawrr (ayúdame a manejar mi lavandería)"
        ],
        .onboardingStep3: [
            .en: "Rawrrrrrrrr (when the customer comes, take their dirty clothes, wash it, dry it, and fold it)",
            .id: "Rawrrrrrrrr (pelanggan akan datang, ambil baju kotor mereka, cuci, keringkan, dan lipat dengan rapi)",
            .es: "Rawrrrrrrrr (cuando el cliente llegue, toma su ropa sucia, lávala, sécala y dóblala)"
        ],

        .tutorialFrontDeskDirtyClothes: [
            .en: "Customer came! Click the dirty clothes to proceed to washing",
            .id: "Pelanggan datang! Tekan baju kotornya untuk lanjut mencuci",
            .es: "¡Llegó un cliente! Toca la ropa sucia para pasar al lavado"
        ],
        .tutorialWashingBasket: [
            .en: "Drag the clothes from the basket onto the stone to wash them",
            .id: "Geser baju dari keranjang ke batu untuk mencuci",
            .es: "Arrastra la ropa de la canasta a la piedra para lavarla"
        ],
        .tutorialWashingSoap: [
            .en: "Pick and drag the right soap variant",
            .id: "Pilih dan geser varian sabun yang tepat",
            .es: "Elige y arrastra el jabón correcto"
        ],
        .tutorialWashingScrub: [
            .en: "Rub the clothes to wash them clean",
            .id: "Usap baju untuk mencuci sampai bersih",
            .es: "Talla la ropa para dejarla limpia"
        ],
        .tutorialWashingCleanBasket: [
            .en: "Put the clean clothes into the clean basket!",
            .id: "Masukkan baju yang sudah bersih ke keranjang bersih!",
            .es: "¡Pon la ropa limpia en la canasta de limpios!"
        ],
        .tutorialWashingNextArrow: [
            .en: "Tap the arrow to move to the next phase!",
            .id: "Klik panah untuk lanjut ke tahap berikutnya!",
            .es: "¡Toca la flecha para ir a la siguiente etapa!"
        ],
        .tutorialDryingBasket: [
            .en: "Drag the clothes from the basket onto the line to dry them!",
            .id: "Geser baju dari keranjang ke penjemuran untuk mengeringkan!",
            .es: "¡Arrastra la ropa de la canasta al tendedero para secarla!"
        ],
        .tutorialDryingBlow: [
            .en: "Blow into the microphone to dry the clothes! Don't blow too hard",
            .id: "Tiup dari microphone untuk mengeringkan baju! Jangan tiup terlalu keras",
            .es: "¡Sopla en el micrófono para secar la ropa! No soples muy fuerte"
        ],
        .tutorialDryingLeafSwipe: [
            .en: "Fan the clothes with the leaf to dry them!",
            .id: "Kibaskan daun untuk mengeringkan baju!",
            .es: "¡Abanica la ropa con la hoja para secarla!"
        ],
        .tutorialDryingToBasket: [
            .en: "Drag the clothes from the line into the basket for the next step!",
            .id: "Geser baju dari penjemuran ke keranjang untuk step berikutnya!",
            .es: "¡Arrastra la ropa del tendedero a la canasta para el siguiente paso!"
        ],
        .tutorialFoldingBasket: [
            .en: "Drag the clothes from the basket onto the banana leaf to wrap them!",
            .id: "Geser baju dari keranjang ke daun pisang untuk membungkus!",
            .es: "¡Arrastra la ropa de la canasta a la hoja de plátano para envolverla!"
        ],
        .tutorialFoldingDirection: [
            .en: "Swipe to fold, following the arrow",
            .id: "Lipat dengan geser sesuai tanda panah",
            .es: "Para doblar, desliza siguiendo las flechas"
        ],
        .tutorialFoldingRope: [
            .en: "Use the rope to tie up the package",
            .id: "Gunakan tali untuk membungkus",
            .es: "Usa la cuerda para amarrar el paquete"
        ],

        .infoCustomer: [
            .en: "Press the sack to proceed to washing process",
            .id: "Tekan karungnya untuk lanjut ke proses mencuci",
            .es: "Presiona la bolsa para pasar al proceso de lavado"
        ],
        .infoFolding: [
            .en: "Drag your finger based on the arrow direction",
            .id: "Geser jarimu sesuai arah panah",
            .es: "Desliza tu dedo según la dirección de la flecha"
        ],
        .infoWashing: [
            .en: "Drag the clothes from the dirty piles and scrub it, then put in the clean piles",
            .id: "Seret baju dari tumpukan kotor lalu gosok, kemudian taruh di tumpukan bersih",
            .es: "Arrastra la ropa de la pila sucia, talla, y luego ponla en la pila limpia"
        ],
        .infoDryingMic: [
            .en: "Make the blow sound on your microphone, don't blow too hard",
            .id: "Tiup ke mikrofonmu, jangan terlalu keras",
            .es: "Haz un sonido de soplido en tu micrófono, no soples muy fuerte"
        ],
        .infoDryingMicFootnote: [
            .en: "*you can turn off microphone feature on setting button",
            .id: "*kamu bisa mematikan fitur mikrofon di tombol pengaturan",
            .es: "*puedes apagar la función de micrófono en el botón de ajustes"
        ],
        .infoDryingLeaf: [
            .en: "Fan the leaf across the clothes to dry them",
            .id: "Kibaskan daunnya di atas baju untuk mengeringkannya",
            .es: "Abanica la ropa con la hoja para secarla"
        ],
        .infoDryingLeafFootnote: [
            .en: "*you can turn on microphone feature on setting button",
            .id: "*kamu bisa menyalakan fitur mikrofon di tombol pengaturan",
            .es: "*puedes activar la función de micrófono en el botón de ajustes"
        ],
        .infoHandoff: [
            .en: "Drag the finished package to the customer",
            .id: "Seret paket yang sudah jadi ke pelanggan",
            .es: "Arrastra el paquete terminado hacia el cliente"
        ],
        .washingNoSoap: [
            .en: "Add some soap first!",
            .id: "Tambahkan sabun dulu!",
            .es: "¡Primero agrega jabón!"
        ],
        .WashingWrongSoap: [
            .en: "Not the right fragance!",
            .id: "Bukan itu pewanginya!",
            .es: "¡Ese no es el aroma correcto!"
        ],
        .foldingHintNotWashed: [
            .en: "Wash the clothes first!",
            .id: "Cuci dulu bajunya!",
            .es: "¡Primero lava la ropa!"
        ],
        .foldingHintNotDried: [
            .en: "Dry the clothes first!",
            .id: "Keringkan dulu bajunya!",
            .es: "¡Primero seca la ropa!"
        ],
        .foldingHintDragClothes: [
            .en: "Drag the clothes into the package!",
            .id: "Seret bajunya ke dalam paket!",
            .es: "¡Arrastra la ropa dentro del paquete!"
        ],
        .foldingHintTieRope: [
            .en: "Now tie the package!",
            .id: "Sekarang ikat paketnya!",
            .es: "Ahora, ¡Amarra el paquete!"
        ],
        .foldingHintDragClothesToCenter: [
            .en: "Drag the clothes to the center",
            .id: "Seret bajunya ke tengah",
            .es: "Arrastra la ropa al centro"
        ],
        .foldingHintSwipeToFold: [
            .en: "Swipe to fold the package!",
            .id: "Geser untuk melipat paketnya!",
            .es: "¡Desliza para doblar el paquete!"
        ],
        .foldingHintDragRopeToCenter: [
            .en: "Drag to the center",
            .id: "Seret ke tengah",
            .es: "Arrastra al centro"
        ],
        .foldingHintPackaged: [
            .en: "Packaged!",
            .id: "Sudah dikemas!",
            .es: "¡Empacado!"
        ],
        .dryingHintSwipeLeaf: [
            .en: "Fan the leaf across the clothes to dry them.",
            .id: "Kibaskan daun di atas baju untuk mengeringkannya.",
            .es: "Abanica la ropa con la hoja para secarla."
        ],
        .dryingHintMicPermission: [
            .en: "Microphone access is required to dry clothes — enable it in Settings.",
            .id: "Akses mikrofon diperlukan untuk mengeringkan baju — aktifkan di Pengaturan.",
            .es: "Se necesita acceso al micrófono para secar la ropa. Actívalo en Ajustes."
        ],
        .dryingHintMicStartFailed: [
            .en: "Couldn't start the microphone.",
            .id: "Mikrofon tidak bisa diaktifkan.",
            .es: "No se pudo activar el micrófono."
        ],
        .washingHintClean: [
            .en: "Clean! Drag it to the basket!",
            .id: "Bersih! Seret ke keranjang!",
            .es: "¡Implecable! ¡Arrástralo a la canasta!"
        ],
        .washingHintNiceClean: [
            .en: "Nice and clean!",
            .id: "Bersih sekali!",
            .es: "¡Como nuevo!"
        ],

        // Customer order lines are written "caveman style" in EN on purpose
        // (broken grammar, blunt). ES keeps that same clipped register.
        .soapDisplayNameRose: [.en: "ROSE", .id: "MAWAR", .es: "ROSA"],
        .soapDisplayNameSoapFruit: [.en: "SOAPFRUIT", .id: "BUAH LERAK", .es: "FRUTA JABÓN"],
        .customerOrderQuickWait: [
            .en: "%@. QUICK. ME WAIT.",
            .id: "%@. CEPAT. SAYA TUNGGU.",
            .es: "%@. RÁPIDO. YO ESPERAR."
        ],
        .customerOrderCleanGood: [
            .en: "%@. CLEAN GOOD.",
            .id: "%@. CUCI BERSIH.",
            .es: "%@. LIMPIAR BIEN."
        ],
        .customerOrderSmellRose: [
            .en: "ROSE. SMELL NICE.",
            .id: "MAWAR. HARUM.",
            .es: "ROSA. OLOR RICO."
        ],
        .customerOrderSmellSoapFruit: [
            .en: "SOAPFRUIT. SMELL FRESH.",
            .id: "BUAH LERAK. SEGAR.",
            .es: "JABÓN FRUTA. OLOR FRESCO."
        ],
        .customerOrderAnySoap: [
            .en: "WASH THESE. ANY SOAP OK.",
            .id: "CUCI INI. SABUN APA SAJA.",
            .es: "LAVAR. CUALQUIER JABÓN OK."
        ],

        .orderNoteTitle: [.en: "ORDER", .id: "PESANAN", .es: "PEDIDO"],
        .orderNoteSoap: [.en: "SOAP", .id: "SABUN", .es: "JABÓN"],
        .orderNoteAnySoap: [.en: "ANY", .id: "BEBAS", .es: "CUALQUIERA"],
        .orderNoteClothes: [.en: "CLOTHES", .id: "BAJU", .es: "ROPA"],
        .skip: [.en: "SKIP", .id: "LEWATI", .es: "OMITIR"],

        .shopTitle: [.en: "SHOP", .id: "TOKO", .es: "TIENDA"],
        .shopSelectPrompt: [
            .en: "SELECT AN ITEM\nTO SEE THE DESCRIPTION",
            .id: "PILIH SATU BARANG\nUNTUK MELIHAT KETERANGAN",
            .es: "ELIGE UN ARTÍCULO\nPARA VER LA DESCRIPCIÓN"
        ],
        .shopBuy: [.en: "BUY", .id: "BELI", .es: "COMPRAR"],
        .shopNotEnoughGems: [
            .en: "Not enough gems!",
            .id: "Gem tidak cukup!",
            .es: "¡Gemas insuficientes!"
        ],
        .shopAlreadyActive: [
            .en: "Already active for today!",
            .id: "Sudah aktif untuk hari ini!",
            .es: "¡Ya está activo hoy!"
        ],
        .shopActiveToday: [.en: "ACTIVE TODAY", .id: "AKTIF HARI INI", .es: "ACTIVO HOY"],
        .shopItemAddTimeName: [
            .en: "ADD MORE TIME",
            .id: "TAMBAH WAKTU",
            .es: "MÁS TIEMPO"
        ],
        .shopItemAddTimeDesc: [
            .en: "MORE TIME, MORE CUSTOMER! GET EXTRA TIME AND GEMS ON THE DAY.",
            .id: "LEBIH BANYAK WAKTU, LEBIH BANYAK PELANGGAN! DAPAT WAKTU DAN GEM TAMBAHAN HARI ITU.",
            .es: "¡MÁS TIEMPO, MÁS CLIENTES! CONSIGUE TIEMPO Y GEMAS EXTRA EN EL DÍA."
        ],
        .shopItemGemMultiplierName: [
            .en: "GEM MULTIPLIER",
            .id: "PENGGANDA GEM",
            .es: "MULTIPLICADOR"
        ],
        .shopItemGemMultiplierDesc: [
            .en: "BOOST YOUR INCOME, EARN 2x MORE GEMS FROM EVERY CUSTOMER OF THE DAY.",
            .id: "TINGKATKAN PENDAPATANMU, DAPAT 2x LEBIH BANYAK GEM DARI SETIAP PELANGGAN HARI ITU.",
            .es: "AUMENTA TUS INGRESOS, GANA 2x MÁS GEMAS DE CADA CLIENTE DEL DÍA."
        ],
        
        // Handoff thank you lines
        .handoffThankYouClean: [
            .en: "CLEAN! ME HAPPY!",
            .id: "BERSIH! AKU SENANG!",
            .es: "¡LIMPIO! ¡YO, FELIZ!"
        ],
        .handoffThankYouFresh: [
            .en: "SO FRESH! THANK YOU!",
            .id: "SEGAR! TERIMA KASIH!",
            .es: "¡FRESCO! ¡YO AGRADECER!"
        ],
        .handoffThankYouPay: [
            .en: "GOOD JOB! ME PAY!",
            .id: "KERJA BAGUS! AKU BAYAR!",
            .es: "¡TRABAJO BUENO! ¡YO PAGAR!"
        ],
        .handoffThankYouSmell: [
            .en: "SMELL NICE! TAKE COIN!",
            .id: "WANGI! AMBIL KOIN!",
            .es: "¡OLOR BUENO! ¡DAR MONEDA!"
        ],
        .startContinueDay: [.en: "DAY %d", .id: "HARI %d", .es: "DÍA %d"],
        .startMoreLevelsComingSoon: [
            .en: "MORE LEVELS COMING SOON!",
            .id: "LEVEL LEBIH BANYAK SEGERA HADIR!",
            .es: "¡MÁS NIVELES PRÓXIMAMENTE!"
        ],
        .startNewGame: [
            .en: "START NEW GAME",
            .id: "PERMAINAN BARU",
            .es: "NUEVO JUEGO"
        ],
        .dryingAllDry: [.en: "All dry!", .id: "Semua sudah kering!", .es: "¡Todo seco!"],
        .dryingTooHardFell: [
            .en: "Too hard! It fell!",
            .id: "Terlalu keras! Jatuh!",
            .es: "¡Muy fuerte! ¡Se cayó!"
        ],

        .packagingSwipeToFoldLeaf: [
            .en: "Swipe to fold the leaf!",
            .id: "Geser untuk melipat daunnya!",
            .es: "¡Desliza para doblar la hoja!"
        ],
        //Reward
        .dayReward: [
            .en: "DAY %d REWARD",
            .id: "HADIAH HARI %d",
            .es: "RECOMPENSA DÍA %d"
        ],
        .clothesFinished: [
            .en: "CLOTHES FINISHED",
            .id: "BAJU SELESAI",
            .es: "PRENDAS TERMINADAS"
        ],
        .baseIncome: [
            .en: "BASE INCOME",
            .id: "PENDAPATAN DASAR",
            .es: "INGRESO BASE"
        ],
        .mistakes: [
            .en: "MISTAKES",
            .id: "KESALAHAN",
            .es: "ERRORES"
        ],
        .wrongFragrance: [
            .en: "Wrong Fragrance",
            .id: "Pewangi Salah",
            .es: "Fragancia Equivocada"
        ],
        .clothesFlewAway: [
            .en: "Clothes Flew Away",
            .id: "Baju Terbang",
            .es: "La Ropa Se Cayó"
        ],
        .totalIncome: [
            .en: "TOTAL INCOME",
            .id: "TOTAL PENDAPATAN",
            .es: "INGRESO TOTAL"
        ],
    ]

    static func t(_ key: LocKey) -> String {
        table[key]?[SettingsManager.shared.language] ?? key.rawValue.uppercased()
    }
    
    static func t(_ key: LocKey, _ args: CVarArg...) -> String {
        let format = table[key]?[SettingsManager.shared.language] ?? key.rawValue.uppercased()
        return String(format: format, arguments: args)
    }
}
