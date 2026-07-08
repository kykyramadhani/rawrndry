//
//  HapticManager.swift
//  TrialRawrndry



import CoreHaptics
import Foundation
import UIKit

class HapticsManager {
    static let shared = HapticsManager()

    private var engine: CHHapticEngine?
    private var scrubPlayer: CHHapticAdvancedPatternPlayer?
    private var isPlayerActive = false

    private init() {
        setupEngine()
        prepareScrubPattern()
        setupAppLifecycleObservers()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()

            engine?.stoppedHandler = { reason in
                print("haptics engine stopped: \(reason.rawValue)")
                self.isPlayerActive = false
            }

            engine?.resetHandler = { [weak self] in
                print("haptics reset: ")
                do {
                    try self?.engine?.start()
                    self?.prepareScrubPattern()
                } catch {
                    print("haptics fatal error \(error)")
                }
            }

            try engine?.start()
        } catch {
            print("Error in [setupEngine()] \(error)")
        }
    }

    private func prepareScrubPattern() {

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let continuousScrub = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 100.0
        )

        do {
            let pattern = try CHHapticPattern(events: [continuousScrub], parameters: [])
            scrubPlayer = try engine?.makeAdvancedPlayer(with: pattern)
            scrubPlayer?.loopEnabled = true
        } catch {
            print("HapticsManager Error [prepareScrubPattern()] \(error)")
        }
    }

    // MARK: - function for scene

    func startScrubbing() {
        guard !isPlayerActive else { return }
        do {
            try scrubPlayer?.start(atTime: 0)
            isPlayerActive = true
        } catch {
            print("Error in [startsScrubbing()] \(error)")
        }
    }

    func updateScrubbing(velocity: CGFloat) {
        guard isPlayerActive else { return }

        //mapping spritekit speed, core haptics rang
        let targetIntensity = Float(min(max(velocity / 1200.0, 0.2), 0.9))
        let targetSharpness = Float(min(max(velocity / 1800.0, 0.2), 0.7))

        let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: targetIntensity, relativeTime: 0)
        let sharpnessParam = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: targetSharpness, relativeTime: 0)

        do {
            try scrubPlayer?.sendParameters([intensityParam, sharpnessParam], atTime: 0)
        } catch {
            print("[updateScrubbing()] error: \(error)")
        }
    }

    func stopScrubbing() {
        guard isPlayerActive else { return }
        do {
            try scrubPlayer?.stop(atTime: 0)
            isPlayerActive = false
        } catch {
            print("[stopScrubbing() error]: \(error)")
        }
    }

    //MARK: Listener for restart haptics engine
    func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc func applicationDidBecomeActive() {

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.engine?.start()
                print("restarted")
            } catch {
                print("could not restart: \(error)")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
