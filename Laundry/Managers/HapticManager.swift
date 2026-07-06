//
//  HapticManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 03/07/26.
//


import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}