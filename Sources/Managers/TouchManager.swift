import Foundation
import OpenMultitouchSupport
import SwiftUI

struct NormalizedTouch: Identifiable, Equatable {
    let id: Int32
    var x: Float // 0.0 to 1.0
    var y: Float // 0.0 to 1.0 (inverted from trackpad usually)
    var pressure: Float // 0.0 to 1.0 (or higher)
    var state: OMSState
}

@MainActor
class TouchManager: ObservableObject {
    static let shared = TouchManager()
    
    @Published var activeTouches: [Int32: NormalizedTouch] = [:]
    
    private let oms = OMSManager.shared
    private var listeningTask: Task<Void, Never>?
    
    init() {}
    
    func start() {
        guard listeningTask == nil else { return }
        
        listeningTask = Task {
            for await touchData in oms.touchDataStream {
                handleTouch(touchData)
            }
        }
        
        oms.startListening()
        print("👆 TouchManager Listening")
    }
    
    func stop() {
        listeningTask?.cancel()
        listeningTask = nil
        oms.stopListening()
    }
    
    private func handleTouch(_ data: [OMSTouchData]) {
        var newTouches: [Int32: NormalizedTouch] = [:]
        
        for touch in data {
            // Trackpad coordinates are usually:
            // X: 0 (Left) -> 1 (Right)
            // Y: 0 (Bottom) -> 1 (Top) -- WAIT, usually 0 is Top in UI, but trackpad hardware might differ.
            // Let's assume standard normalized and flip Y if needed for SwiftUI (where 0 is Top).
            // OMS usually gives 0..1.
            
            // In SwiftUI, (0,0) is Top-Left.
            // If Trackpad (0,0) is Bottom-Left, we need to invert Y.
            // Let's assume 1.0 - y for SwiftUI Y.
            
            // Actually OMS documentation says: x, y Float. 
            // We will verify later. For now assume standard Cartesian 0..1.
            
            // Filter out 'notTouching' or 'hovering' if we only want presses?
            // But we want to show 'hover' too? Maybe later. For now, let's track all substantial touches.
            
            if touch.state == .notTouching { continue }
            
            // Create simplified touch
            let t = NormalizedTouch(
                id: touch.id,
                x: touch.position.x,
                y: 1.0 - touch.position.y, // Invert Y for SwiftUI logic if needed (Assuming hardware 0 is bottom)
                pressure: touch.pressure, // or touch.total / density? Use pressure for now.
                state: touch.state
            )
            
            newTouches[touch.id] = t
        }
        
        // Update published state on MainActor
        self.activeTouches = newTouches
    }
}
