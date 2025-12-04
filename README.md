# Lightweight Project Task Tracker

Simple Rails application for managing projects and their tasks with filtering, sorting, and JSON API support.

[![Rails 8.0](https://img.shields.io/badge/Rails-8.0-red.svg)](https://rubyonrails.org/)
[![Ruby 3.3](https://img.shields.io/badge/Ruby-3.3-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL 15](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)

## What is this?

A lightweight task tracker where users can manage projects and their associated tasks with basic CRUD operations, filtering, sorting, and a simple JSON API.

**Key Features**: Project management, task tracking with status/priority, overdue detection, filtering/sorting, JSON API endpoints.

**Status**: Assignment implementation. See [`docs/requeriments.md`](docs/requeriments.md) for complete specifications.

## Requirements

- **Ruby**: 3.3.0 or higher
- **Rails**: 8.0.0 or higher
- **PostgreSQL**: 15 or higher
- **Bundler**: 2.3 or higher

## Quick Start

```bash
bundle install
rails db:create db:migrate db:seed
rails server
```

Visit [http://localhost:3000](http://localhost:3000)

See [docs/guides/development.md](docs/guides/development.md) for detailed setup instructions.

## Core Features

### Models
- **Project**: name (unique), description, has_many tasks
- **Task**: title, description, status (todo/in_progress/done), priority (1-5), due_date, belongs_to project

### UI Features
- CRUD operations for Projects and Tasks
- Task filtering by status (All, Todo, In Progress, Done)
- Task sorting by priority (high to low) or due date (soonest first)
- Overdue badge when task is past due and not done
- Task counts per project (total and incomplete)

### JSON API

The application provides a RESTful JSON API for accessing task data.

#### Endpoint

**GET** `/api/projects/:project_id/tasks`

Returns a JSON array of tasks for the specified project.

#### Query Parameters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `status` | string | `todo`, `in_progress`, `done` | Filter tasks by status |
| `overdue` | boolean | `true`, `false` | Filter tasks that are overdue |

Parameters can be combined to create complex queries.

#### Response Format

```json
[
  {
    "id": 1,
    "title": "Set up CI",
    "status": "in_progress",
    "priority": 2,
    "due_date": "2025-12-05",
    "overdue": false
  }
]
```

#### Response Fields

- `id` - Task ID (integer)
- `title` - Task title (string)
- `status` - Current status: `todo`, `in_progress`, or `done` (string)
- `priority` - Priority level from 1 (highest) to 5 (lowest) (integer)
- `due_date` - Due date in ISO 8601 format (string, nullable)
- `overdue` - Computed boolean indicating if task is past due and not done (boolean)

#### Example Requests

```bash
# Get all tasks for project 1
curl http://localhost:3000/api/projects/1/tasks

# Get only todo tasks
curl http://localhost:3000/api/projects/1/tasks?status=todo

# Get only overdue tasks
curl http://localhost:3000/api/projects/1/tasks?overdue=true

# Get in-progress tasks that are overdue
curl http://localhost:3000/api/projects/1/tasks?status=in_progress&overdue=true
```

#### Example Response

```json
[
  {
    "id": 1,
    "title": "Set up CI pipeline",
    "status": "in_progress",
    "priority": 2,
    "due_date": "2025-12-05",
    "overdue": false
  },
  {
    "id": 2,
    "title": "Write documentation",
    "status": "todo",
    "priority": 3,
    "due_date": "2025-12-01",
    "overdue": true
  }
]
```

## Development

```bash
rails server                    # Start server
rails console                   # Rails console
bundle exec rspec               # Run tests
rails routes                    # View routes
```

**Full guides**:
- [Development](docs/guides/development.md) - Setup, workflow, debugging
- [Testing](docs/guides/testing.md) - RSpec, factories, test coverage
- [Deployment](docs/guides/deployment.md) - Deploy to Render.com

## Documentation

- [Requirements](docs/requeriments.md) - Complete assignment specifications
- [Documentation Index](docs/index.md) - All documentation links

## Routes

**Web UI:**
- `/projects` - List all projects
- `/projects/:id` - Show project with tasks (supports filtering/sorting)
- `/projects/new` - Create project
- `/projects/:id/edit` - Edit project
- `/projects/:id/tasks/new` - Create task
- `/projects/:id/tasks/:task_id/edit` - Edit task

**API:**
- `GET /api/projects/:project_id/tasks` - List tasks (JSON)

## Notes

This is a coding assignment implementation. No authentication required. Focus is on demonstrating:
- RESTful design patterns
- ActiveRecord scopes and model logic
- Query parameter filtering
- Test coverage of core business logic
- Clean MVC separation

---

**Version**: 1.0.0 | **Assignment**: Rails Task Tracker
