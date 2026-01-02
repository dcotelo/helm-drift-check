# Helm Chart Drift Check

[![GitHub](https://img.shields.io/github/license/helm-tools/helm-drift-check)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/helm-tools/helm-drift-check)](https://github.com/helm-tools/helm-drift-check/releases)

A comprehensive GitHub Action for detecting drift between deployed Helm chart versions and current changes across multiple services. Perfect for GitOps workflows using ArgoCD or similar tools.

## ✨ Features

- 🔍 **Service-specific version detection** - Automatically extracts deployed versions from Argo ApplicationSet files
- 📊 **Multi-service support** - Compare multiple services simultaneously with different deployed versions
- ⚠️ **Configuration validation** - Warns about missing files or version extraction issues without failing
- 📝 **Detailed reporting** - Creates comprehensive PR comments with visual diffs
- 🚀 **Configurable** - JSON-based service configuration for easy maintenance
- 🔧 **Robust** - Handles errors gracefully, perfect for awareness checks
- 🎨 **Clear visualization** - Uses [dyff](https://github.com/homeport/dyff) for human-readable YAML diffs

## 📋 Table of Contents

- [Usage](#-usage)
- [Inputs](#-inputs)
- [Outputs](#-outputs)
- [Service Configuration](#-service-configuration)
- [Examples](#-examples)
- [Output Example](#-output-example)
- [Requirements](#-requirements)
- [How It Works](#-how-it-works)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Usage

### Quick Start

```yaml
name: Helm Drift Check
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  drift-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Helm Chart Drift Check
        uses: helm-tools/helm-drift-check@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          manifests-repository: 'your-org/manifests-repo'
          chart-path: 'charts/your-chart'
          services-config: |
            [
              {
                "name": "api",
                "argo_file": "manifests/argo-apps/api/api-prod.yaml",
                "values_file": "manifests/api/values-prod.yaml"
              },
              {
                "name": "web",
                "argo_file": "manifests/argo-apps/web/web-prod.yaml",
                "values_file": "manifests/web/values-prod.yaml"
              }
            ]
```

### With GitHub App Authentication

For private repositories, you can use GitHub App authentication:

```yaml
- name: Run Helm Chart Drift Check
  uses: helm-tools/helm-drift-check@v1
  with:
    github-app-id: ${{ secrets.APP_ID }}
    github-app-private-key: ${{ secrets.APP_PRIVATE_KEY }}
    manifests-repository: 'your-org/private-manifests'
    chart-path: 'charts/your-chart'
    services-config: |
      [
        {
          "name": "service1",
          "argo_file": "manifests/service1/app.yaml",
          "values_file": "manifests/service1/values.yaml"
        }
      ]
```

## 📥 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github-app-id` | GitHub App ID for private repo access | ❌ | - |
| `github-app-private-key` | GitHub App private key | ❌ | - |
| `github-token` | GitHub token for repo access | ❌ | `${{ github.token }}` |
| `manifests-repository` | Repository with Argo files (format: `owner/repo`) | ✅ | - |
| `chart-path` | Path to Helm chart directory | ❌ | `charts/app` |
| `services-config` | JSON array of service configurations | ✅ | - |
| `dyff-version` | Version of dyff tool to use | ❌ | `1.7.0` |
| `create-pr-comment` | Create PR comments with results | ❌ | `true` |

> **Note:** Either `github-token` or both `github-app-id` and `github-app-private-key` must be provided.

## 📤 Outputs

| Output | Description | Type |
|--------|-------------|------|
| `drift-found` | Whether any drift was detected | `boolean` |
| `files-with-diffs` | Number of files with differences | `number` |
| `total-files` | Total files checked | `number` |
| `summary-file` | Path to summary markdown file | `string` |

### Using Outputs

```yaml
- name: Run Helm Chart Drift Check
  id: drift-check
  uses: helm-tools/helm-drift-check@v1
  with:
    # ... inputs

- name: Handle drift
  if: steps.drift-check.outputs.drift-found == 'true'
  run: |
    echo "Drift detected in ${{ steps.drift-check.outputs.files-with-diffs }} files"
```

## 🔧 Service Configuration

Services are configured using a JSON array. Each service must specify:

```json
[
  {
    "name": "service-name",
    "argo_file": "path/to/argo/applicationset.yaml",
    "values_file": "path/to/helm/values.yaml"
  }
]
```

### Configuration Fields

- **name** *(required)*: Unique identifier for the service (used in reports)
- **argo_file** *(required)*: Path to Argo ApplicationSet file containing `targetRevision`
- **values_file** *(required)*: Path to Helm values file for template rendering

### Path Resolution

All paths in the service configuration are relative to the root of the `manifests-repository`.

## 📚 Examples

### Multi-Environment Setup

```yaml
services-config: |
  [
    {
      "name": "api-prod",
      "argo_file": "argo-apps/api/prod.yaml",
      "values_file": "values/api/prod-us-east.yaml"
    },
    {
      "name": "api-staging",
      "argo_file": "argo-apps/api/staging.yaml",
      "values_file": "values/api/staging-us-west.yaml"
    },
    {
      "name": "worker-prod",
      "argo_file": "argo-apps/worker/prod.yaml",
      "values_file": "values/worker/prod-eu-west.yaml"
    }
  ]
```

### Disable PR Comments

```yaml
- uses: helm-tools/helm-drift-check@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    manifests-repository: 'your-org/manifests'
    create-pr-comment: 'false'
    # ... other inputs
```

### Custom Dyff Version

```yaml
- uses: helm-tools/helm-drift-check@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    manifests-repository: 'your-org/manifests'
    dyff-version: '1.8.0'
    # ... other inputs
```

## 📊 Output Example

The action creates detailed PR comments with visual diffs:

```markdown
## 📊 Helm Chart Drift Check Results

**Comparison:** api: `v1.2.3`, web: `v2.0.1` → `HEAD`

### ✅ web
**Deployed version:** `v2.0.1` | **Values file:** `values-prod.yaml`

No differences detected

### ⚠️ api
**Deployed version:** `v1.2.3` | **Values file:** `values-prod.yaml`

*Changes detected for review and confirmation*
```diff
spec.template.spec.containers[0].image
± value change
  - api:v1.2.3
  + api:v1.2.4

spec.template.spec.containers[0].resources.limits.memory
± value change
  - 512Mi
  + 1Gi
```

---
**📋 Summary:** 1 out of 2 files have changes for review


## 🔒 Requirements

- **Helm 3.x** - Automatically installed via [azure/setup-helm](https://github.com/Azure/setup-helm)
- **Git repository** - Chart repository must have git tags matching versions
- **Argo ApplicationSet files** - Must contain `targetRevision` fields
- **Linux or macOS runner** - Action supports both architectures (amd64/arm64)

## 🎯 How It Works

1. **Authentication** - Generates token using GitHub App or uses provided token
2. **Checkout** - Clones the manifests repository containing Argo files
3. **Version Extraction** - Parses Argo ApplicationSet files to find `targetRevision`
4. **Template Rendering** - Renders Helm templates for both deployed and current versions
5. **Comparison** - Uses dyff to generate human-readable diffs
6. **Reporting** - Creates markdown summary and posts as PR comment

### Architecture

```
┌─────────────────────┐
│  Extract Versions   │  Parses Argo ApplicationSet files
│  (extract-versions) │  Outputs: service_versions.json
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Drift Check       │  Compares Helm templates
│  (drift-check)      │  Uses: dyff for YAML diff
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Report & Comment   │  Posts PR comment with results
│  (GitHub Script)    │  Updates existing comments
└─────────────────────┘
```

## 🐛 Troubleshooting

### No versions found

**Symptom:** Action reports "No service versions found"

**Solutions:**
- Verify Argo ApplicationSet files exist at specified paths
- Ensure files contain `targetRevision` fields
- Check that paths are relative to manifests repository root
- Verify the repository structure matches your configuration

### Missing values files

**Symptom:** Warning about missing values files

**Solutions:**
- Confirm values file paths in service configuration
- Ensure manifests repository checkout is successful
- Check file permissions and naming (case-sensitive)

### Template rendering failures

**Symptom:** "Failed to render Helm template" errors

**Solutions:**
- Validate Helm chart syntax in both versions
- Ensure values files are valid YAML
- Check that all required values are provided
- Test locally with `helm template` command

### Permission denied errors

**Symptom:** Cannot access manifests repository

**Solutions:**
- Verify GitHub token has correct permissions
- For GitHub App, ensure proper installation and permissions
- Check repository visibility settings

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a sample workflow
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [dyff](https://github.com/homeport/dyff) - Amazing YAML diff tool
- [Helm](https://helm.sh/) - The package manager for Kubernetes
- [ArgoCD](https://argoproj.github.io/cd/) - Declarative GitOps CD for Kubernetes

## 📞 Support

- 🐛 [Report a bug](https://github.com/helm-tools/helm-drift-check/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/helm-tools/helm-drift-check/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/helm-tools/helm-drift-check/discussions)

---

Made with ❤️ for the Kubernetes and GitOps community
