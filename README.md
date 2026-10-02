# Crafting Software Job Processing Challenge

An Elixir/Phoenix API for validating and sorting tasks based on their dependencies.

## Overview

A job consists of multiple tasks. Each task has:

- `name` - required string
- `command` - required string
- `requires` - optional list of task names

The API validates the request, resolves task dependencies, and returns the tasks in the order they should be executed.

The service can return the result in two formats:

- JSON
- Bash script

## Approach

The implementation is intentionally simple and fail-fast.

### 1. Validate the task list

Each task is validated before dependency sorting begins.

Validation checks:

- Only `name`, `command`, and `requires` fields are allowed.
- `name` and `command` are required.
- Required fields must contain non-empty strings.
- `requires`, when present, must be a list.
- Every value in `requires` must be a string.
- A task cannot require itself.
- Task names must be unique.
- Every referenced dependency must exist.

Validation stops as soon as the first error is found.

For example, if several tasks contain invalid fields, the API returns the first validation error encountered rather than collecting all errors from the request.

This keeps the validation flow simple and prevents further processing of an invalid job.

### 2. Resolve dependencies

After validation, tasks are sorted according to their `requires` fields.

A task can be selected when all of its dependencies have already been completed.

For example:

```
text
task-1
   ↓
task-3
   ↓
task-2
   ↓
task-4
```

results in:
```
task-1
task-3
task-2
task-4
```

Tasks with no dependencies are immediately eligible to be processed.
If there are remaining tasks but no task can be resolved, the dependency graph is considered circular and an error is returned.

### 3. Generate Bash representation
The sorted tasks can also be converted into a Bash script.

For example:
```
#!/usr/bin/env bash
touch /tmp/file1
echo 'Hello World!' > /tmp/file1
cat /tmp/file1
rm /tmp/file1
```

The commands are returned as text. The API does not execute the generated Bash script.

### API
Sort tasks as JSON

```
POST /api/jobs/sort-tasks
Content-Type: application/json
```

#### Request:
```
{
  "tasks": [
    {
      "name": "task-1",
      "command": "touch /tmp/file1"
    },
    {
      "name": "task-2",
      "command": "cat /tmp/file1",
      "requires": ["task-3"]
    },
    {
      "name": "task-3",
      "command": "echo 'Hello World!' > /tmp/file1",
      "requires": ["task-1"]
    },
    {
      "name": "task-4",
      "command": "rm /tmp/file1",
      "requires": ["task-2", "task-3"]
    }
  ]
}

```

#### Response:
```
{
  "tasks": [
    {
      "name": "task-1",
      "command": "touch /tmp/file1"
    },
    {
      "name": "task-3",
      "command": "echo 'Hello World!' > /tmp/file1"
    },
    {
      "name": "task-2",
      "command": "cat /tmp/file1"
    },
    {
      "name": "task-4",
      "command": "rm /tmp/file1"
    }
  ]
}
```

### Return Bash representation
```
POST /api/jobs/sort-tasks/bash
Content-Type: application/json
```

The request body is the same as the JSON endpoint.

#### Response:
```
#!/usr/bin/env bash
touch /tmp/file1
echo 'Hello World!' > /tmp/file1
cat /tmp/file1
rm /tmp/file1
```

The response is returned as text/plain.


### Error Handling
Invalid requests return:

```
400 Bad Request
```

with a JSON body:

```
{
  "error": "error message"
}
```

Examples include:

```
Missing tasks list
Duplicate task name
Missing required field
Invalid field type
Unknown dependency
Self dependency
Circular dependency
```

The implementation follows a fail-fast strategy: processing stops at the first error encountered.


### Running the Project
Install dependencies:

```
mix deps.get
```

Start the Phoenix server:
```
mix phx.server
```

The API will be available at:
```
http://localhost:4000
```

### Running Tests
Run the complete test suite:
```
mix test
```

Run the controller tests only:
```
mix test test/crafting_software_job_processing_challenge_web/jobs_controller_test.exs
```

### Project Structure
```
lib/
├── crafting_software_job_processing_challenge/
│   └── jobs.ex
└── crafting_software_job_processing_challenge_web/
    ├── controllers/
    │   └── jobs_controller.ex
    └── router.ex

test/
├── crafting_software_job_processing_challenge/
└── crafting_software_job_processing_challenge_web/
    └── jobs_controller_test.exs
```

### Implementation Notes
The application does not use a database because the challenge only requires processing the submitted job and returning the resolved result.

The main flow is:
```
HTTP Request
    |
    v
Controller
    |
    v
Validate Tasks
    |
    v
Validate Dependencies
    |
    v
Resolve Task Order
    |
    +------------------+
    |                  |
    v                  v
JSON Response     Bash Representation
```

The Bash representation is generated from the already-resolved task order and is not executed by the API.

### Technology
- Elixir
- Phoenix
- OTP
- Jason
- ExUnit

This implementation intentionally avoids a database, LiveView, HTML, and frontend assets because they are not required for the challenge.