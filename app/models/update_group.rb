class UpdateGroup
  @queue = :update_group

  def self.perform(group_id)
    group = Group.find(group_id)
    admin = Admin.find_by(:uuid => group.user_uuid)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(admin.token, admin.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      params = {}
      params[:title] = group.name if group.name
      params[:type] = group.type if group.type
      params[:category] = {0 => group.category} if group.category
      client.update_group(group.uuid, params)
    rescue => e
      group.err = e.to_s
      group.status = 'Error updating group'
    end

    group.save
  end

end
