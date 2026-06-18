# Global Rules for Fullstack Agent Workforce

## Coding Standards

- **Indentation**: 4 spaces, no tabs
- **Line length**: Max 100 characters
- **Naming**: 
  - Files: kebab-case
  - Classes/Components: PascalCase
  - Functions: camelCase
  - Constants: UPPER_SNAKE_CASE
- **Comments**: 
  - Block comments for files/modules
  - Inline comments for non-obvious logic
  - No commented-out code
- **Error handling**: 
  - Use try/catch blocks
  - Centralized error logging
  - Custom error types

## Commit Message Conventions

- **Format**: `type(scope): subject`
- **Types**: 
  - `feat`: new feature
  - `fix`: bug fix
  - `docs`: documentation
  - `refactor`: code restructuring
  - `test`: testing
  - `chore`: maintenance
- **Subject**: 50 characters or less
- **Body**: Optional, wrap at 72 characters
- **Footer**: Optional, for breaking changes

## Branching Strategy

- **main**: protected branch, production-ready
- **develop**: integration branch
- **feature/***: feature branches from develop
- **release/***: release preparation
- **hotfix/***: urgent fixes from main

## Pull Request Process

1. PR must be from a feature branch
2. Title must reference JIRA ticket or issue number
3. At least 2 reviewers must approve
4. All checks must pass
5. No merge conflicts allowed
6. PR must be squashed and rebased onto main

## Code Review Checklist

- [ ] Code follows standards
- [ ] Tests cover new functionality
- [ ] No obvious performance issues
- [ ] No security vulnerabilities
- [ ] No accessibility violations
- [ ] Documentation updated if needed
- [ ] No breaking changes without notice
- [ ] PR title is clear and descriptive

## Testing Requirements

- **Unit tests**: 100% coverage for new code
- **Integration tests**: cover major flows
- **E2E tests**: critical user journeys
- **Test naming**: descriptive, matches behavior
- **Test data**: deterministic, no external dependencies

## Security Requirements

- **Input validation**: always validate
- **Output encoding**: prevent XSS
- **Authentication**: use secure methods
- **Authorization**: RBAC enforced
- **Secrets**: never hardcode
- **Scan**: run Snyk/Dependabot on PR

## CI/CD Rules

- **Build**: must pass on every PR
- **Tests**: unit, integration, E2E must pass
- **Security scan**: must pass
- **Static analysis**: must pass
- **No secrets**: detect and block
- **Deploy preview**: must work

## Documentation Standards

- **README**: project overview, setup, architecture
- **ADR**: architecture decisions recorded
- **API docs**: generated from code comments
- **Runbooks**: for common operations
- **Change logs**: versioned in CHANGELOG.md

## Release Process

1. **Release candidate**: created from develop
2. **Smoke test**: verify in staging
3. **Rollback plan**: documented and tested
4. **Feature flags**: used if needed
5. **Post-deploy checks**: metrics, logs, errors

## Incident Response

- **Severity levels**: 
  - P0: critical system failure
  - P1: major functionality broken
  - P2: minor issue
  - P3: documentation/notification
- **Response**: 
  - Acknowledge within 15 minutes
  - Assign owner
  - Communicate status every 30 minutes
  - Resolve and document postmortem

## Postmortem Process

1. **Timeline**: detailed chronology
2. **Root cause**: technical cause
3. **Impact**: users affected
4. **Actions**: what was done
5. **Prevention**: what will be done to avoid recurrence

## Anti-Patterns

- **Skipping reviews**
- **Merging without tests**
- **Hardcoding secrets**
- **Ignoring observability**
- **Treating UX as decoration**
- **Releasing without rollback**
- **Skipping security scans**
- **Poor commit messages**
- **No handoff packets**

## Enforcement

- **CI**: blocks merge on failures
- **Code owners**: required approvals
- **Automated checks**: lint, typecheck, security
- **Manual reviews**: required for critical changes

## Versioning

- **Semantic versioning**: MAJOR.MINOR.PATCH
- **Changelog**: auto-generated from PR titles
- **Tagging**: Git tags for releases

## Metrics

- **Test coverage**: minimum 85%
- **Code quality**: no new violations
- **Build time**: under 10 minutes
- **Deploy frequency**: at least weekly
- **Mean time to recovery**: under 1 hour