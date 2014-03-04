class GetOrgGroups
  @queue = :get_org_groups

  def self.perform(user_id, org_uuid, template)
    user = Admin.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    begin
      group = user.groups.find_by_uuid(org_uuid)
      groups = client.group_subgroups_tree(org_uuid)
      subgroups = group.get_recursive_groups(groups, org_uuid)
      subgroups.each do |uuid, g|
        subgroup = user.groups.find_by_uuid(uuid)
        if subgroup.nil?
          ap_group = {
            :uuid => uuid,
            :title => g[:title],
            :group_above => g[:group_above],
            :title_lower => g[:title].strip.downcase,
            :status => 'AllPlayers',
            :user_uuid => user.uuid
          }
          unless template.nil?
            ap_group.merge!({
              :description => group.description,
              :address_street => group.address_street,
              :address_city => group.address_city,
              :address_state => group.address_state,
              :address_zip => group.address_zip,
              :group_type => group.group_type,
              :category => group.category
            })
            # If we wanted additional fields from allplayers.
            #f = client.group_get(uuid)
            #ap_group.merge!({
            #  :description => f['description'],
            #  :address_street => f['location']['street'],
            #  :address_city => f['location']['city'],
            #  :address_state => f['location']['state'],
            #  :address_zip => f['location']['zip'],
            #  :group_type => f['group_type'],
            #  :category => f['group_category'].first
            #})
          end
          user.groups.create(ap_group)
        end
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error getting groups.'
    else
      user.err = nil
    ensure
      user.save
    end
  end

end
