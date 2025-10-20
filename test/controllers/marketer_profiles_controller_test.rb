require "test_helper"

class MarketerProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketer_profiles_index_url
    assert_response :success
  end

  test "should get show" do
    get marketer_profiles_show_url
    assert_response :success
  end

  test "should get new" do
    get marketer_profiles_new_url
    assert_response :success
  end

  test "should get create" do
    get marketer_profiles_create_url
    assert_response :success
  end

  test "should get edit" do
    get marketer_profiles_edit_url
    assert_response :success
  end

  test "should get update" do
    get marketer_profiles_update_url
    assert_response :success
  end

  test "should get destroy" do
    get marketer_profiles_destroy_url
    assert_response :success
  end
end
