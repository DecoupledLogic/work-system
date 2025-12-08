---
description: Create a new Azure DevOps work item (helper)
allowedTools:
  - Bash
  - Read
---

# Azure DevOps API: Create Work Item

Creates a new work item in the specified project.

## Usage

```bash
/ado-create-work-item "MyProject" "Task" "Fix login bug"
/ado-create-work-item "MyProject" "Task" "Fix login bug" "Detailed description here"
/ado-create-work-item "MyProject" "Bug" "API error" "Description" 1
/ado-create-work-item "MyProject" "User Story" "As a user..." "Description" 2 "user@email.com"
```

## Input Parameters

- **project** (required): Project name
- **workItemType** (required): Task, Bug, User Story, Feature, Epic
- **title** (required): Work item title
- **description** (optional): Work item description (supports HTML)
- **priority** (optional): Priority 1-4 (1=Critical, 2=High, 3=Medium, 4=Low)
- **assignedTo** (optional): User email to assign to

## Implementation

1. **Validate input:**

   ```bash
   project=$1
   workItemType=$2
   title=$3
   description=${4:-""}
   priority=${5:-""}
   assignedTo=${6:-""}

   if [ -z "$project" ] || [ -z "$workItemType" ] || [ -z "$title" ]; then
     echo "Error: project, workItemType, and title are required"
     exit 1
   fi
   ```

2. **Read credentials:**

   ```bash
   credentials=$(cat ~/.azuredevops/credentials.json)
   serverUrl=$(echo "$credentials" | jq -r '.serverUrl')
   collection=$(echo "$credentials" | jq -r '.collection')
   pat=$(echo "$credentials" | jq -r '.pat')
   ```

3. **Build JSON patch document:**

   ```bash
   # Azure DevOps uses JSON Patch format for work item creation
   patchDoc='['
   patchDoc+='{"op":"add","path":"/fields/System.Title","value":"'"$title"'"}'

   if [ -n "$description" ]; then
     # Escape description for JSON
     escapedDesc=$(echo "$description" | jq -Rs '.')
     patchDoc+=',{"op":"add","path":"/fields/System.Description","value":'"$escapedDesc"'}'
   fi

   if [ -n "$priority" ]; then
     patchDoc+=',{"op":"add","path":"/fields/Microsoft.VSTS.Common.Priority","value":'"$priority"'}'
   fi

   if [ -n "$assignedTo" ]; then
     patchDoc+=',{"op":"add","path":"/fields/System.AssignedTo","value":"'"$assignedTo"'"}'
   fi

   patchDoc+=']'
   ```

4. **Make API request:**

   ```bash
   auth=$(echo -n ":${pat}" | base64)

   # URL encode work item type (e.g., "User Story" -> "User%20Story")
   encodedType=$(echo "$workItemType" | jq -sRr @uri)

   curl -s \
     -H "Authorization: Basic ${auth}" \
     -H "Content-Type: application/json-patch+json" \
     -X POST \
     -d "$patchDoc" \
     "${serverUrl}/${collection}/${project}/_apis/wit/workitems/\$${encodedType}?api-version=6.0"
   ```

5. **Parse response and format output:**

```json
{
  "workItem": {
    "id": 12346,
    "rev": 1,
    "url": "https://azuredevops.discovertec.net/Link/_apis/wit/workItems/12346",
    "fields": {
      "System.Id": 12346,
      "System.Title": "Fix login bug",
      "System.Description": "Detailed description here",
      "System.State": "New",
      "System.WorkItemType": "Task",
      "System.AssignedTo": {
        "displayName": "John Doe",
        "uniqueName": "john.doe@company.com"
      },
      "System.CreatedDate": "2025-01-15T16:00:00Z",
      "System.CreatedBy": {
        "displayName": "API User",
        "uniqueName": "api.user@company.com"
      },
      "Microsoft.VSTS.Common.Priority": 2,
      "System.AreaPath": "MyProject",
      "System.IterationPath": "MyProject"
    },
    "_links": {
      "html": {
        "href": "https://azuredevops.discovertec.net/Link/_workitems/edit/12346"
      }
    }
  }
}
```

## Error Handling

**If required parameters missing:**

```text
Missing required parameters: project, workItemType, and title

Usage: /ado-create-work-item <project> <workItemType> <title> [description] [priority] [assignedTo]
Examples:
  /ado-create-work-item "MyProject" "Task" "Fix bug"
  /ado-create-work-item "MyProject" "Bug" "API error" "Full description" 1
  /ado-create-work-item "MyProject" "User Story" "Title" "" 2 "user@email.com"

Work Item Types: Task, Bug, User Story, Feature, Epic
Priority: 1=Critical, 2=High, 3=Medium, 4=Low
```

**If credentials missing:**

```text
Azure DevOps credentials not found.

Please create ~/.azuredevops/credentials.json
```

**If API request fails:**

- 401 Unauthorized: "Invalid or expired PAT"
- 404 Not Found: "Project 'MyProject' not found"
- 400 Bad Request: "Invalid work item type or field value"

Return error JSON:

```json
{
  "error": true,
  "message": "Work item type 'InvalidType' not found in project 'MyProject'",
  "statusCode": 400,
  "project": "MyProject",
  "workItemType": "InvalidType"
}
```

## Notes

- **JSON Patch:** Azure DevOps uses JSON Patch format (RFC 6902) for creation
- **Content-Type:** Must use `application/json-patch+json`
- **Work Item Types:** Available types depend on project's process template (Agile, Scrum, Basic)
- **Default state:** New work items start in "New" state
- **Area/Iteration:** Defaults to project root; can be set with additional fields
- **HTML support:** Description field supports HTML content
