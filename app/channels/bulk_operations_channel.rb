class BulkOperationsChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to project-specific bulk operations updates
    project_id = params[:project_id]
    stream_for "project_#{project_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
