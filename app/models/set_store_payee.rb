class SetStorePayee
  @queue = :set_store_payee

  def self.perform(group_id, payee)
    group = Group.find(group_id)
    client = AllPlayers::Client.new(ENV["STORE_HOST"], 'basic')
    client.add_headers({:Content_Type => 'application/json'})
    response = client.login(ENV["STORE_USER"], ENV["STORE_PASSWORD"])
    client.add_headers({:COOKIE => response['session_name'] + '=' + response['sessid']})
    begin
      client.set_store_payee(group.uuid, payee)
    rescue => e
      group.err = e.to_s
      group.status = 'Error setting payee'
    else
      group.status = 'Success in setting payee.'
    ensure
      group.save
    end
  end

end
