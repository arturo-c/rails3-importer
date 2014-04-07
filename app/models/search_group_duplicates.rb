class SearchGroupDuplicates
  @queue = :search_group_duplicates

  def self.perform(group_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      g = client.group_search({:search => group.title})
      raise 'Group not found ' unless g[0]['uuid']
    rescue => e
      group.err = e.to_s
      group.status = 'No group duplicates'
    else
      group.err = 'Dup Group found: ' + g[0]['uuid']
      groups = client.user_groups_list(group.user_uuid)
      groups.each do |gr|
        if gr['title'] == g[0]['title']
          group.uuid = g[0]['uuid']
        end
      end
      group.status = 'Group duplicate process end'
    ensure
      group.save
    end
  end

end
