# Changelog

All notable changes to the Spring Boot Product Catalogue microservice will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] - 2026-07-15

### Added
- **H2 In-Memory Support**: Integrated H2 database runtime dependencies to enable standalone and lightweight executions.
- **Dynamic Database Profiles**: Configuration parameter overrides using environment variables in `application.properties` with fallback settings.
- **API Version Toggles**: Route access filtering in `ProductController` mapped to the injected `app.version` property.
- **Case-Insensitive Search**: Added a `findByNameContainingIgnoreCase` JPA query method to support substring search operations.
- **Validation Exceptions**: Integrated a `@RestControllerAdvice` bean (`GlobalExceptionHandler`) mapping bad pagination inputs to standard JSON responses for v2.0 search.
- **Multi-Stage Dockerfile**: Multi-stage JRE 8 container build using OpenJDK.
- **Secure Pod Boundaries**: Configured custom ServiceAccount, Role, and RoleBinding namespace configs (RBAC), and disabled automatic API token mounts.
- **TLS Secure Ingress**: Configured path-based HTTPS terminations inside `catalogue.local` via `cert-manager`.
- **Terraform Cluster Provisioner**: Added Terraform Minikube setup module under `terraform/`.
- **Smoke Tests & GHA**: Built TLS smoke testing integrations inside GHA CI/CD pipelines.
