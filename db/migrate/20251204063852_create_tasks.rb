class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "todo"
      t.date :due_date
      t.integer :priority, null: false

      t.timestamps
    end
    add_index :tasks, :status
    add_index :tasks, :due_date
    add_index :tasks, :priority
  end
end
