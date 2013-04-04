class GetMemberUuid
  @queue = :get_member_uuid

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      u = client.user_get_email(user.email) if user.email
      if u == 'No Content' || !user.email
        errors = ''
        errors += 'Missing first name.' unless user.first_name
        errors += 'Missing last name.' unless user.last_name
        errors += 'Missing date of birth(use 1985-08-22).' unless user.birthday
        if user.gender
          errors += 'Invalid gender(use m or f).' unless ['m', 'f'].include? user.gender
        else
          errors += 'Missing gender.'
        end
        if errors == ''
          user.create_member unless user.parent_email
          if user.parent_email
            parent = client.user_get_email(user.parent_email)
            unless parent == 'No Content'
              unless Member.where(:uuid => parent.first['uuid']).first
                Member.new({:uuid => parent.first['uuid'], :status => 'Already on AllPlayers.', :email => user.parent_email}).save
              end
              user.create_child
            else
              raise 'Parent not found'
            end
          end
          user.status = 'Ready to be imported.'
        else
          user.status = 'Invalid user data.'
          user.err = errors
        end
      else
        if u.first['firstname'].casecmp(user.first_name) == 0 && u.first['lastname'].casecmp(user.last_name) == 0
          user.update_attributes(:uuid => u.first['uuid'], :birthday => Date.strptime(u.first['birthday'], "%m/%d/%Y"), :gender => u.first['gender'], :first_name => u.first['firstname'], :last_name => u.first['lastname'], :status => 'AllPlayers')
          user.err = nil
          user.add_to_group if user.group_name
        else
          user.err = "Account email doesn't match first and last name given"
          user.status = 'Email already taken'
        end
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error getting user.'
    end

    user.save
  end

end
