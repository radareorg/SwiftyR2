import Radare2

public final class R2Core {
    let core: UnsafeMutablePointer<RCore>

    public var config: R2Config

    public init() {
        core = r_core_new()!
        config = R2Config(core.pointee.config!)
    }

    deinit {
        r_core_free(core)
    }

    @discardableResult
    public func cmd(_ command: String) -> String {
        return command.withCString { cCommand -> String in
            let rawPtr = r_core_cmd_str(core, cCommand)!
            defer {
                free(rawPtr)
            }
            return String(cString: rawPtr)
        }
    }
}
