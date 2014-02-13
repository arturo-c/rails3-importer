class GetSubmission
  @queue = :get_submission

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    status = 'Done'
    user.err = nil
    begin
      group = Group.where(:uuid => user.group_uuid).first
      raise 'No org webform to get submission' unless group.org_webform_uuid
      # Overwrite and create submission.
      if user.create_new_submission
        user.create_submission
        status = 'Overwriting submission'
        return
      end
      submission = client.get_submission(group.org_webform_uuid, nil, user.uuid)
      member_id = submission['data']['org__sequential_id__org_webform']
      if member_id.kind_of?(Fixnum) || member_id.kind_of?(String)
        mid = member_id.to_i
      elsif member_id.kind_of?(Array)
        mid = member_id.first.to_i
      end
      if user.member_id == 0 || mid == user.member_id
        status = 'Submission completed.'
        user.submission_id = submission['sid']
        user.submission_uuid = submission['uuid']
        user.member_id = mid
      else
        status = 'Submission member id mismatch.'
        user.err = 'Existing member id: ' + mid.to_s
        #user.create_submission
      end
    rescue => e
      user.err = e
      status = 'Submission not found, creating...'
      user.create_submission
    ensure
      user.status = 'Getting Submission: ' + status
      user.save
    end
  end
end
