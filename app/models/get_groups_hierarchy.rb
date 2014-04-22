class GetGroupsHierarchy
  @queue = :get_groups_hierarchy

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    admin = Admin.find(admin_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    a = admin.groups
    begin
      if group.payee
        top_level = Group.where(:uuid => group.payee).first
        template = Group.where(:uuid => group.template).first
        groups_below = a.where(:group_above => template.id)
      else
        top_level = group
        template = Group.find(admin.group_template)
        group.update_attributes({:template => template.uuid})
        groups_below = a.where(:group_above => admin.group_template)
      end
      groups_below.each do |g|
        p = g.dup
        gr = client.group_search(:search => top_level.title + ' ' + g.title)
        p.update_attributes({
                              :uuid => gr[0]['uuid'],
                              :group_above => group.uuid,
                              :template => p.uuid,
                              :payee => top_level.uuid,
                              :title => top_level.title + ' ' + g.title,
                              :address_city => top_level.address_city,
                              :address_state => top_level.address_state,
                              :address_zip => top_level.address_zip,
                              :address_street => top_level.address_street,
                              :user_uuid => group.user_uuid,
                              :status => 'Done'
                            })
        p.get_groups_hierarchy(admin_id) if g[:has_children] == '1'
      end
    rescue => e
      group.err = e.to_s
      group.status = 'Error getting hierarchy'
    else
      group.err = nil
      group.status = 'Done'
    ensure
      group.save
    end
  end

end