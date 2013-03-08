rails_root = Rails.root || File.dirname(__FILE__) + '/../..'
rails_env = Rails.env || 'development'

config = YAML.load_file(Rails.root.join('config', 'resque.yml'))

resque_config = config
Resque.redis = resque_config[rails_env]