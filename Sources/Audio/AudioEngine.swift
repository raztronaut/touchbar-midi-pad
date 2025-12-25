import AVFoundation
import OSLog

@MainActor
class AudioEngine: ObservableObject {
    static let shared = AudioEngine()
    
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler() // Keeping for potential future use or removing?
    
    // Thread-Safety: Access buffers/players only on MainActor or protect them?
    // Since we play on MainActor (triggered by UI), we keep state on MainActor.
    // However, loading happens in background. We need to be careful.
    // AVAudioNode attachment must happen on engine.
    
    @Published var isReady = false
    
    private var players: [Int: AVAudioPlayerNode] = [:]
    private var buffers: [Int: AVAudioPCMBuffer] = [:]
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        engine.attach(sampler) 
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
            isReady = true
            Logger.audio.info("✅ Audio Engine Started")
        } catch {
            Logger.audio.fault("❌ Audio Engine Start Error: \(error.localizedDescription)")
        }
    }
    
    /// Loads a sample for a specific pad asynchronously.
    /// This prevents main thread hitches during heavy file IO or conversion.
    func setupPad(index: Int, sampleURL: URL) async {
        // 1. Heavy lifting in background
        let result = await Task.detached(priority: .userInitiated) { () -> (AVAudioPCMBuffer)? in
            do {
                let file = try AVAudioFile(forReading: sampleURL)
                let processingFormat = file.processingFormat
                
                guard let fileBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                    print("❌ Pad \(index): Read buffer creation failed")
                    return nil
                }
                try file.read(into: fileBuffer)
                
                return fileBuffer
            } catch {
                print("❌ Pad \(index) Error: \(error.localizedDescription)")
                return nil
            }
        }.value
        
        guard let fileBuffer = result else { return }
        
        // 2. Main Actor: Conversion & Attachment
        // We do conversion here to access engine.outputFormat securely
        let audioFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        
        var finalBuffer = fileBuffer
        
        if fileBuffer.format.channelCount != audioFormat.channelCount || fileBuffer.format.sampleRate != audioFormat.sampleRate {
            let inputRatio = audioFormat.sampleRate / fileBuffer.format.sampleRate
            let targetCapacity = AVAudioFrameCount(Double(fileBuffer.frameLength) * inputRatio) + 100
            
            if let converter = AVAudioConverter(from: fileBuffer.format, to: audioFormat),
               let targetBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: targetCapacity) {
                
                // Helper to safely manage state inside the block
                class InputProvider {
                    private var hasProvidedData = false
                    private let buffer: AVAudioPCMBuffer
                    
                    init(buffer: AVAudioPCMBuffer) {
                        self.buffer = buffer
                    }
                    
                    func provide(status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
                        if !hasProvidedData {
                            status.pointee = .haveData
                            hasProvidedData = true
                            return buffer
                        } else {
                            status.pointee = .endOfStream
                            return nil
                        }
                    }
                }
                
                let provider = InputProvider(buffer: fileBuffer)
                let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                    return provider.provide(status: outStatus)
                }
                
                var error: NSError? = nil
                converter.convert(to: targetBuffer, error: &error, withInputFrom: inputCallback)
                
                if let error = error {
                    Logger.audio.error("❌ Pad \(index): Conversion failed - \(error.localizedDescription)")
                } else {
                    finalBuffer = targetBuffer
                    Logger.audio.debug("✅ Pad \(index): Converted \(sampleURL.lastPathComponent)")
                }
            }
        }
        
        // 3. Attach & Connect
        // Detach old if exists?
        if let oldPlayer = players[index] {
            if oldPlayer.isPlaying { oldPlayer.stop() }
            engine.detach(oldPlayer)
        }
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        players[index] = player
        buffers[index] = finalBuffer
        
        Logger.audio.info("✅ Pad \(index): Ready (\(sampleURL.lastPathComponent))")
        
        if !engine.isRunning {
             try? engine.start()
        }
    }

    func play(padIndex: Int, velocity: Float) {
        guard let player = players[padIndex], let buffer = buffers[padIndex] else { return }
        
        if player.isPlaying {
            player.stop()
        }
        
        player.volume = velocity
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}
