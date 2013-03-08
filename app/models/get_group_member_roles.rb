class GetGroupMemberRoles
  @queue = :get_group_member_roles

  def self.perform(member_id)
    member = Member.find(member_id)
    user = Admin.where(:uuid => member.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.prepare_access_token(user.token, user.secret, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"])
    begin
      roles = []
      r = client.group_roles_list(member.group_uuid, member.uuid)
      r.each do |role|
        roles << role['name']
      end
    rescue => e
      member.err = e.to_s
      member.status = 'Error getting roles'
    else
      member.err = nil
      member.update_attributes(:roles => roles)
      member.status = 'Member roles synched'
    end

    member.save
  end

end
