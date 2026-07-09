//
//  DryingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Drag washed items from the wet basket onto the rope, blow into the mic to fill the
//  drying progress bar to 100%, then drag the dried item into the dry basket.

import SpriteKit
import AVFoundation
import SoundAnalysis

class DryingScene: SKScene {

    private enum DragOrigin {
        case basket
        case rope
    }

    private var itemNodes: [SKSpriteNode?] = []
    private var dragState: (index: Int, origin: DragOrigin)?

    /// Which rack slot each currently-hung item occupies, assigned once when it's hung and
    /// kept stable — picking up or removing one item never reflows the others' positions.
    private var itemSlots: [Int: Int] = [:]

    private var basketNode: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var dryBasketNode: SKSpriteNode!
    private var dryBasketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var blowBarFill: SKShapeNode!
    private var blowPercentLabel: SKLabelNode!

    // MARK: - Audio & Sound Analysis Properties
    private let micEngine = AVAudioEngine()
    private var micPermissionGranted = false
    private var micEngineStarted = false
    
    // 🔥 PENGATURAN MODE CLASSIFIER (Set ke true untuk menguji SoundAnalysis)
    private var enableClassifierValidation = false
    
    // SNClassifier Properties
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private let resultsObserver = BlowResultsObserver()
    private let analysisQueue = DispatchQueue(label: "com.laundry.soundAnalysisQueue")
    private var audioFramePosition: AVAudioFramePosition = 0
    
    // Detection State
    private var detectedSoundLabel: String?
    private var detectedConfidence: Double = 0
    private var isBlowingSound = false
    private let confidenceThreshold: Double = 0.80

    private var isBlowing = false
    private var isOverblowing = false
    private let blowThreshold: Float = -20
    private let overblowThreshold: Float = -6

    // Logging Throttlers
    private var bufferLogCounter = 0
    private var lastClassifierLogTime: TimeInterval = 0

    /// The leaf tool shown instead of the mic UI when Settings has the microphone turned off —
    /// swipe it across the rope to dry clothes instead of blowing.
    private var leafNode: SKSpriteNode?
    private var isFanning = false
    private var lastFanPoint: CGPoint?
    private var fanAccumDistance: CGFloat = 0
    private let fanSwipeDistance: CGFloat = 40

    /// Decorative rope-and-leaf-bundle prop shown next to the leaf tool — hides while the
    /// player is actively fanning, and never shows at all in microphone mode.
    private var leafRopeNode: SKSpriteNode?

    private let itemSize = CGSize(width: 70, height: 90)
    private let blowBarWidth: CGFloat = 200
    private let blowBarHeight: CGFloat = 18

    /// Tints the actual clothing texture light blue while wet instead of laying a plain
    /// rectangular color block on top — colorBlendFactor only tints the art's own opaque
    /// pixels, so the wet look follows the garment's real silhouette (no visible box edges).
    private let wetTintColor = UIColor(red: 0.73, green: 0.64, blue: 0.58, alpha: 1)

    private var shakeCamera: SKCameraNode!

