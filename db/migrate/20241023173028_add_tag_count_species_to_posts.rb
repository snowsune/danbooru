class AddTagCountSpeciesToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :tag_count_species, :integer, default: 0, null: false
  end
end