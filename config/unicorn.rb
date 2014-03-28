# config/unicorn.rb
@env = ENV['RAILS_ENV'] || 'development'
if @env == 'production'
  listen 3000, :tcp_nopush => true
  shared_path = "/mnt/apci/usar_importer/shared"
  stderr_path "#{shared_path}/log/unicorn.stderr.log"
  stdout_path "#{shared_path}/log/unicorn.stdout.log"
  working_directory "/mnt/apci/usar_importer/current"
else
  listen "#{@dir}/tmp/unicorn.sock", :backlog => 64
end
worker_processes 2
preload_app true
timeout 280
pid '/tmp/unicorn.usar.pid'
before_fork do |server, worker|
  old_pid = '/tmp/unicorn.usar.pid.oldbin'
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
