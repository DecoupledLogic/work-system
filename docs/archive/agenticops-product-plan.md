# Introduction Your Personal Growth Team

Welcome AgenticOps, where agents work to help you achieve your goals.

Agents handle tasks asynchronously using a credit based system so you can let them run while you focus on other things.

Start working with specialized AI agent teams immediately Zero Setup: No infrastructure or configuration needed Focus on Results: Let us handle the technical details while you focus on your goals.

# Quick Start working with your AI teams in minutes

Ready to start working with your AI teams? Follow this guide to get up and running quickly with AgenticOps. You’ll learn how to set up your account, purchase credits, and begin collaborating with your teams.

## ​ Quick Start Steps

1.  Create Your Account  
    Sign up for AgenticOps. You’ll go through a quick onboarding process and get instant access to our platform.
2.  Hire Your Agent  
    Select the agent that matches your current needs.
3.  Fill Out Intake

    Complete the intake questionnaire for your selected agent

4.  Get Your Deliverables

    Submit an order to begin processing and your deliverables will be available on the orders page.

# Deliverables

Learn about the deliverables you will receive from AgenticOps

## ​Credits System

Credits are the currency of AgenticOps, providing a flexible way to access and manage our AI agents.

Our subscription model provides 300 credits per month at \$249 per quarter. Credits reset monthly, giving you a fresh allocation of 300 credits at the start of each month. Any unused credits from the previous month do not carry over.

These credits can be used flexibly across our entire roster of AI agents - allowing you to mix and match different agents based on your needs. Whether you need help with research, writing, analysis or other tasks, your credits work universally with all available agents.

Agent based work will typically cost between 10-50 credits per task depending on the complexity of the task.

Each Agent displays the credit cost and the specific deliverables you will receive.

## Deliverables

Each Agent will deliver a specific set of deliverables, which are tangible assets you can use. These may include:

-   Written documents like reports, articles, or analysis
-   Video or audio content
-   Background system actions and configurations
-   Data processing results and visualizations

The exact deliverables are clearly listed on each Agent’s profile before you begin working with them.

## ​Accessing Deliverables

Once an agent completes their work, you can access your deliverables from the Orders page. From there, you can:

-   View all completed deliverables in your browser
-   Download deliverables in their native formats (PDF, Word, etc.)
-   Track the status of in-progress work
-   Access historical deliverables from past orders ​

## FAQ

1.  Do credits expire?

    To ensure appropriate usage, credits will expire at the end of the month. You will receive a new allotment of credits at the start of each month.

2.  What if a task fails?

    Right now, if a task fails the system will automatically retry. If you do not receive an automatic refund. Email support and balance will be credited.

3.  Can I get a refund?

    Credits are non-refundable. If you do not use your credits, they will not be carried over to the next month.

4.  How do I purchase more credits?

    This functionality is not yet available and will be released soon.

5.  How do I cancel my subscription?

    You can cancel your subscription through Stripe using the portal link in your sidebar ‘Manage Subscription’.

6.  How do I change my payment method?

    You can change your payment method through stripe using the portal link in your sidebar ‘Manage Subscription’.

# Architecture

Understanding the core architecture of Agentic Templates

AgenticOps follows a modular, microservices-inspired architecture where each template is an independent deployment unit.

This design enables scalability, maintainability, and team autonomy.

The frontend is mostly static and so the core part of the system is the API.

The API can be logically deconstructed into the following components:

![Agentic Team OS Architecture](media/37f53fdba2cb7f927b3a43b3831cb276.png)

**​**

## Core Components

### Orchestrator

The orchestrator is the central routing component that:

-   Handles incoming API requests
-   Routes requests to different parts of the system

### Agents

The Agents are the workers in the system

-   Agents are responsible for making API calls and processing results.
-   You can control the level of autonomy from simple workflows to fully autonomous agents.
-   They do not necessarily have to be AI agents or be fully autonomous.

