class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :bulk_update_status, :bulk_update_priority, :bulk_update_due_date ]

  def index
    @projects = Project.includes(:tasks).all
  end

  def show
    @tasks = @project.tasks

    # Apply status filter if present
    @tasks = @tasks.with_status(params[:status]) if params[:status].present?

    # Apply sorting if present
    @tasks = @tasks.sorted_by(params[:sort]) if params[:sort].present?
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_name = @project.name
    @project.destroy
    redirect_to projects_url, notice: "Project '#{project_name}' and all its tasks were successfully deleted."
  end

  # Bulk operations
  def bulk_update_status
    new_status = params[:new_status]
    filter_params = params[:filters] || {}

    unless %w[todo in_progress done].include?(new_status)
      return render json: { error: "Invalid status" }, status: :unprocessable_entity
    end

    # Enqueue the job
    job = BulkUpdateTaskStatusJob.perform_later(@project.id, new_status, filter_params)

    render json: {
      success: true,
      message: "Bulk status update job enqueued",
      job_id: job.job_id,
      project_id: @project.id
    }
  end

  def bulk_update_priority
    new_priority = params[:new_priority].to_i
    filter_params = params[:filters] || {}

    unless (1..5).include?(new_priority)
      return render json: { error: "Invalid priority (must be 1-5)" }, status: :unprocessable_entity
    end

    # Enqueue the job
    job = BulkUpdateTaskPriorityJob.perform_later(@project.id, new_priority, filter_params)

    render json: {
      success: true,
      message: "Bulk priority update job enqueued",
      job_id: job.job_id,
      project_id: @project.id
    }
  end

  def bulk_update_due_date
    operation_type = params[:operation_type]
    date_value = params[:date_value]
    filter_params = params[:filters] || {}

    valid_operations = %w[clear set_specific add_7_days add_14_days add_30_days tomorrow next_week next_month]
    unless valid_operations.include?(operation_type)
      return render json: { error: "Invalid operation type" }, status: :unprocessable_entity
    end

    # Enqueue the job
    job = BulkUpdateTaskDueDateJob.perform_later(@project.id, operation_type, date_value, filter_params)

    render json: {
      success: true,
      message: "Bulk due date update job enqueued",
      job_id: job.job_id,
      project_id: @project.id
    }
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
