# REPORT

## Overview

This project implements a minimal backend service for a SaaS platform using Dart and Shelf. The backend provides CRUD APIs for notes management, API key authentication, request rate limiting, feature flags by subscription tier, structured logging, centralized error handling, Swagger documentation, Docker support, CI integration, and automated tests.

The main goal during implementation was to keep the architecture simple, modular, maintainable, and production-oriented while staying within the assignment scope.

The application was structured into separate layers for middleware, controllers, services, repositories, validators, and exceptions. This separation keeps responsibilities isolated and improves maintainability and testability.

Main implementation decisions:

- Used Shelf because it is lightweight, middleware-oriented, and suitable for minimal APIs.
- Used middleware pipeline for authentication, logging, rate limiting, and error handling.
- Used API key authentication through `X-API-Key` header validation.
- Used fixed-window rate limiting per API key.
- Added centralized validation and exception handling.
- Added unit tests and integration tests for important application flows.
- Added Swagger/OpenAPI support for API documentation and testing.
- Added Docker multi-stage build and GitHub Actions CI.

Tradeoffs and limitations:

- The current rate limiter uses in-memory storage and is not distributed across multiple server instances.
- API authentication uses static API keys instead of JWT/session authentication to keep implementation minimal.
- SQLite was chosen as lightweight persistence suitable for assignment scope and local development.

---

# Architecture

## High-Level Request Flow

```text
HTTP Request
→ Middleware Pipeline
→ Router
→ Controller
→ Service
→ Repository
→ SQLite / In-Memory Store
→ HTTP Response
```

The backend follows a layered architecture where each layer has a clearly defined responsibility.

---

## Middleware Layer

The middleware layer handles cross-cutting concerns before requests reach controllers.

Middleware order:

```text
Logging Middleware
→ Error Middleware
→ Authentication Middleware
→ Rate Limit Middleware
→ Router
```

### Logging Middleware

The logging middleware logs request and response metadata for monitoring and debugging purposes.

Responsibilities:

- Log incoming requests
- Log response status codes
- Log request execution details
- Improve observability

---

### Error Middleware

The error middleware catches unhandled exceptions and converts them into consistent JSON responses.

Responsibilities:

- Prevent server crashes from propagating to clients
- Return structured error responses
- Preserve HTTP status codes
- Centralize exception handling

This keeps controller and service code cleaner by avoiding repetitive try-catch blocks.

---

### Authentication Middleware

Authentication is implemented using API keys passed through the `X-API-Key` request header.

Responsibilities:

- Read request API key
- Validate API key against configured environment values
- Reject unauthorized requests with HTTP 401
- Attach authenticated API key to request context

Example:

```http
X-API-Key: sandbox_key
```

Environment configuration:

```env
API_KEYS=sandbox_key:standard_key:enhanced_key:enterprise_key
```

---

### Rate Limit Middleware

The rate limiter protects the API from abuse by limiting requests per API key.

A fixed-window rate limiting strategy was implemented using an in-memory bucket map.

Configuration:

```env
RATE_LIMIT_MAX=60
RATE_LIMIT_WINDOW_SEC=60
```

Responsibilities:

- Track requests per API key
- Reset request window after configured duration
- Return HTTP 429 when limit exceeded
- Include `Retry-After` response header

Tradeoff:

The current implementation uses in-memory storage, which works well for a single-instance application but would require Redis or centralized storage for distributed deployments.

---

## Router Layer

Shelf Router is used to map incoming HTTP requests to controller methods.

Configured routes:

| Method | Endpoint            | Description       |
| ------ | ------------------- | ----------------- |
| POST   | `/v1/notes`         | Create note       |
| GET    | `/v1/notes`         | List notes        |
| GET    | `/v1/notes/:id`     | Fetch note        |
| PUT    | `/v1/notes/:id`     | Update note       |
| DELETE | `/v1/notes/:id`     | Delete note       |
| GET    | `/v1/feature-flags` | Get feature flags |
| GET    | `/health`           | Health check      |

