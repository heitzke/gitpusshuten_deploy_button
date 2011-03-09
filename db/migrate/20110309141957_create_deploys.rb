class CreateDeploys < ActiveRecord::Migration
  def self.up
    create_table :deploys do |t|
      t.string  :server_ip
      t.string  :root_password
      t.string  :domain_name
      t.integer :project_id
      t.string  :guid
      t.text    :log_output

      t.timestamps
    end
  end

  def self.down
    drop_table :deploys
  end
end
