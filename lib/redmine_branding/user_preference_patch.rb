# frozen_string_literal: true

module RedmineBranding
  # Benutzereinstellung "Logo verlinkt auf" (Mein Konto → Einstellungen).
  # Gespeichert wie Redmines eigene Einstellungen in den "others" der
  # UserPreference; leer = Vorgabe des Admins.
  module UserPreferencePatch
    def self.included(base)
      base.safe_attributes 'branding_logo_link'
    end

    def branding_logo_link
      self[:branding_logo_link]
    end

    def branding_logo_link=(value)
      value = value.to_s
      self[:branding_logo_link] = LogoLink::USER_CHOICES.include?(value) ? value : ''
    end
  end
end
