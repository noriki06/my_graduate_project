require "test_helper"

class WantsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    sign_in users(:one)
    get new_want_url
    assert_response :success
  end

  test "should create want" do
    sign_in users(:one)

    assert_difference("Want.count", 1) do
      post wants_url, params: { want: { title: "テスト", memo: "メモ", deadline: Date.today } }
    end

    assert_redirected_to root_url
  end
end
