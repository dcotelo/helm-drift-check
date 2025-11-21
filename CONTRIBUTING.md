# Contributing to Helm Chart Drift Check

Thank you for your interest in contributing to Helm Chart Drift Check! This document provides guidelines and instructions for contributing.

## 🌟 Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Submit bug fixes
- ✨ Add new features
- 🧪 Write tests
- 📖 Share your use cases

## 🐛 Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

### How to Report a Bug

1. Use the GitHub issue tracker
2. Include a clear, descriptive title
3. Provide the following information:
   - Action version
   - Runner OS (Ubuntu, macOS, etc.)
   - Helm version
   - Relevant configuration (services-config, etc.)
   - Complete error messages
   - Steps to reproduce
   - Expected vs actual behavior

### Bug Report Template

```markdown
**Action Version:** v1.0.0
**Runner OS:** ubuntu-latest
**Helm Version:** 3.14.0

**Description:**
A clear description of the bug.

**Configuration:**
```yaml
services-config: |
  [...]
```

**Steps to Reproduce:**
1. ...
2. ...

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Error Messages:**
```
Paste error messages here
```

**Additional Context:**
Any other relevant information.
```

## 💡 Suggesting Features

Feature suggestions are welcome! Please:

1. Check existing issues/discussions first
2. Clearly describe the use case
3. Explain how it benefits users
4. Consider implementation complexity
5. Provide examples of how it would work

### Feature Request Template

```markdown
**Problem Statement:**
What problem does this solve?

**Proposed Solution:**
How would you like to see it implemented?

**Alternatives Considered:**
What other solutions did you consider?

**Use Case:**
Describe a real-world scenario where this would be useful.

**Example:**
```yaml
# Show how the feature would be used
```
```

## 🔧 Development Setup

### Prerequisites

- Git
- Bash/Zsh shell
- Helm 3.x
- jq (JSON processor)
- A test GitHub repository with:
  - Helm charts
  - Argo ApplicationSet files
  - Test values files

### Local Development

1. **Fork the repository**

   ```bash
   # Click the Fork button on GitHub
   ```

2. **Clone your fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/helm-drift-check.git
   cd helm-drift-check
   ```

3. **Create a feature branch**

   ```bash
   git checkout -b feature/my-new-feature
   ```

4. **Make your changes**

   - Edit `action.yml` for action metadata
   - Edit scripts in `scripts/` directory
   - Update documentation in `README.md`

5. **Test your changes**

   Create a test workflow in a separate repository:

   ```yaml
   name: Test My Changes
   on: [pull_request]
   
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         
         - name: Test drift check
           uses: YOUR-USERNAME/helm-drift-check@feature/my-new-feature
           with:
             # ... your test configuration
   ```

6. **Validate shell scripts**

   ```bash
   shellcheck scripts/*.sh
   ```

7. **Commit your changes**

   ```bash
   git add .
   git commit -m "feat: add awesome new feature"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New features
   - `fix:` Bug fixes
   - `docs:` Documentation changes
   - `chore:` Maintenance tasks
   - `refactor:` Code refactoring
   - `test:` Test additions/changes

8. **Push to your fork**

   ```bash
   git push origin feature/my-new-feature
   ```

9. **Create a Pull Request**

   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template

## 📝 Pull Request Guidelines

### Before Submitting

- [ ] Code follows existing style and conventions
- [ ] Shell scripts pass shellcheck validation
- [ ] Documentation is updated (README, comments)
- [ ] Changes are tested in a real workflow
- [ ] Commit messages follow conventional commits
- [ ] PR description clearly explains the changes

### PR Description Template

```markdown
## Description
Brief description of what this PR does.

## Motivation
Why is this change needed?

## Changes
- Change 1
- Change 2
- Change 3

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots showing the changes in action.

## Checklist
- [ ] Code follows project conventions
- [ ] Documentation updated
- [ ] Tested in a real workflow
- [ ] No breaking changes (or clearly documented)
```

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, maintainers will merge
4. Your contribution will be included in the next release!

## 🎨 Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -euo pipefail` for safety
- Use meaningful variable names
- Add comments for complex logic
- Use `readonly` for constants
- Quote variables: `"$variable"`
- Use `[[` for conditionals instead of `[`
- Prefer `$(command)` over backticks

### YAML

- Use 2-space indentation
- Keep lines under 120 characters
- Use clear, descriptive keys
- Add comments for complex configurations

### Documentation

- Use clear, concise language
- Include code examples
- Add emoji for visual organization 🎨
- Keep it up-to-date with code changes

## 🧪 Testing

### Manual Testing

1. Create a test repository with:
   - Sample Helm chart
   - Argo ApplicationSet files
   - Values files
   - Different versions tagged in git

2. Create a test workflow using your branch

3. Test scenarios:
   - ✅ No drift detected
   - ⚠️ Drift detected
   - ❌ Missing files
   - ❌ Invalid configuration
   - 🔄 Multiple services
   - 📝 PR comment creation

### Testing Checklist

- [ ] Action runs successfully
- [ ] Versions extracted correctly
- [ ] Drift detection works
- [ ] PR comments posted
- [ ] Error handling works
- [ ] Edge cases handled

## 📚 Documentation

When contributing, please update:

- **README.md** - Main documentation
- **Code comments** - Explain complex logic
- **CHANGELOG.md** - Add entry for your changes
- **Examples** - Update if behavior changes

## 🤝 Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## 📋 Release Process

Maintainers handle releases:

1. Update version in documentation
2. Update CHANGELOG.md
3. Create a GitHub release
4. Tag with semantic version
5. Publish to GitHub Marketplace

## 💬 Getting Help

- 📖 Read the [README](README.md)
- 🔍 Search existing [issues](https://github.com/dcotelo/helm-drift-check/issues)
- 💬 Start a [discussion](https://github.com/dcotelo/helm-drift-check/discussions)
- 📧 Contact maintainers (see GitHub profiles)

## 🙏 Thank You

Every contribution, no matter how small, helps make this project better. Thank you for taking the time to contribute!

---

**Happy Contributing! 🚀**
