class CloneGroup
  @queue = :clone_group

  def self.perform(group_id, clone_uuid)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      client.group_clone(group.uuid, clone_uuid, false)
    rescue => e
      group.err = e.to_s
      group.status = 'Error cloning group'
    end

    group.save
  end

end
