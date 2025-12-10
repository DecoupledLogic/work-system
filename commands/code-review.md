---
description: Deep code review for .NET microservices focusing on Clean Architecture best practices
allowedTools:
  - Read
  - Glob
  - Grep
  - Task
  - Bash
---

# Code Review

Deep code review for .NET microservices following Clean Architecture patterns and best practices.

## Purpose

Perform a comprehensive code review of a .NET microservice, evaluating architecture conformance, code quality, test coverage, and documentation. This command provides structured feedback across all layers of the Clean Architecture.

## Usage

```
/code-review [path] [--focus=<layer>] [--severity=<level>]
```

**Arguments:**
- `[path]` - Path to microservice root (defaults to current directory)

**Options:**
- `--focus=<layer>` - Focus on specific layer: `abstractions`, `api`, `services`, `infrastructure`, `tests`, `docs`
- `--severity=<level>` - Minimum severity to report: `critical`, `high`, `medium`, `low` (default: `low`)

**Examples:**
```
/code-review                                    # Review current microservice
/code-review SubscriptionsMicroservice         # Review specific microservice
/code-review --focus=services                   # Focus on services layer
/code-review --severity=high                    # Only show high+ severity issues
```

## Key Review Patterns (Learned from PR Feedback)

These patterns were identified through actual PR reviews and represent common issues to check for:

### 1. DI Lifetime Selection (High Priority)

**Rule:** Use Transient for stateless services. Only use Scoped if the service needs request-lifetime state.

| Lifetime | When to Use | Example |
|----------|-------------|---------|
| **Transient** | Stateless services, no internal state | Query services, Command services, Repositories |
| **Scoped** | Needs per-request state | IRequestContext, DbContext |
| **Singleton** | Global shared state | Configuration, Caches |

**Anti-pattern to detect:**
```csharp
// BAD: Scoped registration for stateless service
services.AddScoped<ISubscriptionQuery, SubscriptionQuery>();

// GOOD: Transient for stateless service
services.AddTransient<ISubscriptionQuery, SubscriptionQuery>();
```

**Check:** Review `ServiceCollectionExtensions.cs` and `Program.cs` for `AddScoped` registrations. For each one, verify the service actually maintains request-scoped state.

### 2. Vendor Decoupling (High Priority)

**Rule:** Vendor-specific names and implementations should NOT be in Abstractions (domain layer). Vendor code belongs in Infrastructure.

**Anti-patterns to detect:**

- Interface names containing vendor names in Abstractions: `IStaxbillService`, `IStripeClient`
- Method names with vendor names: `SyncFromStaxBillAsync()`, `GetStripeCustomer()`
- Vendor-specific DTOs in Abstractions layer

**Correct pattern:**
```csharp
// In Abstractions - generic names
public interface ISubscriptionSyncService
{
    Task<SyncResult> SyncSubscriptionAsync(string providerSubscriptionId);
}

// In Infrastructure - vendor-specific implementation
public class StaxbillSubscriptionProvider : ISubscriptionProvider { }
```

**Check:** Search for vendor names (Staxbill, Stripe, etc.) in `*.Abstractions/` project.

### 3. Audit Field Population (High Priority)

**Rule:** Use `IRequestContext.Username` for audit fields. Only fall back to service name when user is not authenticated.

**Anti-pattern:**
```csharp
// BAD: Hardcoded service name
subscription.UpdatedBy = "SubscriptionSyncService";
```

**Correct pattern:**
```csharp
// GOOD: Use request context with fallback
subscription.UpdatedBy = _requestContext.IsAuthenticated
    ? _requestContext.Username ?? "ServiceName"
    : "ServiceName";
```

**Check:** Search for `UpdatedBy =` and `CreatedBy =` assignments. Verify IRequestContext is injected and used.

### 4. External Provider ID Types (High Priority)

**Rule:** Use `string` type for external provider IDs to allow diversity in ID formats. Make required (not nullable) when provider always has an ID.

**Anti-pattern:**
```csharp
// BAD: Numeric type limits flexibility
public long? ProviderSubscriptionId { get; set; }
```

