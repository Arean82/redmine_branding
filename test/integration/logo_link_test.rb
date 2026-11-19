# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class LogoLinkTest < Redmine::IntegrationTest
  include RedmineBranding::TestHelper

  fixtures :users, :email_addresses, :user_preferences, :roles, :members, :member_roles,
           :projects, :enabled_modules

  def setup
    reset_branding
  end

  def teardown
    reset_branding
  end

  def test_ziel_steht_auch_ohne_logo_im_kopf
    get '/projects'
    assert_select 'meta[name="branding-logo-link"]', 1
    assert_select 'meta[name="branding-logo"]', 0
  end

  def test_standard_ist_meine_seite_fuer_angemeldete
    log_user('jsmith', 'jsmith')
    get '/projects'
    assert_equal '/my/page', link_meta['content']
  end

  def test_meine_seite_fuehrt_anonyme_zur_hauptseite
    get '/projects'
    assert_equal '/', link_meta['content']
  end

  def test_admin_setzt_projekte_als_vorgabe
    log_user('admin', 'admin')
    post '/admin/branding/options', params: { logo_link: 'projects', login_logo: '1' }
    assert_redirected_to '/admin/branding'

    get '/my/page'
    assert_equal '/projects', link_meta['content']
  end

  def test_admin_setzt_eigene_adresse
    log_user('admin', 'admin')
    post '/admin/branding/options', params: { logo_link: 'custom', logo_link_url: 'https://intranet.example.test/start' }
    get '/projects'
    assert_equal 'https://intranet.example.test/start', link_meta['content']
  end

  def test_ungueltige_eigene_adresse_wird_nicht_gespeichert
    log_user('admin', 'admin')
    %w[javascript:alert(1) //fremd.example.test ftp://x.test].each do |url|
      post '/admin/branding/options', params: { logo_link: 'custom', logo_link_url: url }
      assert_equal I18n.t(:error_branding_logo_link_url, locale: :en), flash[:error], url
    end
    assert_equal 'my_page', RedmineBranding::LogoLink.admin_choice
  end

  def test_benutzer_waehlt_eigenes_ziel
    log_user('jsmith', 'jsmith')
    get '/my/account'
    assert_select 'select#pref_branding_logo_link[name="pref[branding_logo_link]"] option', 4

    put '/my/account', params: { user: { firstname: 'John' }, pref: { branding_logo_link: 'projects' } }
    assert_redirected_to '/my/account'
    assert_equal 'projects', User.find(2).pref.branding_logo_link

    get '/my/page'
    assert_equal '/projects', link_meta['content']
  end

  def test_benutzerwahl_schlaegt_admin_vorgabe
    RedmineBranding::Settings.write('logo_link' => 'projects')
    pref = User.find(2).pref
    pref.branding_logo_link = 'home'
    pref.save!

    log_user('jsmith', 'jsmith')
    get '/projects'
    assert_equal '/', link_meta['content']
  end

  def test_benutzer_kann_keine_eigene_adresse_setzen
    pref = User.find(2).pref
    pref.branding_logo_link = 'custom'
    assert_equal '', pref.branding_logo_link
  end

  def test_admin_sieht_einstellung_beim_benutzer_bearbeiten
    log_user('admin', 'admin')
    get '/users/2/edit'
    assert_select 'select#pref_branding_logo_link'
  end

  def test_einstellungsseite_zeigt_linkziel
    log_user('admin', 'admin')
    get '/admin/branding'
    assert_select 'select#branding_logo_link option[selected][value=my_page]'
    assert_select 'input#branding_logo_link_url'
  end

  private

  def link_meta
    css_select('meta[name="branding-logo-link"]').first
  end
end
