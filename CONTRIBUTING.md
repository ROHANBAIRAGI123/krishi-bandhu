# Contributing Guide

This document defines the Git workflow, branching strategy, and contribution standards for **Krishi Bandhu**. These are project standards, not optional recommendations. All contributors are expected to follow them without exception.

---

## Protected Branches

The repository has two long-lived, protected branches:

| Branch        | Purpose                                                                                              |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| `main`        | Production-ready code. Every commit here represents a stable, deployable release.                    |
| `development` | Integration branch. All feature work is merged here first and stabilised before promotion to `main`. |

> [!CAUTION]
> **Direct pushes to `main` or `development` are strictly prohibited.** All changes must be introduced through a Pull Request. No exceptions.

---

## Branch Hierarchy

```text
main
└── development
    ├── feature/<name>
    ├── fix/<name>
    ├── docs/<name>
    ├── refactor/<name>
    ├── test/<name>
    └── chore/<name>
```

All short-lived branches are cut from `development` and merged back into `development` via Pull Request. `development` is promoted to `main` via a separate Pull Request once it has been tested and approved.

---

## Branch Naming Convention

| Prefix      | Purpose                                                    |
| ----------- | ---------------------------------------------------------- |
| `feature/`  | New functionality or capability                            |
| `fix/`      | Bug fixes, error corrections, or patch work                |
| `docs/`     | Documentation additions or updates only                    |
| `refactor/` | Code restructuring without changing behaviour              |
| `test/`     | Adding or updating tests without changing application code |
| `chore/`    | Tooling, configuration, dependency management, CI/CD setup |

**Examples:**

```text
feature/authentication
feature/realtime-editor

fix/socket-disconnect
fix/login-validation

docs/update-contributing

refactor/editor-service

test/file-api

chore/github-actions
```

**Branch names must:**

- Use lowercase only
- Use hyphens instead of spaces or underscores
- Be concise and descriptive
- Represent exactly one logical unit of work

---

## Development Workflow

### 1. Sync your local `development` branch

Always start from an up-to-date `development`:

```bash
git checkout development
git pull origin development
```

### 2. Create your branch

Cut a new branch from `development` using the appropriate prefix:

```bash
git checkout -b feature/my-feature
```

### 3. Implement your changes

Make focused, incremental commits. Each commit message should describe what changed and why.

### 4. Run all required quality checks

Before pushing, ensure all checks pass locally:

```bash
# Format check
npx prettier --check .

# Run tests
npm test

# Run tests with coverage report
npm run test:coverage
```

> [!IMPORTANT]
> Do not push a branch that fails any of these checks. The CI pipeline will block the Pull Request regardless.

### 5. Push your branch

```bash
git push origin feature/my-feature
```

### 6. Open a Pull Request targeting `development`

```text
feature/my-feature
        ↓
   development
```

### 7. Merge `development` into `main` (after approval and testing)

Once changes in `development` have been reviewed, approved, and all checks pass:

```text
development
     ↓
   main
```

> [!CAUTION]
> **Never merge a feature branch directly into `main`.** All changes must flow through `development` first.

---

## Pull Request Requirements

Every Pull Request **must**:

- [ ] Address exactly one logical change
- [ ] Have a meaningful, descriptive title
- [ ] Explain the motivation — why this change is needed
- [ ] Describe the implementation — what was done and how
- [ ] Reference related issues where applicable (e.g. `Closes #42`)
- [ ] Include screenshots or recordings for any UI or API response changes
- [ ] Update relevant documentation if behaviour or APIs have changed
- [ ] Include tests whenever new functionality or bug fixes are introduced

Pull Requests that are vague, untested, or out of scope will be rejected.

---

## Protected Branch Rules

The following rules apply to both `main` and `development`:

| Rule                                      | Enforcement                                   |
| ----------------------------------------- | --------------------------------------------- |
| Direct pushes are prohibited              | Enforced via branch protection                |
| A Pull Request is required before merging | Enforced via branch protection                |
| At least one approving review is required | Enforced via branch protection (when enabled) |
| All CI checks must pass before merging    | Enforced via required status checks           |
| Merge conflicts must be fully resolved    | Required before merge                         |
| All review conversations must be resolved | Required before merge                         |
| Force pushes are prohibited               | Enforced via branch protection                |
| Branch deletion protection is enabled     | Enforced via branch protection                |

---

## CI Requirements

Pull Requests must not be merged until all required GitHub Actions checks pass.

The following checks run on every Pull Request:

| Check                    | Command                                                |
| ------------------------ | ------------------------------------------------------ |
| Install dependencies     | `npm install`                                          |
| Format validation        | `npx prettier --check .`                               |
| Unit & integration tests | `npm test` (runs `vitest run`)                         |
| Test coverage report     | `npm run test:coverage` (runs `vitest run --coverage`) |k

> [!WARNING]
> If any required check fails, **the Pull Request must not be merged** — even with approvals. Fix the failure on the branch and push again. CI must be green before merge proceeds.

---

## Philosophy

This workflow exists to uphold the following project standards:

- **Stable production branch** — `main` always reflects a deployable, production-ready state.
- **Mandatory code review** — every change is reviewed by at least one other contributor before it reaches `development`.
- **CI as a gate** — automated checks are non-negotiable. Human review does not override a failing CI pipeline.
- **Simplified collaboration** — a consistent branching model means any contributor can understand the state of the codebase at a glance.
- **Clean Git history** — one branch per logical unit of work, merged via PR, produces an auditable and traceable history.
- **Regression prevention** — the `development` buffer between feature branches and `main` ensures issues are caught before they affect production.

These are the standards this project is built on. Deviating from them creates risk for every contributor and every user of this system.
