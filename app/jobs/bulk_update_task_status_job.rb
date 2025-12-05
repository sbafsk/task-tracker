class BulkUpdateTaskStatusJob < ApplicationJob
  queue_as :default

  # Process tasks in batches to avoid memory issues and database locks
  BATCH_SIZE = 500

  def perform(project_id, new_status, filter_params = {})
    project = Project.find(project_id)
    operation_id = "status_update_#{project_id}_#{Time.current.to_i}"

    # Build the query based on filters
    tasks_query = project.tasks

    # Apply status filter if provided
    if filter_params["current_status"].present?
      tasks_query = tasks_query.where(status: filter_params["current_status"])
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

    # Send initial progress update
    broadcast_progress(project_id, operation_id, 0, total_count, "Starting bulk status update...")

    updated_count = 0

    # Process in batches
    tasks_query.in_batches(of: BATCH_SIZE) do |batch|
      batch.update_all(status: new_status, updated_at: Time.current)
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

    # Send completion message
    broadcast_progress(
      project_id,
      operation_id,
      total_count,
      total_count,
      "✓ Successfully updated #{total_count} tasks to '#{new_status}'",
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

  def broadcast_progress(project_id, operation_id, processed, total, message, completed: false, error: false)
    BulkOperationsChannel.broadcast_to(
      "project_#{project_id}",
      {
        operation_id: operation_id,
        operation_type: "status_update",
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
