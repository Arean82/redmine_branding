# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class BrandingTest < Redmine::IntegrationTest
  include RedmineBranding::TestHelper

  fixtures :users, :email_addresses, :user_preferences, :roles, :members, :member_roles,
           :projects, :enabled_modules

  def setup
    reset_branding
  end

  def teardown
    reset_branding
  end

  # --- Logo im Kopf ----------------------------------------------------------

  def test_ohne_logo_keine_ausgabe_im_kopf
    get '/projects'
    assert_response :success
    assert_select 'meta[name="branding-logo"]', 0
    assert_select 'script[src*="branding"]', 0
  end

  def test_admin_laedt_logo_hoch_und_seiten_nennen_es
    log_user('admin', 'admin')
    post '/admin/branding/logo', params: { file: branding_upload('logo.png', 'image/png') }
    assert_redirected_to '/admin/branding'

    get '/projects'
    meta = css_select('meta[name="branding-logo"]').first
    assert meta, 'Meta-Tag fehlt'
    assert_match %r{\A/branding/logo\?v=\h{16}\z}, meta['content']
    assert_select 'link[rel=stylesheet][href*="plugin_assets/redmine_branding/branding"]'
    assert_select 'script[src*="plugin_assets/redmine_branding/branding"][defer]'

    get meta['content']
    assert_response :success
    assert_equal 'image/png', response.media_type
    assert_includes response.headers['Cache-Control'], 'public'
  end

  def test_logo_ist_ohne_anmeldung_erreichbar
    store_branding('logo')
    with_settings login_required: '1' do
      get '/branding/logo'
      assert_response :success
    end
  end

  def test_ohne_passende_pruefsumme_nicht_zwischenspeichern
    store_branding('logo')
    get '/branding/logo?v=veraltet'
    assert_response :success
    assert_not_includes response.headers['Cache-Control'].to_s, 'public'
  end

  def test_neues_logo_ersetzt_das_alte
    store_branding('logo')
    first = RedmineBranding::Asset.new('logo').current

    log_user('admin', 'admin')
    post '/admin/branding/logo', params: { file: branding_upload('logo.svg', 'image/svg+xml') }

    current = RedmineBranding::Asset.new('logo').current
    assert_equal 'image/svg+xml', current['content_type']
    assert_not_equal first['digest'], current['digest']
    assert_equal 1, Dir.glob(File.join(RedmineBranding::Asset.directory, 'logo-*')).size
  end

  def test_als_svg_getarnte_html_datei_wird_abgelehnt
    log_user('admin', 'admin')
    post '/admin/branding/logo', params: { file: branding_upload('not-an-image.svg', 'image/svg+xml') }
    assert_redirected_to '/admin/branding'
    assert_nil RedmineBranding::Asset.new('logo').current
    assert_equal I18n.t(:error_branding_type, locale: :en), flash[:error]
  end

  def test_svg_wird_mit_sandbox_ausgeliefert
    store_branding('logo', 'logo.svg', 'image/svg+xml')
    get '/branding/logo'
    assert_response :success
    assert_includes response.headers['Content-Security-Policy'], 'sandbox'
  end

  def test_admin_entfernt_logo
    store_branding('logo')
    log_user('admin', 'admin')
    delete '/admin/branding/logo'
    assert_redirected_to '/admin/branding'
    assert_nil RedmineBranding::Asset.new('logo').current

    get '/branding/logo'
    assert_response :not_found
  end

  # --- Anmeldeseite ------------------------------------------------------------

  def test_anmeldeseite_zeigt_logo
    store_branding('logo')
    get '/login'
    assert_select '.branding-login-logo img[src^="/branding/logo"]'
  end

  def test_logo_auf_anmeldeseite_abschaltbar
    store_branding('logo')
    log_user('admin', 'admin')
    post '/admin/branding/options', params: { login_logo: '0' }
    assert_redirected_to '/admin/branding'
    assert_not RedmineBranding::Settings.login_logo?

    reset!
    get '/login'
    assert_select '.branding-login-logo', 0
  end

  # --- Favicon -----------------------------------------------------------------

  def test_ohne_favicon_gilt_das_des_themes
    get '/projects'
    assert_select 'link[rel="shortcut icon"]', 1
    assert_select 'link[rel=icon][href^="/branding/favicon"]', 0
  end

  def test_favicon_ersetzt_das_des_themes
    log_user('admin', 'admin')
    post '/admin/branding/favicon', params: { file: branding_upload('logo.png', 'image/png') }
    assert_redirected_to '/admin/branding'

    get '/projects'
    assert_select 'link[rel=icon][type="image/png"][href^="/branding/favicon"]', 1
    assert_select 'link[rel="shortcut icon"]', 0

    get css_select('link[rel=icon]').first['href']
    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  def test_favicon_als_ico
    store_branding('favicon', 'favicon.ico', 'image/x-icon')
    get '/branding/favicon'
    assert_response :success
    assert_includes %w[image/vnd.microsoft.icon image/x-icon], response.media_type
  end

  def test_favicon_lehnt_jpg_ab
    log_user('admin', 'admin')
    post '/admin/branding/favicon', params: { file: branding_upload('logo.jpg', 'image/jpeg') }
    assert_nil RedmineBranding::Asset.new('favicon').current
    assert_equal I18n.t(:error_branding_type, locale: :en), flash[:error]
  end

  def test_logo_und_favicon_sind_unabhaengig
    store_branding('logo')
    store_branding('favicon')
    log_user('admin', 'admin')
    delete '/admin/branding/favicon'

    assert_nil RedmineBranding::Asset.new('favicon').current
    assert RedmineBranding::Asset.new('logo').current
  end

  # --- Rechte und Einstellungsseite --------------------------------------------

  def test_ohne_adminrechte_keine_einstellungen
    log_user('jsmith', 'jsmith')
    get '/admin/branding'
    assert_response :forbidden

    post '/admin/branding/logo', params: { file: branding_upload('logo.png', 'image/png') }
    assert_response :forbidden
    assert_nil RedmineBranding::Asset.new('logo').current
  end

  def test_einstellungsseite_zeigt_beide_formulare_und_optionen
    log_user('admin', 'admin')
    get '/admin/branding'
    assert_response :success
    assert_select 'form#branding-logo-form input[type=file][name=file]'
    assert_select 'form#branding-favicon-form input[type=file][name=file]'
    assert_select 'form#branding-options-form input[type=checkbox][name=login_logo][checked]'
    assert_select '#admin-menu a.icon-photo'
  end

  def test_unbekannte_art_gibt_404
    get '/branding/irgendwas'
    assert_response :not_found
  end
end
