class CreateSubmission
  @queue = :create_submission

  def self.perform(member_id)
    user = Member.find(member_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    status = 'Done'
    begin
      group = Group.where(:uuid => user.group_uuid).first
      fname = HTMLEntities.new.decode(user.first_name)
      lname = HTMLEntities.new.decode(user.last_name)
      if user.member_id == 0
        member_id = 'Auto Generated'
      else
        member_id = user.member_id
      end
      if user.email
        email = user.email
      else
        email = user.parent_email
      end
      submission = client.create_submission(group.org_webform_uuid, {'profile__field_firstname__profile' => fname, 'profile__field_lastname__profile' => lname, 'profile__field_birth_date__profile' => user.birthday, 'profile__field_email__profile' => email, 'org__sequential_id__org_webform' => member_id, 'profile__field_address_street__profile' => user.address_1, 'profile__field_address_additional__profile' => user.address_2, 'profile__field_address_city__profile' => user.city, 'profile__field_address_province__profile' => user.state, 'profile__field_address_postal_code__profile' => user.zip, 'profile__field_address_country__profile' => user.country, 'profile__field_phone__profile' => user.phone, 'organization_name' => user.group_name}, user.uuid)
      member_id = submission['data']['org__sequential_id__org_webform']
      if member_id.kind_of?(Fixnum) || member_id.kind_of?(String)
        mid = member_id.to_i
      elsif member_id.kind_of?(Array)
        mid = member_id.first.to_i
      end
      user.submission_id = submission['sid']
      user.submission_uuid = submission['uuid']
      user.member_id = mid
    rescue => e
      user.err = e
      status = 'Error creating submission'
    ensure
      user.status = 'Create Submission: ' + status
      user.save
    end
  end
end