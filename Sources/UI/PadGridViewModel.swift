import SwiftUI
import Combine
import OSLog

@MainActor
class PadGridViewModel: ObservableObject {
    @Published var pads: [PadModel]
    @Published var isPoweredOn: Bool = true // Default ON
    @Published var useExcessiveVisuals: Bool = false // Toggle for "Excessive" visuals (Default OFF)
    
    private let audioEngine = AudioEngine.shared
    private let touchManager = TouchManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Track which touch ID is pressing which Pad ID
    private var touchToPadMap: [Int32: Int] = [:] 
    
    init() {
        self.pads = PadLayout.generateDefault()
        reloadSamples()
        setupTouchHandling()
    }
    
    func togglePower() {
        isPoweredOn.toggle()
        if isPoweredOn {
            touchManager.start()
        } else {
            touchManager.stop()
            // Reset all pads
            for i in 0..<pads.count { pads[i].isPressed = false; pads[i].pressure = 0.0 }
        }
    }
    
    func reloadSamples() {
        self.pads = PadLayout.generateDefault() // Regenerate layout and re-search samples
        
        Task {
            for pad in pads {
                if let url = pad.sampleURL {
                    await audioEngine.setupPad(index: pad.id, sampleURL: url)
                }
            }
        }
    }

    
    func onAppear() {
        if isPoweredOn { touchManager.start() }
    }
    
    func onDisappear() {
        touchManager.stop()
    }
    
    private func checkSandbox() {
        // Simple check: try to read a file outside bundle or process info
        // Using `ProcessInfo.processInfo.environment` often restricted?
        // Actually OMSManager has issues in Sandbox. If it works, we are good.
    }
    
    private func setupTouchHandling() {
        touchManager.$activeTouches
            .receive(on: RunLoop.main)
            .sink { [weak self] touches in
                self?.handleTouches(touches)
            }
            .store(in: &cancellables)
    }
    
    private func handleTouches(_ touches: [Int32: NormalizedTouch]) {
        // Reset all pads state first? Or only those affected?
        // More efficient to track changes.
        
        var pressedPadIds: Set<Int> = []
        var newTouchToPadMap: [Int32: Int] = [:]
        
        // Map touches to pads
        for (touchId, touch) in touches {
            if let padIndex = getPadIndex(at: touch) {
                newTouchToPadMap[touchId] = padIndex
                pressedPadIds.insert(padIndex)
                
                // Trigger Audio if this is a NEW touch on this pad (Note On)
                // Or if it's the same touch but pressure changed?
                // For drums, we usually just want one-shot on "Entry".
                
                let prevPadIndex = touchToPadMap[touchId]
                
                if prevPadIndex != padIndex, touch.state == .touching || touch.state == .starting {
                    // New hit!
                    let velocity = min(max(touch.pressure * 1.5, 0.2), 1.0) // Boost pressure a bit
                    playPad(index: padIndex, velocity: velocity)
                }
                
                // Update pressure visual
                if pads.contains(where: { $0.id == padIndex }) {
                    // Update the actual pad struct in the array
                    if let arrayIndex = pads.firstIndex(where: { $0.id == padIndex }) {
                        pads[arrayIndex].pressure = touch.pressure
                    }
                }
            }
        }
        
        // Identify released pads
        for i in 0..<pads.count {
            let id = pads[i].id
            let isPressed = pressedPadIds.contains(id)
            
            if pads[i].isPressed != isPressed {
                pads[i].isPressed = isPressed
            }
            if !isPressed {
                pads[i].pressure = 0.0
            }
        }
        
        self.touchToPadMap = newTouchToPadMap
    }
    
