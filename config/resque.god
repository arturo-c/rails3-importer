rails_env   = ENV['RAILS_ENV']  || "development"
rails_root  = ENV['USAR_IMPORTER_ROOT'] || "/mnt/apci/projects/usar-importer"
num_workers = 10
#God.pid_file_directory = rails_root
queue = 'get_admin_groups,get_org_groups,process_import,get_member_uuid,create_member,get_child,create_child,add_to_group,get_submission,create_submission,verify_import_submission,verify_import_roles'
num_workers.times do |num|
  God.watch do |w|
    w.name          = "usar-#{num}"
    w.group         = "usar"
    w.interval      = 30.seconds
    w.env           = { 'RAILS_ENV' => rails_env,
                        'QUEUE'     => queue }
    w.dir           = "#{rails_root}"
    w.start         = "rake resque:work"
    w.start_grace   = 10.seconds
    w.log           = File.expand_path(File.join(File.dirname(__FILE__), '..','log','resque-worker.log'))

    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 200.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
