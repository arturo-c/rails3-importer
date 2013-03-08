class GetGroupMembersRoles
  @queue = :get_group_members_roles

  def self.perform(group_id)
    group = Group.find(group_id)
    user = Admin.where(:uuid => group.user_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(user.token, user.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      Member.where(:group_uuid => group.uuid, :admin_uuid => user.uuid).each do |member|
        member.get_group_member_roles
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

end