### Stores

The Stores are any pooled databases, storage or third-party services.

-   Pooled stores are partitioned by user attributes using SaaS Identity.
-   Stores are accessed by the Agent Plane or Control Plane through repository patterns.

### Order Processing

The AgenticOps under the hood is a order processing system. An order is a request incoming to the API. Orders can be processed in two ways:

-   Synchronous processing as a Request Flow
-   Asynchronous processing as an Event Flow

#### Request Flow

![Request Flow Architecture](media/7399885afe5f0cfcf1bc14a049b205f3.png)

The request flow diagram shows the core components and their interactions:

#### Request Flow

-   Requests enter through the orchestrator
-   The orchestrator manages authentication via SaaS Identity
-   Requests are routed to directly to the Control Plane or Agent Plane

#### Event-Driven Architecture

AgenticOps uses an event-driven architecture to handle asynchronous operations and ensure reliable message delivery between components.

#### Event Flow

![Event-Driven Architecture Flow](media/ec6a34ee7068b2739658b2a7b60ccb8a.png)

The event flow demonstrates how different components interact through events:

##### Message Processing Flow

-   Messages are published to topics by various components
-   Topics route messages to appropriate queues based on message attributes
-   Queue consumers process messages asynchronously
-   The Control Plane and Agent Plane subscribe to relevant queues
-   Messages flow through the system in a decoupled manner

## Resiliency

While AgenticOps is designed to help you set up these communication flows, you are responsible for improving the resiliency of the system.

You will need to implement measures to handle desired SLAs, SLOs, uptime requirements and disaster recovery.

With that said, since AgenticOps is built on top of AWS services, you can leverage the high availability and resiliency of AWS to help you achieve your goals.

# AMU Pattern

Understanding the Adapter-Metadata-Usecases Pattern

The AMU (Adapter-Metadata-Usecases) is a general-purpose pattern used throughout AgenticOps, influenced by hexagonal architecture and ports and adapters pattern. It provides a clear separation of concerns and promotes maintainable, testable code.

## Pattern Overview

![AMU Pattern Structure](media/724c9efa21a0b0ba01db11845c1a4b53.png)

The pattern consists of three main components:

### 1. Adapters

Adapters handle external interactions and infrastructure concerns:

This is split into primary and secondary adapters.

-   Primary adapters are for handling incoming requests to the unit. For example a Lambda handler or DynamoDB stream handler.
-   Secondary adapters are for handling outgoing requests to external services. For example an OpenAI client or a database client.

**​**

#### Primary Adapter

Here is an example of a primary adapter in the Orchestrator for an Agent that handles generating a value strategy. for a saas founder.

