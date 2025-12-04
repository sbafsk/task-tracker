# Clear existing data
puts "Clearing existing data..."
Task.destroy_all
Project.destroy_all

# Project data
projects_data = [
  {
    name: "Website Redesign",
    description: "Redesign the company website with modern UI/UX and improved accessibility"
  },
  {
    name: "Mobile App Development",
    description: "Build a cross-platform mobile app for iOS and Android using React Native"
  },
  {
    name: "Marketing Campaign Q1",
    description: "Launch comprehensive marketing campaign for Q1 2025"
  },
  {
    name: "API Modernization",
    description: "Migrate legacy REST API to GraphQL and improve performance"
  },
  {
    name: "Customer Portal",
    description: "Build self-service customer portal with account management features"
  },
  {
    name: "Data Analytics Dashboard",
    description: "Create real-time analytics dashboard for business metrics"
  },
  {
    name: "Infrastructure Upgrade",
    description: "Upgrade cloud infrastructure and implement auto-scaling"
  },
  {
    name: "Security Audit",
    description: "Conduct comprehensive security audit and implement fixes"
  },
  {
    name: "Documentation Overhaul",
    description: "Rewrite technical documentation and create video tutorials"
  },
  {
    name: "Employee Onboarding System",
    description: "Build automated onboarding system for new hires"
  }
]

# Task templates with variety of titles and descriptions
task_templates = [
  # Design tasks
  { title: "Create wireframes", description: "Design low-fidelity wireframes for user flow", category: :design },
  { title: "Design mockups", description: "Create high-fidelity mockups in Figma", category: :design },
  { title: "Build design system", description: "Establish design system with components and tokens", category: :design },
  { title: "Conduct user research", description: "Interview users and gather feedback", category: :design },
  { title: "Create prototypes", description: "Build interactive prototypes for testing", category: :design },

  # Development tasks
  { title: "Setup project structure", description: "Initialize project with required dependencies", category: :development },
  { title: "Implement authentication", description: "Add user authentication with OAuth2", category: :development },
  { title: "Build REST API endpoints", description: "Create RESTful API endpoints for core features", category: :development },
  { title: "Add database migrations", description: "Create and run database schema migrations", category: :development },
  { title: "Implement search functionality", description: "Add full-text search with Elasticsearch", category: :development },
  { title: "Write unit tests", description: "Add comprehensive unit test coverage", category: :development },
  { title: "Setup CI/CD pipeline", description: "Configure automated testing and deployment", category: :development },
  { title: "Optimize database queries", description: "Refactor slow queries and add indexes", category: :development },
  { title: "Add caching layer", description: "Implement Redis caching for performance", category: :development },
  { title: "Build admin dashboard", description: "Create admin interface for management", category: :development },

  # Testing tasks
  { title: "Write integration tests", description: "Add end-to-end integration test suite", category: :testing },
  { title: "Perform load testing", description: "Test application under high load conditions", category: :testing },
  { title: "Conduct security testing", description: "Run penetration tests and security scans", category: :testing },
  { title: "UAT with stakeholders", description: "User acceptance testing with business team", category: :testing },

  # DevOps tasks
  { title: "Setup monitoring", description: "Configure APM and error tracking", category: :devops },
  { title: "Implement logging", description: "Add structured logging with ELK stack", category: :devops },
  { title: "Configure backups", description: "Setup automated database backups", category: :devops },
  { title: "Setup staging environment", description: "Create staging environment matching production", category: :devops },
  { title: "Implement auto-scaling", description: "Configure horizontal pod autoscaling", category: :devops },

  # Documentation tasks
  { title: "Write API documentation", description: "Document all API endpoints with examples", category: :documentation },
  { title: "Create user guides", description: "Write comprehensive user documentation", category: :documentation },
  { title: "Record demo videos", description: "Create video tutorials for key features", category: :documentation },
  { title: "Update README", description: "Update project README with latest information", category: :documentation },

  # Management tasks
  { title: "Sprint planning", description: "Plan upcoming sprint with team", category: :management },
  { title: "Code review", description: "Review pull requests from team members", category: :management },
  { title: "Stakeholder meeting", description: "Present progress to stakeholders", category: :management },
  { title: "Team retrospective", description: "Conduct sprint retrospective meeting", category: :management },

  # Bug fixes
  { title: "Fix login bug", description: "Resolve issue with login timeout", category: :bugfix },
  { title: "Fix payment processing", description: "Debug payment gateway integration issue", category: :bugfix },
  { title: "Fix mobile responsiveness", description: "Resolve layout issues on mobile devices", category: :bugfix },
  { title: "Fix data validation", description: "Add missing validation rules", category: :bugfix },
  { title: "Fix email notifications", description: "Debug email delivery failures", category: :bugfix }
]

# Status distribution (realistic project distribution)
# 50% todo, 30% in_progress, 20% done
def weighted_status
  rand_num = rand
  if rand_num < 0.5
    "todo"
  elsif rand_num < 0.8
    "in_progress"
  else
    "done"
  end
end

# Create projects
puts "Creating projects..."
projects = projects_data.map do |project_data|
  Project.create!(project_data)
end

# Create 100 tasks distributed across projects
puts "Creating tasks..."
task_count = 0
target_tasks = 100

projects.each_with_index do |project, project_index|
  # Distribute tasks unevenly (some projects have more tasks)
  tasks_for_project = case project_index
  when 0..2 then 15 # First 3 projects get 15 tasks each
  when 3..5 then 10 # Next 3 projects get 10 tasks each
  when 6..8 then 7  # Next 3 projects get 7 tasks each
  else 4            # Last project gets 4 tasks
  end

  tasks_for_project.times do |i|
    break if task_count >= target_tasks

    # Select a random task template
    template = task_templates.sample

    # Determine status based on weights
    status = weighted_status

    # Priority (1-5, with bias toward 2-3)
    priority = [ 1, 2, 2, 3, 3, 3, 4, 4, 5 ].sample

    # Due date logic
    due_date = if rand < 0.1 # 10% have no due date
      nil
    elsif rand < 0.2 # 20% are overdue
      rand(1..14).days.ago
    elsif rand < 0.5 # 30% are due soon (next 7 days)
      rand(1..7).days.from_now
    else # 40% are due later
      rand(8..30).days.from_now
    end

    # Adjust status for completed tasks (they shouldn't be overdue)
    if status == "done" && due_date && due_date < Date.today
      due_date = rand(1..30).days.ago
    end

    Task.create!(
      project: project,
      title: "#{template[:title]} - Phase #{i + 1}",
      description: template[:description],
      status: status,
      priority: priority,
      due_date: due_date
    )

    task_count += 1
  end
end

# Summary statistics
puts "\n" + "=" * 50
puts "Seed data created successfully!"
puts "=" * 50
puts "Projects: #{Project.count}"
puts "Tasks: #{Task.count}"
puts "\nTask Breakdown:"
puts "  Todo: #{Task.where(status: 'todo').count}"
puts "  In Progress: #{Task.where(status: 'in_progress').count}"
puts "  Done: #{Task.where(status: 'done').count}"
puts "\nOverdue tasks: #{Task.overdue.count}"
puts "\nPriority Distribution:"
(1..5).each do |priority|
  count = Task.where(priority: priority).count
  puts "  Priority #{priority}: #{count}"
end

# Show project task counts
puts "\nTasks per Project:"
Project.includes(:tasks).each do |project|
  incomplete = project.tasks.where.not(status: 'done').count
  puts "  #{project.name}: #{project.tasks.count} total (#{incomplete} incomplete)"
end
puts "=" * 50
