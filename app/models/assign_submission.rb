class AssignSubmission
  @queue = :assign_submission

  def self.perform(member_id, webform_uuid)
    member = Member.find(member_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      if member.submission_id
        client.assign_submission(webform_uuid, member.submission_id, member.uuid)
      end
    rescue => e
      member.status = 'Error assigning user webform submission'
      member.err = e
    else
      member.status = 'Webform submission assigned'
      member.err = ''
    end

    member.save
  end

end