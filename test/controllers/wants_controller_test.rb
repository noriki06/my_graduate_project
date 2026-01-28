require "test_helper"

class WantsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get wants_new_url
    assert_response :success
  end

  test "should get create" do
    get wants_create_url
    assert_response :success
  end
end
