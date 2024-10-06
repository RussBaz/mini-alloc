# Mini-Alloc

A basic, thread-safe, sparsed container to hold references to Swift objects.

The intended use case is when you need to create an unknown number of objects and pass them by reference to some C code, and be sure that they will not be garbage collected before the C code finishes processing of those objects.

It does not compact the internal storage, unless you run the `releaseAll` method and provide a new default size.

This project currently requires Swift 6.0+

Sample usage:

```swift
// Basic Usage
final class TestObject {
    var counter = 0
}

let allocator1 = MAContainer<TestObject>()

let id1 = allocator1.retain(TestObject())

// and when done
allocator1.release(id1)

// Or if your object requires knowing its own id

final class TestObjectWithId {
    let id: Int
    var counter = 0

    init(id: Int = 0) {
        self.id = id
    }
}

let allocator2 = MAContainer<TestObjectWithId>()

allocator2.retain { .init(id: $0) }
```

All methods:

```swift
init(initialSize size: Int = 8) // size states how much space to reserved for references

// T: AnyObject
@discardableResult func retain(using: (Int) -> T?) -> Int? // returns a retained object id
@discardableResult func retain(_ item: T) -> Int? // returns a retained object id

@discardableResult func release(_ id: Int) -> Bool // returns true only if a retained object with the given id was released
func release(_ ids: [Int])

func find(by id: Int) -> T? // returns a retained object if it exists

@discardableResult func update<U>(with id: Int, using: (inout T) -> U) -> U? // returns an update function result if the retained object with a given id is found

// do something with every retained object in the container
func map<U>(using: (T) -> U) -> [U]
func forEach(using: (T) -> Void)

func releaseAll(size: Int? = nil) // if the size is provided, it will resize the internal storage to the specified size. Otherwise, it will leave it as it is.

func pointer(to id: Int) -> UnsafeMutablePointer<T>? // returns a pointer to a retained object with the provided id if it exists
```

SPM installation:

- Add the package to your package dependencies

```swift
.package(url: "https://github.com/RussBaz/mini-alloc", from: "1.0.0"),
```

- Then add it to your target dependencies

```swift
.product(name: "MA", package: "mini-alloc"),
```
