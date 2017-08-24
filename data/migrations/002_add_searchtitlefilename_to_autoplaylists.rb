Sequel.migration do
  up do
    alter_table(:auto_playlists) do
      add_column :search, String, text: true
      add_column :title, String
      add_column :filename, String
    end
  end
end
