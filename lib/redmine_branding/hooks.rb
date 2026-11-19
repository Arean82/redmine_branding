# frozen_string_literal: true

module RedmineBranding
  # Kopf jeder Seite:
  #   <meta name="branding-logo-link" content="/my/page" data-label="Meine Seite">
  #     immer – Ziel des Logos (auch für die Fallback-Kachel eines Themes)
  #   <meta name="branding-logo" content="/branding/logo?v=…">
  #     + branding.css / branding.js, nur wenn ein Logo hochgeladen ist
  # Themes, die das Logo selbst darstellen, setzen data-branding-logo="theme"
  # an <html>; dann fügt branding.js nichts ein und das Theme liest die
  # Meta-Tags.
  #
  # Anmeldeseite: Logo über dem Formular (abschaltbar).
  # Mein Konto / Benutzer bearbeiten: Einstellung "Logo verlinkt auf".
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      controller = context[:controller]
      url, label = LogoLink.target_for(User.current, controller)
      tags = [tag.meta(name: 'branding-logo-link', content: url, data: { label: label })]

      logo = Asset.new('logo').current
      if logo
        tags << tag.meta(name: 'branding-logo', content: controller.branding_asset_path('logo', v: logo['digest']))
        tags << stylesheet_link_tag('branding', plugin: 'redmine_branding')
        tags << javascript_include_tag('branding', plugin: 'redmine_branding', defer: true)
      end

      safe_join(tags, "\n")
    end

    def view_account_login_top(context = {})
      return '' unless Settings.login_logo?

      logo = Asset.new('logo').current
      return '' unless logo

      url = context[:controller].branding_asset_path('logo', v: logo['digest'])
      tag.div(class: 'branding-login-logo') do
        tag.img(src: url, alt: Setting.app_title)
      end
    end

    render_on :view_my_account_preferences, partial: 'branding/user_preference'
    render_on :view_users_form_preferences, partial: 'branding/user_preference'
  end
end
