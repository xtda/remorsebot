Sequel.migration do
  up do
    create_table(:auto_playlists) do
      primary_key :id
    end
  end

  down do
    drop_table(:auto_playlists)
  end
end
