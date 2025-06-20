require 'rails_helper'

RSpec.describe Review, type: :model do
  # FactoryBot を使ってテストデータを作成
  let(:user) { create(:user) }
  let(:timer_session) { create(:timer_session, user: user) }

  describe 'バリデーション' do
    it 'score, user, timer_session があれば有効であること' do
      review = build(:review, user: user, timer_session: timer_session)
      expect(review).to be_valid
    end

    it 'user がなければ無効であること' do
      review = build(:review, user: nil, timer_session: timer_session)
      expect(review).not_to be_valid
    end

    it 'timer_session がなければ無効であること' do
      review = build(:review, user: user, timer_session: nil)
      expect(review).not_to be_valid
    end

    it 'score がなければ無効であること' do
      review = build(:review, score: nil, user: user, timer_session: timer_session)
      expect(review).not_to be_valid
    end

    it 'score が 1 未満の場合は無効であること' do
      review = build(:review, score: 0, user: user, timer_session: timer_session)
      expect(review).not_to be_valid
    end

    it 'score が 5 より大きい場合は無効であること' do
      review = build(:review, score: 6, user: user, timer_session: timer_session)
      expect(review).not_to be_valid
    end

    it 'score が 1 から 5 の範囲内であれば有効であること' do
      (1..5).each do |i|
        review = build(:review, score: i, user: user, timer_session: timer_session)
        expect(review).to be_valid
      end
    end

    it 'comment が 500 文字以内であれば有効であること' do
      review = build(:review, comment: 'a' * 500, user: user, timer_session: timer_session)
      expect(review).to be_valid
    end

    it 'comment が 501 文字の場合は無効であること' do
      review = build(:review, comment: 'a' * 501, user: user, timer_session: timer_session)
      expect(review).not_to be_valid
    end

    it 'comment がなくても有効であること' do
      review = build(:review, comment: nil, user: user, timer_session: timer_session)
      expect(review).to be_valid
    end
  end

  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should belong_to(:timer_session) }
  end
end