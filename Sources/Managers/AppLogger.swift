import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.sleek.magicmidi"

    /// Logs related to the Audio Engine and processing
    static let audio = Logger(subsystem: subsystem, category: "Audio")

    /// Logs related to UI events and ViewModels
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// Logs related to data loading and resources
    static let resources = Logger(subsystem: subsystem, category: "Resources")
}
