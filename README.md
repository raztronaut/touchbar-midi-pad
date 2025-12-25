# Sleek

Sleek is a modern, high-performance macOS application built with SwiftUI and clean architecture principles. It features a robust audio engine for sample playback and sleek, native-compliant UI.

## Features

- **Modern UI**: Built entirely with SwiftUI, following the latest macOS design guidelines (unified title bar, sidebar).
- **Audio Engine**: Low-latency audio playback using `AVAudioEngine`.
- **MVVM Architecture**: Clean separation of concerns with verifiable business logic.
- **Project Generation**: Uses XcodeGen for deterministic project files.

## Installation

This project uses `XcodeGen` to generate the `.xcodeproj` file. Do not edit the project file directly.

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/sleek.git
    cd sleek
    ```

2.  **Generate the Xcode project**:
    ```bash
    xcodegen generate
    ```

3.  **Open the project**:
    open `Sleek.xcodeproj`

## Usage

- **Audio Playback**: Load samples via the main interface.
- **Settings**: Configure preferences via the standard macOS settings window.

## Development

### Architecture

- **Views**: declarative SwiftUI views.
- **ViewModels**: `ObservableObject` classes handling state and logic.
- **Services**: Protocol-based services for dependency injection.

### Testing

Run tests via Xcode or command line:
```bash
xcodebuild test -scheme Sleek -destination 'platform=macOS'
```

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
