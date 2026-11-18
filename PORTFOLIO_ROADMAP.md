# Masroof portfolio roadmap

Baseline reviewed on November 17, 2026. Repository roadmap published on November 18, 2026.

This roadmap applies to this repository and follows the shared Null Catchers portfolio plan. Verify the documented state against the current code and runs before starting work.

**Estimated initial demo effort** 20–35 hours for a developer familiar with the project. The estimate excludes external reviews, store accounts, target environment setup, and later milestones.

## Project priorities

**Documented state** The app supports accounts, currencies, transfers, budgets, Arabic reports, receipt OCR, notifications, and mobile offline use.

**P0 — Demo** Turn the tested synthetic month into a recordable Arabic web and mobile walkthrough and measure OCR on an Arabic receipt.

**P1 — Validation and depth** Expand balance and decimal precision invariants across currencies. Test resending a transfer after connection loss, recurring transactions after restart, and clear currency totals.

**P2 — Later** Consider previewable CSV imports with column mappings and duplicate detection. Defer bank integrations until a supported connection and user need exist.

**Acceptance criteria** Balances reconcile, retries create one transfer, the Arabic PDF reads right-to-left, and bad OCR requires review before an expense is saved.

**Demo scenario** Salary → budget → Arabic receipt → budget alert → monthly report. [README](https://github.com/The-Null-Catchers/Masroof/blob/main/README.md), [Offline Sync](https://github.com/The-Null-Catchers/Masroof/blob/main/docs/offline-sync.md).

## Next milestones

[PR #5](https://github.com/The-Null-Catchers/Masroof/pull/5) verified a salary, a retried transfer, receipt review, and a budget breach, then generated an Arabic PDF. The test used simulated OCR. [Reproduction steps](docs/portfolio-demo.md).

1. [ ] Prepare two images of a synthetic Arabic receipt with known date, currency, and amount. Record the actual OCR output per field and verify the UI requests review of missing or mismatched values.
2. [ ] Repeat the monthly journey on web and mobile with the same test account. Reconcile both balances, the category budget, and the PDF total. Verify a retried transfer appears once.
3. [ ] Save an Arabic recording and report tied to the SHA. Identify where OCR was real or simulated and document the report’s direction and number-format checks.

## Portfolio acceptance checklist

- [ ] Another person can reproduce the primary workflow from a clean checkout using the README and test credentials or fixtures.
- [ ] The demo tells one complete story with a defined user, problem, and saved result.
- [ ] Tests cover the main flow, an important failure, and access boundaries when multiple accounts are involved.
- [ ] Demo data is labeled synthetic and reproducible. Review screenshots and recordings for secrets and customer data.
- [ ] Include four to six real screenshots where appropriate, a 60–120 second recording, and working links. Identify the revision used for capture.
- [ ] The README describes implemented capabilities, setup, architecture, limits, tests, and the demo.
- [ ] A short case study explains two engineering decisions, a considered alternative, and how the system handles an actual failure.
- [ ] Release evidence records the commit SHA, CI, prerequisites, and limits. Performance data includes workload, hardware, and method.
- [ ] Licensing and contributor attribution are settled before distribution. Choose the license for each repository individually.

A hosted demo is optional. Code execution, server administration, and secret management can be demonstrated through a recording and a reproducible isolated environment. Keep public demo access scoped to the activities it needs.

## Implementation and follow-up

- Break P0 into tasks with expected behavior, acceptance criteria, and a suitable test.
- Verify existing functionality first. Update this plan when evidence tied to a commit or PR closes a milestone.
- Record the fixture source, the revision used for evidence, and the tested limits.
- Review the final diff and verify required checks for its exact SHA before merging. Follow branch protection.
- For documentation-only changes with no applicable workflow, verify content and links and record the checks actually performed.
- Tie performance, security, and readiness claims to supporting evidence.
