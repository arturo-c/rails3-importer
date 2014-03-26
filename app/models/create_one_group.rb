class CreateOneGroup
  @queue = :create_one_group

  def self.perform(group_id, admin_id, group_template_id, top_level_id)
    begin
      group = Group.find(group_id)
      group.create_import
    rescue => e
      group.status = 'Error creating group'
      group.err = e
    else
      group.status = 'Created group'
      group.err = nil
      group.clone_forms(group.payee, false, nil) if group.payee
      group.clone_forms(group.template, true, group.user_uuid) unless group.payee
      group.create_groups_below(admin_id, group_template_id, top_level_id) unless group_template_id.nil?
    ensure
      group.save
    end
  end

end