```
Code Language
/**
 * Lambda function that handles API Gateway requests for the value strategy service
 * Demonstrates the primary adapter pattern by:
 * 1. Authenticating request via SaaS Identity
 * 2. Enriching request with generated IDs
 * 3. Receiving external request
 * 4. Transforming to internal format 
 * 5. Calling usecase
 * 6. Transforming response back to HTTP
 */
async function valueStrategyLambdaHandler(apiGatewayEvent) {
  try {
    // 1. Authentication & Authorization
    // Verify JWT token and extract claims
    const token = apiGatewayEvent.headers.Authorization;
    const identityService = new SaaSIdentityService();
    const userClaims = await identityService.validateToken(token);
    
    if (!userClaims.isValid) {
      return {
        statusCode: 401,
        body: { message: 'Unauthorized' }
      };
    }

    // 2. Request Enrichment
    // Generate unique IDs for tracking and correlation
    const enrichmentService = new EnrichmentService();
    const orderId = enrichmentService.generateOrderId(); // e.g. "ord_123xyz..."
    const deliverableId = enrichmentService.generateDeliverableId(); // e.g. "del_456abc..."
    
    // Optional: Add metadata like timestamp, request source, etc
    const metadata = {
      requestTimestamp: new Date().toISOString(),
      sourceIp: apiGatewayEvent.requestContext.identity.sourceIp,
      userAgent: apiGatewayEvent.requestContext.identity.userAgent
    };

    // 3. Extract and validate input from HTTP request
    // Adapts API Gateway event into domain input format
    const requestBody = parseRequestBody(apiGatewayEvent);
    const validatedInput = {
      orderId: orderId, // Generated ID
      keyId: userClaims.keyId, // From SaaS identity
      userId: userClaims.userId, // From SaaS identity
      deliverableId: deliverableId, // Generated ID
      agentId: requestBody.agentId,
      deliverableName: requestBody.deliverableName,
      applicationIdea: requestBody.applicationIdea,
      idealCustomer: requestBody.idealCustomer,
      problem: requestBody.problem,
      solution: requestBody.solution,
      metadata: metadata // Optional enrichment data
    };

    // 4. Call domain usecase with validated input
    // This is where we cross the boundary from external to internal
    const result = await publishValueStrategyUseCase(validatedInput);

    // 5. Transform usecase result to HTTP response
    // Adapts domain result back to API format
    return {
      statusCode: 200,
      body: {
        orderId: result.orderId,
        deliverableId: result.deliverableId,
        status: result.orderStatus,
        createdAt: result.orderCreatedAt,
        deliverableName: result.deliverableName
      }
    };

  } catch (error) {
    // 6. Error handling and logging
    // Transforms domain errors to HTTP error responses
    console.error('Lambda handler error:', error);
    
    // Map different error types to appropriate HTTP status codes
    if (error.name === 'ValidationError') {
      return {
        statusCode: 400,
        body: { message: 'Invalid request parameters' }
      };
    }
    
    return {
      statusCode: 500,
      body: { message: 'Internal server error' }
    };
  }
}
```

**Key Points of Primary Adapter Pattern:**

-   Handles all Protocol specific logic
-   Integrates with SaaS Identity for auth
-   Enriches the request with metadata before passing it to the usecase
-   Handles response formatting and errors
-   Keeps infrastructure concerns separate from business logic

#### Secondary Adapter

Secondary adapters handle external integrations like AI services, databases, and third-party APIs. Here’s an example of a secondary adapter for OpenAI:

```
/**
 * Example of a secondary adapter for OpenAI integration
 * Demonstrates the secondary adapter pattern by:
 * 1. Initializing external client
 * 2. Handling external service configuration
 * 3. Managing service interactions
 * 4. Error handling and retries
 * 5. Response transformation
 */
export const createValueStrategy = async (input: RequestValueStrategyInput): Promise<Deliverable> => {
  try {
    // Initialize external service client
    const assistant = await client.beta.assistants.create({
      name: "Value Strategist",
      instructions: systemPrompt,
      model: "gpt-4",
      response_format: responseFormat,
      tools: [/* tool configurations */]
    });

    // Create session/context
    const thread = await client.beta.threads.create();

    // Transform and send input
    await client.beta.threads.messages.create(thread.id, {
      role: "user",
      content: `Please create a value proposition for:
        Application Idea: ${input.applicationIdea}
        Ideal Customer: ${input.idealCustomer}
        Problem: ${input.problem}
        Solution: ${input.solution}`
    });

    // Execute external service call
    const run = await client.beta.threads.runs.create(thread.id, {
      assistant_id: assistant.id
    });

    // Handle async completion and status checks
    const completedRun = await waitForRunCompletion(client, thread.id, run.id);
    
    // Transform and validate response
    const messages = await client.beta.threads.messages.list(thread.id);
    const content = parseAndValidateResponse(messages);
    
    // Cleanup resources
    await cleanup(assistant.id, thread.id);

    return content;
  } catch (error) {
    console.error('Error in external service:', error);
    throw error;
  }
};

// Add retry wrapper for resilience
export const runValueStrategy = withRetry(createValueStrategy, {
  retries: 3,
  delay: 1000,
  onRetry: (error) => console.warn('Retrying due to error:', error)
});
```

