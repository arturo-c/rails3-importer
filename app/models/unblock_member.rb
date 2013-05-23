class UnblockMember
  @queue = :unblock_member

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      client.user_block(user.uuid, 'unblock')
      user.update_attributes(:status => 'Unblocked From AllPlayers', :err => nil)
    rescue => e
      user.update_attributes(:status => 'Error unblocking user.')
      user.update_attributes(:err => e)
    end
  end

end
