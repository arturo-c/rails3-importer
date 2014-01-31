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
      user.roles.each do |role, flag|
        role_found = false
        roles.each do |r|
          if role == r['name']
            role_found = true
            unless flag.nil?
              raise 'Error verifying, ' + flag + ' flag not found for role ' + role unless r['flags'].first == flag
            end
          end
        end
        raise 'Error verifying, ' + r['name'] + ' role not found.' unless role_found
      end
    rescue => e
      user.status = 'Error verifying role.'
      user.err = e
    else
      user.status = 'User account verified'
      user.err = e
    end

    user.save
  end

end
