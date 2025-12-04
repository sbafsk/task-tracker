# Lightweight Project Task Tracker

Simple Rails application for managing projects and their tasks with filtering, sorting, and JSON API support.

[![Rails 8.0](https://img.shields.io/badge/Rails-8.0-red.svg)](https://rubyonrails.org/)
[![Ruby 3.3](https://img.shields.io/badge/Ruby-3.3-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL 15](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)

## What is this?

A lightweight task tracker where users can manage projects and their associated tasks with basic CRUD operations, filtering, sorting, and a simple JSON API.

**Key Features**: Project management, task tracking with status/priority, overdue detection, filtering/sorting, JSON API endpoints.

**Status**: Assignment implementation. See [`docs/requeriments.md`](docs/requeriments.md) for complete specifications.

## Quick Start

```bash
# 1. Install dependencies
bundle install

# 2. Setup database
rails db:create db:migrate

# 3. Start development server
rails server

# 4. Visit application
# http://localhost:3000
```

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
```bash
# Get all tasks for a project
GET /api/projects/:project_id/tasks

# Filter by status
GET /api/projects/1/tasks?status=todo

# Get only overdue tasks
GET /api/projects/1/tasks?overdue=true

# Combine filters
GET /api/projects/1/tasks?status=in_progress&overdue=true
```

**Response format:**
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

## Development

### Running Tests
```bash
# Run full test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/task_spec.rb
```

### Test Coverage
Tests cover:
- Model validations (status, priority, project presence)
- `overdue?` method behavior
- Task scopes (`.with_status`, `.overdue`, `.sorted_by`)
- API endpoint responses and filtering

## Project Requirements

See [`docs/requeriments.md`](requeriments.md) for:
- Complete functional requirements
- Data model specifications
- UI requirements
- API specifications
- Testing requirements

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
