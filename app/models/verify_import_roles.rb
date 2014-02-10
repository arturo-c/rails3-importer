class VerifyImportRoles
  @queue = :verify_import_roles

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      roles = client.group_roles_list(user.group_uuid, user.uuid)
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
      user.status = 'Verification: Error verifying role.'
      user.err = e
    else
      user.status = 'Verification: Roles and Flags verified.'
      user.err = nil
    end

    user.save
  end

end
