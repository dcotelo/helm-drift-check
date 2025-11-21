---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## 🐛 Bug Description

A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce

Steps to reproduce the behavior:

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## ✅ Expected Behavior

A clear and concise description of what you expected to happen.

## 📋 Actual Behavior

A clear and concise description of what actually happened.

## 📊 Action Configuration

Please provide your action configuration (remove sensitive data):

```yaml
- uses: dcotelo/helm-drift-check@v1
  with:
    # Your configuration here
```

## 📝 Logs

Please provide relevant logs from the GitHub Actions run. You can find these in the Actions tab of your repository.

<details>
<summary>GitHub Actions Logs</summary>

```
Paste your logs here
```

</details>

## 🌐 Environment

- **Runner OS**: [e.g. ubuntu-latest, macos-latest]
- **Action Version**: [e.g. v1.0.0]
- **Dyff Version**: [e.g. 1.7.0]
- **Helm Version**: [if known]

## 📄 Additional Context

Add any other context about the problem here, including:

- Repository structure
- Argo ApplicationSet file examples (sanitized)
- Values file examples (sanitized)
- Any relevant manifests repository structure

## ✅ Checklist

- [ ] I have searched existing issues to ensure this is not a duplicate
- [ ] I have provided all the requested information above
- [ ] I have removed any sensitive information from the configuration and logs