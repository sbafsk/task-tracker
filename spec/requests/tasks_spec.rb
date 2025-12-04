require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  let(:project) { create(:project) }
  let(:task) { create(:task, project: project) }
  let(:valid_attributes) { { title: "Test Task", description: "Test Description", status: "todo", priority: 3 } }
  let(:invalid_attributes) { { title: "" } }

  describe "GET /projects/:project_id/tasks/new" do
    it "returns http success" do
      get new_project_task_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:project_id/tasks/:id/edit" do
    it "returns http success" do
      get edit_project_task_path(project, task)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects/:project_id/tasks" do
    context "with valid parameters" do
      it "creates a new Task" do
        expect {
          post project_tasks_path(project), params: { task: valid_attributes }
        }.to change(Task, :count).by(1)
      end

      it "redirects to the project" do
        post project_tasks_path(project), params: { task: valid_attributes }
        expect(response).to redirect_to(project)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Task" do
        expect {
          post project_tasks_path(project), params: { task: invalid_attributes }
        }.to change(Task, :count).by(0)
      end

      it "renders a response with 422 status" do
        post project_tasks_path(project), params: { task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /projects/:project_id/tasks/:id" do
    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated Task" } }

      it "updates the requested task" do
        patch project_task_path(project, task), params: { task: new_attributes }
        task.reload
        expect(task.title).to eq("Updated Task")
      end

      it "redirects to the project" do
        patch project_task_path(project, task), params: { task: new_attributes }
        expect(response).to redirect_to(project)
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        patch project_task_path(project, task), params: { task: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /projects/:project_id/tasks/:id" do
    it "destroys the requested task" do
      task_to_delete = create(:task, project: project)
      expect {
        delete project_task_path(project, task_to_delete)
      }.to change(Task, :count).by(-1)
    end

    it "redirects to the project" do
      delete project_task_path(project, task)
      expect(response).to redirect_to(project)
    end
  end
end
