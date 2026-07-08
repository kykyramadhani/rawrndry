//
//  CustomerModel.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//

import Foundation

struct CustomerModel {
    let id = UUID()
    let characterImage: String
    let itemsToWash: [LaundryItem]
    
    let requestedSoap: SoapFragrance
    
    var orderText: String {
        let soapName = requestedSoap.rawValue.uppercased()
        
        let dialogues = [
            "\(soapName). QUICK. ME WAIT.",
            "WASH FAST! USE \(soapName)!",
            "DIRTY CLOTHES. GIVE \(soapName).",
            "ME WANT \(soapName) SOAP!",
            "USE \(soapName)! MAKE CLEAN!"
        ]
        
        return dialogues.randomElement() ?? "WASH PLS."
    }
}
