# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineBranding
  module TestHelper
    FILES = File.expand_path('fixtures/files', __dir__)

    def branding_upload(name, type)
      Rack::Test::UploadedFile.new(File.join(FILES, name), type)
    end

    def reset_branding
      Setting.plugin_redmine_branding = { 'logo' => nil, 'favicon' => nil, 'login_logo' => '1', 'logo_link' => 'my_page', 'logo_link_url' => '' }
      FileUtils.rm_rf(RedmineBranding::Asset.directory)
    end

    def store_branding(kind, name = 'logo.png', type = 'image/png')
      RedmineBranding::Asset.new(kind).store!(branding_upload(name, type))
    end
  end
end
