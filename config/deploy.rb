# config/deploy.rb 
require 'capistrano'
require 'rvm/capistrano'

set :scm,             :git
set :repository,      'git@github.com:arturo-c/rails3-importer.git'
set :branch,          'origin/usat_importer'
set :migrate_target,  :current
set :ssh_options,     { :forward_agent => true }
set :rails_env,       'production'
set :deploy_to,       '/mnt/apci/usat_importer'
set :normalize_asset_timestamps, false
set :domain, 'import.allplayers.local'
set :rvm_type, :user
set :rvm_ruby_string, 'allplayers-importer@ruby-1.9.3-p392'

set :user,            'root'
set :group,           'root'
set :use_sudo,        false

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

default_environment['RAILS_ENV'] = 'production'

# Use our ruby-1.9.3-p392@allplayers-importer
default_environment['PATH']         = '/usr/local/rvm/gems/ruby-1.9.3-p392@allplayers-importer/bin:/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p392/bin:/usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/vagrant_ruby/bin'
default_environment['GEM_HOME']     = '/usr/local/rvm/gems/ruby-1.9.3-p392@allplayers-importer'
default_environment['GEM_PATH']     = '/usr/local/rvm/gems/ruby-1.9.3-p392@allplayers-importer:/usr/local/rvm/gems/ruby-1.9.3-p392@global'
default_environment['RUBY_VERSION'] = 'ruby-1.9.3-p392'

default_environment['RAILS_ROOT']   = "#{deploy_to}/current"
default_run_options[:shell] = 'bash'

namespace :bundle do
  task :install do
    run "cd #{current_path}; bundle install"
  end
end

namespace :deploy do
  desc 'Deploy your application'
  task :default do
    update
    restart
  end

  desc 'Setup your git-based deployment app'
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
    run "cd #{current_path}; git checkout -f #{branch}"
  end

  task :cold do
    update
    migrate
  end

  task :update do
    transaction do
      update_code
    end
  end

  desc 'Update the deployed code.'
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
  end

  desc 'Update the database (overwritten to avoid symlink)'
  task :migrations do
    transaction do
      update_code
    end
    migrate
    restart
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids &&
      mkdir -p #{latest_release}/public &&
      mkdir -p #{latest_release}/tmp &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -s #{shared_path}/system #{latest_release}/public/system &&
      ln -s #{shared_path}/pids #{latest_release}/tmp/pids &&
      ln -sf #{shared_path}/mongoid.yml #{latest_release}/config/mongoid.yml &&
      ln -sf #{shared_path}/application.yml #{latest_release}/config/application.yml
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime('%Y%m%d%H%M.%S')
      asset_paths = fetch(:public_children, %w(images stylesheets javascripts)).map { |p| "#{latest_release}/public/#{p}" }.join(' ')
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { 'TZ' => 'UTC' }
    end
    bundle.install
  end

  desc 'Zero-downtime restart of Unicorn'
  task :restart, :except => { :no_release => true } do
    run 'kill -s QUIT `cat /tmp/unicorn.usat.pid`'
    start
  end

  desc 'Start unicorn'
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; unicorn -c config/unicorn.rb -D"
  end

  desc 'Stop unicorn'
  task :stop, :except => { :no_release => true } do
    run 'kill -s QUIT `cat /tmp/unicorn.usat.pid`'
  end

  desc 'Stop resque workers'
  task :stop_resque_workers do
    run "cd #{current_path}; rake workers:killall"
  end

  desc 'Restart resque-web interface'
  task :restart_resque_web do
    run "cd #{current_path}; resque-web -K; resque-web -L"
  end

  desc 'Terminate god service'
  task :terminate_god do
    run "cd #{current_path}; god terminate"
  end

  desc 'Start god monitor'
  task :start_god do
    run "cd #{current_path}; god; god load config/resque.god; god start usat"
  end

  desc 'Stop god monitor'
  task :stop_god do
    run "cd #{current_path}; god stop usat"
  end

  desc 'Restart god monitor'
  task :restart_god do
    stop_god
    start_god
  end

  desc 'Start redis server'
  task :start_redis do
    run 'sudo redis-server /etc/redis/redis.conf'
  end

  namespace :rollback do
    desc 'Moves the repo back to the previous version of HEAD'
    task :repo, :except => { :no_release => true } do
      set :branch, 'HEAD@{1}'
      deploy.default
    end

    desc 'Rewrite reflog so HEAD@{1} will continue to point to at the next previous release.'
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc 'Rolls back to the previously deployed version.'
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}; #{rake} #{cmd}"
end

after 'deploy', 'deploy:restart_god'