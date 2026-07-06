//
//  CurrencyManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

class CurrencyManager {
    static let shared = CurrencyManager()
    
    private(set) var coins: Int = 0
    
    private init() {
        self.coins = SaveManager.shared.getSavedCoins()
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
        SaveManager.shared.saveCoins(coins)
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            SaveManager.shared.saveCoins(coins)
            return true
        }
        return false 
    }
}
