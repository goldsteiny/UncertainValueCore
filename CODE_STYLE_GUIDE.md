# Swift Coding Style Guide

## Core Philosophy

Write code that reads like well-structured declarations: define types, compose transformations, return results. Prefer **value types and functional patterns** over mutable state and imperative loops. Code should explain itself through structure and naming, not comments.

---

## Swift's Functional Patterns

### Prefer declarative over imperative

```swift
// ✗ Avoid
var result: [Int] = []
for x in values {
    if x > 0 {
        result.append(x * x)
    }
}

// ✓ Prefer
let result = values.filter { $0 > 0 }.map { $0 * $0 }
```

### Chain higher-order functions for data pipelines

```swift
let normalized = measurements
    .filter { $0.isValid }
    .map { $0.value }
    .map { $0 / maxValue }
```

### Use `compactMap` to filter and transform simultaneously

```swift
// ✗ Separate filter + map
let validIds = responses.filter { $0.id != nil }.map { $0.id! }

// ✓ Single pass
let validIds = responses.compactMap { $0.id }
```

### Leverage `reduce` for aggregation

```swift
let total = transactions.reduce(0) { $0 + $1.amount }
let grouped = items.reduce(into: [:]) { dict, item in
    dict[item.category, default: []].append(item)
}
```

---

## Value Types and Immutability

### Default to `let`, use `var` only when mutation is necessary

```swift
// ✓ Immutable by default
let config = Configuration(timeout: 30, retries: 3)

// Only when mutation is the point
var accumulator = 0
for value in values { accumulator += value }
// But prefer: let total = values.reduce(0, +)
```

### Prefer structs over classes

Classes are for reference semantics, identity, and inheritance. Most domain models should be structs.

```swift
// ✓ Value type for data
struct Measurement {
    let timestamp: Date
    let value: Double
    let unit: Unit
}

// ✓ Class when identity matters
class NetworkSession {
    private var activeRequests: [UUID: Task<Data, Error>] = [:]
}
```

### Use `mutating` methods sparingly

If a method transforms data, prefer returning a new value:

```swift
// ✗ Mutates in place
extension Array {
    mutating func filterInPlace(_ isIncluded: (Element) -> Bool) { ... }
}

// ✓ Returns transformed copy (unless performance-critical)
let filtered = original.filter(isIncluded)
```

---

## Clean Code Principles

### Single Responsibility

Each function/type does exactly one thing. If you need "and" to describe it, split it.

```swift
// ✗ Does too much
func processAndSaveData(_ data: [Record], to url: URL) throws {
    let cleaned = data.filter { $0.isValid }
    let normalized = cleaned.map { normalize($0) }
    let encoded = try JSONEncoder().encode(normalized)
    try encoded.write(to: url)
}

// ✓ Separated concerns
func clean(_ records: [Record]) -> [Record] {
    records.filter(\.isValid)
}

func normalize(_ records: [Record]) -> [NormalizedRecord] {
    records.map(normalize)
}

func save(_ data: Encodable, to url: URL) throws {
    try JSONEncoder().encode(data).write(to: url)
}

// Compose at call site
try save(normalize(clean(data)), to: url)
```

### Meaningful Names Over Comments

```swift
// ✗ Comment explaining unclear code
// Check if user can access premium features
let x = u.s == .a && u.e > Date()

// ✓ Names explain intent
let hasActiveSubscription = user.subscriptionStatus == .active 
    && user.subscriptionExpiry > Date.now
```

### DRY: Extract patterns into functions or extensions

```swift
// ✗ Repeated pattern
let aliceAvg = alice.scores.reduce(0, +) / Double(alice.scores.count)
let bobAvg = bob.scores.reduce(0, +) / Double(bob.scores.count)

// ✓ Extracted
extension Collection where Element: BinaryFloatingPoint {
    var average: Element {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Element(count)
    }
}

let aliceAvg = alice.scores.average
let bobAvg = bob.scores.average
```

### Useful Abstraction Levels

Create extensions and helper types that:
1. Hide implementation details
2. Give meaningful names to operations
3. Enable reuse without copy-paste

```swift
// Domain-specific vocabulary
extension Array where Element == Transaction {
    var totalAmount: Decimal {
        reduce(0) { $0 + $1.amount }
    }
    
    func grouped(by period: Calendar.Component) -> [Date: [Transaction]] {
        Dictionary(grouping: self) { Calendar.current.startOfDay(for: $0.date) }
    }
}
```

---

## Protocol-Oriented Design

