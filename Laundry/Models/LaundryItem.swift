//
//  LaundryItem.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

enum StainLevel {
    case slight
    case hard
}

enum SoapFragrance: String {
    case rose = "Rose"
    case soapFruit = "Soap Fruit"
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
