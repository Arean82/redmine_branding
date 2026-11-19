# frozen_string_literal: true

module RedmineBranding
  # Ersetzt Redmines Favicon (sonst das des Themes) durch das hochgeladene.
  # Wird ApplicationHelper vorangestellt (init.rb); ohne hochgeladenes
  # Favicon bleibt alles wie bei Redmine.
  module FaviconHelper
    def favicon
      meta = Asset.new('favicon').current
      return super unless meta

      favicon_link_tag(favicon_path, rel: 'icon', type: meta['content_type'])
    end

    def favicon_path
      meta = Asset.new('favicon').current
      return super unless meta

      branding_asset_path('favicon', v: meta['digest'])
    end
  end
end
