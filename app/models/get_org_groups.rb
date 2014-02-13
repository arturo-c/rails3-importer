class GetOrgGroups
  @queue = :get_org_groups

  def self.perform(user_id)
    user = Admin.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    begin
      groups = client.group_subgroups_tree(ENV["ORG_UUID"])
      self.get_recursive_groups(groups, ENV["ORG_UUID"])
      @subgroups.each do |uuid, g|
        group = Group.where(:uuid => uuid).first
        if group.nil?
          ap_group = {:uuid => uuid, :name => g[:title], :nid => g[:nid], :group_above => g[:group_above], :name_lower => g[:title].strip.downcase, :status => 'AllPlayers', :user_uuid => ENV["GROUP_ADMIN_UUID"], :org_webform_uuid => ENV["WEBFORM_UUID"]}
          group = Group.create(ap_group)
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
      @subgroups[group['uuid']] = {:title => group['title'], :nid => nid, :group_above => group_above_uuid}
      if group['has_children']
        self.get_recursive_groups(group['below'], group['uuid'])
      end
    end
  end

end
