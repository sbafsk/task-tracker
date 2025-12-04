require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:project) { create(:project) }
  let(:valid_attributes) { { name: "Test Project", description: "Test Description" } }
  let(:invalid_attributes) { { name: "" } }

  describe "GET /projects" do
    it "returns http success" do
      get projects_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:id" do
    it "returns http success" do
      get project_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/new" do
    it "returns http success" do
      get new_project_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:id/edit" do
    it "returns http success" do
      get edit_project_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /projects" do
    context "with valid parameters" do
      it "creates a new Project" do
        expect {
          post projects_path, params: { project: valid_attributes }
        }.to change(Project, :count).by(1)
      end

      it "redirects to the created project" do
        post projects_path, params: { project: valid_attributes }
        expect(response).to redirect_to(Project.last)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Project" do
        expect {
          post projects_path, params: { project: invalid_attributes }
        }.to change(Project, :count).by(0)
      end

      it "renders a response with 422 status" do
        post projects_path, params: { project: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /projects/:id" do
    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Project" } }

      it "updates the requested project" do
        patch project_path(project), params: { project: new_attributes }
        project.reload
        expect(project.name).to eq("Updated Project")
      end

      it "redirects to the project" do
        patch project_path(project), params: { project: new_attributes }
        expect(response).to redirect_to(project)
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        patch project_path(project), params: { project: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /projects/:id" do
    it "destroys the requested project" do
      project_to_delete = create(:project)
      expect {
        delete project_path(project_to_delete)
      }.to change(Project, :count).by(-1)
    end

    it "redirects to the projects list" do
      delete project_path(project)
      expect(response).to redirect_to(projects_url)
    end
  end
end
