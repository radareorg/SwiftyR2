import Radare2

public struct R2Config: Sendable {
    let raw: UnsafeMutablePointer<RConfig>

    let run: @Sendable (@escaping () -> Void) async -> Void

    @inline(__always)
    init(raw: UnsafeMutablePointer<RConfig>, run: @escaping @Sendable (@escaping () -> Void) async -> Void) {
        self.raw = raw
        self.run = run
    }

    public func set(_ key: String, bool value: Bool) async {
        await run { r_config_set_b(raw, key, value) }
    }

    public func set(_ key: String, int value: UInt64) async {
        await run { r_config_set_i(raw, key, value) }
    }

    public func set(_ key: String, int value: Int) async {
        await run { r_config_set_i(raw, key, UInt64(value)) }
    }

    public func set(_ key: String, string value: String) async {
        await run { r_config_set(raw, key, value) }
    }

    public func set(_ key: String, colorMode value: R2ColorMode) async {
        await run { r_config_set_i(raw, key, UInt64(value.rawValue)) }
    }
}

public enum R2ColorMode: Int32 {
    case disabled = 0
    case mode16 = 1
    case mode256 = 2
    case mode16M = 3
}
