import Dispatch
import Radare2

public final class R2Core: @unchecked Sendable {
    let core: UnsafeMutablePointer<RCore>

    public let config: R2Config

    private var retainedProviders: [AnyObject] = []

    private let queue: DispatchQueue

    public init() {
        core = r_core_new()!

        queue = DispatchQueue(label: "swiftyr2.core")

        config = R2Config(
            raw: core.pointee.config!,
            run: { [queue] job in
                await withCheckedContinuation { cont in
                    queue.async {
                        job()
                        cont.resume()
                    }
                }
            })
    }

    deinit {
        queue.sync {
            _r2io_coreWillDeinit(core: core)
            r_core_free(core)
        }
    }

    @discardableResult
    public func openFile(
        uri: String,
        access: R2IOAccess = .rwx,
        loadAddress: UInt64 = 0
    ) async -> UnsafeMutablePointer<RIODesc>? {
        await run { r_core_file_open(self.core, uri, access.rawValue, loadAddress) }
    }

    @discardableResult
    public func binLoad(
        uri: String,
        loadAddress: UInt64 = 0
    ) async -> Bool {
        await run { r_core_bin_load(self.core, uri, loadAddress) }
    }

    @discardableResult
    public func cmd(_ command: String) async -> String {
        await run {
            let cStr = r_core_cmd_str(self.core, command)!
            defer { free(cStr) }
            return String(cString: cStr)
        }
    }

    public func registerIOPlugin(
        provider: R2IOProvider,
        uriSchemes: [String]
    ) async {
        await runVoid {
            _r2io_installPlugin(core: self.core, provider: provider, uriSchemes: uriSchemes)
            self.retainedProviders.append(provider as AnyObject)
        }
    }

    public func registerIOPlugin(
        asyncProvider: R2IOAsyncProvider,
        uriSchemes: [String]
    ) async {
        let adapter = R2IOAsyncProviderAdapter(asyncProvider: asyncProvider)

        await runVoid {
            _r2io_installPlugin(core: self.core, provider: adapter, uriSchemes: uriSchemes)
            self.retainedProviders.append(adapter)
        }
    }

    @inline(__always)
    func run<T>(_ job: @escaping () -> T) async -> T {
        await withCheckedContinuation { cont in
            queue.async {
                cont.resume(returning: job())
            }
        }
    }

    @inline(__always)
    func runVoid(_ job: @escaping () -> Void) async {
        await withCheckedContinuation { cont in
            queue.async {
                job()
                cont.resume()
            }
        }
    }
}
