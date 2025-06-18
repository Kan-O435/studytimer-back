require 'rails_helper'

RSpec.describe Task, type: :model do
  it 'is valid with a title and user' do
    user = User.create(email: 'test@example.com',password: 'password')
    task = Task.new(title: 'テストタスク',user: user)
    expect(task).to be_valid
  end

  it 'is invalid without a title' do
    task = Task.new(title: nil)
    expect(task).to_not be_valid
  end
end