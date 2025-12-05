# Bulk Operations with Solid Queue

This document explains the bulk operations feature implemented for demonstrating Solid Queue functionality.

## Quick Start

```bash
# 1. Create demo project with 10,000 tasks
bundle exec rails db:seed:backlog

# 2. Start server with Solid Queue
bin/dev

# 3. Visit the Backlog project (URL shown after seed)
# 4. Monitor jobs at http://localhost:3000/jobs
```

## Overview

The Task Tracker app includes a bulk operations system that allows mass updates on thousands of tasks using background jobs powered by **Solid Queue**. This feature demonstrates:

- Asynchronous job processing with Solid Queue
- Real-time progress updates via Action Cable
- Batch processing for database efficiency
- Job monitoring with Mission Control Jobs

## Setup

### 1. Create the Backlog Project

Generate a project with 10,000 random tasks:

```bash
bundle exec rails db:seed:backlog
```

This creates:
- 1 "Backlog" project
- 10,000 tasks with realistic distribution:
  - 70% Todo, 20% In Progress, 10% Done
  - Priorities 1-5 (bell curve around 3)
  - Mix of due dates (15% overdue, 30% due soon, 40% future, 15% no due date)

### 2. Start the Rails Server

```bash
bin/dev
```

This starts both the Rails server and the Solid Queue worker process.

### 3. Visit the Backlog Project

Navigate to the project created (URL shown in seed output, typically):
```
http://localhost:3000/projects/<id>
```

## Using Bulk Operations

The bulk operations UI appears on any project with more than 100 tasks.

### Available Operations

#### 1. Update Status
- Filter by current status (optional)
- Select new status (todo, in_progress, done)
- Execute to update all matching tasks

**Example Use Case**: Mark all "Todo" tasks as "In Progress"

#### 2. Update Priority
- Filter by status (optional)
- Select new priority (1-5)
- Execute to update all matching tasks

**Example Use Case**: Set all overdue tasks to priority 5 (highest)

#### 3. Update Due Date
- Filter by status (optional)
- Choose operation:
  - Set to Tomorrow
  - Set to Next Week
  - Add 7/14/30 Days
  - Clear Due Date
- Execute to update all matching tasks

**Example Use Case**: Push all "Todo" task due dates by 7 days

### Real-Time Progress Tracking

When you execute a bulk operation:

1. Job is enqueued immediately
2. Progress bar appears showing:
   - Current progress percentage
   - Number of tasks processed
   - Status message
3. Updates happen in real-time via Action Cable
4. Page auto-reloads when operation completes

## Monitoring Jobs

### Mission Control Jobs Dashboard

Access the jobs dashboard at:
```
http://localhost:3000/jobs
```

Features:
- View all queued, in-progress, and completed jobs
- See job execution times
- Monitor failed jobs and retry them
- View job arguments and error details

### How It Works

#### Job Classes

Three job classes handle bulk operations:

1. **BulkUpdateTaskStatusJob** ([app/jobs/bulk_update_task_status_job.rb](app/jobs/bulk_update_task_status_job.rb:1))
   - Updates task status in batches of 500
   - Broadcasts progress via Action Cable
   - Handles filtering by current status and overdue

2. **BulkUpdateTaskPriorityJob** ([app/jobs/bulk_update_task_priority_job.rb](app/jobs/bulk_update_task_priority_job.rb:1))
   - Updates task priority in batches of 500
   - Supports filtering by status

3. **BulkUpdateTaskDueDateJob** ([app/jobs/bulk_update_task_due_date_job.rb](app/jobs/bulk_update_task_due_date_job.rb:1))
   - Multiple due date operations
   - Batch processing with progress updates

#### Batch Processing

Each job processes tasks in batches of 500 to:
- Avoid memory issues with large datasets
- Prevent database lock contention
- Provide granular progress updates
- Allow cancellation if needed

#### Action Cable Integration

