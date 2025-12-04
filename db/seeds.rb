# Clear existing data
Task.destroy_all
Project.destroy_all

# Create sample projects
project1 = Project.create!(
  name: "Website Redesign",
  description: "Redesign the company website with modern UI/UX"
)

project2 = Project.create!(
  name: "Mobile App Development",
  description: "Build a mobile app for iOS and Android"
)

project3 = Project.create!(
  name: "Marketing Campaign",
  description: "Launch Q1 marketing campaign"
)

# Create tasks for Website Redesign
Task.create!(
  project: project1,
  title: "Design homepage mockup",
  description: "Create high-fidelity mockup for the new homepage",
  status: "done",
  priority: 1,
  due_date: 5.days.ago
)

Task.create!(
  project: project1,
  title: "Implement responsive navigation",
  description: "Build mobile-friendly navigation menu",
  status: "in_progress",
  priority: 1,
  due_date: 2.days.from_now
)

Task.create!(
  project: project1,
  title: "Fix checkout flow bug",
  description: "Users can't complete purchases on mobile",
  status: "todo",
  priority: 1,
  due_date: 1.day.ago
)

Task.create!(
  project: project1,
  title: "Add contact form",
  description: "Implement contact form with validation",
  status: "todo",
  priority: 3,
  due_date: 1.week.from_now
)

# Create tasks for Mobile App
Task.create!(
  project: project2,
  title: "Setup React Native project",
  description: "Initialize project with necessary dependencies",
  status: "done",
  priority: 1,
  due_date: 10.days.ago
)

Task.create!(
  project: project2,
  title: "Implement user authentication",
  description: "Add login and signup functionality",
  status: "in_progress",
  priority: 1,
  due_date: 3.days.ago
)

Task.create!(
  project: project2,
  title: "Design app icon",
  description: "Create app icon for both iOS and Android",
  status: "todo",
  priority: 4,
  due_date: 2.weeks.from_now
)

# Create tasks for Marketing Campaign
Task.create!(
  project: project3,
  title: "Write email campaign copy",
  description: "Draft email content for newsletter",
  status: "todo",
  priority: 2,
  due_date: 3.days.from_now
)

Task.create!(
  project: project3,
  title: "Create social media graphics",
  description: "Design graphics for Instagram and Twitter",
  status: "todo",
  priority: 2,
  due_date: 5.days.from_now
)

Task.create!(
  project: project3,
  title: "Schedule posts",
  description: "Schedule social media posts for next week",
  status: "todo",
  priority: 3,
  due_date: nil
)

puts "Seed data created successfully!"
puts "Projects: #{Project.count}"
puts "Tasks: #{Task.count}"
puts "Overdue tasks: #{Task.overdue.count}"
