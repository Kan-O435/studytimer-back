# このファイルは `rails generate rspec:install` コマンドによって spec/ にコピーされます。
# 通常、このファイルはテストスイートのルートであり、すべてのスペックファイルから最初に読み込まれます。
require 'spec_helper' # RSpecのコア設定を読み込みます

# RAILS_ENV を 'test' に設定します。これにより、Railsアプリケーションはテストモードで動作します。
ENV['RAILS_ENV'] ||= 'test'

# Rails アプリケーションの環境全体を読み込みます。
# これにより、モデル、コントローラ、ルーティング、設定など、アプリケーションのすべてのコンポーネントがテストで利用可能になります。
# この行は spec/rails_helper.rb の中で一度だけ実行されるべきです。
require_relative '../config/environment'

# RailsのRSpecサポートを読み込みます。
# これにより、`type: :model` や `type: :request` といったRSpecのRails固有の機能や、
# `fixture_paths`、`render_views` などのヘルパーが利用可能になります。
require 'rspec/rails'

# shoulda-matchers の設定
require 'shoulda/matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# --- データベース関連の初期設定 ---

# マイグレーションが保留中の場合はテスト実行を中止し、スキーマの更新を促します。
# これにより、データベーススキーマがテストコードと一致しないことによる問題を回避します。
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# --- テストヘルパーとFactoryBot、Deviseの読み込み ---

# spec/support/ ディレクトリとそのサブディレクトリにあるRubyファイルをすべて読み込みます。
# ここには、カスタムマッチャ、マクロ、Deviseのヘルパーなど、テスト固有のヘルパーが配置されます。
# 例えば、`spec/support/devise.rb` や `spec/support/factory_bot.rb` などがある場合、ここで読み込まれます。
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# --- RSpec のグローバル設定 ---

RSpec.configure do |config|
  # FactoryBot のDSL (Domain Specific Language) をテスト内で利用できるようにします。
  # これにより、`FactoryBot.create(:user)` の代わりに `create(:user)` と短縮して書けるようになります。
  config.include FactoryBot::Syntax::Methods

  # Devise のテストヘルパーをリクエストスペック（`type: :request`）で利用できるようにします。
  # これにより、APIテストなどで認証済みのユーザーとしてリクエストを送信できるようになります。
  config.include Devise::Test::IntegrationHelpers, type: :request

  # --- DatabaseCleaner の設定 ---
  # DatabaseCleaner は、テスト間のデータベース状態のクリーンアップを管理するためのgemです。
  # 各テストが独立して実行されることを保証し、テストの信頼性を高めます。

  # テストスイート全体の開始前に、データベースを完全にクリーンアップします。
  # 通常、これは最初の実行時のみに行い、全てのテーブルを削除してから再作成する `truncation` 戦略を使います。
  config.before(:suite) do
    # デフォルトの戦略を `:transaction` に設定。
    # `truncation` でクリーンアップするためには、先にその戦略を定義しておく必要があります。
    DatabaseCleaner.clean_with(:truncation)
  end

  # 各テストケースの実行前にDatabaseCleanerの戦略を設定します。
  # デフォルトでは高速なトランザクション戦略を使用します。
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # JavaScript を伴うシステムスペック（ブラウザ操作など）の場合、
  # トランザクション戦略ではDBの状態が見えないため、`truncation` 戦略に変更します。
  # これにより、JavaScriptからDBの変更が正しく反映されていることを確認できます。
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  # 各テストケースの実行前にデータベースクリーナーを開始します。
  config.before(:each) do
    DatabaseCleaner.start
  end

  # 各テストケースの実行後にデータベースクリーナーを終了（トランザクションのロールバックまたはテーブルのtruncate）します。
  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  # FactoryBot のシーケンス（連番を生成する機能）を各テストの後にリセットします。
  # これにより、テスト間でシーケンスの値が引き継がれるのを防ぎ、テストの独立性を保ちます。
  config.after(:each) do
    FactoryBot.rewind_sequences
  end
  # --- DatabaseCleaner の設定ここまで ---

  # RSpec の期待値（expectations）の挙動を設定します。
  config.expect_with :rspec do |expectations|
    # カスタムマッチャのディスクリプションにチェインされた句を含めるかどうか。
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # RSpec のモック（mocks）の挙動を設定します。
  config.mock_with :rspec do |mocks|
    # 部分的なダブル（partial doubles）が実際に応答しないメソッドを呼び出そうとした場合にエラーを発生させます。
    # これにより、テストの信頼性が向上します。
    mocks.verify_partial_doubles = true
  end

  # メタデータが共有コンテキストにどのように適用されるかを設定します。
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # スタックトレースから不要な行を除外します。
  # これにより、テスト失敗時のエラーメッセージがより見やすくなります。
  # Rails の内部パスや bin/ ディレクトリからのパスを除外しています。
  config.backtrace_exclusion_patterns << /lib\/rails/
  config.backtrace_exclusion_patterns << /bin\//

  # Faker を読み込みます。これはダミーデータを生成するためのgemです。
  # テストコード内で `Faker::Name.name` のように直接利用できます。
  require 'faker'

  # テストが失敗した場合に、ランダムな順序でテストを実行する設定。
  # これにより、テスト間の依存関係によるバグを発見しやすくなります。
  config.order = :random
  Kernel.srand config.seed

  # Rails 7.1.x + Ruby 3.2.x で `ActionView::Template::Handlers::ERB::ENCODING_FLAG` が未定義の場合の対策
  # このコードは、特定の環境下で発生する既知の問題に対する一時的な回避策です。
  # RailsやActionView、Rubyのバージョンが更新され、この問題が解決されたら削除しても構いません。
  config.before(:suite) do
    # ActionView::Template::Handlers::ERB が定義されており、かつ ENCODING_FLAG が未定義の場合にのみ定義します。
    # ERB がモジュールとして定義されていることを前提とします。
    if defined?(ActionView::Template::Handlers::ERB) && !defined?(ActionView::Template::Handlers::ERB::ENCODING_FLAG)
      # 定数を直接追加します。`module ... end` でモジュールを再オープンするのではなく、
      # 定数を直接クラス/モジュールに追加することで、TypeErrorを回避します。
      ActionView::Template::Handlers::ERB.const_set(:ENCODING_FLAG, ''.freeze)
    end
  end
end

# Shoulda::Matchers の設定が重複していたため、一つにまとめました。
# このブロックは既にファイルの先頭に存在するため、重複を削除します。
# Shoulda::Matchers.configure do |config|
#   config.integrate do |with|
#     with.test_framework :rspec
#     with.library :rails
#   end
# end