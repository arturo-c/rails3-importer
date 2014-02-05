class GetGroupMemberRoles
  @queue = :get_group_member_roles

  def self.perform(member_id)
    member = Member.find(member_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      roles = Hash.new
      r = client.group_roles_list(member.group_uuid, member.uuid)
      r.each do |role|
        roles[role['name']] = role['flags']
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
