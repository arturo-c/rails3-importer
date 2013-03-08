class GetSubgroupsMembersRoles
  @queue = :get_subgroups_members_roles

  def self.perform(group_id)
    group = Group.find(group_id)
    user = Admin.where(:uuid => group.user_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(user.token, user.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      group.get_group_members_roles
      @subgroups = []
      self.get_subgroups(group.uuid)
      @subgroups.each do |subgroup|
        subgroup.get_group_members_roles
      end
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting roles'
    else
      group.err = nil
      group.status = 'Member roles synched'
    end

    group.save
  end

  def self.get_subgroups(group_uuid)
    @subgroups ||= []

    subgroups = Group.any_of(:groups_above => group_uuid).entries
    return if subgroups.first.nil?
    subgroups.each do |subgroup|
      @subgroups << subgroup
      self.get_subgroups(subgroup.uuid)
    end
  end

end
