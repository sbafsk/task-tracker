class Task < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[todo in_progress done] }
  validates :priority, presence: true, numericality: { only_integer: true, in: 1..5 }

  scope :with_status, ->(status) { where(status: status) if status.present? }
  scope :overdue, -> { where("due_date < ? AND status != ?", Date.today, "done") }
  scope :sorted_by, ->(sort_param) {
    case sort_param
    when "priority_desc"
      order(priority: :asc)  # Priority 1 = highest, so ascending order
    when "due_date_asc"
      order(Arel.sql("due_date IS NULL, due_date ASC"))  # NULL dates last
    else
      all
    end
  }

  def overdue?
    due_date.present? && due_date < Date.today && status != "done"
  end
end
