class CreateSubmission
  @queue = :create_submission

  def self.perform(member_id, webform_uuid)
    user = Member.find(member_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    user.err = nil
    status = 'Done'
    begin
      unless user.data_fields['org__sequential_id__org_webform']
        user.data_fields['org__sequential_id__org_webform'] = 'Auto Generated'
      end

      submission = client.create_submission(webform_uuid, user.data_fields.symbolize_keys, user.uuid)
      if submission['data']['org__sequential_id__org_webform']
        member_id = submission['data']['org__sequential_id__org_webform']
        if member_id.kind_of?(Fixnum) || member_id.kind_of?(String)
          mid = member_id.to_i
        elsif member_id.kind_of?(Array)
          mid = member_id.first.to_i
        end
        user.member_id = mid
      end
      user.submission_id = submission['sid']
      user.submission_uuid = submission['uuid']
    rescue => e
      user.err = 'Error creating submission' + e
      status = 'Error'
    ensure
      user.status = 'Create Submission: ' + status
      user.save
      #user.verify_import_submission(webform_uuid)
    end
  end
end