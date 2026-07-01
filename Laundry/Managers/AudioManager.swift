//
//  AudioManager.swift
//  Laundry
//
//  Created by Kyky on 30/06/26.
//


import AVFoundation
import SpriteKit

class AudioManager {
    
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var waterAmbiencePlayer: AVAudioPlayer?
    private var birdAmbiencePlayer: AVAudioPlayer?
    
    var isMuted: Bool = false {
        didSet {
            if isMuted {
                stopAllLoopingAudio()
            } else {
            }
        }
    }
    
    private init() {}
    
    func playThemeBGM() {
        bgmPlayer = setupAudioPlayer(fileName: AudioName.themeBGM, volume: 0.5)
        bgmPlayer?.play()
    }
    
    func playRiverAmbience() {
        waterAmbiencePlayer = setupAudioPlayer(fileName: AudioName.waterAmbience, volume: 0.4)
        birdAmbiencePlayer = setupAudioPlayer(fileName: AudioName.birdChirping, volume: 0.3)
        
        waterAmbiencePlayer?.play()
        birdAmbiencePlayer?.play()
    }
    
    func stopThemeBGM() {
        bgmPlayer?.stop()
    }
    
    func stopRiverAmbience() {
        waterAmbiencePlayer?.stop()
        birdAmbiencePlayer?.stop()
    }
    
    func stopAllLoopingAudio() {
        stopThemeBGM()
        stopRiverAmbience()
    }
    
    private func setupAudioPlayer(fileName: String, volume: Float) -> AVAudioPlayer? {
        guard !isMuted else { return nil }
        
        let components = fileName.split(separator: ".")
        guard components.count == 2 else { return nil }
        
        let name = String(components[0])
        let ext = String(components[1])
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Audio file not found: \(fileName)")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            print("Error loading audio file \(fileName): \(error.localizedDescription)")
            return nil
        }
    }
    
    func playSFX(_ fileName: String, on node: SKNode) {
        guard !isMuted else { return }
        
        let playAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
        node.run(playAction)
    }
}
