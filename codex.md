# Instruction for Codex

[규칙]
1. 모든 답변은 반드시 한국어로 작성합니다.
2. 코드 변경이 있을 때마다 **무엇을 변경했는지**와 **왜 그렇게 변경했는지**를 간단하고 이해하기 쉽게 설명합니다.
3. 설명은 실무 초심자도 이해할 수 있도록 너무 깊게 파고들지 말고, 핵심 개념과 이유를 중심으로 적당히 쉽게 작성합니다.

# Codex Internal Roadmap

Authoritative sequence of work for the m0nee refactor. Written for Codex use only.

## Ground Rules
- Single `ExpenseStore` instance per process; inject via `@EnvironmentObject`.
- New types must declare ownership (`@MainActor`, `Sendable`) and document side effects.
- Prefer dependency injection over globals; no direct `UserDefaults.standard` access in UI.

## Phase 1 — Extract Core Services
**Goal:** collapse `ExpenseStore` responsibilities into service protocols that can be mocked.
1. Introduce protocols: `ExpenseRepository`, `BudgetComputing`, `RecurringExpenseScheduling`, `WidgetSyncing`, `ProAccessHandling`.
2. Create concrete implementations by moving logic out of `ExpenseStore` (repository first, then budget, recurring, widget, pro).
3. Refactor `ExpenseStore` into a coordinator that composes these services; ensure persistence APIs become async and main-actor safe.

## Phase 2 — App State Unification
1. Provide the composed `ExpenseStore` from `m0neeApp` and remove `@StateObject` instantiations in child views (e.g. `SettingsView`).
2. Replace scattered `UserDefaults` keys with an `AppSettings` facade that encapsulates suite identifiers and change notifications.
3. Audit `NotificationCenter` usage; migrate to Combine publishers sourced from the unified store.

## Phase 3 — Presentation Layer Cleanup
1. Introduce `ContentViewModel` and `InsightsViewModel` that depend on the services from Phase 1.
2. Move date-range filtering, favourite insight management, and budget formatting into the view models.
3. Keep SwiftUI views declarative: no direct persistence or calculations beyond formatting.

## Phase 4 — Testing Expansion
1. Provide in-memory fakes for each new service protocol; update existing tests to inject fakes instead of hitting file system/iCloud.
2. Add unit tests for budget/recurring calculations, widget payload generation, and pro-access decisions.
3. Establish SwiftUI snapshot coverage for Content, Insights, and Settings flows; add StoreKit TestKit scenarios for purchase lifecycle.

## Phase 5 — Concurrency & Event Hygiene
1. Mark transaction observers and persistence entry points with `@MainActor`; route background file I/O through Task.detached hops that hand results back to the main actor.
2. Replace ad-hoc notifications with structured Combine pipelines; expose typed events (`expensesDidChange`, `budgetDidChange`).
3. Adopt async/await entry points for services and update call sites accordingly.

## Phase 6 — Long-Term Feature Tracks
- Forecasting: surface projected balance using `RecurringExpenseScheduling` data.
- Goal-based budgeting: extend budget service to manage goal envelopes and progress metrics.
- Localized coaching: hook `LanguageManager` + notification pipeline to deliver locale-aware tips.

Maintain incremental PRs per bullet; no phase should land without corresponding tests and documentation updates.
