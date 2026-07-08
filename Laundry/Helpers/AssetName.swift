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
        
        static let chevronRight = "btnChevronRight"
        static let chevronLeft = "btnChevronLeft"
        static let hudIndicator = "hudIndicator"
        static let sunIcon = "sun"
        static let gemIcon = "gemCurrency"
        static let btnInstruction = "btnInstruction"
        static let popUpFrame = "popUpFrame"
        static let btnClose = "btnClose"
        static let iconStarOn = "icon-star-on"
        static let iconStarOff = "icon-star-off"
        static let btnSettings = "btnSettings"
        static let btnSecondary = "btnSecondary"
        static let slider = "slider"
        static let slideBase = "slideBase"
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
        
        // Washing - Static
        static let washingBasketEmpty = "washingBasket" 
        
        // Washing - Dynamic
        static func washingBasketPile(patternID: Int) -> String {
            return "washingBasket\(patternID)"
        }
        
        static func washingPickedClothes(patternID: Int) -> String {
            return "washingPickedClothes\(patternID)"
        }
        
        static func washingClothes(patternID: Int) -> String {
            return "washingClothes\(patternID)"
        }
        
        static func washingStain(id: Int) -> String {
            return "washingStain\(id)"
        }
        
        static func washingSoap(id: Int) -> String {
            return "washingSoap\(id)"
        }
        
        static func washingSoapPicked(id: Int) -> String {
            return "washingSoap\(id)Picked"
        }
    }
    
    enum Font {
        static let comica = "ValdursansComicaNo1-Regular"
    }
}
