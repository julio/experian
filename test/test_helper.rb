require 'yaml'
EXPERIAN_CONFIG = YAML.load_file("../config/config.yml")["test"]
require 'test/unit'
