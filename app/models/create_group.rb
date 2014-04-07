class CreateGroup
  @queue = :create_group

  def self.perform(group_id, admin_id)
    group = Group.find(group_id)
    admin = Admin.find(admin_id)
    begin
      group.create_import
      raise 'Group not created' unless group.uuid
    rescue => e
      group.status = 'Error creating group'
    else
      group.err = nil
      group.status = 'Created group'
      if group.template
        group.clone_forms(group.payee, false, nil) if group.payee
        group.clone_forms(group.template, true, group.user_uuid) unless group.payee
        if group.payee
          temp = Group.where(:uuid => group.template)
          payee = Group.where(:uuid => group.payee)
          group.create_groups_below(admin_id, temp.id, payee.id)
        end
      else
        template = Group.find(admin.group_template)
        if template
          group.update_attributes(:template => template.uuid)
          group.clone_forms(group.payee, false, nil) if group.payee
          group.clone_forms(group.template, true, group.user_uuid) unless group.payee
          group.create_groups_below(admin_id, template.id, group.id)
        end
      end
    ensure
      group.save
    end
  end

end