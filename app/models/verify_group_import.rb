class VerifyGroupImport
  @queue = :verify_group_import

  def self.perform(admin_id, chunk)
    chunk.collect! { |c|
      groups = Group.where(:title => /.*#{c['title']}.*/)
      group = Group.where(:title => c['title'])
      if groups.count == 75
        groups.update_all(:status => 'Verified')
        group.update(:status => 'Verified Master')
      else
        groups.update_all(:status => 'Unverfied')
        group.update(:status => 'Unverified Master')
      end
    }
  end

end
