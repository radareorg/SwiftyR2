import Foundation
import Radare2

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

public final class R2Core: @unchecked Sendable {
    let core: UnsafeMutablePointer<RCore>
    public let config: R2Config

    private var retainedProviders: [AnyObject] = []
    private let executor: CoreThreadExecutor

    public static func create() async -> R2Core {
        let executor = CoreThreadExecutor()

        let core: UnsafeMutablePointer<RCore> = await withCheckedContinuation { cont in
            executor.submit {
                cont.resume(returning: r_core_new()!)
            }
        }

        return R2Core(core: core, executor: executor)
    }

    private init(core: UnsafeMutablePointer<RCore>, executor: CoreThreadExecutor) {
        self.core = core
        self.executor = executor
        self.config = R2Config(
            raw: core.pointee.config!,
            run: { [executor] job in
                await withCheckedContinuation { cont in
                    executor.submit {
                        job()
                        cont.resume()
                    }
                }
            }
        )
    }

    deinit {
        let core = self.core
        let executor = self.executor

        executor.submit { [executor] in
            _r2io_coreWillDeinit(core: core)
            r_core_free(core)

            executor.stop()
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
            executor.submit {
                cont.resume(returning: job())
            }
        }
    }

    @inline(__always)
    func runVoid(_ job: @escaping () -> Void) async {
        await withCheckedContinuation { cont in
            executor.submit {
                job()
                cont.resume()
            }
        }
    }
}

private final class CoreThreadExecutor {
    private let condition = NSCondition()
    private var jobs: [() -> Void] = []
    private var stopped = false

    private var thread: Thread!
    private var pthreadID: pthread_t? = nil

    init() {
        thread = Thread { [weak self] in
            self?.runLoop()
        }
        thread.name = "org.radare.swiftyr2.core"
        thread.qualityOfService = .userInitiated
        thread.start()
    }

    deinit {
        stop()
    }

    private func runLoop() {
        pthreadID = pthread_self()

        while true {
            condition.lock()
            while jobs.isEmpty && !stopped {
                condition.wait()
            }

            if stopped && jobs.isEmpty {
                condition.unlock()
                return
            }

            let job = jobs.removeFirst()
            condition.unlock()

            autoreleasepool {
                job()
            }
        }
    }

    private func isOnCoreThread() -> Bool {
        guard let tid = pthreadID else { return false }
        return pthread_equal(pthread_self(), tid) != 0
    }

    func submit(_ job: @escaping () -> Void) {
        if isOnCoreThread() {
            job()
            return
        }

        condition.lock()
        jobs.append(job)
        condition.signal()
        condition.unlock()
    }

    func stop() {
        condition.lock()
        stopped = true
        condition.signal()
        condition.unlock()
    }
}
