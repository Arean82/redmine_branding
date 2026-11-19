# frozen_string_literal: true

module RedmineBranding
  # Zugriff auf Setting.plugin_redmine_branding: Beschreibungen der Dateien
  # ('logo', 'favicon') und Optionen ('login_logo').
  module Settings
    module_function

    def read
      value = Setting.plugin_redmine_branding
      value.is_a?(Hash) ? value.to_h.stringify_keys : {}
    end

    def write(values)
      Setting.plugin_redmine_branding = read.merge(values.stringify_keys)
    end

    def login_logo?
      read['login_logo'].to_s != '0'
    end
  end
end
