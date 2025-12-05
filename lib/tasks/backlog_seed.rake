namespace :db do
  namespace :seed do
    desc "Create a Backlog project with 10,000+ random tasks for Solid Queue demo"
    task backlog: :environment do
      puts "=" * 60
      puts "Creating Backlog Project for Solid Queue Demo"
      puts "=" * 60

      # Remove existing Backlog project if it exists
      backlog = Project.find_by(name: "Backlog")
      if backlog
        puts "Removing existing Backlog project and its #{backlog.tasks.count} tasks..."
        backlog.destroy
      end

      # Create the Backlog project
      puts "Creating Backlog project..."
      backlog = Project.create!(
        name: "Backlog",
        description: "Demo project with thousands of tasks for testing Solid Queue bulk operations"
      )

      # Task title prefixes
      prefixes = [
        "Fix", "Update", "Refactor", "Implement", "Add", "Remove", "Optimize",
        "Debug", "Test", "Document", "Review", "Deploy", "Configure", "Migrate",
        "Analyze", "Research", "Design", "Build", "Create", "Delete", "Archive",
        "Validate", "Verify", "Investigate", "Monitor", "Audit", "Cleanup",
        "Integrate", "Upgrade", "Downgrade", "Rollback", "Patch", "Enhance"
      ]

      # Task subjects
      subjects = [
        "authentication system", "user profile", "payment gateway", "email service",
        "notification system", "search functionality", "API endpoint", "database query",
        "caching layer", "logging mechanism", "error handling", "validation rules",
        "security policy", "access control", "rate limiting", "data backup",
        "monitoring dashboard", "analytics tracking", "reporting module", "export feature",
        "import process", "webhook integration", "third-party API", "mobile layout",
        "responsive design", "form validation", "file upload", "image processing",
        "video streaming", "chat functionality", "real-time updates", "background job",
        "scheduled task", "cron job", "database migration", "schema update",
        "performance metrics", "load testing", "stress testing", "integration test",
        "unit test", "end-to-end test", "smoke test", "regression test",
        "user interface", "admin panel", "settings page", "profile page",
        "dashboard widget", "navigation menu", "footer section", "header component"
      ]

      # Task description templates
      descriptions = [
        "Needs immediate attention due to production issues",
        "Low priority maintenance task",
        "Enhancement requested by product team",
        "Bug reported by customer support",
        "Technical debt that needs addressing",
        "Performance optimization opportunity",
        "Security vulnerability fix",
        "Feature request from stakeholders",
        "Code quality improvement",
        "Documentation update needed",
        "Dependency update required",
        "Configuration change needed",
        "Deployment preparation task",
        "Monitoring and alerting setup",
        "Data cleanup and migration"
      ]

      # Create 10,000 tasks in batches
      total_tasks = 10_000
      batch_size = 1000
      batches = (total_tasks / batch_size.to_f).ceil

      puts "Creating #{total_tasks} tasks in #{batches} batches..."

      batches.times do |batch_num|
        tasks_data = []

        batch_size.times do |i|
          task_number = (batch_num * batch_size) + i + 1
          break if task_number > total_tasks

          # Generate random task attributes
          prefix = prefixes.sample
          subject = subjects.sample

          # Status distribution: 70% todo, 20% in_progress, 10% done
          status = case rand
                   when 0..0.7 then "todo"
                   when 0.7..0.9 then "in_progress"
                   else "done"
                   end

          # Priority distribution: bell curve around 3
          priority = [1, 2, 2, 3, 3, 3, 3, 4, 4, 5].sample

          # Due date distribution
          due_date = case rand
                     when 0..0.15 then nil # 15% no due date
                     when 0.15..0.30 then rand(1..30).days.ago # 15% overdue
                     when 0.30..0.60 then rand(1..14).days.from_now # 30% due soon
                     else rand(15..90).days.from_now # 40% due later
                     end

          # Completed tasks should have past due dates
          if status == "done" && due_date && due_date > Date.today
            due_date = rand(1..60).days.ago
          end

          tasks_data << {
            project_id: backlog.id,
            title: "#{prefix} #{subject} ##{task_number}",
            description: descriptions.sample,
            status: status,
            priority: priority,
            due_date: due_date,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # Bulk insert for performance
        Task.insert_all(tasks_data)

        completed = [(batch_num + 1) * batch_size, total_tasks].min
        puts "  Progress: #{completed}/#{total_tasks} tasks created (#{(completed.to_f / total_tasks * 100).round(1)}%)"
      end

      # Reload to get accurate counts
      backlog.reload

      # Display summary
      puts "\n" + "=" * 60
      puts "Backlog Project Created Successfully!"
      puts "=" * 60
      puts "Project: #{backlog.name}"
      puts "Total Tasks: #{backlog.tasks.count}"
      puts "\nStatus Distribution:"
      puts "  Todo: #{backlog.tasks.where(status: 'todo').count}"
      puts "  In Progress: #{backlog.tasks.where(status: 'in_progress').count}"
      puts "  Done: #{backlog.tasks.where(status: 'done').count}"
      puts "\nPriority Distribution:"
      (1..5).each do |priority|
        count = backlog.tasks.where(priority: priority).count
        puts "  Priority #{priority}: #{count}"
      end
      puts "\nDue Date Analysis:"
      puts "  No due date: #{backlog.tasks.where(due_date: nil).count}"
      puts "  Overdue: #{backlog.tasks.overdue.count}"
      puts "  Due in next 7 days: #{backlog.tasks.where('due_date BETWEEN ? AND ?', Date.today, 7.days.from_now).count}"
      puts "  Due later: #{backlog.tasks.where('due_date > ?', 7.days.from_now).count}"
      puts "\n" + "=" * 60
      puts "Ready for Solid Queue bulk operations demo!"
      puts "Visit: http://localhost:3000/projects/#{backlog.id}"
      puts "Jobs Dashboard: http://localhost:3000/jobs"
      puts "=" * 60
    end
  end
end
