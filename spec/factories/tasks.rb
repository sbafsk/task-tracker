FactoryBot.define do
  factory :task do
    association :project
    sequence(:title) { |n| "Task #{n}" }
    description { "A sample task description" }
    status { "todo" }
    due_date { 1.week.from_now }
    priority { 3 }

    trait :in_progress do
      status { "in_progress" }
    end

    trait :done do
      status { "done" }
    end

    trait :overdue do
      due_date { 1.day.ago }
      status { "todo" }
    end

    trait :high_priority do
      priority { 1 }
    end

    trait :low_priority do
      priority { 5 }
    end
  end
end
