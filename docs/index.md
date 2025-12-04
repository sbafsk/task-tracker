# Task Tracker Documentation

**Assignment**: Lightweight Project Task Tracker

**Current Status**: See [`docs/status/progress.yaml`](status/progress.yaml)

## Quick Links

**Assignment**:
- [`docs/requeriments.md`](../requeriments.md) - Complete assignment requirements
- [`README.md`](../README.md) - Project overview and API examples

**Development**:
- [`docs/guides/development.md`](guides/development.md) - Setup and workflow
- [`docs/guides/testing.md`](guides/testing.md) - Testing approach
- [`standards/coding.md`](../standards/coding.md) - Code patterns and examples

**AI Context**:
- [`.ai/context.yaml`](../.ai/context.yaml) - Project metadata
- [`.ai/agent-instructions.md`](../.ai/agent-instructions.md) - AI guidelines

## Tech Stack

- **Backend**: Rails 8.0+, Ruby 3.3+
- **Database**: PostgreSQL 15+
- **Views**: ERB templates
- **Testing**: RSpec
- **API**: JSON endpoints

## Models

**Project**:
- `name` (string, required, unique)
- `description` (text, optional)
- `has_many :tasks`

**Task**:
- `title` (string, required)
- `description` (text, optional)
- `status` (todo/in_progress/done)
- `priority` (1-5, where 1 is highest)
- `due_date` (date, optional)
- `belongs_to :project`

## Key Features

1. **CRUD Operations**: Projects and Tasks
2. **Filtering**: Filter tasks by status
3. **Sorting**: Sort by priority (high→low) or due date (soonest→latest)
4. **Overdue Detection**: Automatic overdue badge
5. **JSON API**: Read-only API with filtering

## Daily Commands

```bash
# Start server
rails server

# Run console
rails console

# Run tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/task_spec.rb
```

## Documentation Structure

### For Developers
- Start with `docs/requeriments.md` for requirements
- Check `docs/status/progress.yaml` for current progress
- Follow patterns in `standards/coding.md`
- Use `docs/guides/development.md` for workflow

### For AI Assistants
- Load `.ai/context.yaml` first
- Check `docs/status/progress.yaml` for status queries
- Reference `standards/coding.md` for code generation
- Follow `.ai/agent-instructions.md` guidelines

---

**Remember**: This is an assignment - keep it simple, focus on core requirements, and write comprehensive tests.