**BulkOperationsChannel** ([app/channels/bulk_operations_channel.rb](app/channels/bulk_operations_channel.rb:1)) streams real-time updates:

```ruby
# Jobs broadcast progress
BulkOperationsChannel.broadcast_to(
  "project_#{project_id}",
  {
    processed: 1000,
    total: 10000,
    percentage: 10.0,
    message: "Updated 1000 of 10000 tasks"
  }
)
```

**Stimulus Controller** ([app/javascript/controllers/bulk_operations_controller.js](app/javascript/controllers/bulk_operations_controller.js:1)) handles:
- Subscribing to Action Cable channel
- Updating progress UI
- Auto-reloading on completion

#### Solid Queue Configuration

See [config/queue.yml](config/queue.yml:1):

- **Development**: 5 threads, 2 worker processes
- **Batch size**: 500 jobs per dispatcher cycle
- **Polling interval**: 0.1 seconds for fast pickup

## Architecture

```
User Action (UI)
    ↓
ProjectsController (bulk_update_*)
    ↓
Enqueue Job (Solid Queue)
    ↓
Job Worker picks up job
    ↓
Process in batches (500 tasks)
    ↓ (each batch)
Broadcast progress (Action Cable)
    ↓
Stimulus updates UI
    ↓
Reload page on completion
```

## Performance Considerations

### Database Optimization

1. **Batch Updates**: Using `update_all` instead of individual updates
2. **Indexed Columns**: Status, priority, due_date are indexed
3. **Connection Pooling**: Solid Queue uses separate database
4. **Small Delays**: 0.1s sleep between batches prevents overwhelming DB

### Scalability

For production with even larger datasets:

1. Increase `JOB_CONCURRENCY` environment variable
2. Add more worker processes
3. Consider separate queues for bulk operations
4. Tune batch size based on database performance

Example production config:
```yaml
# config/queue.yml
production:
  workers:
    - queues: "bulk_operations"
      threads: 10
      processes: 5
    - queues: "*"
      threads: 3
      processes: 2
```

## Troubleshooting

### Jobs Not Processing

1. Check Solid Queue is running: `ps aux | grep solid_queue`
2. If using `bin/dev`, check [Procfile.dev](Procfile.dev:1)
3. Verify database connection in [config/database.yml](config/database.yml:1)

### Progress Not Updating

1. Check Action Cable is connected (browser console)
2. Verify `cable.yml` development adapter is `async`
3. Ensure JavaScript is enabled

### Slow Performance

1. Check database load: `SELECT * FROM pg_stat_activity;`
2. Verify indexes exist on tasks table
3. Adjust batch size in job classes
4. Increase worker threads/processes

## Testing

Run bulk operations in development:

```bash
# Create backlog project
bundle exec rails db:seed:backlog

# Start server with Solid Queue
bin/dev

# Visit project and test operations
open http://localhost:3000/projects/<id>
```

Monitor jobs:
```bash
open http://localhost:3000/jobs
```

## Key Files

- **Jobs**: `app/jobs/bulk_update_task_*_job.rb`
- **Channel**: `app/channels/bulk_operations_channel.rb`
- **Controller**: `app/controllers/projects_controller.rb` (bulk_* actions)
- **View**: `app/views/projects/show.html.erb`
- **JS**: `app/javascript/controllers/bulk_operations_controller.js`
- **Styles**: `app/assets/stylesheets/application.css`
- **Config**: `config/queue.yml`, `config/cable.yml`
- **Seed**: `lib/tasks/backlog_seed.rake`

## Demo Script

1. Create Backlog: `rails db:seed:backlog`
2. Start server: `bin/dev`
3. Open project page and Jobs dashboard side-by-side
4. Execute bulk operation (e.g., "Mark all TODO as In Progress")
5. Watch progress bar update in real-time
6. Observe job details in Mission Control dashboard
7. See results after page reload

This demonstrates Solid Queue's ability to handle thousands of background jobs efficiently with real-time feedback!
