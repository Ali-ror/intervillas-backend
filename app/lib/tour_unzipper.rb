require "pathname"
require "fileutils"
require "zip" # gem "rubyzip"

class TourUnzipper
  TARGET_BASE = Rails.root.join("data/tours").tap(&:mkpath)

  Error               = Class.new StandardError
  NoTourFound         = Class.new Error
  MultipleToursFound  = Class.new Error

  attr_reader :tour, :target

  def initialize(tour)
    @tour   = tour
    @target = TARGET_BASE.join(tour.id.to_s)
  end

  def process!
    # If we're in an after_commit hook, `tour.archive_blob.open` might fail,
    # because the "upload" of the Rack tmp file into the disk service happens
    # in another after_commit hook (order dependend). Luckily for us, the
    # Rack tmp file is then still present in `tour.attachment_changes`.
    upload = tour.attachment_changes["archive"]&.attachable || tour.archive_blob
    upload.open { |f| move inflate(f) }

    @target
  ensure
    FileUtils.rm_r tempdir rescue nil
  end

  private

  def tempdir
    @tempdir ||= begin
      name = format "%d-%s", tour.id, Time.current.strftime("%s.%9N")
      Rails.root.join("tmp/tours", name).tap(&:mkpath)
    end
  end

  # Versucht, die Zip-Datei zu entpacken.
  #
  # Betriebssystem-Müll wird ignoriert (__MACOSX-Verzeichnisse,
  # .DS_Store/thumbs.db-Dateien).
  #
  # Irgendwo muss sich in dem entpackten Verzeichnis eine Datei "tour.html"
  # befinden. Das ist der Ausgangspunkt für den Kopier-Vorgang.
  def inflate(file)
    into = tempdir.join("tour")

    Zip::File.open file do |zip|
      relevant = filter_garbage(zip)
      raise NoTourFound, "No relevant files found" if relevant.empty?

      # find anchor
      anchor = relevant.select { |e| e.name =~ /tour.html\z/ }
      raise NoTourFound, "No anchor files found" if anchor.empty?
      raise MultipleToursFound if anchor.size > 1

      elems  = anchor[0].name.split("/")
      prefix = elems.size > 1 ? elems.first + "/" : false

      relevant.each do |entry|
        process_entry(prefix, entry, into)
      end
    end

    into
  end

  def move(src)
    # temp-dir ins Ziel verschieben, bestehende Daten löschen
    FileUtils.rm_r target if target.exist?
    FileUtils.mv src, target
  rescue SystemCallError
    Rails.logger.error($!)
    FileUtils.rm_r tempdir
  end

  def filter_garbage(zip)
    zip.entries.reject { |e| e.name =~ /__MACOSX|thumbs\.db\z|\.DS_Store\z/ }
  end

  def process_entry(prefix, entry, into)
    return if prefix && !entry.name.start_with?(prefix)

    name = entry.name
    name.sub! prefix, "" if prefix
    name = "index.html"  if name == "tour.html"

    entry.extract into.join(name).tap { |f| f.dirname.mkpath }.to_s
  end
end
