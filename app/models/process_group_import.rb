class ProcessGroupImport
  @queue = :process_group_import

  def self.perform(admin_id, chunk)
    chunk.collect! { |c|
      c = self.process_group_import(c, admin_id)
      group = Group.where(:uuid => c['group_uuid']).first if c['group_uuid']
      group = Group.where(:name => c['group_name']).first unless c['group_uuid']
      c['group_uuid'] = group.uuid if group
      c['group_name'] = group.name if group
      c['status'] = 'New group' unless group
      if c['_id']
        group = Group.find(c['_id'])
        unless group.nil?
          r = c.to_hash.with_indifferent_access.symbolize_keys
          group.update_attributes(group.attributes.merge(r))
          group.save
          c = nil
        end
      end
      c
    }
    Group.collection.insert(chunk) if chunk.length > 0
  end

  def self.process_import(r, admin_id)
    admin = Admin.find(admin_id)
    r['admin_uuid'] = admin.uuid
    r['status'] = 'Processing'
    errors = ''
    
    r['uuid'] = r['uuid'].strip if r['uuid']
    r['err'] = errors
    r['status'] = 'Invalid Data' unless errors == ''

    return r
  end

end
