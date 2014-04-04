require 'spec_helper'

describe 'Groups' do
  before :each do
    visit '/'
    mock_auth_hash
    click_link 'Login'
  end

  describe 'GET /groups without signing in' do
    it 'redirects to home page' do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get groups_path
      response.status.should be(200)
    end
  end
end
