class GetMemberUuid
  @queue = :get_member_uuid

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      u = client.user_get_email(user.email)
      if u == 'No Content'
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
            user.create_child
            parent = client.user_get_email(user.parent_email)
            unless parent == 'No Content'
              unless Member.where(:uuid => parent.first['uuid']).first
                Member.new({:uuid => parent.first['uuid'], :status => 'Already on AllPlayers.', :email => user.parent_email}).save
              end
            end
          end
          user.status = 'Ready to be imported.'
          user.err = nil
        else
          user.status = 'Invalid user data.'
          user.err = errors
        end
      else
        user.uuid = u.first['uuid']
        user.status = 'Already on AllPlayers.'
        user.err = nil
        user.add_to_group if user.group_name
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error getting user.'
    end

    user.save
  end

end