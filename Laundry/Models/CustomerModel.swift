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

    /// The fragrance this customer insists on, or nil when any soap will do — the same value
    /// every item in `itemsToWash` carries, so the speech bubble can never promise a soap the
    /// washing station won't actually check for.
    let requestedSoap: SoapFragrance?

    /// Coins paid out for this order, fixed by the day's level design — not derived from
    /// clothes count at handoff time, so the payout can't drift from the design table.
    let reward: Int

    /// This customer's 0-based position in today's queue — used to identify "the very
    /// first customer of the very first day" for the one-time tutorial popup.
    let customerIndexInDay: Int

    var orderText: String {
        guard let requestedSoap else { return Loc.t(.customerOrderAnySoap) }

        let dialogues = [
            String(format: Loc.t(.customerOrderQuickWait), requestedSoap.displayName),
            String(format: Loc.t(.customerOrderCleanGood), requestedSoap.displayName),
            Loc.t(requestedSoap == .rose ? .customerOrderSmellRose : .customerOrderSmellSoapFruit)
        ]

        return dialogues.randomElement()!
    }
}
