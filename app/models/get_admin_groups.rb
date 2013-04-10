class GetAdminGroups
  @queue = :get_admin_groups

  def self.perform(user_id)
    user = Admin.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(user.token, user.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    user.update_attributes(:groups => 'Processing')
    begin
      groups = client.user_groups_list(user.uuid, {:limit => 0})
      unless groups == 'No Content'
        groups.each do |g|
          group = Group.where(:uuid => g['uuid']).first
          if group.nil?
            ap_group = {:uuid => g['uuid'], :name => g['title'], :description => g['description'], :status => 'AllPlayers', :user_uuid => user.uuid, :org_webform_uuid => ENV["WEBFORM_UUID"]}
            group = Group.create(ap_group)
            group.get_group
          else
            if group.groups_above.empty?
              group.get_group
            end
          end
        end
        raise unless Group.where(:user_uuid => user.uuid).first
        user.status = 'Updated at ' + Date.today.to_s
        user.err = nil
      else
        user.status = 'No groups found.'
      end
    rescue => e
      user.err = e.to_s
      user.status = 'No groups found.'
    end

    user.save
  end

end