**Correct pattern:**
```csharp
// GOOD: String allows any format, required when always present
[Required]
[MaxLength(100)]
public string ProviderSubscriptionId { get; set; } = string.Empty;
```

### 5. Migration Type Consistency (Critical)

**Rule:** Migration column types MUST exactly match entity property definitions.

**Check for mismatches:**

- Entity has `string` → Migration must use `nvarchar`, not `bigint`
- Entity has `[Required]` → Migration must have `nullable: false`
- Entity has `[MaxLength(100)]` → Migration must have `maxLength: 100`

**Also verify:**

- Designer file matches migration
- ModelSnapshot matches migration
- No null filters on indexes for required columns

### 6. Concrete vs Interface Injection (Critical)

**Rule:** Services should inject interfaces, not concrete implementations.

**Anti-pattern:**
```csharp
// BAD: Injecting concrete class
public class SubscriptionCommand(
    SubscriptionsRepository repository,  // Concrete!
    SubscriptionsDbContext context)      // Concrete!
```

**Correct pattern:**
```csharp
// GOOD: Injecting interfaces
public class SubscriptionCommand(
    ISubscriptionRepository repository)
```

### 7. In-Memory Filtering (Medium Priority)

**Rule:** Filter data at the database level, not in memory after fetching all records.

**Anti-pattern:**
```csharp
// BAD: Fetches all, filters in memory
var all = await repository.GetAllAsync();
return all.Where(s => s.CustomerId == customerId);
```

**Correct pattern:**
```csharp
// GOOD: Filter at database level
return await repository.GetByCustomerIdAsync(customerId);
```

### 8. Security - Sensitive Data Logging (Critical)

**Rule:** Never log API keys, passwords, or other secrets.

**Anti-pattern:**
```csharp
// BAD: API key in plain text
_logger.LogInformation("Using API Key: {ApiKey}", _options.ApiKey);
```

### Pattern Sources

These patterns were extracted from actual PR reviews:

| Pattern | Source PR | Reviewer |
|---------|-----------|----------|
| DI Lifetime Selection | PR #1045 Thread 4269, PR #1047 Thread 4282 | Ali Bijanfar |
| Vendor Decoupling | PR #1045 Threads 4267, 4268, 4270 | Ali Bijanfar |
| Audit Field Population | PR #1047 Thread 4283 | Ali Bijanfar |
| External Provider ID Types | PR #1047 Thread 4280 | Ali Bijanfar |
| Migration Type Consistency | PR #1047 Threads 4280, 4281, 4289 | Ali Bijanfar |

---

## Review Process

### Step 1: Discover Project Structure

Identify the microservice structure:

```
{Service}Microservice/
├── Link.{Service}.API/               # FastEndpoints, configuration
├── Link.{Service}.Abstractions/      # Domain models, interfaces, DTOs
├── Link.{Service}.Services/          # Business logic, Query/Command
├── Link.{Service}.Infrastructure/    # EF Core, repositories, migrations
├── Link.{Service}.Tests/             # Unit/integration tests
├── README.md                         # Service documentation
└── TECH_DEBT.md                      # Technical debt tracking
```

### Step 2: Review Abstractions Layer

**Files to examine:**
- `Link.{Service}.Abstractions/**/*.cs`

**Checklist:**

| Category | Check | Severity |
|----------|-------|----------|
| **Entities** | Properties have appropriate types | High |
| **Entities** | Required fields marked correctly | High |
| **Entities** | Audit fields present (CreatedOn, UpdatedOn, CreatedBy, UpdatedBy) | Medium |
| **Entities** | Concurrency token (Version/RowVersion) where needed | Medium |
| **Interfaces** | Repository interfaces follow naming convention (I{Entity}Repository) | Low |
| **Interfaces** | Query/Command interfaces properly separated | Medium |
| **Interfaces** | Async methods have Async suffix | Low |
| **Interfaces** | CancellationToken supported where appropriate | Medium |
| **DTOs** | Request/Response records appropriately structured | Medium |
| **DTOs** | No business logic in DTOs | High |
| **DTOs** | Proper use of records vs classes | Low |
| **Dependencies** | No dependencies on other layers (pure abstractions) | Critical |

