require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get dashboard_index_url
    assert_response :success
  end

  test "should get analytics" do
    get dashboard_analytics_url
    assert_response :success
  end

  test "should get profile_stats" do
    get dashboard_profile_stats_url
    assert_response :success
  end

  test "should get job_stats" do
    get dashboard_job_stats_url
    assert_response :success
  end
end
