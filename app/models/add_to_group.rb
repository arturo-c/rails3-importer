class AddToGroup
  @queue = :add_to_group

  def self.perform(user_id)
    user = Member.find(user_id)
    admin = Admin.where(:uuid => user.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    user.err = nil
    status = 'Done'
    begin
      raise 'No group specified.' unless user.group_uuid
      raise 'No role specified.' if user.roles.empty?
      user.roles.each do |role, flag|
        if flag.empty?
          client.user_join_group(user.group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => user.join_date})
        else
          client.user_join_group(user.group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => user.join_date, :flag => flag})
          if flag != 'Active'
            client.user_join_group(user.group_uuid, user.uuid, role.strip, {:should_pay => 0, :join_date => user.join_date, :unflag => 'Active'})
          end
        end
      end
    rescue => e
      user.err = e
      status = 'Error adding user to group.'
    else
      user.get_submission(admin.webform)
    ensure
      user.status = 'Add To Group: ' + status
      user.save
    end
  end

end
