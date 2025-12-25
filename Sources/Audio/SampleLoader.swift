import Foundation
import AVFoundation

struct SampleLoader {
    // Categories based on folder names
    enum DrumCategory: String, CaseIterable {
        case kick = "Kick"
        case snare = "Snare"
        case hiHat = "Hihat"
        case clap = "Clap"
        case tom = "Tom"
        case crash = "Cymbal" // Folder is Cymbal, but we might want sub-types?
        case percussion = "Percussion"
        case fx = "FX"
        case bell = "Bell"
        case ride = "Ride" // Note: Ride might be under Cymbal?
        case other = "Other"
    }
    
    struct SampleFile: Identifiable {
        let id = UUID()
        let name: String
        let url: URL
        let category: String
    }
    
    private static var cachedLibrary: [String: [SampleFile]]?
    
    // Explicitly reload from disk (e.g. if user adds files while app running? unlikely for bundle)
    static func reloadLibrary() {
        cachedLibrary = nil
        _ = loadAllSamples()
    }
    
    static func loadAllSamples() -> [String: [SampleFile]] {
        if let cache = cachedLibrary {
            return cache
        }
        
        var library: [String: [SampleFile]] = [:]
        
        guard let resourcePath = Bundle.main.resourcePath else { return [:] }
        let samplesPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("Samples/Drums")
        
        let fileManager = FileManager.default
        // Use keys to skip hidden files if needed
        guard let enumerator = fileManager.enumerator(at: samplesPath, includingPropertiesForKeys: [.isDirectoryKey]) else { return [:] }
        
        for case let fileURL as URL in enumerator {
            // Skip directories if the enumerator yields them (it does)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
                continue
            }
            
            if ["wav", "aif", "mp3"].contains(fileURL.pathExtension.lowercased()) {
                // Determine category from parent folder
                let rawFolder = fileURL.deletingLastPathComponent().lastPathComponent
                let name = fileURL.deletingPathExtension().lastPathComponent
                
                // Robust Normalization: Match folder name to DrumCategory ignoring case
                // This fixes HiHat/Hihat/hihat inconsistencies.
                let folderName: String
                if let match = DrumCategory.allCases.first(where: { $0.rawValue.localizedCaseInsensitiveCompare(rawFolder) == .orderedSame }) {
                    folderName = match.rawValue
                } else {
                    folderName = rawFolder
                }
                
                let sample = SampleFile(name: name, url: fileURL, category: folderName)
                
                if library[folderName] == nil {
                    library[folderName] = []
                }
                library[folderName]?.append(sample)
            }
        }
        
        print("📂 SampleLoader: Indexed \(library.values.reduce(0) { $0 + $1.count }) samples in \(library.keys.count) categories.")
        cachedLibrary = library
        return library
    }
    
    // Legacy support for PadLayout (uses random or first from category)
    static func loadSample(for type: String) -> URL? {
        let all = loadAllSamples()
        // Map old unique keys "Kick", "Snare" to folders
        // Simple heuristic: Search for key in folder name
        
        // Exact match first
        if let list = all[type], let first = list.first {
            return first.url
        }
        
        // Fuzzy match
        for (category, samples) in all {
            if category.localizedCaseInsensitiveContains(type) {
                return samples.first?.url
            }
        }
        
        // Fallback: If "TomLow", "TomMid" were passed, they might not match folder "Tom"
        // We need a mapping if we want to preserve exact PadLayout logic.
        return nil
    }
}
