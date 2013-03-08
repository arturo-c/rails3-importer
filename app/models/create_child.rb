class CreateChild
  @queue = :create_child

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      parent = Member.where(:email => user.parent_email).first
      raise "Parent not on AllPlayers." unless (parent && parent.uuid)
      u = client.user_create(user.email, user.first_name, user.last_name, user.birthday, user.gender)
      user.update_attributes(:uuid => u['uuid'], :status => 'Imported')
      user.add_to_group
    rescue => e
      user.update_attributes(:status => 'Error importing user.')
      user.update_attributes(:err => e)
    end
  end

end