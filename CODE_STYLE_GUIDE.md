# Domain-Driven Swift Style Guide

## Why This Guide Exists
This codebase is moving to domain-driven development, but DDD is not a license for verbose or repetitive code.

The target state is:
1. Domain-first modeling
2. Clear ownership boundaries
3. Maintainable, readable Swift
4. DRY code with deliberate helper placement

---

## Non-Negotiables

1. Model business rules in domain types, not scattered UI/services.
2. Keep a single source of truth for each rule.
3. Do not copy-paste similar logic into "header variants" of the same function.
4. If logic repeats, extract it to the correct layer/file.
5. Prefer explicit names over comments explaining unclear code.

---

## Layering and Dependency Direction

1. Domain: entities, value objects, domain services, invariants.
2. Application: use-case orchestration and coordination.
3. Infrastructure: SwiftData, protobuf, network, file IO.
4. Presentation: SwiftUI + view models.

Dependency direction must point inward:
- Presentation -> Application -> Domain
- Infrastructure depends on Domain contracts, never vice versa.

---

## Ubiquitous Language

1. Use business terms in type names and methods.
2. One concept gets one name across the codebase.
3. Avoid vague names like `Helper`, `Manager`, `doStuff`, `handle`.

Good:
```swift
struct ReimbursementSettlement {
    let reimbursableID: AccountTransactionID
    let reimbursementID: AccountTransactionID
}
```

Bad:
```swift
struct LinkInfo {
    let id1: Int64
    let id2: Int64
}
```

---

## DRY Extraction Rules (Practical)

Use this exact escalation path for repeated code.

1. Repeated twice in the same function:
- Extract a local private function.

2. Repeated across functions in the same file:
- Extract a file-private helper/type in that file.

3. Repeated across files in the same feature:
- Move to `Features/<Feature>/Components/` or `Features/<Feature>/Models/`.

4. Repeated across multiple features:
- Move to domain/application/shared utility with domain meaning.

5. Repeated UI constants/formatting:
- Move to `AppConstants.swift` / formatter utilities.

Do not skip straight to a global utility unless reuse is truly cross-context.

---

## Helper Placement Matrix

1. Domain rule helper:
- Place in `Domain/` near the owning concept.

2. Aggregate invariant helper:
- Place on aggregate/value object as private/internal method.

3. Mapping helper (domain <-> persistence/proto):
- Place in mapper/converter files in `Domain/Mappers/` or infrastructure converter folder.

4. Feature UI helper (view composition only):
- Place in feature `Components/`.

5. Formatting/parsing helper used app-wide:
- Place in `Utilities/` with explicit domain name.

Bad placement example:
- Putting tax validation logic in a SwiftUI view file.

---

## Good/Bad Swift Style Examples (DDD + DRY)

### 1) Repeated Header Variants of the Same Function

Bad:
```swift
func buildPaymentRow(amount: MonetaryAmount, note: String?) -> RowModel { ... }
func buildPaymentRow(amount: MonetaryAmount, note: String?, tag: String?) -> RowModel { ... }
func buildPaymentRow(amount: MonetaryAmount, note: String?, tag: String?, date: Date?) -> RowModel { ... }
```

Good:
```swift
struct PaymentRowInput {
    let amount: MonetaryAmount
    let note: String?
    let tag: String?
    let date: Date?
}

func buildPaymentRow(_ input: PaymentRowInput) -> RowModel { ... }
```

Why:
1. One stable API surface
2. Fewer copy-paste branches
3. Easier evolution without overload explosion

### 2) Business Rule Duplicated in Multiple Services

Bad:
```swift
// Service A
if transaction.kind == .timeSpent && account.accountType != .time {
    throw ValidationError.invalidAccount
}

// Service B
if transaction.kind == .timeSpent && account.accountType != .time {
    throw ValidationError.invalidAccount
}
```

Good:
```swift
extension Transaction {
    func validateCompatibility(with account: BankAccount) throws {
        if kind == .timeSpent && account.accountType != .time {
            throw ValidationError.invalidAccount
        }
    }
}

// Service A / B
try transaction.validateCompatibility(with: account)
```

Why:
- The rule is owned by domain behavior, not orchestrators.

### 3) Stringly-Typed Domain Branching

Bad:
```swift
if transactionType == "income" { ... }
if transactionType == "reimbursement" { ... }
```

Good:
```swift
enum TransactionKind {
    case income(IncomeInfo)
    case reimbursement(ReimbursementInfo)
}

switch transaction.kind {
case .income(let info):
    ...
case .reimbursement(let info):
    ...
}
```

### 4) Domain Logic in View Layer

Bad:
```swift
struct AccountTransactionEditorView: View {
    var body: some View {
        Button("Save") {
            if transaction.kind == .taxPayment && transaction.taxType == .unknown {
                error = "Tax type required"
            }
        }
    }
}
```

