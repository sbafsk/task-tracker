import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = [
    "statusFilter", "newStatus",
    "priorityStatusFilter", "newPriority",
    "dueDateStatusFilter", "dueDateOperation",
    "progressContainer", "progressBar", "progressMessage", "progressStats"
  ]

  static values = {
    projectId: String
  }

  connect() {
    this.consumer = createConsumer()
    this.subscription = null
    this.subscribeToChannel()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribeToChannel() {
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: "BulkOperationsChannel",
        project_id: this.projectIdValue
      },
      {
        received: (data) => {
          this.handleProgressUpdate(data)
        }
      }
    )
  }

  async updateStatus(event) {
    event.preventDefault()

    const newStatus = this.newStatusTarget.value
    const currentStatus = this.statusFilterTarget.value

    const filters = {}
    if (currentStatus) {
      filters.current_status = currentStatus
    }

    await this.executeOperation("bulk_update_status", {
      new_status: newStatus,
      filters: filters
    })
  }

  async updatePriority(event) {
    event.preventDefault()

    const newPriority = this.newPriorityTarget.value
    const status = this.priorityStatusFilterTarget.value

    const filters = {}
    if (status) {
      filters.status = status
    }

    await this.executeOperation("bulk_update_priority", {
      new_priority: newPriority,
      filters: filters
    })
  }

  async updateDueDate(event) {
    event.preventDefault()

    const operation = this.dueDateOperationTarget.value
    const status = this.dueDateStatusFilterTarget.value

    const filters = {}
    if (status) {
      filters.status = status
    }

    await this.executeOperation("bulk_update_due_date", {
      operation_type: operation,
      filters: filters
    })
  }

  async executeOperation(action, params) {
    // Show progress container
    this.showProgressContainer()
    this.updateProgress(0, "Enqueueing job...")

    try {
      const response = await fetch(`/projects/${this.projectIdValue}/${action}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCsrfToken()
        },
        body: JSON.stringify(params)
      })

      const data = await response.json()

      if (response.ok) {
        this.updateProgress(0, "Job enqueued successfully. Waiting for updates...")
      } else {
        this.showError(data.error || "Failed to enqueue job")
      }
    } catch (error) {
      this.showError(`Network error: ${error.message}`)
    }
  }

  handleProgressUpdate(data) {
    const { processed, total, percentage, message, completed, error } = data

    if (error) {
      this.showError(message)
    } else if (completed) {
      this.updateProgress(percentage, message, true)
      this.updateStats(processed, total)

      // Reload page after 2 seconds to show updated tasks
      setTimeout(() => {
        window.location.reload()
      }, 2000)
    } else {
      this.updateProgress(percentage, message)
      this.updateStats(processed, total)
    }
  }

  showProgressContainer() {
    this.progressContainerTarget.classList.remove("hidden")
    this.progressBarTarget.classList.remove("bg-green-500", "bg-red-500")
    this.progressBarTarget.classList.add("bg-blue-500")
  }

  updateProgress(percentage, message, completed = false) {
    this.progressBarTarget.style.width = `${percentage}%`
    this.progressMessageTarget.textContent = message

    if (completed) {
      this.progressBarTarget.classList.remove("bg-blue-500")
      this.progressBarTarget.classList.add("bg-green-500")
    }
  }

  updateStats(processed, total) {
    this.progressStatsTarget.textContent = `Processed: ${processed} / ${total} tasks`
  }

  showError(message) {
    this.progressBarTarget.classList.remove("bg-blue-500")
    this.progressBarTarget.classList.add("bg-red-500")
    this.progressMessageTarget.textContent = message
  }

  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
