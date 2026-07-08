//
//  ProgressManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import Foundation

class ProgressManager {
    static let shared = ProgressManager()
    
    private(set) var unlockedSoaps: Set<String> = []
    private let unlockedSoapsKey = "unlockedSoapsKey"
    
    private init() {
        loadProgress()
    }
    
    func unlockSoap(_ soap: SoapFragrance) {
        unlockedSoaps.insert(soap.rawValue)
        saveProgress()
    }
    
    func isSoapUnlocked(_ soap: SoapFragrance) -> Bool {
        if soap == .rose { return true }
        return unlockedSoaps.contains(soap.rawValue)
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(Array(unlockedSoaps), forKey: unlockedSoapsKey)
    }
    
    private func loadProgress() {
        if let savedSoaps = UserDefaults.standard.stringArray(forKey: unlockedSoapsKey) {
            unlockedSoaps = Set(savedSoaps)
        }
    }
}
