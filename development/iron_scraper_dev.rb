require 'yaml'

def database_config
  YAML.load(File.open(File.expand_path('../../database.yml', __FILE__)))
end

def params
  {
    'database' => database_config['development'],
    'token' => ENV['IRON_TOKEN'],
    'project' => ENV['IRON_PROJECT_ID']
  }
end

