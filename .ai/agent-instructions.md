# AI Agent Instructions

## Context Loading Priority

1. **Assignment Requirements**: `requeriments.md` (always load first)
2. **Current Status**: `docs/status/progress.yaml` (for progress tracking)
3. **Project Context**: `.ai/context.yaml` (for project metadata)
4. **Coding Standards**: `standards/coding.md` (for code generation)

## Query Routing

- **Assignment requirements**: `requeriments.md`
- **Current progress**: `docs/status/progress.yaml`
- **Project overview**: `README.md`
- **Coding standards**: `standards/coding.md`
- **How to setup**: `README.md` > "Quick Start"
- **API examples**: `README.md` > "JSON API"

## Assignment-Specific Guidelines

### Core Requirements
- Two models: Project (name, description) and Task (title, description, status, priority, due_date)
- CRUD UI for both models
- Task filtering by status (All, Todo, In Progress, Done)
- Task sorting by priority (high→low) or due date (soonest→latest)
- Overdue detection: due_date in past AND status != "done"
- JSON API: GET /api/projects/:project_id/tasks with filtering
- Test coverage for validations, scopes, and API

### When Generating Models

**Project Model:**
```ruby
class Project < ApplicationRecord
  has_many :tasks, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
```

**Task Model:**
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
    when 'priority_desc' then order(priority: :asc)  # 1 is highest
    when 'due_date_asc' then order(Arel.sql('due_date IS NULL, due_date ASC'))
    else all
    end
  }

  def overdue?
    due_date.present? && due_date < Date.today && status != 'done'
  end
end
```

### When Generating Controllers

**Keep controllers thin** - use scopes for filtering:

```ruby
class ProjectsController < ApplicationController
  def show
    @project = Project.find(params[:id])
    @tasks = @project.tasks
                     .with_status(params[:status])
                     .sorted_by(params[:sort])
  end
end
```

**API Controller:**
```ruby
class Api::TasksController < ApplicationController
  def index
    project = Project.find(params[:project_id])
    tasks = project.tasks
                   .with_status(params[:status])

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
```

### When Generating Views

**Project Index** (`/projects`):
- List all projects
- Show project name
- Show task count (total and incomplete)
- Link to create new project

**Project Show** (`/projects/:id`):
- Show project name and description
- Filter form: status dropdown (All, Todo, In Progress, Done)
- Sort dropdown: Priority (high→low), Due Date (soonest→latest)
- Task table: title, status, priority, due date, "Overdue" badge
- Links to add/edit/delete tasks

### When Writing Tests

**Model Tests (RSpec):**
```ruby
RSpec.describe Task, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:status).in_array(%w[todo in_progress done]) }
    it { should validate_numericality_of(:priority).is_in(1..5) }
  end

  describe '#overdue?' do
    it 'returns false when due date is in future' do
      task = build(:task, due_date: 1.day.from_now, status: 'todo')
      expect(task.overdue?).to be false
    end

    it 'returns true when due date is past and status not done' do
      task = build(:task, due_date: 1.day.ago, status: 'todo')
      expect(task.overdue?).to be true
    end

    it 'returns false when due date is past but status is done' do
      task = build(:task, due_date: 1.day.ago, status: 'done')
      expect(task.overdue?).to be false
    end
  end
end
```

**Request Tests (API):**
```ruby
RSpec.describe 'API Tasks', type: :request do
  let(:project) { create(:project) }

  describe 'GET /api/projects/:project_id/tasks' do
    it 'returns tasks as JSON' do
      task = create(:task, project: project)
      get "/api/projects/#{project.id}/tasks"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.first['title']).to eq(task.title)
    end

    it 'filters by status' do
      create(:task, project: project, status: 'todo')
      create(:task, project: project, status: 'done')

      get "/api/projects/#{project.id}/tasks?status=todo"
      json = JSON.parse(response.body)

      expect(json.length).to eq(1)
      expect(json.first['status']).to eq('todo')
    end

    it 'filters overdue tasks' do
      create(:task, project: project, due_date: 1.day.ago, status: 'todo')
      create(:task, project: project, due_date: 1.day.from_now, status: 'todo')

      get "/api/projects/#{project.id}/tasks?overdue=true"
      json = JSON.parse(response.body)

      expect(json.length).to eq(1)
      expect(json.first['overdue']).to be true
    end
  end
end
```

### Query Optimization

**Prevent N+1 queries** when showing project with task counts:
```ruby
# In ProjectsController#index
@projects = Project.left_joins(:tasks)
                   .select('projects.*, COUNT(tasks.id) as tasks_count')
                   .group('projects.id')
```

### Routes

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
end
```

## Development Flow

1. **Start with models**: Create migrations, models with validations and scopes
2. **Write tests**: Model tests for validations, scopes, and overdue? method
3. **Create controllers**: Projects and Tasks CRUD, API endpoint
4. **Build views**: Forms, tables, filtering UI
5. **Test API**: Request specs for JSON endpoints and filtering
6. **Update progress**: Mark completed features in `docs/status/progress.yaml`

## Testing Guidelines

Focus on testing **core business logic**:
- ✓ Model validations
- ✓ Task#overdue? method (3+ cases)
- ✓ Task scopes (with_status, overdue, sorted_by)
- ✓ API endpoint returns JSON
- ✓ API filtering works (status, overdue)

## Documentation Guidelines

Update `docs/status/progress.yaml` as features are completed:
- Mark models as implemented
- Update feature completion percentages
- Track testing progress

## Common Queries

**Q: How do I implement the overdue badge?**
A: In the view, check `task.overdue?` and render a span/badge conditionally.

**Q: How do I handle the status filter "All"?**
A: The `with_status` scope handles nil/blank by returning all tasks.

**Q: How do I sort by priority high→low?**
A: Since 1 is highest priority, use `order(priority: :asc)`.

**Q: What if due_date is NULL in sorting?**
A: Use `order(Arel.sql('due_date IS NULL, due_date ASC'))` to put NULL last.

## Assignment Submission Checklist

- [ ] Project and Task models with proper validations
- [ ] CRUD for both models
- [ ] Task filtering by status
- [ ] Task sorting by priority/due_date
- [ ] Overdue detection in UI
- [ ] JSON API endpoint with filtering
- [ ] Model tests (validations, overdue?, scopes)
- [ ] Request tests (API filtering)
- [ ] README with setup instructions and API examples
- [ ] Clean, RESTful code following Rails conventions
