class GetWebformData
  @queue = :get_webform_data

  def self.perform(user_id)
    user = Member.find(user_id)
    admin = Admin.where(:uuid => user.admin_uuid).first
    client = AllPlayers::Client.new(ENV["HOST"])
    client.add_headers({:Authorization => ActionController::HttpAuthentication::Basic.encode_credentials(ENV["ADMIN_EMAIL"], ENV["ADMIN_PASSWORD"])})
    begin
      birthday = user.birthday[0..-10]
      group = Group.where(:name => user.group_name).first
      submission = client.get_submission(group.org_webform_uuid, nil, nil, {'first_name' => user.first_name, 'last_name' => user.last_name, 'birthday' => birthday}, "1")
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
          key = 'phone' if field == 'Phone:'
        else
          user.member_id = field.split(/[^\d]/).join.to_i if key == 'member_id'
          user.phone = field if key == 'phone'
          key = ''
        end
      end

      user.err = ''
    end

    user.save
  end

end