---

## Controller Layer

The controller layer handles HTTP-specific request and response handling.

Responsibilities:

- Parse request bodies
- Extract query parameters
- Read path parameters
- Return HTTP responses
- Delegate business logic to services

The controller layer intentionally keeps business logic minimal.

---

## Service Layer

The service layer contains the main business logic.

Responsibilities:

- Validate note data
- Apply business rules
- Handle workflows
- Coordinate repository operations

Validation rules implemented:

- Title is required
- Title must be between 1 and 120 characters
- Content must not exceed 10000 characters

Validation logic was centralized to avoid duplicated validation code across controllers.

---

## Repository Layer

The repository layer abstracts persistence logic from the service layer.

Responsibilities:

- Create notes
- Fetch notes
- Update notes
- Delete notes
- Handle pagination queries

This separation makes persistence easier to replace or extend in the future.

---

## Persistence

SQLite was used for lightweight persistence.

Stored fields:

- Note ID
- Title
- Content
- Created timestamp
- Updated timestamp

SQLite was selected because it is lightweight, easy to configure locally, and sufficient for assignment-scale backend systems.

---

## Feature Flags

Feature flags are returned based on API key tier.

Supported tiers:

- Sandbox
- Standard
- Enhanced
- Enterprise

The feature flags endpoint dynamically returns enabled features depending on the authenticated API key tier.

Example endpoint:

```http
GET /v1/feature-flags
```

---

# Tests

Both unit tests and integration tests were implemented.

---

## Unit Tests

Unit tests were added for isolated business logic and middleware behavior.

Covered components:

- Validators
- Authentication middleware
- Rate limit middleware
- Notes service

Unit tests validate:

- Request validation rules
- Authentication behavior
- Rate limiting logic
- Exception handling
- Business rules

---

## Integration Tests

Integration tests validate complete request lifecycle behavior.

Covered flows:

- CRUD APIs
- Authentication middleware
- Rate limiting
- Feature flags
- Error responses
- Pagination

Integration tests run against a real in-memory HTTP server using Shelf.

---

## Running Tests

Run all tests:

```bash
dart test
```

Run integration tests only:

```bash
dart test test/integration
```

Run unit tests only:

```bash
dart test test/unit
```

Expected result:

```text
All tests passed
```

---

# Performance

## Benchmark Methodology

Performance testing was performed by sending 100 requests against:

```http
GET /v1/notes
```

The benchmark focused on:

- Request processing overhead
- Middleware execution performance
- Routing performance
- JSON serialization performance

P95 latency was used instead of average latency because it better represents worst-case request behavior for most users.

---

## Environment

| Property  | Value        |
| --------- | ------------ |
| OS        | macOS        |
| Runtime   | Dart SDK 3.x |
| Framework | Shelf        |
| Machine   | MacBook Pro  |

---

## Performance Results

| Metric          | Value  |
| --------------- | ------ |
| Total Requests  | 100    |
| Average Latency | ~1ms   |
| P95 Latency     | ~1.7ms |

Results may vary depending on system load and runtime environment.

---

## SQLite Persistence

Implemented SQLite persistence for notes storage.

Features:

- Persistent note storage
- Timestamp support
- Repository abstraction
- CRUD persistence operations

---

## OpenAPI and Swagger

Swagger UI was integrated for API documentation and testing.

Features:

- Interactive API documentation
- Request/response visualization
- Endpoint discovery
- API testing through browser

Swagger endpoint:

```text
/swagger
```

---

## Docker Support

Implemented Docker multi-stage build with healthcheck support.

Features:

- Multi-stage optimized image build
- Compiled Dart executable
- Lightweight runtime image
- `/health` endpoint healthcheck support

```
app % docker compose up --build

```

---

## GitHub Actions CI

GitHub Actions CI was added to automatically validate the project.

CI workflow includes:

```bash
dart analyze
dart test
```

The CI pipeline helps detect regressions and ensures the application remains stable during changes.
