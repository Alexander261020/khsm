class AddHelpFieldToGame < ActiveRecord::Migration
  def change
    # Сделаем по умолчанию false и запретим нулевое значение на уровне базы
    add_column :games, :fifty_fifty_used, :boolean, default: false, null: false
    add_column :games, :audience_help_used, :boolean, default: false, null: false
    add_column :games, :friend_call_used, :boolean, default: false, null: false
  end
end
