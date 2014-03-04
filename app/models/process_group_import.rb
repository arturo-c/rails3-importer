class ProcessGroupImport
  @queue = :process_group_import

  def self.perform(admin_id, chunk)
    times = Time.now
    admin = Admin.find(admin_id)
    chunk.collect! { |c|
      c['status'] = 'Processing'
      c['admin_ids'] = [admin.id]
      c['timestamp'] = times
      c
    }
    Group.collection.insert(chunk) if chunk.length > 0
    groups = Group.where(:admin_ids.in => [admin.id], :timestamp => times)
    groups.each do |group| admin.groups.push(group) end
  end

end
