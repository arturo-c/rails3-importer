class CloneForms
  @queue = :clone_forms

  def self.perform(group_id, clone_uuid, new, user_uuid)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      client.group_clone_webforms(group.uuid, clone_uuid, new, user_uuid)
    rescue => e
      group.err = e.to_s
      group.status = 'Error cloning group webforms'
    else
      group.err = nil
      group.status = 'Cloned group webforms'
      group.clone_group(group.template)
    ensure
      group.save
    end
  end

end
