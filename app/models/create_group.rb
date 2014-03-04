class CreateGroup
  @queue = :create_group

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    group.create_import(admin_id)
    admin = Admin.find(admin_id)
    group.create_groups_below(admin_id, admin.group_template, group.id) if admin.group_template
  end

end