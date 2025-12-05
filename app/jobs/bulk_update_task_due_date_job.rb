class BulkUpdateTaskDueDateJob < ApplicationJob
  queue_as :default

  # Process tasks in batches to avoid memory issues and database locks
  BATCH_SIZE = 500

  def perform(project_id, operation_type, date_value = nil, filter_params = {})
    project = Project.find(project_id)
    operation_id = "due_date_update_#{project_id}_#{Time.current.to_i}"

    # Build the query based on filters
    tasks_query = project.tasks

    # Apply status filter if provided
    if filter_params["status"].present?
      tasks_query = tasks_query.where(status: filter_params["status"])
    end

    # Apply overdue filter if requested
    if filter_params["overdue"] == "true"
      tasks_query = tasks_query.overdue
    end

    # Apply priority filter if provided
    if filter_params["priority"].present?
      tasks_query = tasks_query.where(priority: filter_params["priority"])
    end

    total_count = tasks_query.count

    # Determine the new due date based on operation type
    new_due_date = calculate_due_date(operation_type, date_value)

    # Send initial progress update
    broadcast_progress(project_id, operation_id, 0, total_count, "Starting bulk due date update...")

    updated_count = 0

    # Process in batches
    tasks_query.in_batches(of: BATCH_SIZE) do |batch|
      batch.update_all(due_date: new_due_date, updated_at: Time.current)
      updated_count += batch.size

      # Calculate progress
      progress_percentage = (updated_count.to_f / total_count * 100).round(1)

      # Broadcast progress update
      broadcast_progress(
        project_id,
        operation_id,
        updated_count,
        total_count,
        "Updated #{updated_count} of #{total_count} tasks (#{progress_percentage}%)"
      )

      # Small delay to avoid overwhelming the database
      sleep(0.1)
    end

    # Format message based on operation type
    completion_message = format_completion_message(operation_type, new_due_date, total_count)

    # Send completion message
    broadcast_progress(
      project_id,
      operation_id,
      total_count,
      total_count,
      completion_message,
      completed: true
    )
  rescue StandardError => e
    # Broadcast error
    broadcast_progress(
      project_id,
      operation_id,
      updated_count || 0,
      total_count || 0,
      "✗ Error: #{e.message}",
      error: true
    )
    raise
  end

  private

  def calculate_due_date(operation_type, date_value)
    case operation_type
    when "clear"
      nil
    when "set_specific"
      Date.parse(date_value)
    when "add_7_days"
      7.days.from_now.to_date
    when "add_14_days"
      14.days.from_now.to_date
    when "add_30_days"
      30.days.from_now.to_date
    when "tomorrow"
      Date.tomorrow
    when "next_week"
      1.week.from_now.to_date
    when "next_month"
      1.month.from_now.to_date
    else
      raise ArgumentError, "Invalid operation type: #{operation_type}"
    end
  end

  def format_completion_message(operation_type, new_due_date, count)
    case operation_type
    when "clear"
      "✓ Successfully cleared due dates for #{count} tasks"
    when "set_specific"
      "✓ Successfully set due date to #{new_due_date.strftime('%Y-%m-%d')} for #{count} tasks"
    else
      "✓ Successfully updated due dates for #{count} tasks to #{new_due_date.strftime('%Y-%m-%d')}"
    end
  end

  def broadcast_progress(project_id, operation_id, processed, total, message, completed: false, error: false)
    BulkOperationsChannel.broadcast_to(
      "project_#{project_id}",
      {
        operation_id: operation_id,
        operation_type: "due_date_update",
        processed: processed,
        total: total,
        percentage: total > 0 ? (processed.to_f / total * 100).round(1) : 0,
        message: message,
        completed: completed,
        error: error,
        timestamp: Time.current.iso8601
      }
    )
  end
end
