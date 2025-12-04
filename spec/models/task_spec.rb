require 'rails_helper'

RSpec.describe Task, type: :model do
  describe "associations" do
    it { should belong_to(:project) }
  end

  describe "validations" do
    subject { build(:task) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[todo in_progress done]) }
    it { should validate_presence_of(:priority) }
    it { should validate_numericality_of(:priority).only_integer }
    it { should allow_value(1, 2, 3, 4, 5).for(:priority) }
    it { should_not allow_value(0, 6, 10).for(:priority) }
  end

  describe "database constraints" do
    let(:project) { create(:project) }

    it "requires title at database level" do
      task = Task.new(project: project, status: "todo", priority: 3)
      expect { task.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "requires status at database level" do
      task = Task.new(project: project, title: "Test", priority: 3)
      task.status = nil
      expect { task.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "requires priority at database level" do
      task = Task.new(project: project, title: "Test", status: "todo")
      expect { task.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "defaults status to 'todo'" do
      task = Task.new(project: project, title: "Test", priority: 3)
      task.save(validate: false)
      task.reload
      expect(task.status).to eq("todo")
    end
  end

  describe "#overdue?" do
    let(:project) { create(:project) }

    context "when due_date is nil" do
      it "returns false" do
        task = create(:task, project: project, due_date: nil, status: "todo")
        expect(task.overdue?).to be false
      end
    end

    context "when due_date is in the future" do
      it "returns false" do
        task = create(:task, project: project, due_date: 1.day.from_now, status: "todo")
        expect(task.overdue?).to be false
      end
    end

    context "when due_date is today" do
      it "returns false" do
        task = create(:task, project: project, due_date: Date.today, status: "todo")
        expect(task.overdue?).to be false
      end
    end

    context "when due_date is in the past and status is not done" do
      it "returns true for todo status" do
        task = create(:task, project: project, due_date: 1.day.ago, status: "todo")
        expect(task.overdue?).to be true
      end

      it "returns true for in_progress status" do
        task = create(:task, project: project, due_date: 1.day.ago, status: "in_progress")
        expect(task.overdue?).to be true
      end
    end

    context "when due_date is in the past but status is done" do
      it "returns false" do
        task = create(:task, project: project, due_date: 1.day.ago, status: "done")
        expect(task.overdue?).to be false
      end
    end
  end

  describe ".with_status scope" do
    let!(:project) { create(:project) }
    let!(:todo_task) { create(:task, project: project, status: "todo") }
    let!(:in_progress_task) { create(:task, project: project, status: "in_progress") }
    let!(:done_task) { create(:task, project: project, status: "done") }

    it "returns tasks with the specified status" do
      expect(Task.with_status("todo")).to contain_exactly(todo_task)
      expect(Task.with_status("in_progress")).to contain_exactly(in_progress_task)
      expect(Task.with_status("done")).to contain_exactly(done_task)
    end

    it "returns all tasks when status is nil" do
      expect(Task.with_status(nil).count).to eq(3)
    end

    it "returns all tasks when status is empty string" do
      expect(Task.with_status("").count).to eq(3)
    end
  end

  describe ".overdue scope" do
    let!(:project) { create(:project) }
    let!(:overdue_todo) { create(:task, project: project, due_date: 1.day.ago, status: "todo") }
    let!(:overdue_in_progress) { create(:task, project: project, due_date: 2.days.ago, status: "in_progress") }
    let!(:overdue_but_done) { create(:task, project: project, due_date: 1.day.ago, status: "done") }
    let!(:future_task) { create(:task, project: project, due_date: 1.day.from_now, status: "todo") }
    let!(:no_due_date) { create(:task, project: project, due_date: nil, status: "todo") }

    it "returns only overdue tasks that are not done" do
      expect(Task.overdue).to contain_exactly(overdue_todo, overdue_in_progress)
    end

    it "excludes tasks with done status" do
      expect(Task.overdue).not_to include(overdue_but_done)
    end

    it "excludes tasks with future due dates" do
      expect(Task.overdue).not_to include(future_task)
    end

    it "excludes tasks without due dates" do
      expect(Task.overdue).not_to include(no_due_date)
    end
  end

  describe ".sorted_by scope" do
    let!(:project) { create(:project) }
    let!(:task_priority_1) { create(:task, project: project, priority: 1, due_date: 3.days.from_now) }
    let!(:task_priority_3) { create(:task, project: project, priority: 3, due_date: 2.days.from_now) }
    let!(:task_priority_5) { create(:task, project: project, priority: 5, due_date: 1.day.from_now) }
    let!(:task_no_date) { create(:task, project: project, priority: 2, due_date: nil) }

    context "when sorting by priority_desc" do
      it "orders by priority ascending (1 is highest priority)" do
        tasks = Task.sorted_by("priority_desc")
        expect(tasks.to_a).to eq([task_priority_1, task_no_date, task_priority_3, task_priority_5])
      end
    end

    context "when sorting by due_date_asc" do
      it "orders by due_date ascending with NULL dates last" do
        tasks = Task.sorted_by("due_date_asc")
        expect(tasks.first).to eq(task_priority_5)
        expect(tasks.second).to eq(task_priority_3)
        expect(tasks.third).to eq(task_priority_1)
        expect(tasks.last).to eq(task_no_date)
      end
    end

    context "when sort parameter is invalid or nil" do
      it "returns all tasks unsorted" do
        expect(Task.sorted_by("invalid").count).to eq(4)
        expect(Task.sorted_by(nil).count).to eq(4)
      end
    end
  end

  describe "chaining scopes" do
    let!(:project) { create(:project) }
    let!(:overdue_todo) { create(:task, project: project, due_date: 2.days.ago, status: "todo", priority: 1) }
    let!(:overdue_in_progress) { create(:task, project: project, due_date: 1.day.ago, status: "in_progress", priority: 2) }
    let!(:future_todo) { create(:task, project: project, due_date: 1.day.from_now, status: "todo", priority: 3) }

    it "can chain with_status and overdue" do
      tasks = Task.with_status("todo").overdue
      expect(tasks).to contain_exactly(overdue_todo)
    end

    it "can chain overdue and sorted_by" do
      tasks = Task.overdue.sorted_by("priority_desc")
      expect(tasks.to_a).to eq([overdue_todo, overdue_in_progress])
    end

    it "can chain all three scopes" do
      tasks = Task.with_status("todo").overdue.sorted_by("priority_desc")
      expect(tasks).to contain_exactly(overdue_todo)
    end
  end
end
