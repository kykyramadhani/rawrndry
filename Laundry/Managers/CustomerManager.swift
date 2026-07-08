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
    
    func generateCustomers(forDay day: Int) {
        remainingCustomersForToday.removeAll()
        
        let availableImages = [
            AssetName.Character.customer1,
            AssetName.Character.customer2,
            AssetName.Character.customer3,
            AssetName.Character.customer4
        ]
        
        let totalCustomers: Int
        switch day {
        case 1: totalCustomers = 2
        case 2: totalCustomers = 3
        case 3: totalCustomers = 5
        default: totalCustomers = 5
        }
        
        for _ in 0..<totalCustomers {
            let numberOfClothes = Int.random(in: 2...3)
            
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
                requestedSoap: randomSoap // Tetap diteruskan agar CustomerModel tidak error dan teks bubble tetap ada
            )
            
            remainingCustomersForToday.append(newCustomer)
        }
    }
    
    func getNextCustomer() -> CustomerModel? {
        guard !remainingCustomersForToday.isEmpty else { return nil }
        return remainingCustomersForToday.removeFirst()
    }
}
