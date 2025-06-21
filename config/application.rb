require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module StudytimerBack
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #

    # --- ここから追加・修正する設定 ---

    # アプリケーションのタイムゾーンを日本時間 (JST) に設定
    config.time_zone = "Tokyo"

    # Active Recordがデータベースに書き込む時刻のタイムゾーン。
    # :local に設定すると、config.time_zone で設定したタイムゾーンで保存される。
    # :utc にすると、UTCで保存され、読み込み時に config.time_zone に変換される。
    # 一般的には :utc が推奨されるが、ここではJSTで表示・集計する便宜上 :local も選択肢。
    # まずは :local で試して、日付が正しくなるか確認し、その後必要に応じて :utc に変更することも検討。
    config.active_record.default_timezone = :local 

    # データベースから読み込んだ時刻属性をアプリケーションのタイムゾーンに変換する
    config.active_record.time_zone_aware_attributes = true

    # 週の始まりを日曜日にしたい場合 (任意: Railsのデフォルトは月曜日)
    # これを設定すると、Date.current.beginning_of_week などが日曜日を返すようになります。
    # 必要に応じてコメントアウトを外してください。
    # config.active_support.beginning_of_week = :sunday 

    # --- ここまで追加・修正する設定 ---


    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end