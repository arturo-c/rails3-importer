class GetWebformData
  @queue = :get_webform_data

  def self.perform(user_id, webform_uuid)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      submission = client.get_submission(webform_uuid, user.submission_id, nil, {})
    rescue => e
      user.status = 'Error getting webform data'
      user.err = e
    else
      nohtml = submission['html'].gsub!(/(<[^>]*>)|\n|\t/s) {""}
      data = nohtml.split(" ")
      key = ''
      data.each do |field|
        if key.empty?
          key = 'member_id' if field == 'ID:'
        else
          user.member_id = field.split(/[^\d]/).join.to_i if key == 'member_id'
          key = ''
        end
      end
      user.status = 'Webform data synched'
      user.err = ''
    end

    user.save
  end

end
