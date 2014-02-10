class CreateChild
  @queue = :create_child

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    status = 'Done'
    user.err = nil
    begin
      parent = Member.where(:email => user.parent_email.downcase).first
      more_params = {}
      more_params[:email] = user.email if user.email
      u = client.user_create_child(parent.uuid, user.first_name, user.last_name, user.birthday, user.gender, more_params)
    rescue => e
      status = 'Error creating child'
      user.err = e
    else
      if u['uuid']
        user.uuid = u['uuid']
      else
        status = 'Error creating child'
        user.err = 'User not returned'
      end
    ensure
      user.status = 'Create Child: ' + status
      user.save
      user.add_to_group if (user.group_uuid && user.uuid)
    end
  end

end
