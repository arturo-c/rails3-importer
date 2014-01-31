class VerifyImport
  @queue = :verify_import

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    err = nil
    user.err = nil
    user.status = nil
    begin
      group = Group.where(:uuid => user.group_uuid).first
      submission = client.get_submission(group.org_webform_uuid, nil, user.uuid)
      puts submission.to_yaml
    rescue => e
      user.status = 'Verification Process: Error getting user webform submission.'
      err = e
    else
      unless submission['user_uuid'] == user.uuid
        user.status = 'Verification Process: '
        err = 'Submission not assigned to user.'
      end
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
      user.status = 'Verification Process: Error verifying role.'
      err = e
    end

    if err.nil?
      user.status = 'Verification Process: User account verified'
    else
      user.err = err
    end

    user.save
  end

end
