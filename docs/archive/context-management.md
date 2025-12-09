# Context Management

To handle large contexts and facilitate the implementation of the system in one prompt, we can combine several technical solutions for context management and deliverable storage:

## Vector Database for Long-Term Memory

A vector database can store conversational embeddings and provide efficient retrieval for maintaining context over long interactions.

### How It Works

-   Embedding: Each conversational exchange or agent output is embedded into a vector using a language model (e.g., OpenAI's embeddings, Hugging Face).
-   Storage: Store these embeddings in the vector database, indexed by relevant metadata (e.g., agent name, topic, timestamp).
-   Retrieval: Retrieve relevant context using similarity search based on the current query or task prompt.

### Implementation Plan

1.  Store Context: After each agent interaction, generate embeddings for the conversation and store them in the vector database.
2.  Retrieve Context: Query the vector database for the top `N` most relevant embeddings to append as context for the next interaction.
3.  Metadata: Include metadata like `agent_name`, `task`, and `timestamp` for targeted retrieval.

### Advantages

-   Scales efficiently for large and long-running conversations.
-   Ensures only the most relevant context is included in the prompt.

## File Store for Deliverables

A file-based storage system (e.g., Azure Blob Storage, AWS S3, or a simple on-premises file system) can handle deliverable outputs as markdown files.

### How It Works

-   Output Storage: Each agent saves its deliverables as markdown (.`md`) files in a structured directory format.
-   File Metadata: Use metadata (e.g., `agent_name`, `task`, `deliverable_type`, `timestamp`) for organization and retrieval.
-   File Access: Agents can query and update deliverables as needed by referencing these files.

### Implementation Plan

Directory Structure

```
/deliverables/
   /discovery/
      vision_document.md
      epics_and_features.md
   /research/
      user_research.md
      competitor_analysis.md
   /inception/
      product_requirements.md
      stories_list.md
   /elaboration/
      story_specs.md
      tasks_list.md
```

Markdown Format

-   Use markdown for easy readability and compatibility with text-based tools.
-   Include YAML front matter for metadata.

```markdown
---
agent: "Discovery Agent"
deliverable: "Vision Document"
task: "Define the product vision"
timestamp: "2025-01-09"
---
# Vision Document
The product aims to...
```

Read/Write API: Implement APIs to allow agents to read from and write to the file store.

### Advantages

-   Provides a permanent and organized record of outputs.
-   Markdown is lightweight and integrates well with version control systems like Git.

## Combined Workflow

Step-by-Step Integration

1.  Agents Generate Outputs:
    1.  Each agent produces an output and stores it both in the vector database (for memory) and the file store (for persistent storage).
2.  Dynamic Context Construction:
    1.  When an agent is invoked, retrieve the top `N` relevant conversational contexts from the vector database.
    2.  If additional data is needed, reference the file store to fetch full deliverables or previous outputs.
3.  Feedback Loop:
    1.  Agents can refine their outputs based on retrieved context or prior deliverables.

## Tools and Stack

-   Vector Database: Pinecone, Weaviate, Milvus, or FAISS (if self-hosted).
-   File Store: Azure Blob Storage, AWS S3, or any file system with a simple API.
-   Orchestration: Use a backend service (e.g., FastAPI in Python or ASP.NET) to manage context retrieval, file storage, and agent interactions.
-   Markdown Parsing: Libraries like `markdown-it` (JavaScript) or `Markdig` (C\#) for rendering and editing deliverables.
