require 'rails/generators'
require 'rails/generators/migration'

class SafetynetGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  desc "Creates the Safetynet initializer file at config/initializers/safetynet.rb and a migration"


  def self.next_migration_number(path)
    unless @prev_migration_nr
      @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
    else
      @prev_migration_nr += 1
    end
    @prev_migration_nr.to_s
  end

  def install
    generate_initializer
    generate_migration
  end


  private

  def generate_initializer
    template 'initializer.rb', 'config/initializers/safetynet.rb'
  end

  def configuration_output
    output = <<-eos
Rails.configuration.safetynet = {
  email: {
    limit: Rails.env.development? ? 1000 : 1,
    timeframe: 1.hour
  }
}
    eos
  end

  def generate_migration
    puts SafetynetGenerator.source_root
    migration_template 'db/migrate/1_create_safetynet_histories.rb', 'db/migrate/create_safetynet_histories.rb'
  end
end
