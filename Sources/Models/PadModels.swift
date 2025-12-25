import Foundation
import SwiftUI

struct PadModel: Identifiable {
    let id: Int
    let name: String
    var color: Color
    var sampleURL: URL?
    
    // Runtime State
    var isPressed: Bool = false
    var pressure: Float = 0.0
}

struct PadLayout {
    static let rows = 3
    static let cols = 4
    
    static func generateDefault() -> [PadModel] {
        var pads: [PadModel] = []
        
        // Use Strings trying to match folder names or fallback
        let mapping: [(id: Int, name: String, type: String)] = [
            // Bottom Row
            (0, "Kick", "Kick"), (1, "Snare", "Snare"), (2, "Hi-Hat", "Hihat"), (3, "Clap", "Clap"),
            // Middle Row - Map Toms to generic "Tom" for now, or find specific files logic later
            (4, "Low Tom", "Tom"), (5, "Mid Tom", "Tom"), (6, "High Tom", "Tom"), (7, "Crash", "Cymbal"),
            // Top Row
            (8, "Ride", "Ride"), (9, "Ride Bell", "Ride"), (10, "Percussion", "Percussion"), (11, "Cowbell", "Bell")
        ]
        
        // Load the library
        let library = SampleLoader.loadAllSamples()
        
        for item in mapping {
            var url: URL? = nil
            
            // Try explicit match
            if let samples = library[item.type], !samples.isEmpty {
                // Pick random or specific?
                // Use ID * Prime (e.g. 37) to scatter the selection better than just ID % Count 
                // This avoids the "Index 2" problem if file #2 is bad.
                let index = (item.id * 37) % samples.count
                url = samples[index].url
            } 
            // Also try fuzzy search if not found
            else {
                 for (key, samples) in library {
                     if key.localizedCaseInsensitiveContains(item.type) {
                         let index = (item.id * 37) % samples.count
                         url = samples[index].url
                         break
                     }
                 }
            }

            pads.append(PadModel(
                id: item.id,
                name: item.name,
                color: getColor(for: item.type),
                sampleURL: url
            ))
        }
        
        return pads
    }
    
    static func getColor(for type: String) -> Color {
        // Simplified Logic
        if type.contains("Kick") { return .red }
        if type.contains("Snare") { return .blue }
        if type.contains("Hihat") { return .yellow }
        if type.contains("Clap") { return .orange }
        if type.contains("Tom") { return .purple }
        if type.contains("Cymbal") || type.contains("Crash") || type.contains("Ride") { return .green }
        return .gray
    }
}
