# frozen_string_literal: true

# Liefert Logo und Favicon aus – öffentlich, denn beide stehen auch auf der
# Anmeldeseite. Mit passender Prüfsumme (?v=…) darf der Browser die Datei
# lange zwischenspeichern; eine neue Datei bekommt eine neue Adresse.
class BrandingAssetsController < ApplicationController
  skip_before_action :check_if_login_required, :check_password_change, :check_twofa_activation

  def show
    asset = RedmineBranding::Asset.new(params[:kind])
    meta = asset.current
    return head(:not_found) unless meta

    if params[:v] == meta['digest']
      expires_in 1.year, public: true
    else
      expires_now
    end

    # SVG kann Scripte enthalten: beim direkten Aufruf nichts ausführen
    response.headers['Content-Security-Policy'] = "default-src 'none'; style-src 'unsafe-inline'; sandbox"
    response.headers['X-Content-Type-Options'] = 'nosniff'

    send_file asset.path(meta), type: meta['content_type'], disposition: 'inline'
  end
end
