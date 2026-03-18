require 'test_helper'
require 'integration_tests_helper'

class InvitationTest < ActionDispatch::IntegrationTest
  include IntegrationTestHelpers
  self.use_transactional_tests = true

  def setup
    # Freeze time at the start of a TOTP period to avoid tokens expiring
    # at 30-second boundaries between generation and validation
    t = Time.now
    Timecop.freeze(t - (t.to_i % 30) + 5)
  end

  def teardown
    Capybara.reset_sessions!
    Timecop.return
    User.ga_timeout = 3.minutes
    User.ga_timedrift = 3
    User.ga_remembertime = 1.month
  end

  test 'register new user - confirm that we get a display qr page after registering' do
    visit new_user_registration_path
    fill_in('user_email', with: 'test@test.com')
    fill_in('user_password', with: 'Password1')
    fill_in('user_password_confirmation', with: 'Password1')
    click_link_or_button 'Sign up'

    assert_equal user_displayqr_path, current_path

    testuser = User.find_by_email("test@test.com")
    fill_in('user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now))
    click_button 'Continue...'

    assert_equal root_path, current_path
  end

  test 'a new user should be able to sign in without using their token' do
    create_full_user
    User.find_by_email("fulluser@test.com").update(:gauth_enabled => 0)

    visit new_user_session_path
    fill_in 'user_email', :with => 'fulluser@test.com'
    fill_in 'user_password', :with => '123456'
    click_button 'Log in'
    assert_equal root_path, current_path
  end

  test 'a new user should be able to sign in and change their qr code to enabled' do
    create_full_user
    User.find_by_email("fulluser@test.com").update(:gauth_enabled => 0)
    visit new_user_session_path
    fill_in 'user_email', :with => 'fulluser@test.com'
    fill_in 'user_password', :with => '123456'
    click_button 'Log in'

    visit user_displayqr_path

    check 'user_gauth_enabled'
    testuser = User.find_by_email("fulluser@test.com")
    fill_in('user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now))
    click_button 'Continue...'

    assert_equal root_path, current_path
  end

  test 'a new user should be able to sign in change their qr to enabled and be prompted for their token' do
    testuser = create_full_user
    testuser.update(:gauth_enabled => '1')

    visit new_user_session_path
    fill_in 'user_email', :with => 'fulluser@test.com'
    fill_in 'user_password', :with => '123456'
    click_button 'Log in'

    assert_equal user_checkga_path, current_path
  end

  test 'if resource is nil redirects back to custom url' do
    User.stubs(:find_by_gauth_tmp).returns(nil)
    Devise::CheckgaController.any_instance.stubs(:redirect_on_error_url).returns('/foo')
    testuser = create_and_signin_gauth_user

    fill_in 'user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now)
    click_button 'Check Token'
    assert_equal foo_path, current_path
    Capybara.reset_sessions!
  end

  test 'fail token authentication' do
    create_and_signin_gauth_user
    fill_in 'user_gauth_token', :with => '1'
    click_button 'Check Token'

    assert_equal new_user_session_path, current_path
    Capybara.reset_sessions!
  end

  test 'fail token authentication redirects back to custom url' do
    Devise::CheckgaController.any_instance.stubs(:redirect_on_error_url).returns('/foo')
    create_and_signin_gauth_user

    fill_in 'user_gauth_token', :with => "wrong token"
    click_button 'Check Token'
    assert_equal foo_path, current_path
    Capybara.reset_sessions!
  end

  test 'successfull token authentication' do
    testuser = create_and_signin_gauth_user
    fill_in 'user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now)
    click_button 'Check Token'

    assert_equal root_path, current_path
    Capybara.reset_sessions!
  end

  test 'unsuccessful login - if ga_timeout is short' do
    old_ga_timeout = User.ga_timeout
    begin
      User.ga_timeout = 1.second

      testuser = create_and_signin_gauth_user

      # Advance past the ga_timeout while keeping time frozen for TOTP
      Timecop.freeze(Time.now + 5)

      fill_in 'user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now)
      click_button 'Check Token'

      assert_equal new_user_session_path, current_path
    ensure
      User.ga_timeout = old_ga_timeout
      Capybara.reset_sessions!
    end
  end

  test 'unsuccessful login - if ga_timedrift is short' do
    old_ga_timedrift = User.ga_timedrift
    begin
      User.ga_timedrift = 1

      testuser = create_and_signin_gauth_user
      fill_in 'user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now.in(60))
      click_button 'Check Token'

      assert_equal new_user_session_path, current_path
    ensure
      User.ga_timedrift = old_ga_timedrift
      Capybara.reset_sessions!
    end
  end

  test 'user is not prompted for token again after first login until remembertime is up' do
    testuser = create_and_signin_gauth_user
    fill_in 'user_gauth_token', :with => ROTP::TOTP.new(testuser.get_qr).at(Time.now)
    click_button 'Check Token'

    assert_equal root_path, current_path

    visit destroy_user_session_path
    testuser = User.find_by_email("fulluser@test.com")
    visit new_user_session_path
    fill_in 'user_email', :with => 'fulluser@test.com'
    fill_in 'user_password', :with => "123456"
    click_button "Log in"
    assert_equal root_path, current_path
    visit destroy_user_session_path

    Timecop.travel(1.month.to_i + 1.day.to_i)
    testuser = User.find_by_email("fulluser@test.com")
    visit new_user_session_path
    fill_in 'user_email', :with => 'fulluser@test.com'
    fill_in 'user_password', :with => "123456"
    click_button "Log in"
    assert_equal user_checkga_path, current_path

    Timecop.return
  end
end
