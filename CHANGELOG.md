# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release of Helm Chart Drift Check action
- Support for multiple service configurations
- Service-specific version detection from Argo ApplicationSet files
- Comprehensive drift detection with visual diffs
- PR comment integration with detailed reports
- Support for both GitHub token and GitHub App authentication
- Automated testing workflows
- Comprehensive documentation and examples

### Changed
- Converted from internal company action to standalone public action
- Made GitHub token authentication the primary method
- Removed company-specific defaults and configurations
- Updated documentation for general use

### Security
- Sanitized all examples and removed sensitive information
- Added proper input validation and error handling

## [1.0.0] - TBD

### Added
- Initial release as standalone GitHub Action
- Multi-service Helm chart drift detection
- ArgoCD ApplicationSet integration
- Visual diff reporting with dyff
- GitHub Actions marketplace publishing
- Comprehensive test suite
- Documentation and contributing guidelines

---

## Guidelines for Maintainers

When updating this changelog:

1. **Add entries to [Unreleased] section** for new changes
2. **Create new version section** when releasing
3. **Follow the categories**:
   - `Added` for new features
   - `Changed` for changes in existing functionality
   - `Deprecated` for soon-to-be removed features
   - `Removed` for removed features
   - `Fixed` for bug fixes
   - `Security` for vulnerability fixes

4. **Link to GitHub releases** when publishing
5. **Use semantic versioning** (MAJOR.MINOR.PATCH)

### Release Process

1. Update changelog with version number and date
2. Create GitHub release with tag
3. Update major version tag (v1, v2, etc.)
4. Announce in discussions/README if significant changes