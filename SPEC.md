# Purchase Microservice - Technical Specification

> Spring Boot 3 + WebFlux reactive microservice for wine purchase analysis and recommendations.
> Calls external customer and product services via WebClient to aggregate and analyze purchase data.

## Executive Summary

Purchase Microservice is a **Spring Boot 3.3.1 + Project Reactor** application that orchestrates data from two external services (customer-service and product-service) to provide wine purchase analytics and recommendations. It exposes three REST controllers: customer enrichment, purchase history queries, and AI-style product recommendations based on purchase type frequency.

---

## 1. Problem Statement

### Context
A wine retailer needs to analyze customer purchase patterns to recommend relevant products. Data lives in two upstream services. This microservice aggregates, enriches, and provides derived analytics.

### Goals
- Fetch and enrich customer purchase data from external services (reactive, non-blocking)
- Query purchase history by year, sort by value, find most loyal customers
- Generate product recommendations based on each customer's most-purchased wine type
- Provide standard OpenAPI documentation and health monitoring

### Success Metrics
- [x] Reactive pipeline (WebFlux + WebClient) end-to-end
- [x] OpenAPI 3 / Swagger UI
- [x] Spring Boot Actuator health endpoint
- [x] Full test suite (unit + mapper tests)
- [x] Structured exception hierarchy per operation
- [ ] Integration tests with mock upstream services
- [ ] Caching layer for upstream calls

---

## 2. Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Java | 17 |
| Framework | Spring Boot | 3.3.1 |
| Reactive | Spring WebFlux + Reactor | 3.3.1 |
| HTTP Client | WebClient | 3.3.1 |
| API Docs | SpringDoc OpenAPI (WebMVC + WebFlux) | 2.5.0 / 2.1.0 |
| Logging | Log4j2 | (Spring Boot default excluded) |
| Mapping | ModelMapper | Latest |
| Monitoring | Spring Boot Actuator | 3.3.1 |
| Testing | JUnit 5 + Reactor Test | Latest |

---

## 3. Architecture

```
┌──────────────────────────────────────────────────────────┐
│                 HTTP Clients (JSON REST)                  │
└─────────────────────┬────────────────────────────────────┘
                      │
         ┌────────────┴─────────────┐
         ▼                          ▼
┌─────────────────┐        ┌────────────────────┐
│ customer-service│        │  product-service   │
│  /clientes      │        │  /produtos         │
└────────┬────────┘        └─────────┬──────────┘
         │                           │
         └─────────────┬─────────────┘
                       │ WebClient (reactive)
                       ▼
┌──────────────────────────────────────────────────────────┐
│              Purchase Microservice                       │
├──────────────────────────────────────────────────────────┤
│  CustomerController  /cliente/...                        │
│  PurchaseController  /compra/...                         │
│  RecommendationController  /recomendacao/...             │
├──────────────────────────────────────────────────────────┤
│  DataCoordinatorService (orchestrates all data flows)    │
│  CustomerService │ ProductService │ PurchaseService      │
│  PurchaseSummaryService │ RecommendationService          │
└──────────────────────────────────────────────────────────┘
```

---

## 4. Domain Structure

```
domain/
  Customer.java          # name, citizenId, Purchase[], PurchaseSummary
  Product.java           # name, price, type (wine variety)
  Purchase.java          # Product, quantity
  PurchaseSummary.java   # totalQuantity, totalValue, largestPurchase
  Recommendation.java    # customer, productType, Product[]

service/
  CustomerService        # getEnrichedCustomers (fetches + joins purchases to products)
  ProductService         # getProducts (from product-service)
  PurchaseService        # getCustomerPurchases, getYearsLargestPurchase, sortByValue
  PurchaseSummaryService # generatePurchaseSummary per customer
  RecommendationService  # generateRecommendation (by most-purchased type)
  DataCoordinatorService # orchestrates multi-service calls

client/
  CustomerServiceClient  # WebClient → customer-service /clientes
  ProductServiceClient   # WebClient → product-service /produtos

exception/
  (per operation exceptions — 10+ typed exceptions)
```

---

## 5. API Endpoints

```
# Customers
GET  /cliente                        # All customers (enriched with purchases + products)
GET  /cliente/fiel                   # Most loyal customer (highest total purchase value)

# Purchases
GET  /compra?ano={year}              # All purchases (optional: filter by year)
GET  /compra/{year}/maior            # Largest single purchase of the year

# Recommendations (wine type-based)
GET  /recomendacao/cliente/tipo      # Recommendations for all customers based on most-purchased wine type

# Infrastructure
GET  /actuator/health                # Health check
GET  /swagger-ui.html                # API documentation
```

---

## 6. Data Models

```json
// Customer (enriched)
{
  "name": "João Silva",
  "citizenId": "123.456.789-00",
  "purchases": [
    {
      "product": { "name": "Merlot", "price": 29.90, "type": "tinto" },
      "quantity": 3
    }
  ],
  "purchaseSummary": {
    "totalQuantity": 3,
    "totalValue": 89.70,
    "largestPurchase": { ... }
  }
}

// Recommendation
{
  "customer": { ... },
  "productType": "tinto",
  "products": [ { "name": "Cabernet", "price": 45.00, "type": "tinto" } ]
}
```

---

## 7. Testing Strategy

```bash
./mvnw test              # All tests
./mvnw test -pl .        # Specific module
```

**Test coverage:**
- Controller tests (all 3 controllers)
- Service tests (all 6 services)
- Mapper tests (all 4 mappers)
- Client tests (CustomerServiceClient, ProductServiceClient)
- Uses `reactor-test` (StepVerifier) for reactive assertions

---

## 8. Deployment & Operations

```bash
# Build
./mvnw clean package

# Run
./mvnw spring-boot:run

# Docker
docker-compose up

# Env vars
CUSTOMER_SERVICE_URL=http://localhost:8081
PRODUCT_SERVICE_URL=http://localhost:8082
```

---

## 9. Issues Found

### Logic Issues
- **`RecommendationService.generateRecommendation`** counts purchase quantity by type to find the most-purchased wine type, but the `products` Flux passed to the inner call is **consumed** on first use (WebFlux `Flux` from `WebClient` is cold — but if it's hot/shared, it may be empty on re-use). The `products` Flux is created once in `getRecommendations()` and used inside `flatMap` for each customer — if the upstream response is not cached (`cache()`), each customer will trigger a new HTTP call, causing N+1 requests.
- **`GET /recomendacao/cliente/tipo`** has a Portuguese path (`recomendacao`) while the service description uses English — inconsistent API naming convention.

### Missing Features
- No caching: every request fetches from upstream services. Production use would require `Mono.cache()` or Redis.
- No pagination on `/cliente` or `/compra` endpoints — all data is returned in one call.
- No authentication/authorization.

### Configuration
- `springdoc-openapi-starter-webmvc-ui` (2.5.0) and `springdoc-openapi-starter-webflux-ui` (2.1.0) are **both** included. Mixing WebMVC and WebFlux OpenAPI starters in a single Spring Boot application can cause conflicts. The app should use one paradigm.
- `spring-boot-devtools` is in `runtime` scope — acceptable for development but should be excluded in production builds.
