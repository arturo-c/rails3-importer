class GetMemberUuid
  @queue = :get_member_uuid

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      user.err = ''
      if user.uuid && user.group_uuid
        user.add_to_group
        exit!
      elsif user.uuid
        user.status = 'User exists in AllPlayers'
        exit!
      end
      if user.parent_email
        parent = client.user_get_email(user.parent_email)
        if user.email
          u = client.user_get_email(user.email)
          unless u == 'No Content'
            if ((u.first['firstname'].strip.downcase == user.first_name_ && u.first['lastname'].strip.downcase == user.last_name_) || (u.first['email'].strip.downcase == user.email_))
              user.update_attributes(:uuid => u.first['uuid'], :birthday => Date.strptime(u.first['birthday'], "%m/%d/%Y"), :gender => u.first['gender'], :first_name => u.first['firstname'], :last_name => u.first['lastname'], :status => 'AllPlayers')
              user.err = nil
              user.add_to_group if user.group_name
              # Add parent, but currently no way to do that through api.
            end
          end
        end
        unless parent == 'No Content'
          m = Member.where(:email => parent.first['email'].downcase).first
          if m
            unless m.uuid
              m.update_attributes(:uuid => parent.first['uuid'])
            end
          else
            p = parent.first
            Member.create({:admin_uuid => user.admin_uuid, :email => p['email'].downcase, :uuid => p['uuid'], :gender => p['gender'], :first_name => p['firstname'], :last_name => p['lastname'], :birthday => Date.strptime(p['birthday'], "%m/%d/%Y").to_s, :status => 'AllPlayers'})
          end
          user.create_child unless user.uuid
        else
          if Member.where(:email => user.parent_email).first
            user.create_child  unless user.uuid
          else
            raise 'Parent not found'
          end
        end
      elsif user.email
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
            user.create_member
            user.status = 'Ready to be imported.'
          else
            user.status = 'Invalid user data.'
            user.err = errors
          end
        else
          if ((u.first['firstname'].strip.downcase == user.first_name_ && u.first['lastname'].strip.downcase == user.last_name_) || (u.first['email'].strip.downcase == user.email_))
            user.update_attributes(:uuid => u.first['uuid'], :birthday => Date.strptime(u.first['birthday'], "%m/%d/%Y"), :gender => u.first['gender'], :first_name => u.first['firstname'], :last_name => u.first['lastname'], :status => 'AllPlayers')
            user.err = nil
            user.add_to_group if user.group_name
          else
            if user.first_name == 'Parent' || !user.group_name
              user.update_attributes(:uuid => u.first['uuid'], :birthday => Date.strptime(u.first['birthday'], "%m/%d/%Y"), :gender => u.first['gender'], :first_name => u.first['firstname'], :last_name => u.first['lastname'], :status => 'AllPlayers')
              user.err = nil
            else
              user.err = "Account email doesn't match first and last name given"
              user.status = 'Email already taken'
            end
          end
        end
      end
    rescue => e
      user.err = e.to_s
      user.status = 'Error getting user.'
    end

    user.save
  end

end
