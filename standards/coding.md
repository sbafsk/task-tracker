# Coding Standards

Follow [Ruby Style Guide](https://rubystyle.guide/) and Rails conventions.

## Model Structure

```ruby
class Task < ApplicationRecord
  # 1. Associations
  belongs_to :project

  # 2. Validations
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[todo in_progress done] }
  validates :priority, presence: true, numericality: { only_integer: true, in: 1..5 }

  # 3. Scopes
  scope :with_status, ->(status) { where(status: status) if status.present? }
  scope :overdue, -> { where('due_date < ? AND status != ?', Date.today, 'done') }
  scope :sorted_by, ->(sort_param) {
    case sort_param
    when 'priority_desc' then order(priority: :asc)  # 1 is highest
    when 'due_date_asc' then order(Arel.sql('due_date IS NULL, due_date ASC'))
    else all
    end
  }

  # 4. Instance methods
  def overdue?
    due_date.present? && due_date < Date.today && status != 'done'
  end
end
```

## Controller Patterns

Keep controllers thin - use scopes for filtering.

```ruby
class ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:tasks)
  end

  def show
    @project = Project.find(params[:id])
    @tasks = @project.tasks
                     .with_status(params[:status])
                     .sorted_by(params[:sort])
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project, notice: 'Project created successfully.'
    else
      render :new
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
```

## API Controllers

Return JSON with computed fields.

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

## Views

Use forms with proper error handling.

```erb
<%= form_with(model: [@project, @task]) do |form| %>
  <% if @task.errors.any? %>
    <div class="errors">
      <h3><%= pluralize(@task.errors.count, "error") %> prohibited this task from being saved:</h3>
      <ul>
        <% @task.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>

  <div class="field">
    <%= form.label :status %>
    <%= form.select :status, [['To Do', 'todo'], ['In Progress', 'in_progress'], ['Done', 'done']] %>
  </div>

  <div class="field">
    <%= form.label :priority %>
    <%= form.select :priority, (1..5).to_a %>
  </div>

  <div class="field">
    <%= form.label :due_date %>
    <%= form.date_field :due_date %>
  </div>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```

## Database Queries

**Prevent N+1 queries** - use `includes`:

```ruby
# Bad - N+1 query
@projects = Project.all
@projects.each { |project| puts project.tasks.count }

# Good
@projects = Project.includes(:tasks)
@projects.each { |project| puts project.tasks.size }
```

## Routes

RESTful routes with API namespace.

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

## Testing

### Model Tests (RSpec)

```ruby
RSpec.describe Task, type: :model do
  describe 'validations' do
    it { should belong_to(:project) }
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:status).in_array(%w[todo in_progress done]) }
    it { should validate_numericality_of(:priority).is_in(1..5) }
  end

  describe '#overdue?' do
    it 'returns false when due date is in future' do
      task = build(:task, due_date: 1.day.from_now, status: 'todo')
      expect(task.overdue?).to be false
    end

    it 'returns true when due date is past and not done' do
      task = build(:task, due_date: 1.day.ago, status: 'todo')
      expect(task.overdue?).to be true
    end

    it 'returns false when past due but done' do
      task = build(:task, due_date: 1.day.ago, status: 'done')
      expect(task.overdue?).to be false
    end
  end

  describe 'scopes' do
    let(:project) { create(:project) }

    describe '.with_status' do
      it 'filters by status' do
        todo = create(:task, project: project, status: 'todo')
        done = create(:task, project: project, status: 'done')

        expect(Task.with_status('todo')).to include(todo)
        expect(Task.with_status('todo')).not_to include(done)
      end
    end

    describe '.overdue' do
      it 'returns only overdue tasks' do
        overdue = create(:task, project: project, due_date: 1.day.ago, status: 'todo')
        not_overdue = create(:task, project: project, due_date: 1.day.from_now)

        expect(Task.overdue).to include(overdue)
        expect(Task.overdue).not_to include(not_overdue)
      end
    end
  end
end
```

### Request Tests (API)

```ruby
RSpec.describe 'API Tasks', type: :request do
  let(:project) { create(:project) }

  describe 'GET /api/projects/:project_id/tasks' do
    it 'returns tasks as JSON' do
      task = create(:task, project: project, title: 'Test Task')
      get "/api/projects/#{project.id}/tasks"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.first['title']).to eq('Test Task')
      expect(json.first).to have_key('overdue')
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

## Security

- Use strong parameters in controllers
- Validate all user input
- Parameterized queries (Rails default)
- CSRF protection enabled (Rails default)

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Rails Style Guide](https://rails.rubystyle.guide/)
- [RSpec Best Practices](https://rspec.info/documentation/)
