#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'resque/tasks'
Rails3Importer::Application.load_tasks
namespace :workers do
  task :killall do
    require 'resque'
    Resque::Worker.all.each do |worker|
      puts "Shutting down worker #{worker}"
      host, pid, queues = worker.id.split(':')
      Process.kill("QUIT", pid.to_i)
    end
  end
end
