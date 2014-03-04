class DeleteSubmission
  @queue = :delete_submission

  def self.perform(user_id, webform_uuid)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    client.add_headers({:NOTIFICATION_BYPASS => 1, :API_USER_AGENT => 'AllPlayers-Import-Client'})
    begin
      client.delete_submission(user.submission_uuid)
    rescue => e
      user.status = 'Error deleting submission.'
      user.err = e
    else
      user.status = 'Submission deleted.'
      user.err = nil
    end

    user.save
  end

end