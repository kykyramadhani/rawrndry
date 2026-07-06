//
//  AssetName.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

enum AssetName {

    enum Background {
        static let start = "startBackground"
        static let frontDesk = "frontdeskBackground"
        static let washing = "washingBackground"
    }
    
    enum UI {
        static let buttonMain = "btnMain"
        static let speechBubble = "speechBubble"
    }
    
    enum Character {
        static let customer1 = "frontdeskCustomer1"
        static let customer2 = "frontdeskCustomer2"
        static let customer3 = "frontdeskCustomer3"
        static let customer4 = "frontdeskCustomer4"
    }
    
    enum Item {
        // Frontdesk
        static let foregroundDesk = "frontdeskForeground"
        static let dirtyClothesBag = "frontdeskDirtyClothes"
        static let fly1 = "frontdeskFlies1"
        static let fly2 = "frontdeskFlies2"
        
        // Washing
        static let washingBasket = "washingBasket"
        static let washingBasketPiles = "washingBasketPiles"
        static let washingSoap = "washingSoap"
        static let dirtStain = "washingStain"
    }
    
    enum Font {
        static let comica = "ValdursansComicaNo1-Regular"
    }
}
