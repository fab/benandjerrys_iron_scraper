require 'yaml'

def database_config
  YAML.load(File.read('database.yml'))
end

def params
  {
    'database' => database_config['development'],
    'token' => ENV['IRON_TOKEN'],
    'project' => ENV['IRON_PROJECT_ID']
  }
end

