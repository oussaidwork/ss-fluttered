# 12 — Quality Gates

## Purpose

Define the mandatory gates every project must pass.

## Gate 1 — Definition of Ready

Must be true before implementation starts:

- Requirements are clear
- Acceptance criteria exist
- UX flows are defined
- API contracts are drafted
- Risks are listed
- Test plan is drafted

## Gate 2 — Definition of Done

Must be true before merge:

- Code is complete
- Tests pass
- Lint passes
- Typecheck passes
- Docs are updated
- Security review is complete
- Accessibility check is complete
- Observability is ready

## Gate 3 — PR Review

Required before merge:

- At least one reviewer approves
- No unresolved critical comments
- Tests are green
- No obvious architecture drift
- No missing documentation

## Gate 4 — CI / CD

Required before release:

- Build passes
- Unit tests pass
- Integration tests pass
- E2E tests pass
- Security scan passes
- Bundle size budget passes
- Deployment preview works

## Gate 5 — Release

Required before production:

- Release notes are written
- Rollback plan is ready
- Monitoring is configured
- Feature flags are ready if needed
- Production smoke test is ready

## Gate 6 — Post-release

Required after release:

- Metrics are reviewed
- Logs are checked
- Error rate is stable
- User feedback is collected
- Postmortem is completed if needed

## Evidence required

- Test report
- Review approval
- Security scan
- Accessibility report
- Observability dashboard
- Release checklist

## Failure rule

If any gate fails, the feature cannot move forward until the failure is fixed or explicitly waived by the tech lead.
