# Branches

2. Version Control Systems (VCS)

Use tools like Git, Mercurial, or Subversion (SVN) to track and manage changes over time.

Git best practices:

    Use branches (main, develop, feature/x, release/x, hotfix/x)

    Tag releases:
    git tag v1.0.0
    git push origin v1.0.0

## Main Branches

`main` Stable production-ready code

## Feature Branches

Use for developing new features.

Format: `feature/<short-description>`. Include a ticket or issue ID: `feature/123-add-user-profile`.

## Bugfix Branches

Use for fixing bugs not in production.

Format: `bugfix/<short-description>`. Include a ticket or issue ID: `bugfix/123-typo-footer`.

## Hotfix Branches

Use for urgent fixes to production.

Format: `hotfix/<short-description>`. Include a ticket or issue ID: `hotfix/123-payment-crash`.

## Release Branches

Used to prepare a new production release (testing, minor fixes, version bump).

Format: `release/<version>`.

## Other Prefixes (Optional)

chore/: for maintenance tasks (e.g., updating dependencies)

test/: for testing-related work

doc/: for documentation changes

ci/: for CI/CD config updates

### ✅ Best Practices

- Use dashes (-) instead of underscores for readability.
- Keep names short but meaningful.
- Include a ticket or issue ID.
