require 'yaml'

def database_config
  YAML.load(File.read('database.yml'))
end

def params
  {
    "database" => database_config["development"],
    'start' => 40782,
    'end' => 40782
  }
end

