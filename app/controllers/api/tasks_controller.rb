class Api::TasksController < ApplicationController
  def index
    project = Project.find(params[:project_id])
    tasks = project.tasks

    # Apply status filter if present
    tasks = tasks.with_status(params[:status]) if params[:status].present?

    # Apply overdue filter if present
    tasks = tasks.overdue if params[:overdue] == "true"

    # Return JSON with computed overdue field
    render json: tasks.map { |task|
      {
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        due_date: task.due_date,
        overdue: task.overdue?
      }
    }
  end
end