Good:
```swift
struct AccountTransactionEditorView: View {
    let onSave: () -> Void

    var body: some View {
        Button("Save", action: onSave)
    }
}

struct SaveTransactionUseCase {
    func execute(_ transaction: Transaction) throws {
        try TaxTransactionValidator.validate(transaction)
        // persist...
    }
}
```

### 5) Repeated Filtering/Grouping Pipelines

Bad:
```swift
let janPayments = transactions
    .filter { $0.kind == .payment }
    .filter { Calendar.current.component(.month, from: $0.record.time) == 1 }

let febPayments = transactions
    .filter { $0.kind == .payment }
    .filter { Calendar.current.component(.month, from: $0.record.time) == 2 }
```

Good:
```swift
extension Collection where Element == Transaction {
    func payments(in month: Int, calendar: Calendar = .current) -> [Transaction] {
        filter {
            $0.kind == .payment &&
            calendar.component(.month, from: $0.record.time) == month
        }
    }
}

let janPayments = transactions.payments(in: 1)
let febPayments = transactions.payments(in: 2)
```

### 6) Copy-Pasted Mapper Branches

Bad:
```swift
func applyPayment(_ info: OutflowInfo, to model: AccountTransaction) {
    model.transactionCategory = .outflow
    model.outflowTarget = info.target
    model.taxCategory = info.taxCategory
}

func applyGiveAway(_ info: OutflowInfo, to model: AccountTransaction) {
    model.transactionCategory = .outflow
    model.outflowTarget = info.target
    model.taxCategory = info.taxCategory
}
```

Good:
```swift
private func applyOutflowBase(_ info: OutflowInfo, to model: AccountTransaction) {
    model.transactionCategory = .outflow
    model.outflowTarget = info.target
    model.taxCategory = info.taxCategory
}

func applyPayment(_ info: OutflowInfo, to model: AccountTransaction) {
    applyOutflowBase(info, to: model)
    model.transactionKindCode = TransactionKindCode.payment.rawValue
}

func applyGiveAway(_ info: OutflowInfo, to model: AccountTransaction) {
    applyOutflowBase(info, to: model)
    model.transactionKindCode = TransactionKindCode.giveAway.rawValue
}
```

---

## Aggregate and Value Object Guidance

1. Use value objects for concepts with validation and behavior (money, date spans, rates).
2. Keep aggregate mutation methods small and invariant-focused.
3. Do not expose mutable internals for convenience.

Good:
```swift
struct TaxYear: Equatable, Sendable {
    let value: Int

    init(_ value: Int) throws {
        guard (2000...2100).contains(value) else { throw TaxError.invalidYear }
        self.value = value
    }
}
```

Bad:
```swift
struct TaxYear {
    var value: Int // mutated from anywhere, no invariant
}
```

---

## Error Handling Style

1. Use typed domain errors.
2. Include enough context to debug.
3. Do not return `nil` for business rule violations.

Good:
```swift
enum TransactionRuleViolation: Error {
    case invalidAccountKind(kind: AccountType, transaction: TransactionKind)
    case missingTaxType(transactionID: AccountTransactionID)
}
```

Bad:
```swift
func validate(_ t: Transaction) -> Bool
```

---

## Readability Rules

1. Prefer `guard` for preconditions and early exit.
2. Keep nesting shallow (target <= 2 levels).
3. Prefer small pure helpers over long procedural functions.
4. Comments explain why, not what.

Bad:
```swift
if a {
    if b {
        if c {
            // ...
        }
    }
}
```

Good:
```swift
guard a else { return }
guard b else { return }
guard c else { return }
// ...
```

---

## Concurrency Rules

1. Use `async/await` for async orchestration.
2. Keep shared mutable state isolated.
3. Domain logic should remain deterministic and testable.
4. Do not hide task creation in random helpers.

---

## Review Checklist for DRY + DDD (Required)

For each PR, reviewers and authors must answer:

1. What domain concept is introduced/changed?
2. Where is the invariant enforced?
3. Is any rule duplicated across files/services/views?
4. Did we extract repeated logic to the right layer?
5. Are helper functions placed in the best file/module for reuse?
6. Any overloaded/header-variant functions that should be replaced by a typed input object?
7. Any stringly-typed branching that should be enum/value-object based?
8. Does the code read in business language?

If #3 or #4 fails, request refactor before merge.

---

## Quick Anti-Repetition Playbook

When you notice repeated logic:

1. Stop copy-pasting.
2. Identify true owner of the rule (domain/application/presentation).
3. Extract the smallest shared unit with a domain name.
4. Replace duplicates in same PR.
5. Add at least one targeted test for extracted behavior.

---

## Summary

Write Swift that reflects the business model and stays easy to evolve.

1. Domain rules live in domain types.
2. Orchestration lives in application services.
3. IO/mapping lives in infrastructure.
4. Views render state and send intents.
5. Repetition is a design smell. Extract it early and place helpers deliberately.
