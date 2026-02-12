require "rails_helper"

RSpec.describe "Wants", type: :request do
  let(:user) { create(:user) }

  it "未ログインは一覧にアクセスできない（ログインへ）" do
    get wants_path
    expect(response).to have_http_status(:found) # 302
  end

  it "ログイン済みは一覧にアクセスできる（200）" do
    sign_in user
    get wants_path
    expect(response).to have_http_status(:ok)
  end

  it "ログイン済みは作成できる" do
    sign_in user
    expect {
      post wants_path, params: { want: { title: "筋トレ継続", memo: "週3", target_date: Date.today + 10 } }
    }.to change(Want, :count).by(1)
  end
end
