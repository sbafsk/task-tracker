require 'rails_helper'

RSpec.describe "Api::Tasks", type: :request do
  let(:project) { create(:project) }
  let!(:todo_task) { create(:task, project: project, status: "todo", title: "Todo Task") }
  let!(:in_progress_task) { create(:task, project: project, status: "in_progress", title: "In Progress Task") }
  let!(:done_task) { create(:task, project: project, status: "done", title: "Done Task") }
  let!(:overdue_task) { create(:task, project: project, status: "todo", due_date: 2.days.ago, title: "Overdue Task") }
  let!(:future_task) { create(:task, project: project, status: "todo", due_date: 2.days.from_now, title: "Future Task") }

  describe "GET /api/projects/:project_id/tasks" do
    it "returns http success" do
      get api_project_tasks_path(project)
      expect(response).to have_http_status(:success)
    end

    it "returns JSON array" do
      get api_project_tasks_path(project)
      expect(response.content_type).to match(a_string_including("application/json"))
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end

    it "returns all tasks for the project" do
      get api_project_tasks_path(project)
      json = JSON.parse(response.body)
      expect(json.length).to eq(5)
    end

    it "includes all required fields" do
      get api_project_tasks_path(project)
      json = JSON.parse(response.body)
      task_json = json.first

      expect(task_json).to have_key("id")
      expect(task_json).to have_key("title")
      expect(task_json).to have_key("description")
      expect(task_json).to have_key("status")
      expect(task_json).to have_key("priority")
      expect(task_json).to have_key("due_date")
      expect(task_json).to have_key("overdue")
    end

    it "includes computed overdue field" do
      get api_project_tasks_path(project)
      json = JSON.parse(response.body)

      overdue_task_json = json.find { |t| t["title"] == "Overdue Task" }
      expect(overdue_task_json["overdue"]).to be true

      future_task_json = json.find { |t| t["title"] == "Future Task" }
      expect(future_task_json["overdue"]).to be false
    end

    context "with status filter" do
      it "filters tasks by status=todo" do
        get api_project_tasks_path(project), params: { status: "todo" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(3)
        expect(json.all? { |t| t["status"] == "todo" }).to be true
      end

      it "filters tasks by status=in_progress" do
        get api_project_tasks_path(project), params: { status: "in_progress" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(1)
        expect(json.first["title"]).to eq("In Progress Task")
      end

      it "filters tasks by status=done" do
        get api_project_tasks_path(project), params: { status: "done" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(1)
        expect(json.first["title"]).to eq("Done Task")
      end
    end

    context "with overdue filter" do
      it "filters tasks by overdue=true" do
        get api_project_tasks_path(project), params: { overdue: "true" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(1)
        expect(json.first["title"]).to eq("Overdue Task")
      end
    end

    context "with combined filters" do
      it "combines status and overdue filters" do
        get api_project_tasks_path(project), params: { status: "todo", overdue: "true" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(1)
        expect(json.first["title"]).to eq("Overdue Task")
        expect(json.first["status"]).to eq("todo")
        expect(json.first["overdue"]).to be true
      end

      it "returns empty array when no tasks match combined filters" do
        get api_project_tasks_path(project), params: { status: "done", overdue: "true" }
        json = JSON.parse(response.body)

        expect(json.length).to eq(0)
      end
    end
  end
end
