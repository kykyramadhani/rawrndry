//
//  LevelDesign.swift
//  Laundry
//
//  The hand-authored day-by-day level plan: how many customers show up each day,
//  how many clothes each one brings, and what each order pays out.
//

import Foundation

struct DayLevelConfig {
    struct CustomerConfig {
        let clothesCount: Int
        let reward: Int
    }

    let customers: [CustomerConfig]
}

enum LevelDesign {

    static let days: [DayLevelConfig] = [
        // Day 1
        DayLevelConfig(customers: [
            .init(clothesCount: 2, reward: 400),
            .init(clothesCount: 2, reward: 400)
        ]),
        // Day 2
        DayLevelConfig(customers: [
            .init(clothesCount: 3, reward: 600),
            .init(clothesCount: 1, reward: 200),
            .init(clothesCount: 3, reward: 600)
        ]),
        // Day 3
        DayLevelConfig(customers: [
            .init(clothesCount: 1, reward: 200),
            .init(clothesCount: 2, reward: 400),
            .init(clothesCount: 2, reward: 400),
            .init(clothesCount: 3, reward: 600),
            .init(clothesCount: 3, reward: 600)
        ])
    ]

    /// Returns the config for `day` (1-indexed), or nil if there's no designed content for it yet.
    static func config(forDay day: Int) -> DayLevelConfig? {
        guard day >= 1, day <= days.count else { return nil }
        return days[day - 1]
    }
}
