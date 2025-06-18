# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'

# ここが非常に重要です。rspec-railsの機能が不足している可能性が高いので、明示的にrequireします。
# 通常は 'config/environment' の中でRails自体がロードされ、
# その際に rspec-rails の Railtie も読み込まれるはずですが、
# エラーから見て、それが不十分な可能性があります。
require 'rails' # ★この行は残しておく
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails' # ★この行を追加または確認してください！

# DatabaseCleanerを読み込む
require 'database_cleaner/active_record'

# Devise::Test::IntegrationHelpers を読み込む
require 'devise/test/integration_helpers'

# Requires supporting ruby files with custom matchers and macros, etc., in
# spec/support/ and its subdirectories.
# Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }
# 上記のコメントアウトを外して、spec/support/ディレクトリ内のヘルパーファイルを読み込むようにすることも検討してください。
# 例えば、custom_devise_helpers.rb などを作成している場合。
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f } # ★この行のコメントアウトを解除する

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # 前回の修正でコメントアウトした filter_rails_from_backtrace! は
  # rspec/rails が適切に読み込まれていれば利用可能になるはずですが、
  # 一旦はエラーを避けるためにコメントアウトしたままで良いでしょう。
  # 問題が解決した後に必要であれば再評価してください。
  # config.filter_rails_from_backtrace!

  # config.use_transactional_fixtures = false # 前回コメントアウトしたままでOKです。

  # FactoryBotのシンタックスをテスト内で使えるようにする
  config.include FactoryBot::Syntax::Methods

  # Deviseのテストヘルパーをrequest specで使用できるようにする
  config.include Devise::Test::IntegrationHelpers, type: :request

  # --- DatabaseCleanerの設定 ---
  # テストスイート全体の開始前にDBを完全にクリーンアップ
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # 各テストの前にDatabaseCleanerの戦略を設定
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction # デフォルトはトランザクション戦略
  end

  # system specなどJavaScriptを伴うテストの場合、トランザクションだとDBの状態が見えないためtruncationに変更
  config.before(:each, type: :system) do # もしsystem specがあれば、この行のコメントアウトを解除
    DatabaseCleaner.strategy = :truncation
  end

  # 各テストの前にデータベースクリーナーを開始
  config.before(:each) do
    DatabaseCleaner.start
  end

  # 各テストの後にデータベースクリーナーを終了（トランザクションをロールバックまたはテーブルをtruncate）
  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  # FactoryBotのシーケンスを各テストの後にリセット
  config.after(:each) do
    FactoryBot.rewind_sequences
  end
  # --- DatabaseCleanerの設定ここまで ---

  # rspec-expectations config
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Backtrace filtering (previous version's fix)
  config.backtrace_exclusion_patterns << /lib\/rails/
  config.backtrace_exclusion_patterns << /bin\//
end