class GetChild
  @queue = :get_child

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    parent = Member.where(:email => user.parent_email.downcase).first
    more_params = {}
    more_params[:email] = user.email if user.email
    status = 'Done'
    user.err = nil
    begin
      children = client.user_children_list(parent.uuid)
      if children.length == 1 && children.first.is_a?(Hash)
        c = client.user_get(children.first['uuid'])
        fname = HTMLEntities.new.decode(c['firstname'])
        lname = HTMLEntities.new.decode(c['lastname'])
        if user.first_name.casecmp(fname) == 0 && user.last_name.casecmp(lname) == 0
          user.uuid = c['uuid']
          return
        end
      else
        children.each do |child|
          next unless child.is_a?(Hash)
          c = client.user_get(child['uuid'])
          fname = HTMLEntities.new.decode(c['firstname'])
          lname = HTMLEntities.new.decode(c['lastname'])
          if user.first_name.casecmp(fname) == 0 && user.last_name.casecmp(lname) == 0
            user.uuid = c['uuid']
            return
          end
        end
      end
      status = 'Creating child'
      user.create_child
    rescue => e
      status = 'Error getting children'
      user.err = e
    ensure
      user.status = 'Get Child: ' + status
      user.save
      user.add_to_group if (user.group_uuid && user.uuid)
    end
  end

end
