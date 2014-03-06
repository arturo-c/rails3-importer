Rails.application.config.middleware.use OmniAuth::Builder do
  provider :all_players, ENV["OMNIAUTH_PROVIDER_KEY"], ENV["OMNIAUTH_PROVIDER_SECRET"], :client_options => {:site => ENV["HOST"]}
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
