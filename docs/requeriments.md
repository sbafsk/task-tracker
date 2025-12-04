rails-coding-assignment
Assignment: Lightweight Project Task Tracker

Assignment: Lightweight Project Task Tracker
You’ll build a small Rails app where a user can manage projects and their tasks, with basic filtering, sorting, and a simple JSON API.

High-Level Requirements
Build a Rails application with:

Two main models: Project and Task
Basic CRUD UI for both
Filtering / sorting on tasks
Some business logic (status, overdue detection)
A simple JSON API endpoint
Test coverage for the core logic
No authentication is required.

Functional Requirements
1. Data Model
Create two models with the following attributes:

Project

name (string, required, unique)
description (text, optional)
Task

project_id (references Project)
title (string, required)
description (text, optional)
status (string, required; allowed: "todo", "in_progress", "done")
due_date (date, optional)
priority (integer, required; 1–5 inclusive, where 1 is highest priority)
Constraints & Validations

A Task must belong to a Project.
status must be in the allowed list.
priority must be between 1 and 5.
name on Project must be unique and present.
2. Project Management UI
Create standard CRUD for Project:

/projects

List all projects with:
Name
Number of tasks
Number of tasks not done yet
Link to create a new project.
/projects/:id

Show:
Project name & description
A table of all tasks in the project (see Task UI)
Provide links to:
Edit project
Delete project
Add a new task to this project
You may use scaffold generators, but you must hand-edit controllers/views to meet the requirements.

3. Task Management UI
Tasks are primarily managed from within a project.

On /projects/:id:

Display a table of tasks with columns:

Title
Status
Priority
Due date
A badge or label showing "Overdue" if:
due_date is present
AND due_date is in the past
AND status is not "done"
Each row should have actions:

View task
Edit task
Delete task
New/Edit Task Form

A form that allows setting:

Title
Description
Status (select dropdown with the three options)
Due date (date field)
Priority (1–5, select or number field)
When validation fails, display error messages at the top of the form.

4. Filtering and Sorting Tasks
On the project show page (/projects/:id):

Add a filter/sort form above the tasks table with:
Status filter: All, Todo, In Progress, Done
Sort by: dropdown with Priority (high → low) and Due Date (soonest → latest)
Filters should be applied via query params on the project show route (e.g. /projects/1?status=todo&sort=priority_desc).
The combination of filter + sort should apply together.
5. JSON API Endpoint
Expose a simple read-only API for tasks:

Endpoint:

GET /api/projects/:project_id/tasks
Behavior:

Returns all tasks for the given project as JSON.
Supports optional query parameters:
status (same allowed values, filters tasks)
overdue=true (if present and true, only return tasks that are overdue according to the same rules as the UI)
JSON format (example):
json

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
Notes:

overdue should be a computed boolean field in the JSON, not stored in the DB.
Do not require authentication for this endpoint.
6. Model Logic
In the Task model:

Implement an instance method:
ruby

def overdue?
  due_date.present? && due_date < Date.today && status != "done"
end
(or equivalent)

Implement scopes:
.with_status(status) – safely handles nil/blank by returning all.
.overdue – returns tasks that are overdue.
.sorted_by(sort_param) – where sort_param supports priority_desc and due_date_asc.
Use these scopes in both the HTML controller and the API controller.

7. Tests
Write tests (RSpec or Minitest) that cover:

Model tests for Task:

Validations for status, priority, and presence of title and project.
overdue? method behavior in at least 3 cases:
Due in future → not overdue.
Due in past and status not "done" → overdue.
Due in past and status "done" → not overdue.
Request / Controller tests (or system tests):

The API endpoint returns tasks for a project in JSON.
The status filter works on the API (e.g., request with status=todo returns only todo tasks).
The overdue=true filter on the API returns only overdue tasks.
You don’t need 100% coverage; make sure the core logic is tested.

Non-Functional Requirements
Use Rails 7 or 8 conventions (just state which version you target).
Use standard ERB templates (no need for fancy CSS, but basic readable markup is expected).
Keep controllers reasonably lean; push query logic into scopes.
Use RESTful routes. API routes should be namespaced under /api.
Provide:
A link to a public Git repo.
Instructions in README.md:
Rails version
Setup steps
How to run tests
Example API requests (with query parameters).
Any notes on tradeoffs, shortcuts, or things you would improve with more time.