**Key Points of Secondary Adapter Pattern:**

-   Encapsulates external service integration details
-   Handles service-specific configuration
-   Manages connection lifecycle
-   Implements retry and error handling
-   Transforms data between domain and external formats

### 2. Metadata

Metadata is used to glue the adapters and usecases together. It defines the domain models, types, and interfaces:

```
// System prompts/instructions
export const systemPrompt = () => `
  You are an expert value strategist. Your order is to create 
  a detailed one-page value proposition based on the provided 
  application idea, target customer, problem, and proposed solution.
`;

// Domain schemas and types
export const ValueStrategySchema = z.object({
  deliverableName: z.string(),
  sections: z.object({
    applicationIdea: z.object({
      id: z.string(),
      label: z.string(),
      type: z.literal('text'),
      description: z.string().optional(),
      data: z.string()
    }),
    valueProposition: z.object({
      id: z.string(),
      label: z.string(),
      type: z.literal('text'),
      description: z.string().optional(),
      data: z.string()
    }),
    benefitBreakdown: z.object({
      id: z.string(),
      label: z.string(),
      type: z.literal('list'),
      description: z.string().optional(),
      data: z.array(z.string())
    })
    // ... other sections
  })
});

// Base schemas for requests/responses
export const BasePayloadSchema = z.object({
  userId: z.string(),
  orderId: z.string(),
  deliverableId: z.string(),
  deliverableName: z.string(),
  agentId: z.string()
});

// Input/Output schemas
export const RequestValueStrategyInputSchema = BasePayloadSchema.extend({
  applicationIdea: z.string(),
  idealCustomer: z.string(),
  problem: z.string(),
  solution: z.string()
});

export const DeliverableSchema = z.object({
  deliverableContent: ValueStrategySchema
});

// Type exports
export type RequestValueStrategyInput = z.infer<typeof RequestValueStrategyInputSchema>;
export type Deliverable = z.infer<typeof DeliverableSchema>;
```

**Key Points of Metadata Pattern:**

-   Defines system prompts and instructions
-   Specifies data schemas and validation rules
-   Declares domain types and interfaces
-   Establishes contract between adapters and usecases
-   Provides type safety and runtime validation

**​**

### 3. Usecases

Usecases implement the business logic and orchestrate the flow between adapters. They handle:

-   Business rules and domain logic
-   Flow coordination between adapters
-   Error handling and logging
-   Data transformation and validation

Here’s an example usecase that generates a value strategy:

```
export const createValueStrategyUsecase = async (input: RequestValueStrategyInput): Promise<Message> => {
  console.log("--- Create Value Strategy Usecase ---");
  try {
    // Generate strategy content using OpenAI adapter
    const deliverableContent = await runValueStrategy(input);

    // Transform result into deliverable format
    const deliverable: DeliverableDTO = {
      userId: input.userId,
      orderId: input.orderId,
      deliverableId: input.deliverableId,
      deliverableName: input.deliverableName,
      agentId: input.agentId,
      ...deliverableContent
    };

    // Store result using repository adapter
    await deliverableRepository.saveDeliverable(deliverable);

    // Return success message
    return {
      message: "Value strategy created successfully"
    };

  } catch (error) {
    console.error('Error generating value strategy:', error);
    throw new Error('Failed to generate value strategy');
  }
};
```

**Key Points of Usecase Pattern:**

-   Pure business logic with no infrastructure concerns
-   Coordinates between multiple adapters (e.g., OpenAI and database)
-   Handles error cases and logging
-   Transforms data between adapter formats
-   Returns standardized response types

### Pattern Benefits

1.  **Separation of Concerns**
    -   Clear boundaries between components
    -   Easier to maintain and modify
    -   Better testability
