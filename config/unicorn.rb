# config/unicorn.rb
@env = ENV['RAILS_ENV'] || 'development'
dir = ENV['GROUP_IMPORTER_ROOT'] || '/mnt/apci/usat_importer'
if @env == 'production'
  listen 80, :tcp_nopush => true
  shared_path = "#{dir}/shared"
  stderr_path "#{shared_path}/log/unicorn.stderr.log"
  stdout_path "#{shared_path}/log/unicorn.stdout.log"
  working_directory "#{dir}/current"
else
  listen "#{dir}/tmp/unicorn.sock", :backlog => 64
end
worker_processes 2
preload_app true
timeout 280
pid '/tmp/unicorn.usat.pid'
before_fork do |server, worker|
  old_pid = '/tmp/unicorn.usat.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
end
