import Radare2

public struct R2Config {
    let raw: UnsafeMutablePointer<RConfig>

    @inline(__always)
    init(_ raw: UnsafeMutablePointer<RConfig>) {
        self.raw = raw
    }

    public func set(_ key: String, bool value: Bool) {
        r_config_set_b(raw, key, value)
    }

    public func set(_ key: String, int value: UInt64) {
        r_config_set_i(raw, key, value)
    }

    public func set(_ key: String, int value: Int) {
        r_config_set_i(raw, key, UInt64(value))
    }

    public func set(_ key: String, string value: String) {
        r_config_set(raw, key, value)
    }

    public func set(_ key: String, colorMode value: R2ColorMode) {
        r_config_set_i(raw, key, UInt64(value.rawValue))
    }
}

public enum R2ColorMode: UInt {
    case disabled = 0
    case mode16 = 1
    case mode256 = 2
    case mode16M = 3
}
