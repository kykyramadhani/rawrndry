import AVFoundation
import SpriteKit

class AudioManager {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var waterAmbiencePlayer: AVAudioPlayer?
    private var birdAmbiencePlayer: AVAudioPlayer?
    
    private var scrubPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []

    private let bgmBaseVolume: Float = 0.5
    private let waterBaseVolume: Float = 0.4
    private let birdBaseVolume: Float = 0.3
    private let scrubBaseVolume: Float = 0.8

    var isMuted: Bool = false {
        didSet {
            if isMuted {
                stopAllLoopingAudio()
            }
        }
    }

    private init() {}

    func playThemeBGM() {
        guard !isMuted else { return }
        if bgmPlayer?.isPlaying == true { return }

        bgmPlayer = setupAudioPlayer(fileName: "theme_song.wav", volume: bgmBaseVolume * SettingsManager.shared.musicVolume)
        bgmPlayer?.play()
    }

    func playRiverAmbience() {
        guard !isMuted else { return }
        if waterAmbiencePlayer?.isPlaying == true { return }

        waterAmbiencePlayer = setupAudioPlayer(fileName: "river.wav", volume: waterBaseVolume * SettingsManager.shared.musicVolume)
        birdAmbiencePlayer = setupAudioPlayer(fileName: "bird_chirping.wav", volume: birdBaseVolume * SettingsManager.shared.musicVolume)

        waterAmbiencePlayer?.play()
        birdAmbiencePlayer?.play()
    }

    func playScrubbing() {
        guard !isMuted else { return }

        if scrubPlayer == nil {
            scrubPlayer = setupAudioPlayer(fileName: "scrubing.wav", volume: scrubBaseVolume * SettingsManager.shared.sfxVolume)
        }

        if scrubPlayer?.isPlaying == false {
            scrubPlayer?.play()
        }
    }

    /// Call right after the SFX or music slider changes so any already-playing loop reflects it live.
    func refreshVolumes() {
        bgmPlayer?.volume = bgmBaseVolume * SettingsManager.shared.musicVolume
        waterAmbiencePlayer?.volume = waterBaseVolume * SettingsManager.shared.musicVolume
        birdAmbiencePlayer?.volume = birdBaseVolume * SettingsManager.shared.musicVolume
        scrubPlayer?.volume = scrubBaseVolume * SettingsManager.shared.sfxVolume
    }
    
    func stopScrubbing() {
        scrubPlayer?.stop()
        scrubPlayer?.currentTime = 0
    }
    
    func stopThemeBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
    func stopRiverAmbience() {
        waterAmbiencePlayer?.stop()
        birdAmbiencePlayer?.stop()
        waterAmbiencePlayer = nil
        birdAmbiencePlayer = nil
    }
    
    func stopAllLoopingAudio() {
        stopThemeBGM()
        stopRiverAmbience()
        stopScrubbing()
    }
    
    private func setupAudioPlayer(fileName: String, volume: Float) -> AVAudioPlayer? {
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
            player.numberOfLoops = -1 // Loop tanpa henti selama dimainkan
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// One-shot sound effect, e.g. `playSFX("folding")` for `folding.wav`. Routed through an
    /// `AVAudioPlayer` (rather than `SKAction.playSoundFileNamed`) so `SettingsManager`'s SFX
    /// volume actually applies.
    func playSFX(_ name: String) {
        guard !isMuted else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Audio file not found: \(name).wav")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = SettingsManager.shared.sfxVolume
            player.prepareToPlay()
            sfxPlayers.append(player)
            player.play()
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }
}
