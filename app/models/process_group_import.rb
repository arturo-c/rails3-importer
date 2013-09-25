class ProcessGroupImport
  @queue = :process_group_import

  def self.perform(admin_id, chunk)
    chunk.collect! { |c|
      c = self.process_group_import(c, admin_id)
      group = Group.where('uuid' => c['uuid']).first if c['uuid']
      if group
      	r = c.to_hash.with_indifferent_access.symbolize_keys
     	group.update_attributes(group.attributes.merge(r))
      	group.save
      	c = nil
      end
      c
    }
    Group.collection.insert(chunk) if chunk.length > 0
  end

  def self.process_group_import(r, admin_id)
    admin = Admin.find(admin_id)
    r['user_uuid'] = admin.uuid
    r['status'] = 'Processing'
    errors = ''
    r['location']['zip'] = r['zip'] if r['zip']
    r['uuid'] = r['uuid'].strip if r['uuid']
    r['err'] = errors
    r['status'] = 'Invalid Data' unless errors == ''

    return r
  end

end
