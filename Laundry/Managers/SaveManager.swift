//
//  SaveManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

class SaveManager {
    static let shared = SaveManager()
    
    private let defaults = UserDefaults.standard
    private let dayKey = "savedDayIndex"
    private let coinKey = "savedCoinCount"
    
    private init() {}
    
    // MARK: - Day Saving
    func saveDay(_ day: Int) {
        defaults.set(day, forKey: dayKey)
    }
    
    func getSavedDay() -> Int {
        let day = defaults.integer(forKey: dayKey)
        return day == 0 ? 1 : day // Mulai dari hari ke-1 jika belum ada save
    }
    
    // MARK: - Coin Saving
    func saveCoins(_ coins: Int) {
        defaults.set(coins, forKey: coinKey)
    }
    
    func getSavedCoins() -> Int {
        return defaults.integer(forKey: coinKey)
    }
}