//
//  CustomerManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//

import Foundation

class CustomerManager {
    static let shared = CustomerManager()
    
    var remainingCustomersForToday: [CustomerModel] = []
    
    private init() {}
    
    /// Populates the queue from `LevelDesign`'s fixed customer/clothes/reward table for this day.
    /// Leaves the queue empty if there's no designed content for `day` yet (StartScene is
    /// responsible for keeping the player from reaching this state in the first place).
    func generateCustomers(forDay day: Int) {
        remainingCustomersForToday.removeAll()

        guard let config = LevelDesign.config(forDay: day) else { return }

        let availableImages = [
            AssetName.Character.customer1,
            AssetName.Character.customer2,
            AssetName.Character.customer3,
            AssetName.Character.customer4
        ]

        for (index, customerConfig) in config.customers.enumerated() {
            let numberOfClothes = customerConfig.clothesCount

            var availablePatterns = [1, 2, 3, 4]
            availablePatterns.shuffle()

            // 1. Tentukan Sabun di awal
            // Acak apakah pelanggan ini punya request spesifik atau bebas (nil)
            let hasSpecificRequest = Bool.random()
            let randomSoap: SoapFragrance = Bool.random() ? .rose : .soapFruit
            let itemRequestedSoap: SoapFragrance? = hasSpecificRequest ? randomSoap : nil

            var clothes: [LaundryItem] = []

            for i in 0..<numberOfClothes {
                let randomStain: StainLevel = Bool.random() ? .slight : .hard
                let uniquePatternID = availablePatterns[i]

                // 2. Tambahkan parameter requestedSoap dan usedSoap (default nil)
                clothes.append(LaundryItem(
                    patternID: uniquePatternID,
                    stain: randomStain,
                    requestedSoap: itemRequestedSoap,
                    usedSoap: nil
                ))
            }

            let randomCharacter = availableImages.randomElement()!

            let newCustomer = CustomerModel(
                characterImage: randomCharacter,
                itemsToWash: clothes,
                requestedSoap: randomSoap, // Tetap diteruskan agar CustomerModel tidak error dan teks bubble tetap ada
                reward: customerConfig.reward,
                customerIndexInDay: index
            )

            remainingCustomersForToday.append(newCustomer)
        }
    }
    
    func getNextCustomer() -> CustomerModel? {
        guard !remainingCustomersForToday.isEmpty else { return nil }
        return remainingCustomersForToday.removeFirst()
    }
}
