# devflow Examples

Realistic flows. All output abbreviated.

---

## 1. Tiny — SQL cleanup

```
> /devflow reformat the user-search query in OrderRepository.java to use multiline + named params
```

Expected:
```
Mode: tiny — one file, formatting only, no behavior change.

Read OrderRepository.java:42-58. Rewrite query block. Run:
$ mvn -q -pl repo test -Dtest=OrderRepositoryTest
Tests run: 7, Failures: 0, Errors: 0

Done. Changed OrderRepository.java only.
```

No spec. No plan. One verification.

---

## 2. Standard — new API endpoint

```
> /devflow add GET /api/v1/customers/{id}/orders returning paged list, default size 20, max 100
```

Expected:
```
Mode: standard — multi-file (controller + service + repo + test), behavior change, architecture clear.

Discovery: Spring Boot 3, JPA, paging via Pageable, existing pattern in ProductController.

Design (inline):
- New endpoint in CustomerController
- Reuse CustomerService.findOrders(id, Pageable)
- Add JPA query in OrderRepository.findByCustomerId(id, Pageable)
- Validation: size 1..100, page >= 0

Checklist:
[ ] T1 repo method + test
[ ] T2 service method + test
[ ] T3 controller + integration test
[ ] T4 full mvn verify

Implementing T1...
$ mvn -q test -Dtest=OrderRepositoryTest
Tests run: 9, Failures: 0
✓

(...T2, T3 similar...)

Final:
$ mvn -q verify
BUILD SUCCESS · 142 tests, 0 failed

Files: OrderRepository.java, CustomerService.java, CustomerController.java + 3 tests.
Next: commit feat(orders): list customer orders endpoint
```

---

## 3. Debug — failing test

```
> /devflow-debug PaymentServiceTest.refundExpired failing on CI but passes locally
```

Expected:
```
Loading devflow-systematic-debugging.

Reproduce:
$ mvn -q test -Dtest=PaymentServiceTest#refundExpired
Tests run: 1, Failures: 1
  expected: 2026-05-15T00:00:00Z but was: 2026-05-14T19:00:00Z

Evidence: assertion uses LocalDateTime.now() + ZoneId.systemDefault().
CI runs in UTC, dev in Asia/Tbilisi (UTC+4). Diff = 4h, but failure offset 5h → DST adjacent.

Hypothesis: comparison mixes LocalDateTime and Instant, drops zone info.
Falsifier: PaymentService.refund() returns LocalDateTime — grep confirms.

Failing test (already exists). Minimal fix:
- PaymentService.java:88 — change return type to Instant, callers updated
- PaymentServiceTest.java:34 — assert with Instant comparison

Verify:
$ TZ=UTC mvn -q test -Dtest=PaymentServiceTest
Tests run: 6, Failures: 0
$ TZ=Asia/Tbilisi mvn -q test -Dtest=PaymentServiceTest
Tests run: 6, Failures: 0

Root cause: zone-naive datetime compared across zones. Fixed by using Instant.
```

---

## 4. Deep — payments refactor

```
> /devflow-plan migrate refund flow from Stripe v1 to v2 API with backward-compat for in-flight requests
```

Expected:
```
Mode: deep — payments + external API + migration.

Loading devflow-discovery.
[discovery output: services, files, current StripeClient, ~14 callsites]

Spec saved: docs/devflow/specs/stripe-v2-refunds.md
Plan saved: docs/devflow/plans/stripe-v2-refunds.md (11 tasks)

Top risks:
- in-flight refunds during deploy → use idempotency keys consistent across versions
- v2 webhook signature change → dual-verify until cutover
- partial refunds field rename → translation layer

Next: /devflow-execute docs/devflow/plans/stripe-v2-refunds.md
```

Then:
```
> /devflow-execute docs/devflow/plans/stripe-v2-refunds.md
```

Runs T1..T11 task by task, verifying each. Stops on red.

---

## 5. Review only

```
> /devflow-review feature/customer-orders
```

Expected:
```
Scope: git diff main...feature/customer-orders (4 files, +127/-12)

Requirement match: meets ticket WMS-844.

Findings:
- src/.../CustomerController.java:54 (major) — page size cap of 100 not enforced; returns 500 on size=10000. Fix: clamp via PageRequest.of(page, Math.min(size, MAX_SIZE)).
- src/.../OrderRepository.java:31 (minor) — query missing index hint; verify orders(customer_id, created_at) index exists.
- src/.../CustomerControllerTest.java (minor) — no test for empty result.

Security: ok (auth via existing filter). PII: response body fine.

Recommendation: **approve-with-fixes** — fix the size cap before merge.
```

---

## 6. Tiny — typo fix

```
> /devflow fix typo "recieve" → "receive" in NotificationService
```

Expected:
```
Mode: tiny — single word, single file.

$ npm test -- --testPathPattern=NotificationService
Tests: 12 passed

Done. NotificationService.ts line 47.
```
