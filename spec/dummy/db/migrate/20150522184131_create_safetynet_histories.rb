class CreateSafetynetHistories < ActiveRecord::Migration
  def self.up
    create_table :safetynet_histories do |t|
      t.string :address
      t.string :channel
      t.string :method
      t.datetime :created_at
    end

    add_index :safetynet_histories, [:address, :channel, :method, :created_at], name: 'safetynet_histories_idx'
  end

  def self.down
    drop_table :safetynet_histories
  end
end