require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "associations" do
    it { should have_many(:tasks).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe "database constraints" do
    it "requires name at database level" do
      project = Project.new(description: "Test")
      expect { project.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "dependent destroy" do
    it "destroys associated tasks when project is destroyed" do
      project = create(:project)
      task1 = create(:task, project: project)
      task2 = create(:task, project: project)

      expect { project.destroy }.to change { Task.count }.by(-2)
    end
  end
end
