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

  describe "PATCH /wants/:id" do
    let!(:want) { create(:want, user: user, title: "元タイトル") }

    it "ログイン済みは自分のwantを更新できる" do
      sign_in user
      patch want_path(want), params: { want: { title: "新タイトル" } }
      expect(want.reload.title).to eq("新タイトル")
    end

    it "他ユーザーのwantは更新できない（404）" do
      other_user = create(:user)
      sign_in other_user
      patch want_path(want), params: { want: { title: "不正更新" } }
      expect(response).to have_http_status(:not_found)
      expect(want.reload.title).to eq("元タイトル")
    end
  end

  describe "DELETE /wants/:id" do
    let!(:want) { create(:want, user: user) }

    it "ログイン済みは自分のwantを削除できる" do
      sign_in user
      expect {
        delete want_path(want)
      }.to change(Want, :count).by(-1)
    end

    it "削除後は一覧にリダイレクトされる" do
      sign_in user
      delete want_path(want)
      expect(response).to redirect_to(wants_path)
    end
  end

  describe "PATCH /wants/:id/achieve" do
    let!(:want) { create(:want, user: user, achieved_at: nil) }

    it "達成を記録できる" do
      sign_in user
      patch achieve_want_path(want), params: { want: { achievement_note: "やり遂げた！" } }
      expect(want.reload.achieved?).to be true
    end

    it "達成後は一覧にリダイレクトされる" do
      sign_in user
      patch achieve_want_path(want), params: { want: { achievement_note: "完了" } }
      expect(response).to redirect_to(wants_path)
    end
  end

  describe "PATCH /wants/:id/toggle_publish" do
    let!(:want) { create(:want, user: user, published: false) }

    it "非公開→公開に切り替えられる" do
      sign_in user
      patch toggle_publish_want_path(want)
      expect(want.reload.published?).to be true
    end

    it "公開→非公開に切り替えられる" do
      want.update!(published: true)
      sign_in user
      patch toggle_publish_want_path(want)
      expect(want.reload.published?).to be false
    end
  end

  describe "GET /public_wants" do
    it "ログイン済みはアクセスできる（200）" do
      sign_in user
      get public_wants_path
      expect(response).to have_http_status(:ok)
    end

    it "未ログインはリダイレクトされる（302）" do
      get public_wants_path
      expect(response).to have_http_status(:found)
    end
  end

  describe "GET /public_wishlist" do
    it "ログイン済みはアクセスできる（200）" do
      sign_in user
      get public_wishlist_path
      expect(response).to have_http_status(:ok)
    end
  end
end
