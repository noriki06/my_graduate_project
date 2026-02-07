require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module MyGraduateProject
  class Application < Rails::Application
    config.load_defaults 7.2
    config.i18n.default_locale = :ja
    config.autoload_lib(ignore: %w[assets tasks])

    # ✅ 追加：CSP（inline style を許可して棒グラフの width が反映されるようにする）
    config.content_security_policy do |policy|
      policy.default_src :self, :https
      policy.font_src    :self, :https, :data
      policy.img_src     :self, :https, :data
      policy.object_src  :none
      policy.script_src  :self, :https

      # style="width: xx%" を許可する
      policy.style_src   :self, :https, :unsafe_inline
    end
  end
end
