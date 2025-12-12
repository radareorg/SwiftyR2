import Radare2

public final class R2Core {
    let core: UnsafeMutablePointer<RCore>

    public var config: R2Config

    public init() {
        core = r_core_new()!
        config = R2Config(core.pointee.config!)
    }

    deinit {
        _r2io_coreWillDeinit(core: core)
        r_core_free(core)
    }

    @discardableResult
    public func openFile(
        uri: String,
        access: R2IOAccess = .rwx,
        loadAddress: UInt64 = 0
    ) -> UnsafeMutablePointer<RIODesc>? {
        r_core_file_open(core, uri, access.rawValue, loadAddress)
    }

    @discardableResult
    public func binLoad(
        uri: String,
        loadAddress: UInt64 = 0
    ) -> Bool {
        r_core_bin_load(core, uri, loadAddress)
    }

    @discardableResult
    public func cmd(_ command: String) -> String {
        let cResult = r_core_cmd_str(core, command)!
        defer { free(cResult) }
        return String(cString: cResult)
    }

    public func beginTaskSync() {
        withUnsafeMutablePointer(to: &core.pointee.tasks) { tasksPtr in
            r_core_task_sync_begin(tasksPtr)
        }
    }

    public func registerIOPlugin(provider: R2IOProvider, uriSchemes: [String]) {
        _r2io_installPlugin(
            core: core,
            provider: provider,
            uriSchemes: uriSchemes
        )
    }
}
