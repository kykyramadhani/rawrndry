//
//  DayManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

class DayManager {
    static let shared = DayManager()
    
    var currentDay: Int = 1
    
    private init() {
        self.currentDay = SaveManager.shared.getSavedDay()
    }
    
    func startNewDay() {
        CustomerManager.shared.generateCustomers(forDay: currentDay)
        print("Mulai Hari ke-\(currentDay) dengan \(CustomerManager.shared.remainingCustomersForToday.count) pelanggan.")
    }
    
    func endDay() {
        currentDay += 1
        SaveManager.shared.saveDay(currentDay)
    }
}