### Define behavior through protocols

```swift
protocol Validatable {
    var isValid: Bool { get }
}

protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

// Conformance adds capability
struct User: Validatable, Identifiable {
    let id: UUID
    let email: String
    
    var isValid: Bool { email.contains("@") }
}
```

### Use protocol extensions for shared implementation

```swift
extension Collection where Element: Validatable {
    var allValid: Bool { allSatisfy(\.isValid) }
    var validElements: [Element] { filter(\.isValid) }
}

// Now any collection of Validatable types gets these for free
let validUsers = users.validElements
```

### Prefer composition over inheritance

```swift
// ✗ Deep inheritance hierarchy
class Vehicle { }
class Car: Vehicle { }
class ElectricCar: Car { }
class TeslaModelS: ElectricCar { }

// ✓ Composed capabilities
protocol Drivable { func drive() }
protocol Electric { var batteryLevel: Double { get } }
protocol Autonomous { func enableAutopilot() }

struct Tesla: Drivable, Electric, Autonomous {
    var batteryLevel: Double
    func drive() { ... }
    func enableAutopilot() { ... }
}
```

---

## Error Handling

### Use typed errors

```swift
enum NetworkError: Error {
    case noConnection
    case timeout(after: TimeInterval)
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
}

// Caller can handle specific cases
do {
    let data = try await fetch(url)
} catch NetworkError.timeout(let duration) {
    logger.warn("Request timed out after \(duration)s")
} catch NetworkError.noConnection {
    showOfflineUI()
} catch {
    logger.error("Unexpected: \(error)")
}
```

### Prefer `throws` over optionals for recoverable errors

```swift
// ✗ Loses error information
func parse(_ json: Data) -> User? {
    try? JSONDecoder().decode(User.self, from: json)
}

// ✓ Preserves error context
func parse(_ json: Data) throws -> User {
    try JSONDecoder().decode(User.self, from: json)
}
```

### Use `Result` for async callbacks (pre-async/await)

```swift
func fetch(completion: @escaping (Result<Data, NetworkError>) -> Void)
```

---

## Optionals: Complete Guide

Optionals represent the presence or absence of a value. Swift provides multiple tools—choose based on context.

### Decision Tree

```
Do you need the unwrapped value for multiple statements?
├─ Yes → guard let (early exit) or if let (scoped)
└─ No, just transforming or providing default
   ├─ Need default value? → ?? (nil coalescing)
   ├─ Need to access property/method? → ?. (optional chaining)  
   ├─ Need to transform value? → .map { }
   └─ Transform returns optional? → .flatMap { }
```

### `guard let` — Early exit, value available for rest of scope

Use when: The unwrapped value is needed for the remainder of the function, and absence means you should exit early.

```swift
func processUser(_ user: User?) {
    guard let user else { return }
    
    // `user` is non-optional for all code below
    updateProfile(user)
    syncPreferences(user)
    sendWelcomeEmail(user)
}

func loadConfig(from path: String?) throws -> Config {
    guard let path else {
        throw ConfigError.missingPath
    }
    guard let data = FileManager.default.contents(atPath: path) else {
        throw ConfigError.fileNotFound(path)
    }
    return try JSONDecoder().decode(Config.self, from: data)
}
```

### `if let` — Conditional execution, limited scope

Use when: You only need the value for a specific branch, or have meaningful else logic.

```swift
if let cached = cache[key] {
    return cached
} else {
    let computed = expensiveComputation()
    cache[key] = computed
    return computed
}

// Also useful for conditional side effects
if let delegate {
    delegate.didComplete(self)
}
```

### `?.` (Optional Chaining) — Access properties/methods, propagate nil

Use when: Accessing a property or calling a method on an optional, and nil should propagate.

```swift
// Returns String? — nil if user is nil, otherwise user's name
let name = user?.name

// Chain multiple levels — nil anywhere short-circuits
let cityName = user?.address?.city?.name

// Call methods — returns Void? (usually discarded)
user?.saveChanges()

// Combine with nil coalescing for defaults
let displayName = user?.profile?.displayName ?? "Anonymous"
```

**Key insight**: `?.` always returns an optional. `user?.name` is `String?` even if `name` is `String`.

### `??` (Nil Coalescing) — Provide default value

Use when: You have a sensible default for the nil case.

```swift
let timeout = customTimeout ?? 30
let username = user?.name ?? "Guest"
let items = fetchedItems ?? []

// Chain for fallback hierarchy
let locale = userPreference ?? systemLocale ?? Locale(identifier: "en_US")
```

