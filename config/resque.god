rails_env   = ENV['RAILS_ENV']  || "production"
rails_root  = ENV['RAILS_ROOT']
num_workers = rails_env == 'production' ? 5 : 2
God.pid_file_directory = rails_root
queue = 'process_import,get_admin_groups,get_group,get_subgroups_members,get_group_members,get_subgroups_members_roles,get_group_members_roles,get_group_member_roles,get_submission,get_member_uuid,get_webform_data,create_group,add_to_group_and_subgroups,remove_from_group_and_subgroups,remove_from_group,assign_submission'
num_workers.times do |num|
  God.watch do |w|
    w.name          = "resque-#{num}"
    w.group         = "resque"
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
