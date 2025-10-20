require "test_helper"

class JobListingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get job_listings_index_url
    assert_response :success
  end

  test "should get show" do
    get job_listings_show_url
    assert_response :success
  end

  test "should get new" do
    get job_listings_new_url
    assert_response :success
  end

  test "should get create" do
    get job_listings_create_url
    assert_response :success
  end

  test "should get edit" do
    get job_listings_edit_url
    assert_response :success
  end

  test "should get update" do
    get job_listings_update_url
    assert_response :success
  end

  test "should get destroy" do
    get job_listings_destroy_url
    assert_response :success
  end
end
