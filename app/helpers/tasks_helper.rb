module TasksHelper
  PRIORITY_LABELS = {
    1 => "Highest",
    2 => "High",
    3 => "Medium",
    4 => "Low",
    5 => "Lowest"
  }.freeze

  def priority_text(priority)
    PRIORITY_LABELS[priority] || priority.to_s
  end

  def priority_options_for_select(selected = nil)
    PRIORITY_LABELS.map { |value, label| [ label, value ] }
  end
end
