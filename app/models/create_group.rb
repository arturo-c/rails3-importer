class CreateGroup
  @queue = :create_group

  def self.perform(group_id)
    group = Group.find(group_id)
    admin = Admin.find(group.user_uuid)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(admin.token, admin.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      ap_group = client.group_create(group.name, group.description, group.location, group.category, {:group_type => group.type})
      group.update_attributes(:uuid => ap_group['uuid'])
    rescue => e
      group.update_attributes(:status => 'Error importing user.')
      group.update_attributes(:err => e)
    end
  end

end