2.  **Dependency Inversion**
    -   Business logic depends on abstractions
    -   Infrastructure details are isolated
    -   Easier to swap implementations
3.  **Testability**
    -   Business logic can be tested in isolation
    -   Easy to mock external dependencies
    -   Clear component boundaries

### Best Practices

1.  **Keep Components Focused**
    -   Adapters handle external concerns
    -   Metadata defines structures
    -   Usecases contain business logic
2.  **Dependency Injection**
    -   Inject dependencies through constructors
    -   Use interfaces for dependencies
    -   Follow IoC principles
3.  **Error Handling**
    -   Define domain-specific errors
    -   Handle errors at appropriate levels
    -   Maintain error boundaries
4.  **Testing Strategy**
    -   Unit test usecases in isolation
    -   Mock adapters in tests
    -   Integration test full flows

# SaaS Identity

Understanding tenant isolation through JWT claims

SaaS Identity is a core concept in AgenticOps that provides secure tenant isolation using JWT (JSON Web Token) claims.

This pattern ensures that each request is properly authenticated and scoped to the correct tenant.

## Overview

The SaaS Identity pattern uses JWT tokens with custom claims to:

-   Scope access to resources
-   Track user credits
-   Rate limit requests
-   Maintain security boundaries

![SaaS Identity Sequence Diagram](media/321e38e16529b89f257e8c52a7841697.png)

The diagram above illustrates the flow of a request through the SaaS Identity system:

1.  The API receives and parses the incoming event with a JWT token
2.  The token is validated with the SaaS Identity Provider(s)
3.  The claims within the token are validated
4.  Finally, the usecase is executed with the validated identity context

Let’s break down how the SaaS identity system works in the agentic-api-template:

## Core Components

1.  **SaaSIdentityVendingMachine Class** (/packages/utils/src/tools/saas-identity.ts):

```
export class SaaSIdentityVendingMachine implements ISaasIdentityVendingMachine {
    private jwtService: IJwtService;

    constructor() {
        this.jwtService = new ClerkService();
    }

    // Key methods:
    async decodeJwt(token: string): Promise<JwtPayload>
    async getValidUserFromAuthHeader(event: APIGatewayProxyEventV2): Promise<ValidUser | null>
    async getValidUser(event: APIGatewayProxyEventV2): Promise<ValidUser>
}
```

While initializing dependencies in the constructor violates the Dependency Inversion Principle, it’s done here intentionally for simplicity. Since we know we’ll only use Clerk as our JWT service, creating the instance directly reduces boilerplate and makes the code more straightforward to use - just instantiate and go! You are free to reverse this pattern or swap in a different JWT service like Okta or Auth0 if you need to. It will just need to implement the IJwtService interface.

1.  **JWT Service** (/packages/utils/src/vendors/jwt-vendor.ts):

```
export class ClerkService implements IJwtService {
    private clerkClient: ClerkClient;
    
    // Handles JWT validation and decoding
    async validateToken(token: string): Promise<JwtPayload>
    async decodeToken(token: string): Promise<JwtPayload>
    async extractTokenFromHeader(event: APIGatewayProxyEventV2): Promise<string>
}
```

## Metadata

You can modify how a user is validated and what data is extracted from the JWT token.

For example, here is the schema for a valid user:

The keyId is from Unkey, and helps downstream services identity the users remaining credits for different requests.

The users keyId is added to the metadata of the JWT token on signup via a webhook.

When working with Clerk you can modify the claims on the JWT token to include this keyID.

This keyId is used to track the users remaining credits for different requests.

1.  **JWT Schema** (/packages/utils/src/metadata/jwt.schema.ts):

```
export const DecodedJwtSchema = z.object({
    sub: z.string(),
    metadata: z.record(z.string(), z.any()).optional(),
});
```

## Authentication Flow

