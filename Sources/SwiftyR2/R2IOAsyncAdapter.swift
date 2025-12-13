#if canImport(Dispatch)
    import Dispatch
    import Radare2

    extension R2Core {
        public func registerIOPlugin(
            asyncProvider: R2IOAsyncProvider,
            uriSchemes: [String]
        ) {
            let adapter = R2IOAsyncProviderAdapter(asyncProvider: asyncProvider)
            _r2io_installPlugin(
                core: core,
                provider: adapter,
                uriSchemes: uriSchemes
            )
        }
    }

    public final class R2IOAsyncProviderAdapter: R2IOProvider, @unchecked Sendable {
        private let asyncProvider: R2IOAsyncProvider

        public init(asyncProvider: R2IOAsyncProvider) {
            self.asyncProvider = asyncProvider
        }

        public func supports(path: String, many: Bool) -> Bool {
            asyncProvider.supports(path: path, many: many)
        }

        public func open(path: String, access: R2IOAccess, mode: Int32) throws -> R2IOFile {
            let asyncFile = try blockingFromAsyncThrowing { [self] in
                try await self.asyncProvider.open(path: path, access: access, mode: mode)
            }
            return R2IOAsyncFileAdapter(asyncFile: asyncFile)
        }
    }

    public final class R2IOAsyncFileAdapter: R2IOFile, @unchecked Sendable {
        private let asyncFile: R2IOAsyncFile

        public init(asyncFile: R2IOAsyncFile) {
            self.asyncFile = asyncFile
        }

        public func close() throws {
            _ = try blockingFromAsyncThrowing { [self] in
                try await self.asyncFile.close()
            }
        }

        public func read(at offset: UInt64, count: Int) throws -> [UInt8] {
            try blockingFromAsyncThrowing { [self] in
                try await self.asyncFile.read(at: offset, count: count)
            }
        }

        public func write(at offset: UInt64, bytes: [UInt8]) throws -> Int {
            try blockingFromAsyncThrowing { [self] in
                try await self.asyncFile.write(at: offset, bytes: bytes)
            }
        }

        public func size() throws -> UInt64 {
            try blockingFromAsyncThrowing { [self] in
                try await self.asyncFile.size()
            }
        }

        public func setSize(_ size: UInt64) throws {
            _ = try blockingFromAsyncThrowing { [self] in
                try await self.asyncFile.setSize(size)
            }
        }
    }

    private func blockingFromAsyncThrowing<T>(
        _ body: @escaping () async throws -> T
    ) throws -> T {
        let sema = DispatchSemaphore(value: 0)
        var result: Result<T, Error>!

        Task.detached {
            do {
                let value = try await body()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            sema.signal()
        }

        sema.wait()

        switch result! {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
#endif  // canImport(Dispatch)
