# Project Constitution
<!-- Example: Spec Constitution, TaskFlow Constitution, etc. -->

## Core Principles

### I. Library-First
Every feature starts as a standalone library; Libraries must be self-contained, independently testable, documented; Clear purpose required - no organizational-only libraries

### II. CLI Interface
Every library exposes functionality via CLI; Text in/out protocol: stdin/args → stdout, errors → stderr; Support JSON + human-readable formats

### III. Test-First (NON-NEGOTIABLE)
TDD mandatory: Tests written → User approved → Tests fail → Then implement; Red-Green-Refactor cycle strictly enforced

### IV. Integration Testing
Focus areas requiring integration tests: New library contract tests, Contract changes, Inter-service communication, Shared schemas

### V. Observability
Text I/O ensures debuggability; Structured logging required; MAJOR.MINOR.BUILD format

## Additional Constraints

### Security Requirements
All data transmission must be encrypted; Sensitive information must be stored securely; Access controls must be implemented for all features

### Performance Standards
System must handle 1000 concurrent users; Response time must be under 200ms for 95% of requests; System must be able to process 10,000 requests per minute

## Development Workflow

### Quality Gates
All PRs must pass automated tests; Code coverage must be at least 80%; All security vulnerabilities must be addressed; Performance benchmarks must be met

### Review Process
All changes require peer review; Critical changes require two reviewers; Security changes require security team review

## Governance
All PRs/reviews must verify compliance; Complexity must be justified; Use [GUIDANCE_FILE] for runtime development guidance

**Version**: 1.0.0 | **Ratified**: 2025-06-13 | **Last Amended**: 2025-06-13