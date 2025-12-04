# Rails Patterns

Generate code following Rails assignment patterns and conventions.

## Usage

```
/rails-patterns [pattern-type]
```

## Available Patterns

**model** - Project or Task model with validations and scopes
**controller** - RESTful controller (Projects or Tasks)
**api** - JSON API controller for tasks
**test** - RSpec tests for models or requests

## Guidelines

Follow these standards:
- `standards/coding.md` - Coding conventions
- `requeriments.md` - Assignment requirements

## Examples

```
/rails-patterns model Task
/rails-patterns controller Projects
/rails-patterns api Tasks
/rails-patterns test Task
```

When generating code, ensure:
- Follows assignment requirements
- Includes proper validations
- Uses scopes for filtering
- Prevents N+1 queries
- Includes tests
