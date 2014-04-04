require 'spec_helper'

describe 'access top page' do
  it 'can sign in user with AllPlayers account' do
    visit '/'
    page.should have_content('Login')
    mock_auth_hash
    click_link 'Login'
    page.should have_content('Signed in!')
    page.should have_content('Logout')
  end
end