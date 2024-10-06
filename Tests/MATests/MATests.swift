import Testing

@testable import MA

final class TestObject {
    let id: Int
    var counter = 0

    init(id: Int = 0) {
        self.id = id
    }

    func increment() {
        counter += 1
    }

    var square: Int { counter ^ 2 }
}

extension TestObject: Equatable {
    public static func == (lhs: TestObject, rhs: TestObject) -> Bool {
        lhs.id == rhs.id && lhs.counter == rhs.counter
    }
}

@Test func sanity() async throws {
    let allocator = MAContainer<TestObject>()

    let id1 = allocator.retain { .init(id: $0) }
    let id2 = allocator.retain { .init(id: $0) }
    let id3 = allocator.retain { .init(id: $0) }

    #expect(id1 != nil)
    #expect(id2 != nil)
    #expect(id3 != nil)

    guard let id1, let id2, let id3 else { return }

    allocator.update(with: id1) {
        $0.increment()
        for _ in 0 ..< id1 * id1 {
            $0.increment()
        }
    }

    allocator.update(with: id2) {
        $0.increment()
        for _ in 0 ..< id2 * id2 {
            $0.increment()
        }
    }

    allocator.update(with: id3) {
        $0.increment()
        for _ in 0 ..< id3 * id3 {
            $0.increment()
        }
    }

    var counters = allocator.map { $0 }

    #expect(counters.count == 3)
    #expect(counters[0].id == id1)
    #expect(counters[1].id == id2)
    #expect(counters[2].id == id3)
    #expect(counters[0].counter == 1)
    #expect(counters[1].counter == 2)
    #expect(counters[2].counter == 5)

    let item = allocator.find(by: id2)
    #expect(item == counters[1])

    #expect(allocator.release(id2) == true)

    counters = allocator.map { $0 }
    #expect(counters.count == 2)
    #expect(counters[0].id == id1)
    #expect(counters[1].id == id3)

    #expect(allocator.release(id2) == false)
    #expect(allocator.find(by: id2) == nil)

    item?.increment()

    let pointer = allocator.pointer(to: id3)
    #expect(pointer!.pointee == counters[1])
    pointer!.pointee.increment()

    let id4 = allocator.retain(.init(id: 1))
    #expect(id2 == id4)

    let id5 = allocator.retain { .init(id: $0) }
    #expect(id5 != nil)

    counters = allocator.map { $0 }

    #expect(counters.count == 4)
    #expect(counters[0].id == id1)
    #expect(counters[1].id == id4)
    #expect(counters[2].id == id3)
    #expect(counters[3].id == id5)
    #expect(counters[0].counter == 1)
    #expect(counters[1].counter == 0)
    #expect(counters[2].counter == 6)
    #expect(counters[3].counter == 0)

    let item6 = TestObject(id: 4)

    let id6 = allocator.retain(item6)
    #expect(id6 != nil)

    item6.counter += 3

    var timesPinged = 0

    // swiftformat:disable:next preferForLoop
    allocator.forEach {
        timesPinged += $0.counter
    }

    #expect(timesPinged == 10)

    allocator.releaseAll()

    counters = allocator.map { $0 }
    #expect(counters.count == 0)
}

@Test func size() async throws {
    let allocator = MAContainer<TestObject>(initialSize: -1)
    #expect(allocator.size == 4)

    let id1 = allocator.retain { .init(id: $0) }!
    let id2 = allocator.retain { .init(id: $0) }!
    let id3 = allocator.retain { .init(id: $0) }!
    let id4 = allocator.retain { .init(id: $0) }!
    let id5 = allocator.retain { .init(id: $0) }!

    #expect(id1 == 0)
    #expect(allocator.size == 5)

    allocator.release(id2)
    #expect(allocator.size == 5)

    allocator.release([id3, id4, id5])
    #expect(allocator.size == 5)

    let id6 = allocator.retain { .init(id: $0) }!
    #expect(allocator.size == 5)
    #expect(id5 == id6)

    allocator.retain { .init(id: $0) }
    allocator.retain { .init(id: $0) }
    allocator.retain { .init(id: $0) }
    allocator.retain { .init(id: $0) }

    #expect(allocator.size == 6)

    allocator.releaseAll(size: 2)
    #expect(allocator.size == 4)
    allocator.releaseAll(size: 16)
    #expect(allocator.size == 16)
    allocator.releaseAll() // Does not change the size of inner array
    #expect(allocator.size == 16)
}
