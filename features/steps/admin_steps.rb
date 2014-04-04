Given /^"([^"]*)" is logged in$/ do |email|
  admin = Admin.create(:uuid => 'string', :name => 'name')
  @session = {:user_id => admin.id, :user_uuid => admin.uuid}
  log_in
end

private

def log_in
  if Capybara.current_driver == :webkit
    page.driver.browser.set_cookie("stub_user_id=#{@session[:user_id]}; path=/; domain=127.0.0.1")
    page.driver.browser.set_cookie("stub_user_uuid=#{@session[:user_uuid]}; path=/; domain=127.0.0.1")
  else
    cookie_jar = Capybara.current_session.driver.browser.current_session.instance_variable_get(:@rack_mock_session).cookie_jar
    cookie_jar[:stub_user_id] = @session[:user_id]
    cookie_jar[:user_uuid] = @session[:user_uuid]
  end
end