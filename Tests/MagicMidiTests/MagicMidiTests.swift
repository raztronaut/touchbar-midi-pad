import XCTest
import AVFoundation
@testable import MagicMidi

final class MagicMidiTests: XCTestCase {
    
    func testPadLayoutGeneration() {
        let pads = PadLayout.generateDefault()
        
        // Assert 4x3 grid = 12 pads
        XCTAssertEqual(pads.count, 12, "Should generate exactly 12 pads for 4x3 grid")
        
        // Assert IDs are unique and in range 0-11
        let ids = pads.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(uniqueIds.count, 12, "Pad IDs must be unique")
        XCTAssertTrue(ids.allSatisfy { $0 >= 0 && $0 < 12 })
        
        // Verify Mapping (Random check)
        // Pad 0 should be Kick
        let kickPad = pads.first { $0.id == 0 }
        XCTAssertEqual(kickPad?.name, "Kick")
        
        // Pad 1 should be Snare
        let snarePad = pads.first { $0.id == 1 }
        XCTAssertEqual(snarePad?.name, "Snare")
    }
    
    func testSampleLoaderBundledResources() {
        // Test that we can find the resources we just copied
        // Assuming Bundle.main is the test bundle or app bundle? 
        // In Unit Tests, Bundle(for: Class) gives the Test Bundle. 
        // We need the App Bundle, or we need to ensure resources are in the Test Bundle too?
        // Usually unit tests run IN the app context (Host Application).
        
        // Let's test the logic. The logic uses `Bundle.main`.
        // If run as App Host, Bundle.main is the App.
        
        let kickURL = SampleLoader.loadSample(for: "Kick")
        XCTAssertNotNil(kickURL, "Kick sample should be found in Bundle")
        
        let snareURL = SampleLoader.loadSample(for: "Snare")
        XCTAssertNotNil(snareURL, "Snare sample should be found in Bundle")
        
        // "TomLow" likely maps to "Tom" folder fuzzy match or specific naming
        let tomURL = SampleLoader.loadSample(for: "Tom")
        XCTAssertNotNil(tomURL, "Tom sample should be found")
        
        let cowbellURL = SampleLoader.loadSample(for: "Bell")
        XCTAssertNotNil(cowbellURL, "Cowbell sample should be found")
        
        // Verify AIF support logic stays matching
        if let clapURL = SampleLoader.loadSample(for: "Clap") {
             XCTAssertTrue(["wav", "aif", "mp3"].contains(clapURL.pathExtension.lowercased()))
        }
    }
    
    func testExpandedLibrarySize() {
        let allSamples = SampleLoader.loadAllSamples()
        var totalCount = 0
        for (_, list) in allSamples {
            totalCount += list.count
        }
        print("Total Samples Found: \(totalCount)")
        XCTAssertTrue(totalCount > 50, "Should have expanded library loaded (found \(totalCount))")
    }
    
    func testAllPadsLoadValidAudioBuffers() {
        let pads = PadLayout.generateDefault()
        
        for pad in pads {
            guard let url = pad.sampleURL else {
                XCTFail("Pad \(pad.id) (\(pad.name)) has no sample URL")
                continue
            }
            
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                    XCTFail("Pad \(pad.id) (\(pad.name)): Could not create buffer")
                    continue
                }
                try file.read(into: buffer)
                XCTAssertTrue(buffer.frameLength > 0, "Pad \(pad.id): Buffer should not be empty")
            } catch {
                XCTFail("Pad \(pad.id) (\(pad.name)): Failed to read audio file - \(error)")
            }
        }
    }
    
    func testPadModelInitialization() {
        let pad = PadModel(id: 99, name: "Test", color: .red, sampleURL: nil)
        XCTAssertEqual(pad.id, 99)
        XCTAssertFalse(pad.isPressed)
        XCTAssertEqual(pad.pressure, 0.0)
    }
}
