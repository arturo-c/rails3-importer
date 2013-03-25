class GetWebformData
  @queue = :get_webform_data

  def self.perform(user_id)
    user = Member.find(user_id)
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      group = Group.where(:name => /.*#{user.group_name}.*/).first
      raise 'Submission ID is needed to get webform data' unless user.submission_id
      submission = client.get_submission(group.org_webform_uuid, user.submission_id, nil, {}, "1")
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
