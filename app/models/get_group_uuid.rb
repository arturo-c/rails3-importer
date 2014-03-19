class GetGroupUuid
  @queue = :get_group_uuid

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    admin = Admin.find(admin_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(admin.token, admin.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      g = Group.where(:title => group.title, :status => 'AllPlayers').first
      group.update_attributes(:uuid => g.uuid)
      raise unless group.save
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting group'
    end

    group.save
  end

end
