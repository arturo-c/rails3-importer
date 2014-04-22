class GetGroupUuid
  @queue = :get_group_uuid

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    admin = Admin.find(admin_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      g = client.group_search({:search => group.title})
      raise unless g[0]['uuid']
      group.update_attributes(:uuid => g[0]['uuid'])
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting group'
    else
      group.err = nil
      group.status = 'Group uuid retrieved'
    ensure
      group.save
    end
  end

end
