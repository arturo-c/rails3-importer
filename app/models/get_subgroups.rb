class GetSubgroups
  @queue = :get_subgroups

  def self.perform(group_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    group.err = nil
    begin
      members = client.group_members_list(group.uuid, nil, {:limit => 0})
      members.each do |member|
        u = admin_client.user_get(member['uuid'])
        m = Member.find_or_create_by({:admin_uuid => group_admin.uuid, :email => u['email'], :uuid => member['uuid'], :gender => u['gender'], :first_name => HTMLEntities.new.decode(u['firstname']), :last_name => HTMLEntities.new.decode(u['lastname']), :birthday => Date.strptime(u['birthday'], "%m/%d/%Y").to_s, :group_name => group.name, :group_uuid => group.uuid, :status => 'AllPlayers'})
      end
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting members.'
    else
      group.err = nil
      group.status = 'Members synched'
    ensure
      group.save
    end
  end

end
