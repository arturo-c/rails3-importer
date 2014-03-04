class GetSubmission
  @queue = :get_submission

  def self.perform(user_id, webform_uuid)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    status = 'Done'
    user.err = nil
    begin
      if user.create_new_submission
        user.create_submission(webform_uuid)
        status = 'Overwriting submission'
        return
      end
      submission = client.get_submission(webform_uuid, nil, user.uuid)
      #member_id = submission['data']['org__sequential_id__org_webform']
      #if member_id.kind_of?(Fixnum) || member_id.kind_of?(String)
        #mid = member_id.to_i
      #elsif member_id.kind_of?(Array)
        #mid = member_id.first.to_i
      #end
      #if user.member_id == 0 || mid == user.member_id
        status = 'Submission completed.'
        user.submission_id = submission['sid']
        user.submission_uuid = submission['uuid']
        #user.member_id = mid
      #else
        #status = 'Submission member id mismatch.'
        #user.err = 'Existing member id: ' + mid.to_s
      #end
    rescue => e
      user.err = e
      status = 'Submission not found, creating...'
      user.create_submission(webform_uuid)
    ensure
      user.status = 'Getting Submission: ' + status
      user.save
    end
  end
end
