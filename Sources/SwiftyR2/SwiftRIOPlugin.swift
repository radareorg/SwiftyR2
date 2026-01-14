import Radare2

internal func _r2io_installPlugin(
    core: UnsafeMutablePointer<RCore>,
    provider: R2IOProvider,
    uriSchemes: [String]
) {
    let mgr = pluginManager()

    let io = core.pointee.io!
    let state = mgr.state(for: io)

    state.providers.append(provider)

    state.uriSchemes.append(contentsOf: uriSchemes)
    var seenPerCore = Set<String>()
    state.uriSchemes = state.uriSchemes.filter { seenPerCore.insert($0).inserted }

    mgr.recomputeGlobalURIs()
    if mgr.globalURIs.isEmpty {
        swiftRIOPlugin.uris = nil
    } else {
        let joined = mgr.globalURIs.joined(separator: ",")
        swiftRIOPlugin.uris = UnsafePointer(strdup(joined))
    }

    if !state.isRegistered {
        r_io_plugin_add(io, &swiftRIOPlugin)
        state.isRegistered = true
    }
}

internal func _r2io_coreWillDeinit(core: UnsafeMutablePointer<RCore>) {
    let mgr = pluginManager()
    if let io = core.pointee.io {
        mgr.removeState(for: io)
        mgr.recomputeGlobalURIs()
        if mgr.globalURIs.isEmpty {
            swiftRIOPlugin.uris = nil
        } else {
            let joined = mgr.globalURIs.joined(separator: ",")
            swiftRIOPlugin.uris = UnsafePointer(strdup(joined))
        }
    }
}

private func pluginManager() -> PluginManager {
    if let raw = swiftRIOPlugin.data {
        return Unmanaged<PluginManager>.fromOpaque(raw).takeUnretainedValue()
    }

    let mgr = PluginManager()
    let raw = Unmanaged.passRetained(mgr).toOpaque()
    swiftRIOPlugin.data = raw
    return mgr
}

private final class PluginManager {
    var cores: [UInt: CoreState] = [:]
    var globalURIs: [String] = []

    func state(for io: UnsafeMutablePointer<RIO>) -> CoreState {
        let key = UInt(bitPattern: UnsafeRawPointer(io))
        if let existing = cores[key] {
            return existing
        }
        let new = CoreState()
        cores[key] = new
        return new
    }

    func removeState(for io: UnsafeMutablePointer<RIO>) {
        let key = UInt(bitPattern: UnsafeRawPointer(io))
        cores.removeValue(forKey: key)
    }

    func recomputeGlobalURIs() {
        var all: [String] = []
        var seen = Set<String>()
        for state in cores.values {
            for u in state.uriSchemes where seen.insert(u).inserted {
                all.append(u)
            }
        }
        globalURIs = all
    }
}

private final class CoreState {
    var isRegistered: Bool = false
    var uriSchemes: [String] = []
    var providers: [R2IOProvider] = []
}

private var swiftRIOPlugin: RIOPlugin = {
    let meta = makeMeta()

    return RIOPlugin(
        meta: meta,
        data: nil,
        uris: nil,
        listener: nil,
        isdbg: false,
        system: nil,
        open: swift_rio_open,
        open_many: nil,
        read: swift_rio_read,
        seek: swift_rio_seek,
        write: swift_rio_write,
        close: swift_rio_close,
        is_blockdevice: nil,
        is_chardevice: nil,
        getpid: nil,
        gettid: nil,
        getbase: nil,
        resize: swift_rio_resize,
        extend: nil,
        accept: nil,
        create: nil,
        check: swift_rio_check
    )
}()

private func makeMeta() -> RPluginMeta {
    var meta = RPluginMeta()
    meta.name = strdup("swift-io")
    meta.desc = strdup("Swift-based radare2 IO plugin")
    meta.author = strdup("SwiftyR2")
    meta.version = strdup("1.0.0")
    meta.license = strdup("MIT")
    meta.contact = strdup("https://github.com/frida/SwiftyR2")
    meta.copyright = strdup("(c) 2025 SwiftyR2")
    return meta
}

private let swift_rio_check:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafePointer<CChar>?,
        Bool
    ) -> Bool = { io, pathname, many in
        let path = String(cString: pathname!)
        return chooseProvider(io: io!, path: path, many: many) != nil
    }

