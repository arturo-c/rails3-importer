class CreateMember
  @queue = :create_member

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      local = Member.where(:email => user.email).first
      uuid = nil
      uuid = local.uuid if local.uuid
      if uuid.nil?
        u = client.user_create(user.email, user.first_name, user.last_name, user.birthday, user.gender)
        uuid = u['uuid']
      end
      user.update_attributes(:uuid => uuid, :status => 'Imported', :err => nil)
      user.add_to_group if user.group_name
    rescue => e
      user.update_attributes(:status => 'Error importing user.')
      user.update_attributes(:err => e)
    end
  end

end