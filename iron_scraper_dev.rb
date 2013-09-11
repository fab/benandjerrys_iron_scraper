require 'yaml'

def database_config
  YAML.load(File.read('database.yml'))
end

def params
  {
    'database' => database_config['development'],
    'start' => 0,
    'end' => 4
  }
end