**Avoid** when the default masks a bug or when nil represents an error condition that should be handled explicitly.

### `.map` on Optional — Transform if present, stay optional

Use when: You want to transform a value if it exists, but keep the result optional.

**Signature**: `Optional<T>.map<U>((T) -> U) -> Optional<U>`

```swift
// Transform optional value
let uppercased: String? = name.map { $0.uppercased() }

// Equivalent to:
let uppercased: String? = name != nil ? name!.uppercased() : nil

// With nil coalescing for final value
let displayName = user.map { "\($0.firstName) \($0.lastName)" } ?? "Unknown"
```

**When to use `.map` vs `?.`**:

```swift
// Use ?. for simple property access
let length = name?.count

// Use .map when transformation involves the whole value
let formatted = date.map { formatter.string(from: $0) }
let doubled = number.map { $0 * 2 }

// Use .map when you need to call a free function
let parsed = jsonString.map { try? JSONDecoder().decode(Config.self, from: $0) }
```

### `.flatMap` on Optional — Transform to optional, flatten

Use when: Your transformation itself returns an optional, and you want to avoid `Optional<Optional<T>>`.

**Signature**: `Optional<T>.flatMap<U>((T) -> Optional<U>) -> Optional<U>`

```swift
// URL.init(string:) returns URL?, so use flatMap
let url: URL? = urlString.flatMap { URL(string: $0) }
// or: urlString.flatMap(URL.init(string:))

// vs map which would give URL??
let badUrl: URL?? = urlString.map { URL(string: $0) }  // ✗ Nested optional

// Chain transformations that may fail
let port: Int? = urlString
    .flatMap { URL(string: $0) }
    .flatMap { $0.port }

// Dictionary lookup returns optional
let value: Int? = key.flatMap { dict[$0] }
```

**Rule of thumb**: If your closure returns `T`, use `.map`. If it returns `T?`, use `.flatMap`.

### `compactMap` on Collections — Filter nils while transforming

Use when: Mapping over a collection where some transformations fail (return nil).

```swift
// Parse valid URLs only
let urls: [URL] = strings.compactMap { URL(string: $0) }

// Extract non-nil properties
let names: [String] = users.compactMap { $0.middleName }

// Equivalent to filter + map, but single pass
let valid = items.compactMap { item -> ProcessedItem? in
    guard item.isValid else { return nil }
    return process(item)
}
```

### Force Unwrap `!` — When you have proof

Use **only** when:
1. You have compile-time certainty (e.g., static strings for URL/Regex)
2. In tests where failure should crash
3. After a check that the compiler can't see

```swift
// ✓ Static string, guaranteed valid
let googleURL = URL(string: "https://google.com")!

// ✓ Regex literal (compiler validates)
let pattern = try! Regex("[a-z]+")

// ✓ After external validation compiler can't see
let value = dictionary["requiredKey"]!  // Only if you control the dictionary contents

// ✗ Never on user input or external data
let url = URL(string: userInput)!  // Will crash
```

### Combining Techniques

```swift
// Chain optional access, transform, provide default
let bio = user?.profile.map { $0.biography.prefix(100) }.map(String.init) ?? "No bio"

// Multiple optional dependencies
func fullAddress() -> String? {
    guard let street, let city, let zip else { return nil }
    return "\(street), \(city) \(zip)"
}

// Pattern: Optional binding with where clause
if let age = user?.age, age >= 18 {
    showAdultContent()
}

// Pattern: switch on optional
switch optionalValue {
case .some(let value):
    process(value)
case .none:
    handleMissing()
}
```

### Anti-patterns to avoid

```swift
// ✗ Redundant nil check before ?.
if user != nil {
    user?.doSomething()  // The ?. already handles nil
}
// ✓ Just use ?.
user?.doSomething()

// ✗ Force unwrap after nil check
if user != nil {
    process(user!)
}
// ✓ Use binding
if let user {
    process(user)
}

// ✗ Overcomplicated: .map that just returns the value
let x = optional.map { $0 } ?? defaultValue
// ✓ Direct nil coalescing
let x = optional ?? defaultValue

// ✗ Using .map just to access a property
let name = user.map { $0.name }
// ✓ Optional chaining
let name = user?.name

// ✗ Nested nil checks
if let a = optionalA {
    if let b = a.optionalB {
        use(b)
    }
}
// ✓ Chained binding
if let b = optionalA?.optionalB {
    use(b)
}
```

---

## Concurrency (Swift Concurrency)

### Use structured concurrency

