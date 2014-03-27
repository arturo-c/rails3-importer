class GetOrgGroups
  @queue = :get_org_groups

  def self.perform(user_id, org_uuid)
    user = Admin.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    begin
      groups = client.group_subgroups_tree(org_uuid)
      self.get_recursive_groups(groups, org_uuid)
      @subgroups.each do |uuid, g|
        subgroup = Group.where(:uuid => uuid).first
        if subgroup.nil?
          ap_group = {
              :uuid => uuid,
              :title => g[:title],
              :group_above => g[:group_above],
              :title_lower => g[:title].strip.downcase,
              :status => 'AllPlayers',
              :user_uuid => user.uuid
          }
          user.groups.create(ap_group)
        end
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error getting members.'
    else
      user.err = nil
      user.status = 'Members synched'
    ensure
      user.save
    end
  end

  def self.get_recursive_groups(groups, group_above_uuid)
    @subgroups ||= {}

    groups.each do |nid, group|
      @subgroups[group['uuid']] = {:title => group['title'], :group_above => group_above_uuid}
      if group['has_children']
        self.get_recursive_groups(group['below'], group['uuid'])
      end
    end
  end

end