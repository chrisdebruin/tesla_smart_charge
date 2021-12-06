require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = :info

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/data.sqlite'
)

# ActiveRecord::Schema.define do
#   create_table :auth_tokens, force: true do |table|
#     table.column :access_token, :string
#     table.column :refresh_token, :string
#     table.column :created_at, :datetime
#   end

#   create_table :statuses, force: true do |table|
#     table.column :car_status, :string
#     table.column :charging_state, :string
#     table.column :charge_amps, :integer
#     table.column :production_amps, :integer
#     table.column :created_at, :datetime
#   end
# end

class AuthToken < ActiveRecord::Base
end

class Status < ActiveRecord::Base
end
