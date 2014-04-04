module OmniauthMacros
  require 'hashie/mash'
  def mock_auth_hash
    # The mock_auth configuration allows you to set per-provider (or default)
    # authentication hashes to return during integration testing.
    access_token = Hashie::Mash.new
    access_token.secret = 'test'
    access_token.token = 'test'
    OmniAuth.config.mock_auth[:allplayers] = {
      :uid => '12345',
      :provider => 'allplayers',
      :info => {
        :name => 'mockuser'
      },
      'extra' => {
        'access_token' => access_token
      }
    }
  end
end