**Best Practices:**
```csharp
// Good: Entity with audit fields and concurrency
public class Subscription
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTimeOffset CreatedOn { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTimeOffset UpdatedOn { get; set; }
    public string UpdatedBy { get; set; } = string.Empty;
    public byte[] Version { get; set; } = [];  // Concurrency token
}

// Good: Interface with async pattern
public interface ISubscriptionRepository
{
    Task<Subscription?> GetByIdAsync(int id, CancellationToken ct = default);
    Task<Subscription> CreateAsync(Subscription entity, CancellationToken ct = default);
    Task<Subscription> UpdateAsync(Subscription entity, CancellationToken ct = default);
}
```

### Step 3: Review API Layer

**Files to examine:**
- `Link.{Service}.API/Endpoints/**/*.cs`
- `Link.{Service}.API/Program.cs`
- `Link.{Service}.API/appsettings*.json`

**Checklist:**

| Category | Check | Severity |
|----------|-------|----------|
| **Endpoints** | Follow FastEndpoints patterns (not MVC Controllers) | High |
| **Endpoints** | Proper authorization policies applied | Critical |
| **Endpoints** | Request validation using FluentValidation | High |
| **Endpoints** | Mappers used for entity-to-response transformation | Medium |
| **Endpoints** | Swagger/OpenAPI documentation complete | Medium |
| **Configuration** | No secrets in appsettings.json | Critical |
| **Configuration** | Service addresses properly externalized | High |
| **Configuration** | Health checks configured | Medium |
| **DI Registration** | Services registered with appropriate lifetimes (see Pattern #1) | High |
| **DI Registration** | Transient for stateless, Scoped only for request-state | High |
| **DI Registration** | No concrete class injections (see Pattern #6) | Critical |
| **Middleware** | Error handling middleware present | High |
| **Middleware** | Request logging/telemetry configured | Medium |

**Best Practices:**
```csharp
// Good: FastEndpoints with proper structure
public class GetSubscription(ISubscriptionQuery query)
    : Ep.Req<GetSubscription.Parameters>.Res<Ok<SubscriptionResponse>>.Map<SubscriptionMapper>
{
    public record Parameters(int Id);

    public override void Configure()
    {
        Policies(PolicyNames.LinkAdmin);  // Authorization
        Get("/subscriptions/{Id}");
        Summary(s => s.Summary = "Get subscription by ID");
    }

    public override async Task<Ok<SubscriptionResponse>> ExecuteAsync(
        Parameters req, CancellationToken ct)
    {
        var subscription = await query.GetByIdAsync(req.Id, ct);
        return TypedResults.Ok(Map.FromEntity(subscription));
    }
}

// Good: DI Registration with correct lifetimes
builder.Services.AddScoped<IRequestContext, RequestContext>();  // Per-request
builder.Services.AddTransient<ISubscriptionQuery, SubscriptionQuery>();
builder.Services.AddTransient<ISubscriptionCommand, SubscriptionCommand>();
```

### Step 4: Review Services Layer

**Files to examine:**
- `Link.{Service}.Services/**/*.cs`

**Checklist:**

| Category | Check | Severity |
|----------|-------|----------|
| **Query Services** | Read-only operations, no side effects | High |
| **Command Services** | Write operations properly isolated | High |
| **Business Logic** | Validation at service level, not repository | Medium |
| **External Integrations** | Proper error handling for API calls | High |
| **External Integrations** | Retry policies for transient failures | Medium |
| **External Integrations** | Timeouts configured | High |
| **Logging** | Structured logging with correlation IDs | Medium |
| **Logging** | Sensitive data not logged | Critical |
| **Audit** | IRequestContext used for audit fields | High |
| **Exception Handling** | Domain-specific exceptions defined | Medium |
| **Exception Handling** | Exceptions not swallowed silently | High |

**Best Practices:**
```csharp
// Good: Service using IRequestContext for audit
public class SubscriptionSyncService(
    IStaxbillApiClient staxbillClient,
    ISubscriptionRepository repository,
    IRequestContext requestContext,
    ILogger<SubscriptionSyncService> logger) : ISubscriptionSyncService
{
    public async Task<SyncResult> SyncAsync(string id, CancellationToken ct)
    {
        try
        {
            logger.LogInformation("Syncing subscription {Id}", id);

            var subscription = await repository.GetByIdAsync(id);
            subscription.UpdatedBy = requestContext.IsAuthenticated
                ? requestContext.Username ?? "Service"
                : "Service";
            subscription.UpdatedOn = DateTimeOffset.UtcNow;

            await repository.UpdateAsync(subscription);
            return SyncResult.Success(id);
        }
        catch (StaxbillApiException ex)
        {
            logger.LogError(ex, "API error syncing {Id}", id);
            return SyncResult.Failed($"API error: {ex.Message}");
        }
    }
}
```

### Step 5: Review Infrastructure Layer

**Files to examine:**
- `Link.{Service}.Infrastructure/**/*.cs`
- `Link.{Service}.Infrastructure/Migrations/*.cs`

**Checklist:**

| Category | Check | Severity |
|----------|-------|----------|
| **DbContext** | Inherits from common base (MicroserviceDbContext) | Medium |
| **DbContext** | Entity configurations in separate files | Low |
| **Repositories** | Implement interfaces from Abstractions | High |
| **Repositories** | Async operations used throughout | High |
| **Repositories** | No business logic in repositories | High |
| **Migrations** | Column types match entity definitions | Critical |
| **Migrations** | Indexes on frequently queried columns | Medium |
| **Migrations** | Foreign keys properly defined | High |
| **Migrations** | Designer and Snapshot files consistent | High |
| **HTTP Clients** | Typed HTTP clients used | Medium |
| **HTTP Clients** | Proper serialization options | Medium |

**Best Practices:**
```csharp
// Good: Repository implementing interface
public class SubscriptionRepository(SubscriptionsDbContext context)
    : ISubscriptionRepository
{
    public async Task<Subscription?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        return await context.Subscriptions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id, ct);
    }

    public async Task<Subscription?> GetByProviderSubscriptionIdAsync(
        string providerSubscriptionId, CancellationToken ct = default)
    {
        return await context.Subscriptions
            .FirstOrDefaultAsync(s => s.ProviderSubscriptionId == providerSubscriptionId, ct);
    }
}

// Good: Migration with correct types
migrationBuilder.AddColumn<string>(
    name: "ProviderSubscriptionId",
    schema: "Subscriptions",
    table: "Subscription",
    type: "nvarchar(100)",
    maxLength: 100,
    nullable: false,
    defaultValue: "");
```

### Step 6: Review Tests

**Files to examine:**
- `Link.{Service}.Tests/**/*.cs`

**Checklist:**

| Category | Check | Severity |
|----------|-------|----------|
| **Coverage** | Core business logic has tests | High |
| **Coverage** | Edge cases and error paths tested | Medium |
| **Coverage** | Integration points have tests | High |
| **Structure** | Tests follow Arrange-Act-Assert pattern | Low |
| **Structure** | Test class per service/endpoint | Low |
| **Mocking** | External dependencies mocked | High |
| **Mocking** | Repository interfaces mocked (not implementations) | High |
| **Assertions** | Clear, specific assertions | Medium |
| **Assertions** | Verify mock interactions where appropriate | Medium |
| **Naming** | Test names describe scenario and expected outcome | Low |

**Best Practices:**
```csharp
// Good: Well-structured test with mocks
public class SubscriptionSyncServiceTests
{
    private readonly Mock<IStaxbillApiClient> _mockClient;
    private readonly Mock<ISubscriptionRepository> _mockRepository;
    private readonly Mock<IRequestContext> _mockContext;
    private readonly SubscriptionSyncService _service;

    public SubscriptionSyncServiceTests()
    {
        _mockClient = new Mock<IStaxbillApiClient>();
        _mockRepository = new Mock<ISubscriptionRepository>();
        _mockContext = new Mock<IRequestContext>();
        _service = new SubscriptionSyncService(
            _mockClient.Object, _mockRepository.Object,
            _mockContext.Object, Mock.Of<ILogger<SubscriptionSyncService>>());
    }

    [Fact]
    public async Task SyncAsync_ValidId_UpdatesSubscription()
    {
        // Arrange
        var subscription = new Subscription { Id = 1, ProviderSubscriptionId = "123" };
        _mockRepository.Setup(r => r.GetByIdAsync("123"))
            .ReturnsAsync(subscription);

        // Act
        var result = await _service.SyncAsync("123");

        // Assert
        Assert.True(result.Success);
        _mockRepository.Verify(r => r.UpdateAsync(It.IsAny<Subscription>()), Times.Once);
    }
}
```

### Step 7: Review Documentation

**Files to examine:**
- `README.md`
- `TECH_DEBT.md`

**README.md Checklist:**

| Section | Check | Severity |
|---------|-------|----------|
| **Overview** | Purpose and responsibilities clear | High |
| **Getting Started** | Setup instructions present | Medium |
| **Configuration** | Required settings documented | High |
| **API Endpoints** | Endpoints listed with descriptions | Medium |
| **Architecture** | Layer responsibilities explained | Low |
| **Dependencies** | External service dependencies listed | Medium |

**TECH_DEBT.md Checklist:**

| Check | Severity |
|-------|----------|
| File exists | Medium |
| Items have IDs (TD-001, TD-002) | Low |
| Items have priority (High/Medium/Low) | Medium |
| Security issues marked as High priority | High |
| Remediation approaches documented | Medium |
| Items added for new debt identified in review | Medium |

### Step 8: Generate Report

Output format:

```
## Code Review: {Service}Microservice

### Summary
| Layer | Issues | Critical | High | Medium | Low |
|-------|--------|----------|------|--------|-----|
| Abstractions | X | 0 | X | X | X |
| API | X | 0 | X | X | X |
| Services | X | 0 | X | X | X |
| Infrastructure | X | 0 | X | X | X |
| Tests | X | 0 | X | X | X |
| Documentation | X | 0 | X | X | X |
| **Total** | **X** | **0** | **X** | **X** | **X** |

### Critical Issues
[None found / List of critical issues]

### High Priority Issues
1. **[Layer]** Issue description
   - File: `path/to/file.cs:line`
   - Recommendation: How to fix

### Medium Priority Issues
[Grouped by layer]

### Low Priority Issues
[Grouped by layer]

### Strengths
- [List things done well]

### Recommendations
1. [Actionable recommendation]
2. [Actionable recommendation]

### Technical Debt Items
| ID | Issue | Priority | Notes |
|----|-------|----------|-------|
| TD-XXX | Description | Priority | New/Existing |

*Review completed: {timestamp}*
```

## Review Focus Areas

### --focus=abstractions
Reviews only:
- Entity definitions and relationships
- Interface contracts
- DTO structures
- Layer isolation

### --focus=api
Reviews only:
- FastEndpoints structure
- Authorization policies
- DI registration
- Configuration management

### --focus=services
Reviews only:
- Business logic implementation
- External API integrations
- Error handling patterns
- Audit trail usage

### --focus=infrastructure
Reviews only:
- Repository implementations
- Database context and migrations
- HTTP client configurations
- Data access patterns

### --focus=tests
Reviews only:
- Test coverage analysis
- Mocking patterns
- Test organization
- Assertion quality

### --focus=docs
Reviews only:
- README completeness
- TECH_DEBT tracking
- Code comments quality
- API documentation

## Integration with TECH_DEBT.md

When issues are found that represent technical debt:

1. Check if issue already exists in TECH_DEBT.md
2. If new debt found, propose addition:
   ```markdown
   ## TD-XXX: [Brief Title]

   **Priority:** [High|Medium|Low]
   **Category:** [Security|Performance|Maintainability|etc.]
   **Location:** `path/to/affected/code`

   ### Issue
   [Description of the technical debt]

   ### Impact
   [Why this matters]

   ### Remediation
   [How to fix it]
   ```

3. Include proposed additions in review output

## Configuration

The review uses these reference files when available:

- `.claude/architecture.yaml` - Architecture guardrails
- `.claude/agent-playbook.yaml` - Project-specific rules
- `TECH_DEBT.md` - Existing debt tracking

## See Also

- `/deliver` - Delivery pipeline with integrated code review
- `/architecture-review` - Full architecture analysis
- `/work-init` - Initialize work system with architecture config
