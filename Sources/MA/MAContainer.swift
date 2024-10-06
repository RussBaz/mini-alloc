import Foundation

public final class MAContainer<T: AnyObject> {
    private var lock = NSLock()
    private var items: [T?]

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

        if let nextIndex {
            items[nextIndex] = item
            return nextIndex
        } else {
            let index = items.endIndex
            items.append(item)
            return index
        }
    }

    @discardableResult
    public func retain(_ item: T) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        let nextIndex = next.popLast()

        if let nextIndex {
            items[nextIndex] = item
            return nextIndex
        } else {
            let index = items.endIndex
            items.append(item)
            return index
        }
    }

    @discardableResult
    public func release(_ id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard id < items.endIndex else { return false }

        guard items[id] != nil else { return false }

        items[id] = nil
        next.append(id)

        return true
    }

    public func release(_ ids: [Int]) {
        lock.lock()
        defer { lock.unlock() }

        for id in ids {
            guard items[id] != nil else { continue }
            items[id] = nil
            next.append(id)
        }
    }

    public func find(by id: Int) -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items[id]
    }

    @discardableResult
    public func update<U>(with id: Int, using: (inout T) -> U) -> U? {
        lock.lock()
        defer { lock.unlock() }

        guard items[id] != nil else { return nil }

        return using(&items[id]!)
    }

    public func map<U>(using: (T) -> U) -> [U] {
        lock.lock()
        defer { lock.unlock() }

        return items.compactMap { item in
            guard let item else { return nil }
            return using(item)
        }
    }

    public func forEach(using: (T) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        for item in items {
            if let item {
                using(item)
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

        guard items[id] != nil else { return nil }

        return withUnsafeMutablePointer(to: &items[id]!) { $0 }
    }

    public var size: Int { items.count }
}
