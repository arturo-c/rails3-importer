require 'spec_helper'

describe 'Members' do
  before :each do
    visit '/'
    mock_auth_hash
    click_link 'Login'
  end

  describe 'GET /members' do
    it 'return 200 status' do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get members_path
      response.status.should be(200)
    end
  end
end
