import Radare2

public protocol R2IOProvider: AnyObject, Sendable {
    func supports(path: String, many: Bool) -> Bool
    func open(path: String, access: R2IOAccess, mode: Int32) throws -> R2IOFile
}

public protocol R2IOFile: AnyObject, Sendable {
    func close() throws
    func read(at offset: UInt64, count: Int) throws -> [UInt8]
    func write(at offset: UInt64, bytes: [UInt8]) throws -> Int
    func size() throws -> UInt64
    func setSize(_ size: UInt64) throws
}

public protocol R2IOAsyncProvider: AnyObject, Sendable {
    func supports(path: String, many: Bool) -> Bool
    func open(path: String, access: R2IOAccess, mode: Int32) async throws -> R2IOAsyncFile
}

public protocol R2IOAsyncFile: AnyObject, Sendable {
    func close() async throws
    func read(at offset: UInt64, count: Int) async throws -> [UInt8]
    func write(at offset: UInt64, bytes: [UInt8]) async throws -> Int
    func size() async throws -> UInt64
    func setSize(_ size: UInt64) async throws
}

public struct R2IOAccess: OptionSet {
    public let rawValue: Int32

    public static let none = R2IOAccess([])
    public static let read = R2IOAccess(rawValue: 4)
    public static let write = R2IOAccess(rawValue: 2)
    public static let execute = R2IOAccess(rawValue: 1)

    public static let rw: R2IOAccess = [.read, .write]
    public static let rx: R2IOAccess = [.read, .execute]
    public static let wx: R2IOAccess = [.write, .execute]
    public static let rwx: R2IOAccess = [.read, .write, .execute]

    public static let shared = R2IOAccess(rawValue: 8)
    public static let priv = R2IOAccess(rawValue: 16)
    public static let access = R2IOAccess(rawValue: 32)
    public static let create = R2IOAccess(rawValue: 64)

    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static func from(rw: Int32) -> R2IOAccess {
        R2IOAccess(rawValue: rw)
    }
}
