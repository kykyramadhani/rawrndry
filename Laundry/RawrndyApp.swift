//
//  RawrndyApp.swift
//  Laundry
//
//  Created by Kyky on 04/07/26.
//


//
//  RawrndyApp.swift
//  TrialRawrndry
//
//  Created by Kyky on 01/07/26.
//


import SwiftUI
import SpriteKit

@main
struct RawrndyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var scene: SKScene {
        let scene = StartScene(size: CGSize(width: 844, height: 390)) 
        scene.scaleMode = .aspectFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBar(hidden: true)
    }
}
