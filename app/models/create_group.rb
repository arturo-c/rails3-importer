class CreateGroup
  @queue = :create_group

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    admin = Admin.find(admin_id)
    group.create_import
    template = Group.find(admin.group_template)
    if template
      group.update_attributes(:template => template.uuid)
      group.clone_group(template.uuid)
      group.set_store_payee(group.uuid)
      group.clone_forms(template.uuid, true, group.user_uuid)
      group.create_groups_below(admin_id, template.id, group.id)
    end
  end

end