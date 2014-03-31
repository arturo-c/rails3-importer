class VerifyImportSubmission
  @queue = :verify_import_submission

  def self.perform(user_id, webform_uuid)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    begin
      submission = client.get_submission_by_uuid(user.submission_uuid)
    rescue => e
      user.status = 'Verification: Error getting user webform submission.'
      user.err = e
    else
      if submission['user_uuid'] == user.uuid
        if submission['data']['org__sequential_id__org_webform'].first.to_i == user.member_id
          user.status = 'Verification: Submission assigned to user.'
          #user.verify_import_roles
        else
          user.status = 'Verification: Submission member id mismatch'
          user.err = 'Existing member id for submission: ' + submission['data']['org__sequential_id__org_webform'].to_s
        end
      else
        user.status = 'Verification: Submission not assigned to correct user.'
        user.err = 'Submission not assigned to user.'
      end
    end

    user.save
  end

end
