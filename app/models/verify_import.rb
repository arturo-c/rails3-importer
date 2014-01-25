class VerifyImport
  @queue = :verify_import

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    err = nil
    begin
      group = Group.where(:uuid => user.group_uuid).first
      submission = client.get_submission(group.org_webform_uuid, nil, user.uuid)
    rescue => e
      user.status = 'Error getting user webform submission'
      err = e
    else
      user.status = 'No submission found' unless submission['sid']
    end
    begin
      roles = client.group_roles_list(group.uuid, user.uuid)
      roles_found = false
      user.roles.each do |role|
        roles.each do |r|
          roles_found = true if r['name'] == role
        end
        raise 'Error verifying, ' + role + ' role not found.' unless roles_found
      end
    rescue => e
      user.status = 'Error verifying role.'
      err = e
    else
      user.status = 'User account verified'
      err = e
    end

    user.save
  end

end
