# Testing Guide

## Setup

### Install RSpec

```bash
# Add to Gemfile
bundle add rspec-rails --group development,test
bundle add factory_bot_rails --group development,test
bundle add shoulda-matchers --group test

# Install
rails g rspec:install
```

### Configure RSpec

**spec/rails_helper.rb** (add at end):
```ruby
# Configure shoulda-matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Configure FactoryBot
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

## Test Structure

```
spec/
├── models/
│   ├── project_spec.rb
│   └── task_spec.rb
├── requests/
│   └── api/
│       └── tasks_spec.rb
└── factories/
    ├── projects.rb
    └── tasks.rb
```

## Model Tests

### Project Spec

**spec/models/project_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { should have_many(:tasks).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end
end
```

### Task Spec

**spec/models/task_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { should belong_to(:project) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:status).in_array(%w[todo in_progress done]) }
    it { should validate_numericality_of(:priority).is_in(1..5) }
  end

  describe '#overdue?' do
    let(:project) { create(:project) }

    context 'when due_date is in the future' do
      it 'returns false' do
        task = build(:task, project: project, due_date: 1.day.from_now, status: 'todo')
        expect(task.overdue?).to be false
      end
    end

    context 'when due_date is in the past and status is not done' do
      it 'returns true' do
        task = build(:task, project: project, due_date: 1.day.ago, status: 'todo')
        expect(task.overdue?).to be true
      end
    end

    context 'when due_date is in the past but status is done' do
      it 'returns false' do
        task = build(:task, project: project, due_date: 1.day.ago, status: 'done')
        expect(task.overdue?).to be false
      end
    end

    context 'when due_date is nil' do
      it 'returns false' do
        task = build(:task, project: project, due_date: nil, status: 'todo')
        expect(task.overdue?).to be false
      end
    end
  end

  describe 'scopes' do
    let(:project) { create(:project) }

    describe '.with_status' do
      it 'filters tasks by status' do
        todo_task = create(:task, project: project, status: 'todo')
        done_task = create(:task, project: project, status: 'done')

        result = Task.with_status('todo')

        expect(result).to include(todo_task)
        expect(result).not_to include(done_task)
      end

      it 'returns all tasks when status is nil' do
        task1 = create(:task, project: project, status: 'todo')
        task2 = create(:task, project: project, status: 'done')

        result = Task.with_status(nil)

        expect(result).to include(task1, task2)
      end
    end

    describe '.overdue' do
      it 'returns only overdue tasks' do
        overdue_task = create(:task, project: project, due_date: 1.day.ago, status: 'todo')
        future_task = create(:task, project: project, due_date: 1.day.from_now, status: 'todo')
        done_task = create(:task, project: project, due_date: 1.day.ago, status: 'done')

        result = Task.overdue

        expect(result).to include(overdue_task)
        expect(result).not_to include(future_task, done_task)
      end
    end

    describe '.sorted_by' do
      it 'sorts by priority (high to low)' do
        task_low = create(:task, project: project, priority: 5)
        task_high = create(:task, project: project, priority: 1)
        task_medium = create(:task, project: project, priority: 3)

        result = Task.sorted_by('priority_desc')

        expect(result.to_a).to eq([task_high, task_medium, task_low])
      end

      it 'sorts by due_date (soonest first)' do
        task_far = create(:task, project: project, due_date: 10.days.from_now)
        task_soon = create(:task, project: project, due_date: 1.day.from_now)
        task_no_date = create(:task, project: project, due_date: nil)

        result = Task.sorted_by('due_date_asc')

        expect(result.first).to eq(task_soon)
        expect(result.last).to eq(task_no_date)  # NULL dates last
      end
    end
  end
end
```

## Request Tests (API)

**spec/requests/api/tasks_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe 'API Tasks', type: :request do
  let(:project) { create(:project) }

  describe 'GET /api/projects/:project_id/tasks' do
    it 'returns tasks as JSON' do
      task = create(:task, project: project, title: 'Test Task')

      get "/api/projects/#{project.id}/tasks"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json.first['title']).to eq('Test Task')
      expect(json.first).to have_key('id')
      expect(json.first).to have_key('status')
      expect(json.first).to have_key('priority')
      expect(json.first).to have_key('due_date')
      expect(json.first).to have_key('overdue')
    end

    it 'includes overdue boolean in response' do
      task = create(:task, project: project, due_date: 1.day.ago, status: 'todo')

      get "/api/projects/#{project.id}/tasks"

      json = JSON.parse(response.body)
      expect(json.first['overdue']).to be true
    end

    context 'with status filter' do
      it 'filters tasks by status' do
        todo_task = create(:task, project: project, status: 'todo', title: 'Todo')
        done_task = create(:task, project: project, status: 'done', title: 'Done')

        get "/api/projects/#{project.id}/tasks?status=todo"

        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first['status']).to eq('todo')
        expect(json.first['title']).to eq('Todo')
      end
    end

    context 'with overdue filter' do
      it 'returns only overdue tasks when overdue=true' do
        overdue = create(:task, project: project, due_date: 1.day.ago, status: 'todo')
        not_overdue = create(:task, project: project, due_date: 1.day.from_now, status: 'todo')

        get "/api/projects/#{project.id}/tasks?overdue=true"

        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first['overdue']).to be true
      end
    end

    context 'with combined filters' do
      it 'applies both status and overdue filters' do
        # Overdue in_progress task (should match)
        match = create(:task, project: project, status: 'in_progress', due_date: 1.day.ago)

        # Overdue todo task (wrong status)
        create(:task, project: project, status: 'todo', due_date: 1.day.ago)

        # In_progress future task (not overdue)
        create(:task, project: project, status: 'in_progress', due_date: 1.day.from_now)

        get "/api/projects/#{project.id}/tasks?status=in_progress&overdue=true"

        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first['status']).to eq('in_progress')
        expect(json.first['overdue']).to be true
      end
    end
  end
end
```

## Factories

**spec/factories/projects.rb**:
```ruby
FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { "A sample project description" }
  end
end
```

**spec/factories/tasks.rb**:
```ruby
FactoryBot.define do
  factory :task do
    association :project
    sequence(:title) { |n| "Task #{n}" }
    description { "A sample task description" }
    status { 'todo' }
    priority { 3 }
    due_date { 5.days.from_now }

    trait :overdue do
      due_date { 1.day.ago }
      status { 'todo' }
    end

    trait :done do
      status { 'done' }
    end

    trait :high_priority do
      priority { 1 }
    end
  end
end
```

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/task_spec.rb

# Run specific test
bundle exec rspec spec/models/task_spec.rb:10

# Run with documentation format
bundle exec rspec --format documentation
```

## Test Coverage

Focus on testing:
- ✓ Model validations
- ✓ Model associations
- ✓ `Task#overdue?` method (3+ cases)
- ✓ Task scopes (`with_status`, `overdue`, `sorted_by`)
- ✓ API returns JSON format
- ✓ API status filter
- ✓ API overdue filter
- ✓ API combined filters

## Resources

- [RSpec Rails Documentation](https://rspec.info/documentation/)
- [FactoryBot Guide](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
