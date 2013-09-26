class UpdateGroup
  @queue = :update_group

  def self.perform(group_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      params = {}
      params[:title] = group.name if group.name
      params[:group_type] = group.type if group.type
      client.group_update(group.uuid, params)
    rescue => e
      group.err = e.to_s
      group.status = 'Error updating group'
    end

    group.save
  end

end
