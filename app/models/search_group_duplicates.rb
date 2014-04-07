class SearchGroupDuplicates
  @queue = :search_group_duplicates

  def self.perform(group_id)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      group = client.group_search({:search => group.title})
      raise 'Group not found ' unless group[0]['uuid']
    rescue => e
      group.err = e.to_s
      group.status = 'No group duplicates'
    else
      group.err = 'Dup Group found: ' + group[0]['uuid']
      group.status = 'Group duplicate process end'
    ensure
      group.save
    end
  end

end
