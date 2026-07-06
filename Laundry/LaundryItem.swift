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
    case floral = "Rose"
    case fruity = "Lemon"
}

struct LaundryItem {
    let patternID: Int
    let stain: StainLevel
    
    var imageName: String {
        return "washingClothes\(patternID)"
    }
}
