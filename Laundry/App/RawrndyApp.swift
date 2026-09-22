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
    /// Stored, not computed: a computed property here handed SpriteView a brand-new StartScene
    /// on every re-render, throwing away whatever scene the player was actually in.
    @State private var scene: SKScene = {
        let size = CGSize(width: 844, height: 390)
        // A fresh install opens on the backstory film; every launch after that goes straight
        // to the start screen.
        let hasSeenIntro = UserDefaults.standard.bool(forKey: TutorialFlag.introVideo.rawValue)
        let scene: SKScene = hasSeenIntro ? StartScene(size: size) : IntroVideoScene(size: size)
        scene.scaleMode = .aspectFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBar(hidden: true)
            .task { GameCenterManager.shared.authenticate() }
    }
}
