class CreateGroupsBelow
  @queue = :create_groups_below

  def self.perform(group_id, admin_id, group_template_id, top_level_id)
    admin = Admin.find(admin_id)
    group = Group.find(group_id)
    top_level = Group.find(top_level_id)
    a = admin.groups
    groups_below = a.where(:group_above => group_template_id)
    groups_below.each do |g|
      p = g.dup
      p.update_attributes({
        :group_above => group.uuid,
        :title => top_level.title + ' ' + g.title,
        :address_city => top_level.address_city,
        :address_state => top_level.address_state,
        :address_zip => top_level.address_zip,
        :address_street => top_level.address_street
      })
      p.create_one_group(admin_id, g.id, top_level_id) if g[:has_children] == '1'
      p.create_one_group(admin_id, nil, nil) unless g[:has_children] == '1'
    end
  end
end