# POCKET — iOS personal finance tracker

Native SwiftUI + SwiftData + Swift Charts app for iOS 17+. UI language: Bulgarian.

## Features
- Balance, monthly income and expenses
- Add and delete transactions
- Spending charts by day and category
- Local SwiftData storage
- Currency display preference (EUR/BGN/USD; **no conversion**)

## Building
This repository contains `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen).
On macOS with Xcode 16 or newer and XcodeGen:

```sh
xcodegen generate
xcodebuild -project POCKET.xcodeproj -scheme POCKET -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions builds on a hosted macOS runner; it does **not** produce a signed, installable iPhone app. Publishing on TestFlight/App Store requires Apple Developer Program membership and signing.

## Privacy
Transactions are saved locally with SwiftData. No account, server, bank integration, or analytics SDK.

## Notes
- A balance is calculated from transactions and is not a real bank balance.
- Amounts are stored as integer minor units to avoid floating-point errors.
- Changing the currency only changes display formatting. Do not mix currencies in one ledger.
- This is an initial source release, not yet verified by a successful CI run.
