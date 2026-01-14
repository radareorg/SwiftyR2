# SwiftyR2

[![CI](https://github.com/radareorg/SwiftyR2/actions/workflows/ci.yml/badge.svg)](https://github.com/radareorg/SwiftyR2/actions/workflows/ci.yml)

A Swift wrapper for Radare2, the popular reverse engineering framework. This package provides a modern, async/await-based Swift API for working with Radare2's powerful binary analysis capabilities.

## Features

- **Async/Await API**: Modern Swift concurrency support with async/await
- **Type Safety**: Strongly typed interfaces for Radare2 functionality
- **Cross-Platform**: Supports macOS 11+ and iOS 13+
- **Thread Safe**: Safe concurrent access to Radare2 core functionality

## Installation

Add SwiftyR2 to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/radareorg/SwiftyR2.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import SwiftyR2

// Create a new Radare2 core instance
let core = await R2Core.create()

// Execute a command and get the output
let output = await core.cmd("?V")
print("Radare2 version: \(output)")

// Access configuration
let config = core.config
await config.set("asm.arch", "x86")
```

### Working with Files

```swift
// Open a binary file
await core.cmd("o /path/to/binary")

// Analyze the binary
await core.cmd("aaa")

// Print function information
let functions = await core.cmd("afl")
print("Functions:\n\(functions)")
```

### Configuration

```swift
// Set analysis options
await core.config.set("analysis.depth", "10")
await core.config.set("asm.bits", "64")

// Get current settings
let arch = await core.config.get("asm.arch")
print("Current architecture: \(arch)")
```

## Requirements

- Swift 5.9+
- macOS 11.0+ or iOS 13.0+
- Xcode 14+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the same license as Radare2. See [LICENSE.md](LICENSE.md) for details.