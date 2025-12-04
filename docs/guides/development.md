# Development Guide

## Quick Start

```bash
# 1. Create Rails app
rails new task-tracker --database=postgresql

# 2. Navigate to app
cd task-tracker

# 3. Setup database
rails db:create

# 4. Generate models
rails g model Project name:string description:text
rails g model Task project:references title:string description:text status:string due_date:date priority:integer

# 5. Run migrations
rails db:migrate

# 6. Setup RSpec (if using)
bundle add rspec-rails --group development,test
rails g rspec:install

# 7. Start server
rails server
```

## Development Workflow

### 1. Create Models First

**Project Model** (`app/models/project.rb`):
```ruby
class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
```

**Task Model** (`app/models/task.rb`):
```ruby
class Task < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[todo in_progress done] }
  validates :priority, presence: true, numericality: { only_integer: true, in: 1..5 }

  scope :with_status, ->(status) { where(status: status) if status.present? }
  scope :overdue, -> { where('due_date < ? AND status != ?', Date.today, 'done') }
  scope :sorted_by, ->(sort_param) {
    case sort_param
    when 'priority_desc' then order(priority: :asc)
    when 'due_date_asc' then order(Arel.sql('due_date IS NULL, due_date ASC'))
    else all
    end
  }

  def overdue?
    due_date.present? && due_date < Date.today && status != 'done'
  end
end
```

### 2. Generate Controllers

```bash
rails g controller Projects index show new edit
rails g controller Tasks new edit
rails g controller Api::Tasks
```

### 3. Setup Routes

**config/routes.rb**:
```ruby
Rails.application.routes.draw do
  resources :projects do
    resources :tasks
  end

  namespace :api do
    resources :projects, only: [] do
      resources :tasks, only: [:index]
    end
  end

  root "projects#index"
end
```

### 4. Build Views

Create views in this order:
1. `app/views/projects/index.html.erb` - List projects
2. `app/views/projects/show.html.erb` - Show project with tasks
3. `app/views/projects/new.html.erb` - New project form
4. `app/views/tasks/new.html.erb` - New task form

### 5. Implement API

**app/controllers/api/tasks_controller.rb**:
```ruby
module Api
  class TasksController < ApplicationController
    def index
      project = Project.find(params[:project_id])
      tasks = project.tasks.with_status(params[:status])
      tasks = tasks.overdue if params[:overdue] == 'true'

      render json: tasks.map { |task|
        {
          id: task.id,
          title: task.title,
          status: task.status,
          priority: task.priority,
          due_date: task.due_date,
          overdue: task.overdue?
        }
      }
    end
  end
end
```

### 6. Write Tests

See [`docs/guides/testing.md`](testing.md) for testing approach.

## Common Tasks

### Add Seed Data

**db/seeds.rb**:
```ruby
project = Project.create!(name: "Sample Project", description: "A test project")

project.tasks.create!([
  { title: "Setup CI", status: "in_progress", priority: 2, due_date: 5.days.from_now },
  { title: "Fix bug", status: "todo", priority: 1, due_date: 1.day.ago },
  { title: "Write docs", status: "done", priority: 3, due_date: 3.days.ago }
])
```

Run: `rails db:seed`

### Test API in Console

```bash
rails console
```

```ruby
# Create test data
project = Project.create!(name: "Test")
task = project.tasks.create!(title: "Task 1", status: "todo", priority: 1, due_date: 1.day.ago)

# Test overdue detection
task.overdue?  # => true

# Test scopes
Task.overdue
Task.with_status('todo')
Task.sorted_by('priority_desc')
```

### Test API with curl

```bash
# Get all tasks
curl http://localhost:3000/api/projects/1/tasks

# Filter by status
curl http://localhost:3000/api/projects/1/tasks?status=todo

# Get overdue tasks
curl http://localhost:3000/api/projects/1/tasks?overdue=true

# Combine filters
curl http://localhost:3000/api/projects/1/tasks?status=in_progress&overdue=true
```

## Performance Tips

### Prevent N+1 Queries

**Projects Index** - show task counts:
```ruby
# Bad - causes N+1
@projects = Project.all
# In view: project.tasks.count triggers query per project

# Good - use includes
@projects = Project.includes(:tasks)

# Better - use counter_cache or left_joins with select
@projects = Project.left_joins(:tasks)
                   .select('projects.*, COUNT(tasks.id) as tasks_count')
                   .group('projects.id')
```

## Debugging

```bash
# Check routes
rails routes | grep projects

# Open console
rails console

# Check SQL queries in logs
tail -f log/development.log
```

## Resources

- Assignment requirements: [`requeriments.md`](../../requeriments.md)
- Coding standards: [`standards/coding.md`](../../standards/coding.md)
- Current progress: [`docs/status/progress.yaml`](../status/progress.yaml)
