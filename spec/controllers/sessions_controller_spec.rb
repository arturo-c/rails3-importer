require 'spec_helper'

describe SessionsController do

  before(:each) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:allplayers] = {
        'uid' => '12345',
        'provider' => 'allplayers',
        'info' => {
          'name' => 'Bob'
        },
        'extra' => {
          'access_token' => 'test'
        }
      }
  end

  describe "GET 'new'" do
    it "redirectes users to authentication" do
      get 'new'
      assert_redirected_to '/auth/allplayers'
    end
  end

end
