//
//  IntroVideoScene.swift
//  Laundry
//
//  The backstory film, shown once on a fresh install before the player ever reaches the
//  start screen. Skippable at any point, and never shown again once it has played through
//  or been skipped — "start new game" is what puts it back.
//

import AVFoundation
import SpriteKit

final class IntroVideoScene: SKScene {


    private var player: AVPlayer?
    private var videoNode: SKVideoNode?
    private var endObserver: NSObjectProtocol?

    /// Guards against finishing twice, which is easy to do here: the skip button and the
    /// video reaching its end can both fire, and two transitions would stack two StartScenes.
    private var hasFinished = false

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black

        guard let url = Bundle.main.url(forResource: "Rawrndry_Backstory", withExtension: "mp4") else {
            // Nothing to play — don't strand the player on a black screen just because the
            // film is missing from the bundle.
            print("Intro video not found in bundle")
            finish()
            return
        }

        setupVideo(url: url)
        setupSkipButton()
    }

    private func setupVideo(url: URL) {
        // The game is silent at this point (StartScene is what starts the theme), so the
        // film gets the audio session to itself without anything to duck or stop first.
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .pause
        self.player = player

        let videoNode = SKVideoNode(avPlayer: player)
        // The film is 2622x1206 and the scene is 844x390, near enough the same shape that
        // filling the screen crops almost nothing.
        videoNode.size = size
        videoNode.position = .zero
        videoNode.zPosition = -1
        addChild(videoNode)
        self.videoNode = videoNode

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.finish()
        }

        videoNode.play()
    }

    /// Same artwork and lettering as the start screen's button, sitting bottom-right so it
    /// never covers the middle of the frame.
    private func setupSkipButton() {
        let button = SKSpriteNode(imageNamed: "btnMain")
        button.name = "skipButton"
        button.position = CGPoint(x: size.width * 0.33, y: -size.height * 0.33)
        button.zPosition = 10
        button.alpha = 0
        addChild(button)

        let label = SKLabelNode(text: Loc.t(.skip))
        label.fontName = AssetName.Font.comica
        label.fontSize = 35
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        // Faded in rather than popped in, so the opening frames of the film are clean.
        button.run(.sequence([.wait(forDuration: 1.0), .fadeIn(withDuration: 0.4)]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard tappedNodeName(at: touch.location(in: self)) == "skipButton" else { return }
        guard let button = childNode(withName: "skipButton") else {
            finish()
            return
        }
        runButtonTapAnimation(on: button) { self.finish() }
    }

    /// Stops the film, marks it seen, and moves on. Tearing the player down here rather than
    /// in `willMove(from:)` is what keeps the audio from carrying on over the start screen.
    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true

        stopPlayback()

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        UserDefaults.standard.set(true, forKey: TutorialFlag.introVideo.rawValue)

        let startScene = StartScene(size: size)
        startScene.scaleMode = scaleMode
        view?.presentScene(startScene, transition: .fade(with: .black, duration: 0.6))
    }

    /// Pausing the AVPlayer alone does not hold: SKVideoNode keeps driving the player's rate
    /// for as long as the node is in a scene, and the outgoing scene outlives the transition,
    /// so the film carried on playing behind the start screen. The node has to be told to
    /// pause and then taken out of the scene, and the item dropped, before the player stays
    /// down.
    private func stopPlayback() {
        videoNode?.pause()
        videoNode?.removeFromParent()
        videoNode = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    /// Safety net for any exit that doesn't go through `finish()`.
    override func willMove(from view: SKView) {
        stopPlayback()
    }

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }
}
