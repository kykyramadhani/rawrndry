import AVFoundation
import SpriteKit

class AudioManager {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var waterAmbiencePlayer: AVAudioPlayer?
    private var birdAmbiencePlayer: AVAudioPlayer?
    
    private var scrubPlayer: AVAudioPlayer?
    
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
        
        bgmPlayer = setupAudioPlayer(fileName: "theme_song.wav", volume: 0.5)
        bgmPlayer?.play()
    }
    
    func playRiverAmbience() {
        guard !isMuted else { return }
        if waterAmbiencePlayer?.isPlaying == true { return }
        
        waterAmbiencePlayer = setupAudioPlayer(fileName: "river.wav", volume: 0.4)
        birdAmbiencePlayer = setupAudioPlayer(fileName: "bird_chirping.wav", volume: 0.3)
        
        waterAmbiencePlayer?.play()
        birdAmbiencePlayer?.play()
    }
    
    func playScrubbing() {
        guard !isMuted else { return }
        
        if scrubPlayer == nil {
            scrubPlayer = setupAudioPlayer(fileName: "scrubing.wav", volume: 0.8)
        }
        
        if scrubPlayer?.isPlaying == false {
            scrubPlayer?.play()
        }
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
    
    func playSFX(_ fileName: String, on node: SKNode) {
        guard !isMuted else { return }
        let playAction = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
        node.run(playAction)
    }
}
