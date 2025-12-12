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

    public var scrHtml: Bool {
        get { r_config_get_b(raw, "scr.html") }
        set { r_config_set_b(raw, "scr.html", newValue) }
    }

    public var scrUtf8: Bool {
        get { r_config_get_b(raw, "scr.utf8") }
        set { r_config_set_b(raw, "scr.utf8", newValue) }
    }

    public var scrColor: R2ColorMode {
        get { R2ColorMode(rawValue: UInt(r_config_get_i(raw, "scr.color")))! }
        set { r_config_set_i(raw, "scr.color", UInt64(newValue.rawValue)) }
    }

    public var cfgJsonNum: String {
        get { String(cString: r_config_get(raw, "cfg.json.num")) }
        set { r_config_set(raw, "cfg.json.num", newValue) }
    }

    public var asmEmu: Bool {
        get { r_config_get_b(raw, "asm.emu") }
        set { r_config_set_b(raw, "asm.emu", newValue) }
    }

    public var emuStr: Bool {
        get { r_config_get_b(raw, "emu.str") }
        set { r_config_set_b(raw, "emu.str", newValue) }
    }

    public var analCallingConvention: String {
        get { String(cString: r_config_get(raw, "anal.cc")) }
        set { r_config_set(raw, "anal.cc", newValue) }
    }

    public var asmOS: String {
        get { String(cString: r_config_get(raw, "asm.os")) }
        set { r_config_set(raw, "asm.os", newValue) }
    }

    public var asmArch: String {
        get { String(cString: r_config_get(raw, "asm.arch")) }
        set { r_config_set(raw, "asm.arch", newValue) }
    }

    public var asmBits: UInt64 {
        get { r_config_get_i(raw, "asm.bits") }
        set { r_config_set_i(raw, "asm.bits", newValue) }
    }
}

public enum R2ColorMode: UInt {
    case disabled = 0
    case mode16 = 1
    case mode256 = 2
    case mode16M = 3
}
