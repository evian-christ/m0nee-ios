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

---

## Phase 1 — Error Handling & User Feedback
**Goal:** 사용자에게 명확한 에러 피드백을 제공하고 데이터 손실을 방지한다.

1. **에러 처리 강화**
   - `ExpenseStore.persist()` 실패 시 사용자에게 알림 표시
   - `FileExpenseRepository` 에러를 `ExpenseStore`로 전파하는 메커니즘 구현
   - 에러 타입 정의: `ExpenseStoreError` enum 생성 (`.saveFailed`, `.loadFailed`, `.syncFailed`)

2. **로딩 상태 관리**
   - `ExpenseStore`에 `@Published var isLoading: Bool` 추가
   - `bootstrap()` 중 로딩 상태 표시
   - iCloud 동기화 상태를 나타내는 `@Published var syncStatus: SyncStatus` 추가

3. **사용자 알림 시스템**
   - `@Published var errorMessage: String?` 추가하여 에러 메시지 표시
   - ContentView에 `.alert()` modifier로 에러 표시
   - 성공 메시지도 표시 (예: "Data synced successfully")

## Phase 2 — Data Security & Privacy
**Goal:** 사용자의 민감한 지출 데이터를 안전하게 보호한다.

1. **파일 암호화**
   - `FileExpenseRepository`에 FileProtection API 적용 (`.completeUntilFirstUserAuthentication`)
   - 민감한 설정값 Keychain 저장 검토

2. **백업 파일 관리**
   - 백업 파일 최대 개수 제한 (예: 최근 3개만 유지)
   - 오래된 백업 자동 삭제 로직 추가
   - 백업 복구 UI 개선 (현재는 숨겨진 기능)

3. **데이터 내보내기 보안**
   - Export 시 민감 정보 제외 옵션 추가
   - 내보낸 파일에 대한 암호 설정 옵션 검토

## Phase 3 — Performance Optimization
**Goal:** 앱 성능을 최적화하여 사용자 경험을 개선한다.

1. **저장 최적화**
   - `persist()` 호출에 debouncing 적용 (500ms 딜레이)
   - 배치 작업 시 한 번만 저장하도록 개선
   - `persist(immediate: Bool = false)` 파라미터 추가

2. **계산 메모이제이션**
   - `InsightsView`의 `currentExpenses` computed property를 `@State`로 변경
   - 날짜 범위 계산 결과 캐싱
   - 카테고리별 합계 등 반복 계산 최적화

3. **대용량 데이터 처리**
   - 지출 목록 lazy loading 구현
   - 페이지네이션 또는 가상 스크롤 검토
   - 대량 데이터(1000+ expenses) 테스트 시나리오 추가

## Phase 4 — Presentation Layer (ViewModel)
**Goal:** 비즈니스 로직을 View에서 분리하여 테스트 가능하고 유지보수하기 쉬운 구조를 만든다.

1. **ViewModel 도입**
   - `ContentViewModel` 생성: 지출 필터링, 정렬, 그룹핑 로직 이동
   - `InsightsViewModel` 생성: 날짜 범위 계산, 인사이트 카드 관리 로직 이동
   - `SettingsViewModel` 검토 (필요시 생성)

2. **View 단순화**
   - SwiftUI View는 순수하게 UI 렌더링만 담당
   - computed property를 ViewModel의 @Published property로 이동
   - View에서 직접적인 `ExpenseStore` 접근 최소화

3. **ViewModel 테스트**
   - 각 ViewModel에 대한 단위 테스트 작성
   - Mock 서비스 사용하여 격리된 테스트 환경 구성

## Phase 5 — Testing Expansion
**Goal:** 테스트 커버리지를 확대하여 앱 안정성을 높인다.

1. **통합 테스트**
   - 서비스 간 상호작용 테스트 (ExpenseStore + Repository + BudgetService)
   - iCloud 동기화 시나리오 테스트 (로컬 우선, iCloud 우선, 충돌)
   - 데이터 마이그레이션 엔드투엔드 테스트

2. **StoreKit 테스트**
   - StoreKit Testing framework 사용하여 구매 플로우 테스트
   - Pro 기능 잠금/해제 시나리오 테스트
   - 구독 복원 로직 테스트

3. **UI 테스트 (선택)**
   - ViewInspector 또는 SnapshotTesting 도입 검토
   - 주요 화면의 스냅샷 테스트
   - 접근성(Accessibility) 테스트

## Phase 6 — Code Quality Improvements
**Goal:** 코드 가독성과 유지보수성을 향상시킨다.

1. **Magic String 제거**
   - Product ID를 상수로 정의: `Constants.productIDs`
   - UserDefaults key를 enum으로 관리
   - 카테고리 기본값을 상수로 정의

2. **코드 중복 제거**
   - `AppSettings`의 `set()` 메서드를 제네릭으로 통합
   - 반복되는 날짜 계산 로직을 `DateHelper` 유틸리티로 추출
   - 통화 포맷팅 로직 통합

3. **문서화**
   - 주요 서비스 프로토콜에 DocC 주석 추가
   - 복잡한 알고리즘(recurring expense generation)에 설명 추가
   - README.md 업데이트 (아키텍처 다이어그램 포함)

## Phase 7 — Feature Enhancements (Long-term)
**Goal:** 사용자 가치를 높이는 새로운 기능을 추가한다.

1. **예산 예측**
   - 반복 지출 데이터를 활용한 미래 지출 예측
   - 현재 속도로 지출 시 예산 소진 시점 표시
   - 월말 예상 지출 계산

2. **목표 기반 예산**
   - 저축 목표 설정 기능
   - 목표 달성률 시각화
   - 목표별 예산 envelope 관리

3. **고급 인사이트**
   - 지출 패턴 분석 (요일별, 시간대별)
   - 카테고리별 트렌드 그래프
   - 전월/전년 대비 비교

4. **사용자 경험 개선**
   - 온보딩 플로우 개선 (인터랙티브 튜토리얼)
   - 인사이트 카드 커스터마이징 강화
   - 애니메이션 및 전환 효과 개선
   - 다크 모드 최적화

---

**실행 원칙:**
- 각 Phase는 독립적으로 완료 가능해야 함
- 각 Phase 완료 시 테스트와 문서 업데이트 필수
- Phase 1-3는 높은 우선순위로 빠르게 진행
- Phase 4-6은 안정성과 유지보수성 확보
- Phase 7은 장기 로드맵으로 유연하게 조정
