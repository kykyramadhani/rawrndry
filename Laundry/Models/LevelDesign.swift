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
        
        var reward: Int {
            return clothesCount * LevelDesign.piecePrice
        }
    }

    let customers: [CustomerConfig]
}

enum LevelDesign {
    static let piecePrice: Int = 200
    static let penaltyWrongSoap: Int = 30
    static let penaltyClothesFlown: Int = 25 //NOTE: change if needed to dynamic calc

    // days authored by us
    static let authoredDays: [DayLevelConfig] = [
        // Day 1
        DayLevelConfig(customers: [
            .init(clothesCount: 2), //400
            .init(clothesCount: 2)  //400
        ]),
        // Day 2
        DayLevelConfig(customers: [
            .init(clothesCount: 3), //600
            .init(clothesCount: 1), //200
            .init(clothesCount: 3) //600
        ]),
        // Day 3
        DayLevelConfig(customers: [
            .init(clothesCount: 1), //200
            .init(clothesCount: 2), //400
            .init(clothesCount: 2), //400
            .init(clothesCount: 3), //600
            .init(clothesCount: 3)  //600
        ])
    ]

    /// Returns the config for `day` (1-indexed), or generates the day, always deterministic based on the day number
    static func config(forDay day: Int) -> DayLevelConfig {
            if day >= 1, day <= authoredDays.count {
                return authoredDays[day - 1]
            }
            return generateDay(day)
        }

        private static func generateDay(_ day: Int) -> DayLevelConfig {
            let daysPastTutorial = day - authoredDays.count

            //ceiling so the game is not impossible to play
            let customerCount = min(3 + daysPastTutorial / 4, 8)
            let maxClothesPerCustomer = 3 //NOTE: change to min(3 + daysPastTutorial / 6, 6), once the bigger loads of clothes are implemented

            var rng = SeededRNG(seed: day) //same day has the same config for everyone, (deterministic seed)
            let customers = (0..<customerCount).map { _ in
                DayLevelConfig.CustomerConfig(clothesCount: Int.random(in: 1...maxClothesPerCustomer, using: &rng))
            }
            return DayLevelConfig(customers: customers)
        }
}

//the same seed always produces the same sequence of "random" numbers
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    // produces the next number in the sequence, and advances the internal state so
    // the number after this one will be different.
    mutating func next() -> UInt64 {
        // formula: multiply the state by one fixed constant, then add another
        // fixed constant.
        //
        // &* and &+ are Swift way of allow overflow in multiply and add. Normal "*" and "+"
        // would crash if the math produced a number too big to fit in 64 bits.
        
        state = state &* 6364136223846793005 &+ 1442695040888963407 //magic numbers
        return state
    }
}
