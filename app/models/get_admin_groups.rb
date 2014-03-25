class GetAdminGroups
  @queue = :get_admin_groups

  def self.perform(user_id)
    user = Admin.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(user.token, user.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      groups = client.user_groups_list(user.uuid, {:limit => 0})
      user_groups = user.groups
      unless groups == 'No Content'
        groups.each do |g|
          #group = user_groups.find_by_uuid(g['uuid'])
          #if group.nil?
            ap_group = {
              :uuid => g['uuid'],
              :title => g['title'],
              :title_lower => g['title'].strip.downcase,
              :description => g['description'],
              :status => 'AllPlayers'
            }
            user_groups.create(ap_group)
          #end
        end
        user.status = 'Updated at ' + Date.today.to_s
        user.err = nil
      else
        user.status = 'No groups found.'
      end
    ensure
      user.save
    end
  end

end
