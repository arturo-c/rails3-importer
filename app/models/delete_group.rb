class DeleteGroup
  @queue = :delete_group

  def self.perform(group_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      client.group_delete(group.uuid) if group.title != 'ScheduleStar'
      group.update_attributes(:status => 'Deleted From AllPlayers', :err => nil)
    rescue => e
      group.update_attributes(:status => 'Error deleting group.')
      group.update_attributes(:err => e)
    end
  end

end
