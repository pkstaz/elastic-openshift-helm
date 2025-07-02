# Contributing to Elasticsearch OpenShift Helm Chart

Thank you for your interest in contributing to the Elasticsearch OpenShift Helm Chart! This document provides guidelines for contributing to this project.

## Maintainer

**Carlos Estay**
- Email: cestay@redhat.com
- GitHub: [pkstaz](https://github.com/pkstaz)

## How to Contribute

### Reporting Issues

Before creating an issue, please:

1. Check if the issue has already been reported
2. Search the existing issues for similar problems
3. Provide detailed information including:
   - OpenShift version
   - Helm version
   - Elasticsearch version
   - Steps to reproduce
   - Expected vs actual behavior
   - Logs and error messages

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following the coding standards
4. **Test your changes**:
   ```bash
   # Validate the chart
   helm lint .
   
   # Test template rendering
   helm template test .
   
   # Test with different values
   helm template test . -f values-production.yaml
   ```
5. **Update documentation** if needed
6. **Commit your changes** with clear commit messages
7. **Push to your fork** and create a pull request

### Code Standards

- Use consistent indentation (2 spaces for YAML)
- Follow Helm chart best practices
- Add comments for complex logic
- Update documentation for new features
- Include tests when possible

### Testing Guidelines

Before submitting a PR, please test:

1. **Chart validation**: `helm lint .`
2. **Template rendering**: `helm template test .`
3. **Installation test**: Deploy to a test OpenShift cluster
4. **Functionality test**: Verify Elasticsearch and ElasticVue work correctly
5. **Cleanup test**: Verify uninstallation works properly

### Documentation

When adding new features:

1. Update `README.md` with new configuration options
2. Add examples to the documentation
3. Update `values.yaml` with new parameters
4. Add comments explaining the purpose of new configurations

## Development Setup

### Prerequisites

- OpenShift 4.x cluster
- Helm 3.x
- `oc` CLI tool
- Elasticsearch Operator installed

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/pkstaz/elastic-openshift-helm.git
   cd elastic-openshift-helm
   ```

2. **Install dependencies** (if any):
   ```bash
   # Currently no external dependencies
   ```

3. **Test the chart**:
   ```bash
   # Validate
   helm lint .
   
   # Test rendering
   helm template test .
   
   # Test installation
   helm install test . --dry-run
   ```

## Release Process

1. **Update version** in `Chart.yaml`
2. **Update documentation** if needed
3. **Create a release tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. **Create GitHub release** with changelog
5. **Update Helm repository** (if applicable)

## Contact

For questions about contributing:

- **Email**: cestay@redhat.com
- **GitHub Issues**: Create an issue in the repository
- **GitHub Discussions**: Use the Discussions tab for general questions

## License

By contributing to this project, you agree that your contributions will be licensed under the Apache License 2.0. 