private let swift_rio_open:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafePointer<CChar>?,
        Int32,
        Int32
    ) -> UnsafeMutablePointer<RIODesc>? = { io, pathname, rw, mode in
        let io = io!
        let pathname = pathname!

        let path = String(cString: pathname)
        let access = R2IOAccess.from(rw: rw)

        guard let provider = chooseProvider(io: io, path: path, many: false) else {
            return nil
        }

        let file: R2IOFile
        do {
            file = try provider.open(path: path, access: access, mode: mode)
        } catch {
            return nil
        }

        let box = FileBox(file: file, offset: 0)
        let opaque = UnsafeMutableRawPointer(Unmanaged.passRetained(box).toOpaque())

        return r_io_desc_new(io, &swiftRIOPlugin, path, rw, mode, opaque)
    }

private func chooseProvider(
    io: UnsafeMutablePointer<RIO>,
    path: String,
    many: Bool
) -> R2IOProvider? {
    let mgr = pluginManager()
    let state = mgr.state(for: io)
    for p in state.providers {
        if p.supports(path: path, many: many) {
            return p
        }
    }
    return nil
}

private let swift_rio_close: @convention(c) (UnsafeMutablePointer<RIODesc>?) -> Bool = { fd in
    let fd = fd!
    let data = fd.pointee.data!
    let box = Unmanaged<FileBox>.fromOpaque(data).takeRetainedValue()
    fd.pointee.data = nil

    try? box.file.close()
    return true
}

private let swift_rio_read:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafeMutablePointer<RIODesc>?,
        UnsafeMutablePointer<UInt8>?,
        Int32
    ) -> Int32 = { io, fd, buf, count in
        let io = io!
        let buf = buf!

        let box = fileBox(from: fd)
        let requested = Int(count)

        let bytes: [UInt8]
        do {
            bytes = try box.file.read(at: box.offset, count: requested)
        } catch {
            return -1
        }

        let n = min(bytes.count, requested)

        if n > 0 {
            _ = bytes.withUnsafeBufferPointer { src in
                memcpy(buf, src.baseAddress!, n)
            }
        }

        box.offset &+= UInt64(n)
        io.pointee.off = box.offset

        return Int32(n)
    }

private let swift_rio_write:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafeMutablePointer<RIODesc>?,
        UnsafePointer<UInt8>?,
        Int32
    ) -> Int32 = { io, fd, buf, count in
        let io = io!
        let buf = buf!

        let box = fileBox(from: fd)
        let len = Int(count)

        var bytes = [UInt8](repeating: 0, count: len)
        _ = bytes.withUnsafeMutableBufferPointer { dst in
            memcpy(dst.baseAddress!, buf, len)
        }

        let written: Int
        do {
            written = try box.file.write(at: box.offset, bytes: bytes)
        } catch {
            return -1
        }

        box.offset &+= UInt64(written)
        io.pointee.off = box.offset

        return Int32(written)
    }

private let swift_rio_seek:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafeMutablePointer<RIODesc>?,
        UInt64,
        Int32
    ) -> UInt64 = { io, fd, rawOffset, whence in
        let io = io!
        let box = fileBox(from: fd)

        let sizeU: UInt64
        do {
            sizeU = try box.file.size()
        } catch {
            return UInt64.max
        }

        let size: Int64 = sizeU > UInt64(Int64.max) ? Int64.max : Int64(sizeU)

        let curU = box.offset
        let cur: Int64 = curU > UInt64(Int64.max) ? Int64.max : Int64(curU)

        let signedOffset = Int64(bitPattern: rawOffset)

        var new: Int64

        switch whence {
        case SEEK_SET:
            new = signedOffset
        case SEEK_CUR:
            new = cur &+ signedOffset
        case SEEK_END:
            new = size &+ signedOffset
        default:
            return UInt64.max
        }

        if new < 0 { new = 0 }
        if new > size { new = size }

        let newU = UInt64(new)
        box.offset = newU
        io.pointee.off = newU

        return newU
    }

private let swift_rio_resize:
    @convention(c) (
        UnsafeMutablePointer<RIO>?,
        UnsafeMutablePointer<RIODesc>?,
        UInt64
    ) -> Bool = { io, fd, size in
        let io = io!
        let box = fileBox(from: fd)

        do {
            try box.file.setSize(size)
            let newSize = try box.file.size()
            if box.offset > newSize {
                box.offset = newSize
                io.pointee.off = newSize
            }
            return true
        } catch {
            return false
        }
    }

private final class FileBox {
    let file: R2IOFile
    var offset: UInt64

    init(file: R2IOFile, offset: UInt64) {
        self.file = file
        self.offset = offset
    }
}

private func fileBox(from fd: UnsafeMutablePointer<RIODesc>?) -> FileBox {
    let desc = fd!
    let data = desc.pointee.data!
    return Unmanaged<FileBox>.fromOpaque(data).takeUnretainedValue()
}
