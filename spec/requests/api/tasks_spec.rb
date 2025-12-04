require 'rails_helper'

RSpec.describe "Api::Tasks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/tasks/index"
      expect(response).to have_http_status(:success)
    end
  end

end
