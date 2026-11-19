# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class AssetTest < ActiveSupport::TestCase
  include RedmineBranding::TestHelper

  def setup
    reset_branding
  end

  def teardown
    reset_branding
  end

  # Bean redmine-branding-yh3t — Regression: Upload im Textmodus.
  #
  # Symptom (lokal, Redmine 6.1.6, 2026-11-19): store! mit einer per
  # File.open im Textmodus geöffneten PNG-Datei brach mit ArgumentError
  # "invalid byte sequence in UTF-8" ab. Ursache: der Inhalt wurde mit
  # blank? geprüft, das per Regex arbeitet und an Binärdaten mit
  # UTF-8-Kodierung scheitert. Browser-Uploads (Binärmodus) waren nicht
  # betroffen.
  def test_upload_im_textmodus_wird_gespeichert
    File.open(File.join(RedmineBranding::TestHelper::FILES, 'logo.png')) do |file|
      assert_equal Encoding::UTF_8, file.external_encoding, 'Testvoraussetzung: Textmodus'
      upload = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: 'logo.png', type: 'image/png')

      RedmineBranding::Asset.new('logo').store!(upload)
    end

    meta = RedmineBranding::Asset.new('logo').current
    assert_equal 'image/png', meta['content_type']
    assert_equal File.binread(File.join(RedmineBranding::TestHelper::FILES, 'logo.png')),
                 File.binread(RedmineBranding::Asset.new('logo').path(meta))
  end

  def test_leere_datei_wird_abgelehnt
    Tempfile.create(['empty', '.png']) do |file|
      upload = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: 'empty.png', type: 'image/png')
      error = assert_raises(RedmineBranding::Asset::InvalidUpload) { RedmineBranding::Asset.new('logo').store!(upload) }
      assert_equal :blank, error.reason
    end
  end
end
