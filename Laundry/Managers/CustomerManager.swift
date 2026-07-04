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
            let numberOfClothes = Int.random(in: 1...3)
            var clothes: [LaundryItem] = []
            
            for _ in 0..<numberOfClothes {
                let randomStain: StainLevel = Bool.random() ? .slight : .hard
                let randomPatternID = Int.random(in: 1...1) 
                
                clothes.append(LaundryItem(patternID: randomPatternID, stain: randomStain))
            }
            
            let randomSoap: SoapFragrance = Bool.random() ? .floral : .fruity
            let randomCharacter = availableImages.randomElement()!
            
            let newCustomer = CustomerModel(
                characterImage: randomCharacter,
                itemsToWash: clothes,
                requestedSoap: randomSoap
            )
            
            remainingCustomersForToday.append(newCustomer)
        }
    }
    
    func getNextCustomer() -> CustomerModel? {
        guard !remainingCustomersForToday.isEmpty else { return nil }
        return remainingCustomersForToday.removeFirst()
    }
}