```swift
// ✓ Automatic cancellation, clear lifetime
func fetchAllData() async throws -> [Data] {
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask { try await fetch(url) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

### Isolate mutable state with actors

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    
    func image(for url: URL) -> UIImage? {
        cache[url]
    }
    
    func store(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}
```

### Mark async boundaries explicitly

```swift
// ✓ Clear where suspension can occur
func loadProfile() async throws -> Profile {
    let userData = try await api.fetchUser()      // suspension point
    let preferences = try await api.fetchPrefs()  // suspension point
    return Profile(user: userData, preferences: preferences)
}
```

---

## Type Design

### Use enums with associated values for state machines

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}

// Exhaustive switch ensures all states handled
switch state {
case .idle: showPlaceholder()
case .loading: showSpinner()
case .loaded(let data): display(data)
case .failed(let error): showError(error)
}
```

### Leverage phantom types for compile-time safety

```swift
struct Identifier<T>: Hashable {
    let rawValue: String
}

struct User { let id: Identifier<User> }
struct Order { let id: Identifier<Order> }

// Can't accidentally pass user ID where order ID expected
func fetchOrder(id: Identifier<Order>) async throws -> Order
```

### Use typealiases for domain clarity

```swift
typealias Euros = Decimal
typealias Kilometers = Double
typealias UserID = UUID

func calculateShipping(distance: Kilometers) -> Euros
```

---

## What to Avoid

### No stringly-typed APIs

```swift
// ✗ Error-prone, no autocomplete
NotificationCenter.default.post(name: NSNotification.Name("userLoggedIn"), ...)

// ✓ Type-safe
extension Notification.Name {
    static let userLoggedIn = Notification.Name("userLoggedIn")
}
NotificationCenter.default.post(name: .userLoggedIn, ...)
```

### No Any unless absolutely necessary

```swift
// ✗ Loses type information
func process(_ items: [Any]) { ... }

// ✓ Generic constraint
func process<T: Processable>(_ items: [T]) { ... }
```

### No massive view controllers / god objects

Split responsibilities. Use composition. Extract coordinators, view models, services.

### No deeply nested closures

```swift
// ✗ Callback hell
fetchUser { user in
    fetchOrders(for: user) { orders in
        fetchDetails(for: orders) { details in
            // ...
        }
    }
}

// ✓ Async/await
let user = try await fetchUser()
let orders = try await fetchOrders(for: user)
let details = try await fetchDetails(for: orders)
```

### No magic numbers or strings

```swift
// ✗ What is 86400?
let expiry = Date().addingTimeInterval(86400)

// ✓ Self-documenting
let expiry = Date().addingTimeInterval(.days(1))

extension TimeInterval {
    static func days(_ n: Int) -> TimeInterval { Double(n) * 24 * 60 * 60 }
}
```

---

## Testing

### Write testable code by using dependency injection

```swift
// ✗ Hard to test
struct OrderService {
    func placeOrder() async throws {
        let api = APIClient()  // hidden dependency
        try await api.submit(order)
    }
}

// ✓ Injectable dependency
struct OrderService {
    let api: APIClientProtocol
    
    func placeOrder() async throws {
        try await api.submit(order)
    }
}

// Test with mock
let mock = MockAPIClient()
let service = OrderService(api: mock)
```

### Prefer pure functions—they're trivially testable

```swift
// Pure: same input → same output, no side effects
func calculateDiscount(subtotal: Decimal, couponCode: String?) -> Decimal {
    guard let code = couponCode, validCoupons.contains(code) else { return 0 }
    return subtotal * 0.1
}

// Test is straightforward
XCTAssertEqual(calculateDiscount(subtotal: 100, couponCode: "SAVE10"), 10)
XCTAssertEqual(calculateDiscount(subtotal: 100, couponCode: nil), 0)
```

---

## Summary Checklist

Before committing code, verify:

- [ ] Functions do one thing
- [ ] Names describe intent without needing comments  
- [ ] No repeated code patterns (DRY)
- [ ] Loops replaced with `map`/`filter`/`reduce` where appropriate
- [ ] Value types (`struct`) preferred over reference types (`class`)
- [ ] `let` by default, `var` only when mutation required
- [ ] Optionals handled gracefully (no force unwraps in production)
- [ ] Errors are typed and informative
- [ ] Protocols define behavior, extensions provide defaults
- [ ] No magic numbers or stringly-typed APIs
- [ ] Concurrency uses structured async/await patterns
- [ ] Dependencies are injectable for testability
