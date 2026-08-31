//
//  LaundryItem.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import CoreGraphics

enum StainLevel {
    case slight
    case hard
}

enum SoapFragrance: String, CaseIterable {
    case rose = "Rose"
    case soapFruit = "Soap Fruit"

    var displayName: String {
        Loc.t(self == .rose ? .soapDisplayNameRose : .soapDisplayNameSoapFruit)
    }

    /// Which numbered soap art this fragrance uses (washingSoap1 / washingSoap2).
    var holderID: Int { self == .rose ? 1 : 2 }

    /// How opaque the applied soap settles at. Foam is a solid blob where petals are sparse,
    /// so it has to sit lighter or it hides the stain the player still has to aim at.
    var sprayOpacity: CGFloat {
        self == .rose ? 0.9 : 0.6
    }

    /// The burst art thrown across the clothes the moment this soap is applied — Soap Fruit
    /// picks one of its two foam blobs at random, so repeat washes don't look identical.
    var sprayTexture: String {
        switch self {
        case .rose: return AssetName.Item.washingPetals
        case .soapFruit: return [AssetName.Item.washingFoam1, AssetName.Item.washingFoam2].randomElement()!
        }
    }

    /// Rendered size of that burst, in points.
    var spraySize: CGSize {
        self == .rose ? CGSize(width: 123, height: 123) : CGSize(width: 77, height: 77)
    }
}

struct LaundryItem {
    let patternID: Int
    let stain: StainLevel
    
    let requestedSoap: SoapFragrance?
    
    var usedSoap: SoapFragrance?
    
    var imageName: String {
        return AssetName.Item.washingClothes(patternID: patternID)
    }
}
