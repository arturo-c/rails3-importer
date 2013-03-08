class GetGroup
  @queue = :get_group

  def self.perform(group_id)
    group = Group.find(group_id)
    admin = Admin.find_by(:uuid => group.user_uuid)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(admin.token, admin.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      ap_group = client.group_get(group.uuid)
      groups_above = []
      ap_group['groups_above_uuid'].each do |g|
        groups_above << g.gsub(/[^0-9a-z-]/i, '') unless g.empty?
      end
      group.update_attributes(:groups_above => groups_above, :location => ap_group['location'])
      raise unless group.save
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting group'
    end

    group.save
  end

end
