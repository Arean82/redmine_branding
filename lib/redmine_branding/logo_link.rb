# frozen_string_literal: true

module RedmineBranding
  # Wohin das Logo im Kopf verlinkt.
  #
  #   Admin-Vorgabe (Administration → Branding): home, my_page, projects
  #   oder custom (eigene Adresse)
  #   Benutzer (Mein Konto): leer = Vorgabe, sonst home, my_page, projects
  #
  # my_page gilt nur für angemeldete Benutzer, anonyme landen auf der
  # Startseite.
  module LogoLink
    CHOICES = %w[home my_page projects custom].freeze
    USER_CHOICES = %w[home my_page projects].freeze
    DEFAULT = 'my_page'

    module_function

    def admin_choice
      choice = Settings.read['logo_link'].to_s
      CHOICES.include?(choice) ? choice : DEFAULT
    end

    def custom_url
      Settings.read['logo_link_url'].to_s.strip
    end

    def user_choice(user)
      return '' unless user&.logged?

      choice = user.pref.branding_logo_link.to_s
      USER_CHOICES.include?(choice) ? choice : ''
    end

    def choice_for(user)
      user_choice(user).presence || admin_choice
    end

    # Eigene Adresse: relativ zur Installation ("/projects/intern") oder
    # absolut mit http(s); nichts anderes (kein javascript:, kein //host)
    def valid_url?(value)
      value = value.to_s.strip
      return false if value.blank? || value.match?(/\s/)

      (value.start_with?('/') && !value.start_with?('//')) || value.match?(%r{\Ahttps?://[^/\s]+}i)
    end

    # Ziel als [Adresse, Beschriftung] für den Kopf
    def target_for(user, controller)
      case choice_for(user)
      when 'my_page'
        if user&.logged?
          [controller.my_page_path, I18n.t(:label_my_page)]
        else
          [controller.home_path, I18n.t(:label_home)]
        end
      when 'projects'
        [controller.projects_path, I18n.t(:label_project_plural)]
      when 'custom'
        url = custom_url
        valid_url?(url) ? [url, Setting.app_title] : [controller.home_path, I18n.t(:label_home)]
      else
        [controller.home_path, I18n.t(:label_home)]
      end
    end

    def label_for(choice)
      case choice
      when 'home' then I18n.t(:label_home)
      when 'my_page' then I18n.t(:label_my_page)
      when 'projects' then I18n.t(:label_project_plural)
      when 'custom' then I18n.t(:label_branding_logo_link_custom)
      end
    end
  end
end
