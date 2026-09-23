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

    /// How opaque the applied soap settles at.
    var sprayOpacity: CGFloat { 0.9 }

    /// The burst art thrown across the clothes the moment this soap is applied.
    var sprayTexture: String {
        switch self {
        case .rose: return AssetName.Item.washingPetals
        case .soapFruit: return AssetName.Item.washingFoam
        }
    }

    /// Rendered size of that burst, in points.
    var spraySize: CGSize {
        self == .rose ? CGSize(width: 175, height: 175) : CGSize(width: 120, height: 120)
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
