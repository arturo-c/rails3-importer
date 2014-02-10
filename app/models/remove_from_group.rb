class RemoveFromGroup
  @queue = :remove_from_group

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      raise 'No group specified.' unless user.group_uuid
      leave = client.user_leave_group(user.group_uuid, user.uuid)
    rescue => e
      user.err = e.to_s
      user.status = 'Error removing user from group'
    else
      user.status = 'User removed from group'
      user.err = ''
    end

    user.save
  end

end