    private var ropeY: CGFloat { size.height * 0.78 }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.15, y: size.height * 0.24) }
    private var dryBasketPosition: CGPoint { CGPoint(x: size.width * 0.85, y: size.height * 0.24) }
    private var rackZone: CGRect { CGRect(x: size.width * 0.15, y: ropeY - 60, width: size.width * 0.7, height: 90) }
    private var basketZone: CGRect { CGRect(x: basketPosition.x - 60, y: basketPosition.y - 50, width: 120, height: 110) }
    private var dryBasketZone: CGRect { CGRect(x: dryBasketPosition.x - 60, y: dryBasketPosition.y - 50, width: 120, height: 110) }

    override func didMove(to view: SKView) {
        // A camera lets us shake the whole screen (see shakeScreen()) by moving the camera
        // instead of scene content — positioned at scene center with no zoom/rotation, it
        // renders identically to having no camera at all until it's actually shaken.
        shakeCamera = SKCameraNode()
        shakeCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(shakeCamera)
        camera = shakeCamera

        addBackground(imageNamed: "dryingBackground")
        addCurrencyHUD(topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90), day: GameState.shared.currentDay, coins: GameState.shared.score)
        addStationArrows(current: .drying)

        addRope()
        addBasketVisual()
        addBlowBar()
        addStatusLabel()
        setupPickedClothesNode()
        setupItems()

        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.85, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.08))

        addSettingsButton()

        setupDryingInput()
    }

    override func willMove(from view: SKView) {
        teardownDryingInput()
    }

    // MARK: - Input mode (microphone vs leaf swipe)

    private func setupDryingInput() {
        if SettingsManager.shared.microphoneEnabled {
            requestMicPermissionAndStart()
        } else {
            addLeafTool()
            addLeafRopeProp()
            showHint(Loc.t(.dryingHintSwipeLeaf), on: hintLabel)
        }
    }

    private func teardownDryingInput() {
        if micEngineStarted {
            stopMicEngine()
        }
        leafNode?.removeFromParent()
        leafNode = nil
        leafRopeNode?.removeFromParent()
        leafRopeNode = nil
        isFanning = false
        lastFanPoint = nil
        isOverblowing = false
    }

    /// Called when the settings popup closes, in case the microphone toggle changed mid-scene.
    private func refreshDryingInputMode() {
        teardownDryingInput()
        setupDryingInput()
    }

    /// Hidden at rest — it only appears while the player is actively dragging/fanning it
    /// (see touchesBegan/touchesEnded/touchesCancelled), so it doesn't clutter the rope area
    /// when it's not in use.
    private func addLeafTool() {
        let leaf = SKSpriteNode(imageNamed: "dryingLeafFan")
        leaf.name = "leafTool"
        leaf.size = CGSize(width: 120, height: 100)
        leaf.position = CGPoint(x: size.width * 0.5, y: ropeY - 70)
        leaf.zPosition = 40
        leaf.isHidden = true
        addChild(leaf)
        leafNode = leaf
    }

    /// Sits just below center screen — clear of the fan and the hanging rack so it doesn't
    /// compete with either.
    private func addLeafRopeProp() {
        let prop = SKSpriteNode(imageNamed: "dryingLeafRope")
        prop.size = CGSize(width: 150, height: 150)
        prop.position = CGPoint(x: size.width * 0.5, y: size.height * 0.30)
        prop.zPosition = 4
        addChild(prop)
        leafRopeNode = prop
    }

    // MARK: - Setup

    /// dryingRope.png is baked at the same canvas size as dryingBackground.png, with the rope
    /// already drawn in place — so it's overlaid full-screen rather than stretched into a thin bar.
    private func addRope() {
        let rope = SKSpriteNode(imageNamed: "dryingRope")
        rope.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rope.size = size
        rope.zPosition = 0
        addChild(rope)
    }

    /// Same basket + pile formatting as WashingScene: an empty basket sprite with the
    /// pattern-specific pile sprite sized and positioned to exactly overlay it (not a
    /// smaller, offset sliver), for every pattern 1...4.
    private func addBasketVisual() {
        basketNode = SKSpriteNode(imageNamed: "dryingBasket")
        basketNode.size = CGSize(width: 120, height: 120)
        basketNode.position = basketPosition
        basketNode.zPosition = 2
        addChild(basketNode)

        basketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles1")
        basketPiles.size = basketNode.size
        basketPiles.position = basketNode.position
        basketPiles.zPosition = 3
        addChild(basketPiles)

        dryBasketNode = SKSpriteNode(imageNamed: "dryingBasket")
        dryBasketNode.size = CGSize(width: 120, height: 120)
        dryBasketNode.position = dryBasketPosition
        dryBasketNode.zPosition = 2
        addChild(dryBasketNode)

        dryBasketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles1")
        dryBasketPiles.size = dryBasketNode.size
        dryBasketPiles.position = dryBasketNode.position
        dryBasketPiles.zPosition = 3
        addChild(dryBasketPiles)
    }

    private func setupPickedClothesNode() {
        pickedClothes = SKSpriteNode(imageNamed: "dryingClothesPicked1")
        pickedClothes.size = itemSize
        pickedClothes.zPosition = 30
        pickedClothes.isHidden = true
        addChild(pickedClothes)
    }

    private func setupItems() {
        itemNodes = Array(repeating: nil, count: GameState.shared.clothesTypes.count)
        itemSlots = [:]

        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isHungToDry {
            hangItem(index: index)
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }

    private func makeHungItemNode(index: Int) -> SKSpriteNode {
        let variant = GameState.shared.itemProgress[index].dryingVariant
        let node = SKSpriteNode(imageNamed: "dryingClothesHanged\(variant)")
        node.size = itemSize
        node.name = "item-\(index)"
        node.zPosition = 5

        let progress = GameState.shared.itemProgress[index].dryProgress
        node.color = wetTintColor
        node.colorBlendFactor = 1 - progress

        return node
    }

    /// Hangs `index` at its previously-assigned rack slot, or claims the next free one if
    /// this is the first time it's being hung. The slot sticks until `freeSlot(for:)` is
    /// called, so picking up or removing a different item never moves this one.
    private func hangItem(index: Int) {
        let slot = itemSlots[index] ?? nextFreeSlot()
        itemSlots[index] = slot

        let node = makeHungItemNode(index: index)
        node.position = rackSlotPosition(slot: slot)
        addChild(node)
        itemNodes[index] = node
    }

    private func nextFreeSlot() -> Int {
        var slot = 0
        while itemSlots.values.contains(slot) { slot += 1 }
        return slot
    }

    /// Releases `index`'s rack slot once it's no longer hung (dried and collected, or
    /// dropped/fallen back into the wet basket) so a future item can claim it.
    private func freeSlot(for index: Int) {
        itemSlots.removeValue(forKey: index)
    }

    private func rackSlotPosition(slot: Int) -> CGPoint {
        let spacing: CGFloat = 80
        let startX = size.width * 0.55 - spacing * 1.5
        return CGPoint(x: startX + CGFloat(slot) * spacing, y: ropeY - 55)
    }

    private func updateBasketPilesVisibility() {
        if let index = GameState.shared.itemProgress.firstIndex(where: {
            $0.isWashed && !$0.isHungToDry && !$0.isDried
        }) {
            basketPiles.texture = SKTexture(imageNamed: "dryingBasketPiles\(GameState.shared.itemProgress[index].dryingVariant)")
            basketPiles.isHidden = false
        } else {
            basketPiles.isHidden = true
        }

        if let index = GameState.shared.itemProgress.firstIndex(where: { $0.isDried && !$0.isHungToDry }) {
            dryBasketPiles.texture = SKTexture(imageNamed: "dryingBasketPiles\(GameState.shared.itemProgress[index].dryingVariant)")
            dryBasketPiles.isHidden = false
        } else {
            dryBasketPiles.isHidden = true
        }
    }

    /// Same look as the Settings popup's sliders (slideBase track + amber fill), minus the thumb —
    /// this one's a read-only progress display, not a control.
    private func addBlowBar() {
        let bg = SKSpriteNode(imageNamed: AssetName.UI.slideBase)
        bg.size = CGSize(width: blowBarWidth, height: blowBarHeight)
        bg.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        bg.zPosition = 10
        addChild(bg)

        let fill = SKShapeNode()
        fill.fillColor = .orange
        fill.strokeColor = .clear
        fill.zPosition = 11
        bg.addChild(fill)
        blowBarFill = fill
        setBlowBarFillPath(fraction: 0)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "0%"
        label.fontSize = 14
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: blowBarHeight)
        label.zPosition = 12
        bg.addChild(label)
        blowPercentLabel = label
    }

    private func setBlowBarFillPath(fraction: CGFloat) {
        let fillHeight = blowBarHeight - 6
        let filledWidth = blowBarWidth * max(0, min(1, fraction))
        blowBarFill.path = CGPath(
            roundedRect: CGRect(x: -blowBarWidth / 2, y: -fillHeight / 2, width: filledWidth, height: fillHeight),
            cornerWidth: fillHeight / 2,
            cornerHeight: fillHeight / 2,
            transform: nil
        )
    }

    private func addStatusLabel() {
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusLabel.fontSize = 26
        statusLabel.fontColor = .white
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        statusLabel.zPosition = 20
        statusLabel.alpha = 0
        addChild(statusLabel)
    }

    // MARK: - Microphone & Sound Classifier

    private func requestMicPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                self.micPermissionGranted = granted
                if granted {
                    self.startMicEngine()
                } else {
                    self.showHint(Loc.t(.dryingHintMicPermission), on: self.hintLabel)
                }
            }
        }
    }

    private func startMicEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            print("❌ [Mic] Engine Setup Failed: \(error)")
            showHint(Loc.t(.dryingHintMicStartFailed), on: hintLabel)
            return
        }

        let inputNode = micEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Setup Classifier only if enabled
        if enableClassifierValidation {
            setupSoundClassifier(format: format)
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try micEngine.start()
            micEngineStarted = true
            print("🎙️ [Mic] Engine Started Successfully")
        } catch {
            print("❌ [Mic] Engine Start Failed: \(error)")
            showHint(Loc.t(.dryingHintMicStartFailed), on: hintLabel)
        }
    }

    private func stopMicEngine() {
        micEngine.inputNode.removeTap(onBus: 0)
        micEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        micEngineStarted = false
        
        // Teardown Classifier
        streamAnalyzer?.removeAllRequests()
        streamAnalyzer = nil
        audioFramePosition = 0
    }
    
    private func setupSoundClassifier(format: AVAudioFormat) {
        streamAnalyzer = SNAudioStreamAnalyzer(format: format)
        
        resultsObserver.onResult = { [weak self] identifier, confidence, logString in
            self?.handleClassification(identifier: identifier, confidence: confidence, logString: logString)
        }
        
        do {
            // Note: If built-in model lacks "blowing/wind", you MUST train a custom .mlmodel
            // via Create ML and load it here using SNClassifySoundRequest(mlModel: customModel)
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            try streamAnalyzer?.add(request, withObserver: resultsObserver)
            print("🧠 [Analyzer] Classifier Request Added")
        } catch {
            print("❌ [Analyzer] Failed to setup SoundAnalysis: \(error.localizedDescription)")
        }
    }

    /// Runs on the audio engine's internal thread — keep this cheap and hop to main before touching game state.
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferLogCounter += 1
        // Log every ~20th buffer to avoid console freeze
        let shouldLog = (bufferLogCounter % 20 == 0)

        if shouldLog {
            print("--------------------------------------------------")
            print("🎙️ [Mic] Audio Buffer Received")
        }

        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // 1. DUAL PIPELINE - PART A: CALCULATE RMS (ALWAYS RUNS)
        var sumOfSquares: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sumOfSquares += sample * sample
        }
        let rms = sqrt(sumOfSquares / Float(frameLength))
        let avgPower = 20 * log10(max(rms, 0.000001))
        
        if shouldLog {
            print("📊 [RMS] Power = \(String(format: "%.1f", avgPower)) dB")
        }
        
        // 2. DUAL PIPELINE - PART B: SEND TO CLASSIFIER (IF ENABLED)
        if enableClassifierValidation, let analyzer = self.streamAnalyzer {
            if shouldLog { print("🧠 [Analyzer] Analyzer Processing Buffer...") }
            
            analysisQueue.async { [weak self] in
                guard let self = self else { return }
                do {
                    try analyzer.analyze(buffer, atAudioFramePosition: self.audioFramePosition)
                    self.audioFramePosition += AVAudioFramePosition(frameLength)
                } catch {
                    if shouldLog { print("❌ [Analyzer] Analysis Error: \(error)") }
                }
            }
        }

        // 3. MERGE PIPELINE - HANDLE POWER ON MAIN THREAD
        DispatchQueue.main.async { [weak self] in
            self?.handleMicPower(avgPower, shouldLog: shouldLog)
        }
    }
    
    private func handleClassification(identifier: String, confidence: Double, logString: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.detectedSoundLabel = identifier
            self.detectedConfidence = confidence
            self.isBlowingSound = self.isValidBlowingSound(identifier: identifier, confidence: confidence)
            
            // Throttle Classifier Top Predictions Log (Print once per second)
            let currentTime = CACurrentMediaTime()
            if currentTime - self.lastClassifierLogTime > 1.0 {
                print(logString)
                self.lastClassifierLogTime = currentTime
            }
        }
    }
    
    private func isValidBlowingSound(identifier: String, confidence: Double) -> Bool {
        let lowercased = identifier.lowercased()
        return lowercased.contains("wind") ||
               lowercased.contains("breath") ||
               lowercased.contains("blow")
    }

    private func handleMicPower(_ power: Float, shouldLog: Bool) {
        var isAccepted = true
        var rejectReason = ""

        // 1. Classifier Validation & Graceful Fallback
        if enableClassifierValidation {
            if detectedConfidence < confidenceThreshold {
                // FALLBACK: Model belum yakin / gagal, kita izinkan RMS jalan (Sistem Lama)
                if shouldLog { print("⚠️ [Fallback] Classifier confidence too low (\(String(format: "%.2f", detectedConfidence))). Using RMS.") }
            } else if !isBlowingSound {
                // REJECT: Classifier yakin ini BUKAN suara tiupan
                isAccepted = false
                rejectReason = "Classifier rejected label: \(detectedSoundLabel ?? "Unknown")"
            }
        }

        // Output Status
        if shouldLog {
            if !isAccepted {
                print("❌ [Rejected] \(rejectReason) | Power: \(String(format: "%.1f", power)) dB")
            } else if enableClassifierValidation && detectedConfidence >= confidenceThreshold {
                print("✅ [Accepted] Prediction: \(detectedSoundLabel ?? "Unknown") (\(String(format: "%.2f", detectedConfidence))) | Power: \(String(format: "%.1f", power)) dB")
            }
        }

        if !isAccepted {
            isBlowing = false
            isOverblowing = false
            return
        }

        // 2. RMS Power Execution (Existing Logic)
        if power > overblowThreshold {
            isBlowing = false
            if !isOverblowing {
                if shouldLog { print("💨 [Action] OVERBLOW TRIGGERED -> dropOverblownItems()") }
                isOverblowing = true
                dropOverblownItems()
            }
        } else if power > blowThreshold {
            isOverblowing = false
            if !isBlowing {
                if shouldLog { print("🌬️ [Action] BLOW DETECTED -> advanceDrying()") }
                isBlowing = true
                advanceDrying()
            }
        } else {
            isBlowing = false
            isOverblowing = false
        }
    }

    // MARK: - Drying progress (advanced by either a mic blow or a leaf swipe)

    private func advanceDrying() {
        let dryingIndices = GameState.shared.itemProgress.indices.filter {
            GameState.shared.itemProgress[$0].isHungToDry && GameState.shared.itemProgress[$0].dryProgress < 1
        }
        guard !dryingIndices.isEmpty else { return }

        for index in dryingIndices {
            let progress = min(1, GameState.shared.itemProgress[index].dryProgress + 0.12)
            GameState.shared.itemProgress[index].dryProgress = progress
            
            // Menggunakan colorBlendFactor sesuai existing logic
            itemNodes[index]?.colorBlendFactor = 1 - progress
        }

        swayAndFlash(indices: dryingIndices)
        updateBlowBar()

        if GameState.shared.isFullyDried {
            showStatus("All dry!")
            run(.sequence([.wait(forDuration: 1.5), .run { [weak self] in self?.hideStatus() }]))
        }
    }

    private func swayAndFlash(indices: [Int]) {
        let degreesToRadians: (CGFloat) -> CGFloat = { $0 * .pi / 180 }
        let sway = SKAction.sequence([
            .rotate(toAngle: degreesToRadians(5), duration: 0.1, shortestUnitArc: true),
            .rotate(toAngle: degreesToRadians(-5), duration: 0.15, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.1, shortestUnitArc: true)
        ])

        for index in indices {
            guard let node = itemNodes[index] else { continue }
            let variant = GameState.shared.itemProgress[index].dryingVariant
            node.texture = SKTexture(imageNamed: "dryingClothesBlowed\(variant)")
            node.run(sway) {
                guard GameState.shared.itemProgress[index].isHungToDry else { return }
                node.texture = SKTexture(imageNamed: "dryingClothesHanged\(variant)")
            }
        }
    }

    /// Blowing too hard drops any still-wet hung items back into the wet basket — a real penalty,
    /// distinct from the gentle sway a normal-strength blow triggers.
    private func dropOverblownItems() {
        let fallingIndices = GameState.shared.itemProgress.indices.filter {
            GameState.shared.itemProgress[$0].isHungToDry && GameState.shared.itemProgress[$0].dryProgress < 1
        }
        guard !fallingIndices.isEmpty else { return }

        showStatus("Too hard! It fell!")
        run(.sequence([.wait(forDuration: 1.0), .run { [weak self] in self?.hideStatus() }]))
        
        // Memicu goyangan layar (camera shake)
        shakeScreen()

        for index in fallingIndices {
            guard let node = itemNodes[index] else { continue }
            let variant = GameState.shared.itemProgress[index].dryingVariant
            node.texture = SKTexture(imageNamed: "dryingClothesFallen\(variant)")
            node.zPosition = 4

            let drop = SKAction.group([
                .moveBy(x: 0, y: -60, duration: 0.35),
                .fadeOut(withDuration: 0.35),
                .rotate(byAngle: .pi / 6, duration: 0.35)
            ])
            node.run(.sequence([drop, .removeFromParent()]))
            itemNodes[index] = nil
            freeSlot(for: index)

            GameState.shared.itemProgress[index].isHungToDry = false
            GameState.shared.itemProgress[index].dryProgress = 0
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }

    /// Jolts the camera through a quick decaying zigzag — since the camera defines the
    /// viewport, moving it (rather than any content node) shakes literally everything
    /// on screen, popups included, matching the force of an overblow.
    private func shakeScreen() {
        let originalPosition = shakeCamera.position
        let shake = SKAction.sequence([
            .moveBy(x: -14, y: 6, duration: 0.035),
            .moveBy(x: 22, y: -10, duration: 0.035),
            .moveBy(x: -20, y: 8, duration: 0.035),
            .moveBy(x: 16, y: -6, duration: 0.035),
            .moveBy(x: -10, y: 4, duration: 0.035),
            .moveBy(x: 6, y: -2, duration: 0.035),
            .move(to: originalPosition, duration: 0.03)
        ])
        shakeCamera.run(shake)
    }

    /// Bar reflects actual drying progress (average of all hung items) toward 100% — not raw mic volume.
    private func updateBlowBar() {
        let hungProgress = GameState.shared.itemProgress.filter { $0.isHungToDry }.map { $0.dryProgress }
        let fraction = hungProgress.isEmpty ? 0 : hungProgress.reduce(0, +) / CGFloat(hungProgress.count)
        setBlowBarFillPath(fraction: fraction)
        blowPercentLabel.text = "\(Int(fraction * 100))%"
    }

    // MARK: - UI helpers

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.alpha = 0
        statusLabel.run(.fadeIn(withDuration: 0.2))
    }

    private func hideStatus() {
        statusLabel.run(.fadeOut(withDuration: 0.2))
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }

        if handleStationArrowTap(nodeName: name, current: .drying) { return }
        if handleSettingsButtonTap(nodeName: name, onClose: { [weak self] in self?.refreshDryingInputMode() }) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                if SettingsManager.shared.microphoneEnabled {
                    self.showTipPopup(
                        text: Loc.t(.infoDryingMic),
                        footnote: Loc.t(.infoDryingMicFootnote)
                    )
                } else {
                    self.showTipPopup(
                        text: Loc.t(.infoDryingLeaf),
                        footnote: Loc.t(.infoDryingLeafFootnote)
                    )
                }
            }
            return
        }

        guard dragState == nil else { return }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)) {
            beginDrag(index: index, from: .rope, at: location)
            return
        }

        if basketPiles.contains(location) || basketNode.contains(location),
           let index = GameState.shared.itemProgress.firstIndex(where: { $0.isWashed && !$0.isHungToDry && !$0.isDried }) {
            beginDrag(index: index, from: .basket, at: location)
            return
        }

        if leafNode != nil {
            isFanning = true
            lastFanPoint = location
            fanAccumDistance = 0
            leafNode?.position = location
            leafNode?.isHidden = false
            leafRopeNode?.isHidden = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesMoved(at: location) { return }

        if isFanning {
            leafNode?.position = location
            if let last = lastFanPoint {
                fanAccumDistance += hypot(location.x - last.x, location.y - last.y)
            }
            lastFanPoint = location
            if fanAccumDistance > fanSwipeDistance {
                fanAccumDistance = 0
                advanceDrying()
            }
            return
        }

        guard dragState != nil else { return }
        pickedClothes.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handleSettingsPopupTouchesEnded() { return }

        if isFanning {
            isFanning = false
            lastFanPoint = nil
            leafNode?.isHidden = true
            leafRopeNode?.isHidden = false
            return
        }

        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        resolveDrop(index: drag.index, origin: drag.origin, at: pickedClothes.position)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFanning {
            isFanning = false
            lastFanPoint = nil
            leafNode?.isHidden = true
            leafRopeNode?.isHidden = false
            return
        }

        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        if drag.origin == .rope {
            hangItem(index: drag.index)
        }
        updateBasketPilesVisibility()
    }

    private func beginDrag(index: Int, from origin: DragOrigin, at location: CGPoint) {
        dragState = (index, origin)

        if origin == .rope {
            itemNodes[index]?.removeFromParent()
            itemNodes[index] = nil
        }

        pickedClothes.texture = SKTexture(imageNamed: "dryingClothesPicked\(GameState.shared.itemProgress[index].dryingVariant)")
        pickedClothes.position = location
        pickedClothes.isHidden = false
        updateBasketPilesVisibility()
    }

    private func resolveDrop(index: Int, origin: DragOrigin, at position: CGPoint) {
        switch origin {
        case .basket:
            if rackZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = true
                hangItem(index: index)
            }
        case .rope:
            let progress = GameState.shared.itemProgress[index]
            if progress.isDried, dryBasketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
                freeSlot(for: index)
            } else if !progress.isDried, basketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
                GameState.shared.itemProgress[index].dryProgress = 0
                freeSlot(for: index)
            } else {
                hangItem(index: index)
            }
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }
}

// MARK: - Observer For Sound Analysis
private class BlowResultsObserver: NSObject, SNResultsObserving {
    var onResult: ((String, Double, String) -> Void)?

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        
        let topClassifications = Array(classificationResult.classifications.prefix(3))
        var logString = "🤖 [Classifier] Top Predictions:\n"
        for c in topClassifications {
            logString += "   - \(c.identifier) (\(String(format: "%.2f", c.confidence)))\n"
        }
        
        guard let top = topClassifications.first else { return }
        onResult?(top.identifier, top.confidence, logString)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("❌ [Analyzer] SoundAnalysis Error: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        // Observer completion hook
    }
}
