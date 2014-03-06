class CreateGroupTemplate
  @queue = :create_group_template

  def self.perform(admin_id, group_id)
    user = Admin.find(admin_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    user.err = nil
    begin
      # Get group template additional data.
      temp = client.group_get(group.uuid)
      group.update_attributes({
        :description => temp['description'],
        :title => temp['title'],
        :address_street => temp['location']['street'],
        :address_city => temp['location']['city'],
        :address_state => temp['location']['state'],
        :address_zip => temp['location']['zip'],
        :group_type => temp['group_type'],
        :category => temp['group_category'].first,
        :status => 'AllPlayers'
      })
      groups = client.group_subgroups_tree(group.uuid)
      subgroups = group.get_recursive_groups(groups, group.uuid)
      subgroups.each do |uuid, g|
        subgroup = user.groups.find_by_uuid(uuid)
        if subgroup.nil?
          ap_group = {
            :uuid => uuid,
            :title => g[:title].sub(/^School Name /, ''),
            :group_above => g[:group_above],
            :title_lower => g[:title].sub(/^School Name /, '').strip.downcase,
            :has_children => g[:has_children],
            :status => 'AllPlayers',
            :user_uuid => user.uuid
          }
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