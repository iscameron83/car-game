//
//  AudioEngine.swift
//  Car game — Procedural audio: engine rev + impact thud
//

import AVFoundation

final class BikeAudio {

    /// Master switch — audio is parked for now; flip to true to bring it back.
    static let isEnabled = false

    static let shared = BikeAudio()

    private let engine       = AVAudioEngine()
    private let enginePlayer = AVAudioPlayerNode()
    private let impactPlayer = AVAudioPlayerNode()
    private let pitchNode    = AVAudioUnitTimePitch()

    private var isRevving = false
    private var impactCooldown: TimeInterval = 0
    private var impactBuffer: AVAudioPCMBuffer?

    // Use a fixed stereo 44100 format for all buffers — avoids hardware mismatch
    private let bufferFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

    private init() {
        guard Self.isEnabled else { return }   // don't even claim the audio session
        setupAudioSession()
        setupGraph()
        generateImpactBuffer()
        try? engine.start()
    }

    // MARK: - Public API

    func setThrottle(_ on: Bool) {
        guard Self.isEnabled else { return }
        isRevving = on
        if on, !enginePlayer.isPlaying { enginePlayer.play() }
    }

    func updateRPM(_ rpm: Float) {
        guard Self.isEnabled else { return }
        // Pitch: 1.0 at idle → 2.2 at full throttle
        pitchNode.rate = 1.0 + rpm * 1.2
        if isRevving {
            enginePlayer.volume = 0.25 + rpm * 0.55
        } else {
            enginePlayer.volume = max(0, enginePlayer.volume - 0.03)
        }
    }

    func playImpact(intensity: Float = 1.0) {
        guard Self.isEnabled else { return }
        let now = CACurrentMediaTime()
        guard now > impactCooldown, let buf = impactBuffer else { return }
        impactCooldown = now + 0.20
        impactPlayer.volume = (0.3 + intensity * 0.7).clamped(to: 0...1)
        impactPlayer.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
        if !impactPlayer.isPlaying { impactPlayer.play() }
    }

    // MARK: - Graph

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func setupGraph() {
        engine.attach(enginePlayer)
        engine.attach(pitchNode)
        engine.attach(impactPlayer)

        // Connect using our fixed stereo format throughout
        engine.connect(enginePlayer, to: pitchNode,            format: bufferFormat)
        engine.connect(pitchNode,    to: engine.mainMixerNode, format: bufferFormat)
        engine.connect(impactPlayer, to: engine.mainMixerNode, format: bufferFormat)

        enginePlayer.volume = 0
        scheduleEngineLoop()
    }

    // MARK: - Engine buffer (stereo sawtooth + harmonics, looped)

    private func scheduleEngineLoop() {
        guard let buf = makeEngineBuffer() else { return }
        enginePlayer.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
    }

    private func makeEngineBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = bufferFormat.sampleRate
        let frequency: Double = 55       // A1 — low engine rumble
        let frameCount = AVAudioFrameCount(sampleRate * 0.5)   // 0.5s loop

        guard let buffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else { return nil }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var s: Double = 0
            s += 0.40 * sin(2 * .pi * frequency     * t)
            s += 0.25 * sin(2 * .pi * frequency * 2 * t)
            s += 0.15 * sin(2 * .pi * frequency * 3 * t)
            s += 0.10 * sin(2 * .pi * frequency * 4 * t)
            s += 0.06 * sin(2 * .pi * frequency * 5 * t)
            s += 0.04 * sin(2 * .pi * frequency * 7 * t)
            s += 0.12 * sin(2 * .pi * frequency / 2 * t)
            let sample = Float(s * 0.55)
            channels[0][i] = sample   // L
            channels[1][i] = sample   // R
        }
        return buffer
    }

    // MARK: - Impact buffer (stereo thud/crunch, one-shot)

    private func generateImpactBuffer() {
        let sampleRate = bufferFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * 0.25)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: bufferFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else { return }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env   = exp(-t * 28)
            let thud  = sin(2 * .pi * 60  * t) * 0.7
            let noise = Double.random(in: -1...1) * 0.4
            let click = sin(2 * .pi * 220 * t) * exp(-t * 80) * 0.5
            let sample = Float((thud + noise + click) * env * 0.85)
            channels[0][i] = sample
            channels[1][i] = sample
        }
        impactBuffer = buffer
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
