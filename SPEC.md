# Purchase Microservice - Technical Specification

> Technical specification for the Purchase Management REST API.
> Reference for understanding Spring Boot microservice architecture.

## Executive Summary

- **Project**: Purchase Microservice
- **Type**: REST API / Spring Boot Microservice
- **Language**: Java 17+
- **Framework**: Spring Boot with Actuator & OpenAPI 3
- **Status**: Active Development
- **Owner**: Development team

---

## 1. Problem Statement

### Context
The Purchase Microservice provides a REST API for managing purchase orders, payments, and order lifecycle. It integrates with Docker for containerization and includes health check endpoints via Spring Boot Actuator.

### Goals
- **Primary**: Expose REST endpoints for CRUD operations on purchases
- **Secondary**: Provide operational health checks and monitoring
- **Tertiary**: Auto-generate API documentation via OpenAPI 3

### Success Metrics
- [x] Maven-based build and dependency management
- [x] Spring Boot Actuator health endpoints
- [x] OpenAPI/Swagger documentation
- [x] Docker container support
- [x] GitHub Actions CI/CD pipeline
- [ ] Test coverage > 80%
- [ ] API response time p95 < 100ms

---

## 2. Technology Stack

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Runtime | Java | 17+ | LTS version, performance |
| Framework | Spring Boot | 2.7+ / 3.x | Production-grade web apps |
| Build Tool | Maven | 3.8.4+ | Dependency management, plugins |
| ORM | Spring Data JPA | 2.7+ | Database abstraction |
| API Docs | OpenAPI 3 | 3.0 | Auto-generated API docs |
| Monitoring | Spring Boot Actuator | 2.7+ | Health checks, metrics |
| Containers | Docker | Latest | Containerized deployment |
| Testing | JUnit 5 + Spring Test | 5.x | Unit and integration tests |
| CI/CD | GitHub Actions | - | Automated testing on push |

### Key Dependencies
- `spring-boot-starter-web`: REST controller framework
- `spring-boot-starter-data-jpa`: ORM layer
- `springdoc-openapi-ui`: Swagger UI generation
- `spring-boot-starter-actuator`: Health checks and metrics
- Database driver (MySQL/PostgreSQL)

---

## 3. Architecture

### High-Level Microservice Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    HTTP Clients / API Gateway                   │
└──────────────────────┬────────────────────────────────────────┘
                       │ HTTP/REST
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Spring Boot Application                        │
├──────────────────────────────────────────────────────────────────┤
│                   Spring Web (REST Controller)                   │
│          POST /api/purchases, GET /api/purchases/:id             │
└──────────────────────┬────────────────────────────────────────┘
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
┌───▼──────────────────┴────┐   ┌─────────▼──────────────┐
│    Service Layer          │   │  Data Access Layer     │
├───────────────────────────┤   ├────────────────────────┤
│ - PurchaseService         │   │ - PurchaseRepository   │
│ - OrderService            │   │ - PaymentRepository    │
│ - PaymentService          │   │ - Query Methods        │
│ - ValidationService       │   │                        │
└───┬───────────────────────┘   └────────┬───────────────┘
    │                                    │
    └────────────────┬───────────────────┘
                     │
            ┌────────▼───────────┐
            │   Spring Boot Data │
            │  Actuator & Metrics│
            ├────────────────────┤
            │ /actuator/health   │
            │ /actuator/metrics  │
            └────────┬───────────┘
                     │
            ┌────────▼───────────┐
            │   Database         │
            ├────────────────────┤
            │ Purchase Entity    │
            │ Order Entity       │
            │ Payment Entity     │
            └────────────────────┘
```

### Request/Response Flow

```
HTTP Request (POST /api/purchases)
    ↓
DispatcherServlet → Controller
    ↓
Service Layer (validation, business logic)
    ↓
Repository (JPA queries)
    ↓
Database (persist/retrieve)
    ↓
Response (JSON with status code)
```

---

## 4. Project Structure

```
src/
├── main/
│   ├── java/com/purchase/
│   │   ├── controller/         # REST endpoints
│   │   │   └── PurchaseController.java
│   │   ├── service/            # Business logic
│   │   │   ├── PurchaseService.java
│   │   │   ├── OrderService.java
│   │   │   └── PaymentService.java
│   │   ├── repository/         # Data access (JPA)
│   │   │   ├── PurchaseRepository.java
│   │   │   └── PaymentRepository.java
│   │   ├── model/              # Domain entities
│   │   │   ├── Purchase.java
│   │   │   ├── Order.java
│   │   │   └── Payment.java
│   │   ├── dto/                # Request/response objects
│   │   │   ├── PurchaseDTO.java
│   │   │   └── PaymentDTO.java
│   │   ├── exception/          # Custom exceptions
│   │   │   └── PurchaseException.java
│   │   └── Application.java    # Entry point
│   └── resources/
│       ├── application.yml     # Config
│       ├── application-dev.yml
│       └── application-prod.yml
└── test/
    └── java/com/purchase/
        ├── controller/         # Controller tests
        ├── service/            # Service tests
        └── repository/         # Integration tests
```

---

## 5. Key Patterns

- **Layered Architecture**: Controller → Service → Repository
- **Entity Mapping**: DTO pattern for request/response
- **Exception Handling**: Global exception handler with custom exceptions
- **Health Checks**: Actuator endpoints for monitoring
- **OpenAPI/Swagger**: Auto-generated API documentation
- **CI/CD**: GitHub Actions for automated testing
- **Database Versioning**: Schema migrations (Flyway/Liquibase)

---

## 6. API Endpoints (Example)

```
POST   /api/purchases              # Create purchase
GET    /api/purchases              # List all purchases
GET    /api/purchases/{id}         # Get single purchase
PUT    /api/purchases/{id}         # Update purchase
DELETE /api/purchases/{id}         # Delete purchase

POST   /api/purchases/{id}/payment # Add payment
GET    /api/purchases/{id}/payment # List payments

GET    /actuator/health            # Health check
GET    /swagger-ui.html            # API documentation
```

