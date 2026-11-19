# frozen_string_literal: true

require 'digest'
require 'fileutils'

module RedmineBranding
  # Eine hochgeladene Datei (Logo oder Favicon): liegt im Redmine-
  # Dateiverzeichnis (files/redmine_branding), damit sie mit den Anhängen
  # gesichert wird; Beschreibung (Dateiname, Typ, Prüfsumme) in den
  # Plugin-Einstellungen.
  class Asset
    KINDS = {
      'logo' => {
        types: {
          'image/png' => 'png',
          'image/jpeg' => 'jpg',
          'image/webp' => 'webp',
          'image/gif' => 'gif',
          'image/svg+xml' => 'svg'
        },
        max_size: 2 * 1024 * 1024
      },
      'favicon' => {
        types: {
          'image/vnd.microsoft.icon' => 'ico',
          'image/x-icon' => 'ico',
          'image/png' => 'png',
          'image/svg+xml' => 'svg'
        },
        max_size: 512 * 1024
      }
    }.freeze

    # Ungültiger Upload; reason ist ein Symbol für die Fehlermeldung
    class InvalidUpload < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    attr_reader :kind

    def self.directory
      File.join(Attachment.storage_path, 'redmine_branding')
    end

    def initialize(kind)
      raise ArgumentError, "Unbekannte Art: #{kind}" unless KINDS.key?(kind.to_s)

      @kind = kind.to_s
    end

    def allowed_types
      KINDS[kind][:types]
    end

    def max_size
      KINDS[kind][:max_size]
    end

    # Beschreibung der aktuellen Datei oder nil (auch wenn die Datei fehlt)
    def current
      meta = Settings.read[kind]
      return nil unless meta.is_a?(Hash) && meta['filename'].present?
      return nil unless File.file?(path(meta))

      meta
    end

    def path(meta)
      File.join(self.class.directory, File.basename(meta['filename']))
    end

    def store!(upload)
      raise InvalidUpload, :blank unless upload.respond_to?(:read) && upload.respond_to?(:original_filename)
      raise InvalidUpload, :too_large if upload.size > max_size

      # Binär behandeln: im Textmodus gelesene Dateien tragen sonst UTF-8 als
      # Kodierung, und blank? scheitert an ungültigen Byte-Folgen
      data = upload.read.to_s.b
      raise InvalidUpload, :blank if data.empty?

      # Typ nach Inhalt (Dateiname nur als Hinweis): eine umbenannte
      # HTML-Datei wird so nicht als SVG angenommen
      content_type = Marcel::MimeType.for(StringIO.new(data), name: upload.original_filename)
      extension = allowed_types[content_type]
      raise InvalidUpload, :type unless extension

      digest = Digest::SHA256.hexdigest(data)[0, 16]
      filename = "#{kind}-#{digest}.#{extension}"

      FileUtils.mkdir_p(self.class.directory)
      remove_files
      File.binwrite(File.join(self.class.directory, filename), data)

      Settings.write(kind => { 'filename' => filename, 'content_type' => content_type, 'digest' => digest })
    end

    def remove!
      remove_files
      Settings.write(kind => nil)
    end

    private

    def remove_files
      Dir.glob(File.join(self.class.directory, "#{kind}-*")).each { |file| FileUtils.rm_f(file) }
    end
  end
end