    private func getPadIndex(at touch: NormalizedTouch) -> Int? {
        // Simple grid hit testing
        // 4 Columns, 3 Rows
        // X: 0..1, Y: 0..1
        
        let col = Int(floor(touch.x * Float(PadLayout.cols)))
        let row = Int(floor(touch.y * Float(PadLayout.rows))) // 0 is Top now?
        
        // Wait, PadLayout mapping:
        // Rows 0 (Top), 1 (Mid), 2 (Bottom) Logic in Layout generateDefault was:
        // 0,1,2,3 -> But Layout array order? 
        // Let's look at PadModel IDs.
        
        // Layout logic:
        // Row 0 (Top): 8,9,10,11
        // Row 1 (Mid): 4,5,6,7
        // Row 2 (Bot): 0,1,2,3
        
        // If Y=0 is Top:
        // row 0 -> Top
        // row 1 -> Mid
        // row 2 -> Bot
        
        // But let's check col/row bounds
        guard col >= 0 && col < PadLayout.cols && row >= 0 && row < PadLayout.rows else {
             return nil
        }
        
        // Map (row, col) to Pad ID
        // Row 0 (Top) -> Indices 8,9,10,11.  Index = 8 + col
        // Row 1 (Mid) -> Indices 4,5,6,7.    Index = 4 + col
        // Row 2 (Bot) -> Indices 0,1,2,3.    Index = 0 + col
        
        // Formula: ID = (2 - row) * 4 + col ? 
        // If row 0 (Top) -> (2-0)*4 + col = 8 + col. YES.
        // If row 1 (Mid) -> (2-1)*4 + col = 4 + col. YES.
        // If row 2 (Bot) -> (2-2)*4 + col = 0 + col. YES.
        
        let id = (2 - row) * 4 + col
        return id
    }
    
    func playPad(index: Int, velocity: Float) {
        audioEngine.play(padIndex: index, velocity: velocity)
    }
    // MARK: - Sample Management
    // MARK: - Sample Management
    func randomizeSamples() {
        // Optimized cache load (Sync is fine as index is strict reference)
        let library = SampleLoader.loadAllSamples()
        
        // Perform UI updates first (Optimistic UI)
        // Then fire async audio loading
        
        var newAssignments: [(Int, URL)] = []
        
        for index in pads.indices {
            let pad = pads[index]
            var typeKey = SampleLoader.DrumCategory.other.rawValue
            
            // Map Pad Name -> Category
            if pad.name.contains("Kick") { typeKey = SampleLoader.DrumCategory.kick.rawValue }
            else if pad.name.contains("Snare") { typeKey = SampleLoader.DrumCategory.snare.rawValue }
            else if pad.name.contains("Hi-Hat") { typeKey = SampleLoader.DrumCategory.hiHat.rawValue }
            else if pad.name.contains("Clap") { typeKey = SampleLoader.DrumCategory.clap.rawValue }
            else if pad.name.contains("Tom") { typeKey = SampleLoader.DrumCategory.tom.rawValue }
            else if pad.name.contains("Crash") { typeKey = SampleLoader.DrumCategory.crash.rawValue }
            else if pad.name.contains("Ride") { typeKey = SampleLoader.DrumCategory.ride.rawValue }
            else if pad.name.contains("Cowbell") { typeKey = SampleLoader.DrumCategory.bell.rawValue }
            else if pad.name.contains("Percussion") { typeKey = SampleLoader.DrumCategory.percussion.rawValue }

            // Try explicit match first
            if let samples = library[typeKey], !samples.isEmpty {
                let randomSample = samples.randomElement()!
                pads[index].sampleURL = randomSample.url
                newAssignments.append((pad.id, randomSample.url))
            } else {
                // Fallback: Use fuzzy match
                var found = false
                for (key, list) in library {
                    if key.localizedCaseInsensitiveContains(typeKey), let randomSample = list.randomElement() {
                        pads[index].sampleURL = randomSample.url
                        newAssignments.append((pad.id, randomSample.url))
                        found = true
                        break
                    }
                }
                
                if !found {
                    // Ultimate fallback
                    if let randomCategory = library.values.randomElement(), let randomSample = randomCategory.randomElement() {
                        pads[index].sampleURL = randomSample.url
                        newAssignments.append((pad.id, randomSample.url))
                    }
                }
            }
        }
        
        Logger.ui.info("🎲 Kit Randomized. Loading \(newAssignments.count) samples async...")
        
        // Offload audio loading
        Task {
            // Can parallelize if we want?
            // await withTaskGroup... but for 12 pads linear is fast enough if async.
            for (id, url) in newAssignments {
                await AudioEngine.shared.setupPad(index: id, sampleURL: url)
            }
            Logger.ui.info("✅ Kit Loading Complete")
        }
    }
}
