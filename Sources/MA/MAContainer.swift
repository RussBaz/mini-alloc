import Foundation

public final class MAContainer<T: AnyObject> {
    private var lock = NSLock()
    private var items: [UnsafeMutablePointer<T>?]

    private var next: [Int]

    public init(initialSize size: Int = 8) {
        items = Array(repeating: nil, count: max(4, size))
        next = Array(items.indices.reversed())
    }

    @discardableResult
    public func retain(using: (Int) -> T?) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        let nextIndex = next.popLast()

        let item = using(nextIndex ?? next.endIndex)

        guard let item else { return nil }

        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: item)

        if let nextIndex {
            items[nextIndex] = pointer
            return nextIndex
        } else {
            let index = items.endIndex
            items.append(pointer)
            return index
        }
    }

    @discardableResult
    public func retain(_ item: consuming T) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        let nextIndex = next.popLast()

        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: item)

        if let nextIndex {
            items[nextIndex] = pointer
            return nextIndex
        } else {
            let index = items.endIndex
            items.append(pointer)
            return index
        }
    }

    @discardableResult
    public func release(_ id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard id < items.endIndex else { return false }

        guard let pointer = items[id] else { return false }

        pointer.deinitialize(count: 1)
        pointer.deallocate()
        items[id] = nil
        next.append(id)

        return true
    }

    public func release(_ ids: [Int]) {
        lock.lock()
        defer { lock.unlock() }

        for id in ids {
            guard let pointer = items[id] else { continue }

            pointer.deinitialize(count: 1)
            pointer.deallocate()
            items[id] = nil
            next.append(id)
        }
    }

    public func find(by id: Int) -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items[id]?.pointee
    }

    @discardableResult
    public func update<U>(with id: Int, using: (inout T) -> U) -> U? {
        lock.lock()
        defer { lock.unlock() }

        guard items[id] != nil else { return nil }

        return using(&items[id]!.pointee)
    }

    public func map<U>(using: (T) -> U) -> [U] {
        lock.lock()
        defer { lock.unlock() }

        return items.compactMap { pointer in
            guard let pointer else { return nil }
            return using(pointer.pointee)
        }
    }

    @available(*, deprecated, renamed: "each", message: "Please use the new function name in order to avoid accidentally triggering default swiftformat 'preferForLoop' rule.")
    public func forEach(using fn: (T) -> Void) {
        each(using: fn)
    }

    public func each(using: (T) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        for item in items {
            if let item {
                using(item.pointee)
            }
        }
    }

    public func releaseAll(size: Int? = nil) {
        lock.lock()
        defer { lock.unlock() }

        if let size {
            items = Array(repeating: nil, count: max(4, size))
        } else {
            for i in items.indices {
                items[i] = nil
            }
        }
        next = Array(items.indices.reversed())
    }

    public func pointer(to id: Int) -> UnsafeMutablePointer<T>? {
        lock.lock()
        defer { lock.unlock() }

        return items[id]
    }

    public var size: Int { items.count }
}