1.  **Token Validation**:
    -   When a request comes in, the getValidUser method is called
    -   It first tries to validate via auth header using getValidUserFromAuthHeader
    -   If successful, returns a ValidUser object
    -   If not, throws an “Unauthorized” error
2.  **JWT Processing**:
    -   The ClerkService handles JWT token validation
    -   Extracts token from Authorization header
    -   Validates token using Clerk’s verification system
    -   Decodes token payload for user information

## Usage in Primary Adapters

Below is an example of a Lambda Primary Adapter in the orchestrator that uses the SaaSIdentityVendingMachine to validate a user.

```
import { SaaSIdentityVendingMachine } from '@utils/tools/saas-identity';

export const requestValueStrategyAdapter = async (
  event: APIGatewayProxyEventV2
): Promise<APIGatewayProxyResultV2> => {
  try {
    const svm = new SaaSIdentityVendingMachine();
    const validUser: ValidUser = await svm.getValidUser(event);

    // Continue with backend logic if user is valid
    // ...

  } catch (error) {
    return handleError(error);
  }
};
```

## Creating the SaaS Identity

### [*​*](https://docs.agenticteamos.com/self-hosting/concepts/saas-identity#1-adding-the-keyid-to-the-jwt-token)1. Adding the KeyId to the JWT Token

When a user signs up, a webhook is handled by the control plane of the system.

Inside of the user module, the registerUserAdapter is called.

Here you will likely want to add any additional validation needed and in the usecase handler onboarding your user.

![Signup Webhook Configuration](media/061b646801a752f23462c26421bb4406.png)

/control-plane/user/adapters/primary/register-user.adapter.ts

```
export const registerUserAdapter = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  try {
    const clerkService = new ClerkService();
    // Validate the webhook event
    const evt = await clerkService.validateWebhookEvent(event);
    switch (evt?.type) {
      case 'user.created':
        const parsedUserData = UserDetailsSchema.parse(evt.data);
        const newUser: NewUser = {
          userId: parsedUserData.id,
        }
        await registerUserUseCase(newUser);
       ///...
    }
  }
};
```

Go to the page on [**Clerk**](https://docs.agenticteamos.com/self-hosting/concepts/intgrations/clerk) for more information on how to configure the webhook for this flow.

### 2. Updating User’s KeyID Properties

When a user makes a purchase, a webhook is handled by the control plane of the system.

Inside of the billing module, the checkoutSessionWebhookAdapter is called.

Here you will likely want to add any additional validation needed and in the usecase handler updating the users keyId properties.

This is where you can add credits to the users API key and update the keyId properties based on the purchase.

![Purchase Webhook Configuration](media/034d24d4ceb43619974b4d93351f669d.png)

/control-plane/billing/adapters/primary/checkout-session-completed.adapter.ts

```
export const checkoutSessionWebhookAdapter = async (event: any) => {
    console.log("---Checkout session webhook adapter---");
    const signature = event.headers["stripe-signature"];
    let stripeEvent;
    try {
        stripeEvent = await stripe.webhooks.constructEvent(event.body, signature, stripeWebhookSecret);   
    } catch (err) {
        console.error(`⚠️  Webhook signature verification failed.` , err);
        return { statusCode: 400, body: "Invalid signature" };
    }
    const session = stripeEvent.data.object;
    switch (stripeEvent.type) {
        case "checkout.session.completed":
            const metadataRefill = MetadataRefillSchema.parse(session.metadata);
            const updateApiKeyCommand = {
                keyId: metadataRefill.keyId,
                refill: {
                    interval: metadataRefill.interval,
                    amount: parseInt(metadataRefill.amount),
                    refillDay: parseInt(metadataRefill.refillDay)
                }
            };
            await checkoutSessionCompletedUseCase(updateApiKeyCommand);
            break;
    }
}
```

Go to the page [**Setup Webhooks**](https://docs.agenticteamos.com/guides/setup-webhooks) for more information on how to configure the webhooks to enable this flow.
