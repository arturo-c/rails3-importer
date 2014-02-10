class GetMemberUuid
  @queue = :get_member_uuid

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    status = 'Done'
    begin
      if user.parent_email == user.email
        raise 'Email and Parent Email are identical.'
      end
      if user.uuid && user.group_uuid
        status = 'User in AllPlayers'
        user.add_to_group
        return
      elsif user.uuid
        status = 'User in AllPlayers No Group'
        return
      end
      if user.parent_email
        parent = client.user_get_email(user.parent_email)
        if user.email
          u = client.user_get_email(user.email)
          unless u == 'No Content'
            fname = HTMLEntities.new.decode(u.first['firstname'])
            lname = HTMLEntities.new.decode(u.first['lastname'])
            if ((fname.strip.downcase == user.first_name_ && lname.strip.downcase == user.last_name_))
              user.uuid = u.first['uuid']
              status = 'User in AllPlayers'
              user.add_to_group if user.group_uuid
              return
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
            Member.create({:admin_uuid => user.admin_uuid, :email => p['email'].downcase, :uuid => p['uuid'], :gender => p['gender'], :first_name => p['firstname'], :last_name => p['lastname'], :birthday => Date.strptime(p['birthday'], "%m/%d/%Y").to_s, :status => 'Get Member: Parent in AllPlayers'})
          end
          user.get_child
        else
          if Member.where(:email => user.parent_email).first
            user.get_child
          else
            raise 'Parent not found.'
          end
        end
      elsif user.email
        u = client.user_get_email(user.email)
        if u == 'No Content'
          user.create_member
          status = 'Ready to be imported'
        else
          fname = HTMLEntities.new.decode(u.first['firstname'])
          lname = HTMLEntities.new.decode(u.first['lastname'])
          if ((fname.strip.downcase == user.first_name_ && lname.strip.downcase == user.last_name_))
            user.uuid = u.first['uuid']
            status = 'User in AllPlayers'
            user.add_to_group if user.group_uuid
          else
            if user.group_uuid
              user.err = 'Account email does not match first and last name given: ' + fname + ' ' + lname
              status = 'Email already taken'
            else
              user.uuid = u.first['uuid']
              status = 'Email does not match'
            end
          end
        end
      end
    rescue => e
      user.err = e.to_s
      status = 'Error getting user'
    ensure
      user.status = 'Get Member: ' + status
      user.save
    end
  end

end
