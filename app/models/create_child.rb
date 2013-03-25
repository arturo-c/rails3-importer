class CreateChild
  @queue = :create_child

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      parent = Member.where(:email => user.parent_email).first
      raise "Parent not on AllPlayers." unless (parent && parent.uuid)
      more_params = {}
      more_params[:email] = user.email if user.email
      exists = false
      begin
        children = client.user_children_list(parent.uuid)
      rescue => e
        u = client.user_create_child(parent.uuid, user.first_name, user.last_name, user.birthday, user.gender, more_params)
      else
        if children.length == 1
          c = client.user_get(children.first['uuid'])
          if user.first_name.casecmp(c['firstname']) == 0 && user.last_name.casecmp(c['lastname']) == 0
            exists = true
            u = c
          end
        else
          children.each do |child|
            c = client.user_get(child['uuid'])
            if user.first_name.casecmp(c['firstname']) == 0 && user.last_name.casecmp(c['lastname']) == 0
              exists = true
              u = c
            end
          end
        end
        u = client.user_create_child(parent.uuid, user.first_name, user.last_name, user.birthday, user.gender, more_params) unless exists
      end
    rescue => e
      user.update_attributes(:status => 'Error importing user.')
      user.update_attributes(:err => e)
    else
      if u['uuid']
        user.update_attributes(:uuid => u['uuid'], :status => 'Imported')
        user.add_to_group
      else
        user.update_attributes(:status => 'Error importing user')
      end
    end
  end

end