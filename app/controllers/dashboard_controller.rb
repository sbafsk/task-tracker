class DashboardController < ApplicationController
  def index
    @total_projects = Project.count
    @total_tasks = Task.count

    # Task statistics by status
    @tasks_todo = Task.where(status: "todo").count
    @tasks_in_progress = Task.where(status: "in_progress").count
    @tasks_done = Task.where(status: "done").count

    # Task statistics by priority
    @tasks_high_priority = Task.where(priority: [ 1, 2 ]).count
    @tasks_medium_priority = Task.where(priority: 3).count
    @tasks_low_priority = Task.where(priority: [ 4, 5 ]).count

    # Overdue tasks
    @overdue_tasks = Task.where("due_date < ? AND status != ?", Date.today, "done").count

    # Recent projects
    @recent_projects = Project.order(created_at: :desc).limit(5)
  end
end
