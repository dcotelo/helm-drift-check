# Getting Started with Helm Chart Drift Check

This guide will help you quickly set up Helm Chart Drift Check in your repository.

## 🚀 Quick Setup

### 1. Basic Workflow

Create `.github/workflows/drift-check.yml` in your repository:

```yaml
name: Helm Drift Check

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  drift-check:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Helm Chart Drift Check
        uses: dcotelo/helm-drift-check@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          manifests-repository: 'your-org/your-manifests-repo'
          chart-path: 'charts/your-app'
          services-config: |
            [
              {
                "name": "production",
                "argo_file": "argo-apps/prod/app.yaml",
                "values_file": "values/prod.yaml"
              }
            ]
```

### 2. Configure Your Services

Update the `services-config` with your actual service configuration:

```yaml
services-config: |
  [
    {
      "name": "api-prod",
      "argo_file": "manifests/argo-apps/api/prod.yaml",
      "values_file": "manifests/api/values-prod.yaml"
    },
    {
      "name": "api-staging",
      "argo_file": "manifests/argo-apps/api/staging.yaml",
      "values_file": "manifests/api/values-staging.yaml"
    },
    {
      "name": "web-prod",
      "argo_file": "manifests/argo-apps/web/prod.yaml",
      "values_file": "manifests/web/values-prod.yaml"
    }
  ]
```

### 3. Repository Structure

Your manifests repository should have this structure:

```
your-manifests-repo/
├── argo-apps/
│   ├── api/
│   │   ├── prod.yaml      # Contains targetRevision
│   │   └── staging.yaml
│   └── web/
│       └── prod.yaml
├── values/
│   ├── api/
│   │   ├── values-prod.yaml
│   │   └── values-staging.yaml
│   └── web/
│       └── values-prod.yaml
└── charts/
    └── your-app/          # Your Helm chart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
```

## 🔧 Prerequisites

### 1. Argo ApplicationSet Files

Your Argo ApplicationSet files must contain a `targetRevision` field:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app-prod
spec:
  template:
    spec:
      source:
        repoURL: https://your-charts-repo.com
        chart: my-app
        targetRevision: "1.2.3"  # ← This is required!
        helm:
          valueFiles:
          - values-prod.yaml
```

### 2. Git Tags

Your chart repository should have git tags that match the `targetRevision` values in your Argo files.

### 3. Repository Access

The action needs access to your manifests repository. You can use:

- **GitHub token** (for public repos or same organization)
- **GitHub App** (recommended for private repos across organizations)

## 🔐 Authentication Options

### Option 1: GitHub Token (Recommended)

```yaml
- uses: dcotelo/helm-drift-check@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}  # Default
    # ... other inputs
```

### Option 2: GitHub App

```yaml
- uses: dcotelo/helm-drift-check@v1
  with:
    github-app-id: ${{ secrets.APP_ID }}
    github-app-private-key: ${{ secrets.APP_PRIVATE_KEY }}
    # ... other inputs
```

## 📊 What You'll Get

### PR Comments

The action will create comprehensive PR comments with:

- ✅ Services with no changes
- ⚠️ Services with detected changes
- 📋 Summary with change count
- 🔗 Link to workflow run

### Example Output

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
spec.template.spec.containers[0].resources.limits.memory
± value change
  - 512Mi
  + 1Gi
```

**📋 Summary:** 1 out of 2 files have changes for review
```

## 🐛 Troubleshooting

### Common Issues

1. **"No service versions found"**
   - Check that your Argo ApplicationSet files exist at the specified paths
   - Verify `targetRevision` fields are present
   - Ensure the manifests repository is accessible

2. **"Missing values files"**
   - Verify values file paths in your service configuration
   - Check that files exist in the manifests repository

3. **"Template rendering failed"**
   - Validate your Helm chart syntax
   - Ensure all required values are provided in values files

### Debug Mode

Add this step before the drift check for debugging:

```yaml
- name: Debug configuration
  run: |
    echo "Manifests repo: ${{ inputs.manifests-repository }}"
    echo "Chart path: ${{ inputs.chart-path }}"
    echo "Services config: ${{ inputs.services-config }}"
```

## 🔄 Next Steps

1. **Test the setup** by creating a test PR
2. **Customize** the service configuration for your environment
3. **Add more services** as needed
4. **Configure notifications** or integrate with other tools
5. **Set up branch protection rules** if desired

## 📚 Learn More

- [Full Documentation](README.md)
- [Configuration Examples](README.md#examples)
- [Troubleshooting Guide](README.md#troubleshooting)
- [Contributing](CONTRIBUTING.md)

---

Need help? [Create an issue](https://github.com/dcotelo/helm-drift-check/issues/new) or [start a discussion](https://github.com/dcotelo/helm-drift-check/discussions)!