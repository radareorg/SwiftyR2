import Darwin
import Radare2

public final class R2Core {
    private let core: UnsafeMutablePointer<RCore>

    public init() {
        self.core = r_core_new()!
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
