# Contributing to UncertainValueCore

Thanks for contributing. This project is Apple-only and targets Swift 5.9+.

## Prerequisites
- Xcode 15+
- Swift 5.9+
- macOS 14+ (for local development)

## Development Setup
- Clone the repo and open it in Xcode or use Swift Package Manager.
- Build and test with:

```bash
swift test
```

## Guidelines
- Prefer value types and explicit NormStrategy usage.
- Avoid preconditions in public APIs; use errors or optional returns.
- Keep new public APIs documented in README and docs/public_api.md.
- Add tests for new behavior and edge cases.

## Pull Requests
- Keep PRs focused and small.
- Update CHANGELOG.md for user-visible changes.
- Include tests for new or changed behavior.
