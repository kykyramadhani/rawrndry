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

    /// Coins paid out for this order, fixed by the day's level design — not derived from
    /// clothes count at handoff time, so the payout can't drift from the design table.
    let reward: Int

    /// This customer's 0-based position in today's queue — used to identify "the very
    /// first customer of the very first day" for the one-time tutorial popup.
    let customerIndexInDay: Int

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
