#
# Pdftk stellt einen Wrapper für das PDF Toolkit (`pdftk`) zur Verfügung.
#
module Pdftk
  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super message
    end

    def inspect
      format "#<%s code=%s message=%p>", self.class, code, message
    end
  end

  extend self

  # `pdftk $sources cat output $dest`
  #
  # @param [#to_s|#write] dest
  #   Pfad für die pdftk-Ausgabe. String wird als Pathname interpretiert, existierende Dateien
  #   werden überschrieben. `nil` und `"-"` sind gültige Werte, die den Ruckgabewert verändern
  #   (Beschreibung siehe dort).
  # @param [String|Pathname] sources
  #   Array von Quell-Dateien, werden als Pathnames interpretiert. Nil-Werte und Pfade zu nicht
  #   existierenden Dateien werden herausgefiltert. Nach dem Filtern müssen mehr als zwei Einträge
  #   übrigbleiben.
  # @return [String|Object]
  #   Wenn dest `nil` oder `"-"` ist, dann wird das PDF als String (Byte-Array) zurückgegeben.
  #   Ansonsten wird dest zurückgegeben.
  # @raises Error
  #   Wenn pdftk sich nicht ordnungsgemäß beendet (exitcode != 0).
  def join(*sources, dest: nil)
    sources     = normalize_sources(sources)
    bufio, dest = normalize_io_arguments(dest)

    pdftk!(*sources, "cat", "output", dest.to_s) do |io|
      bufio ? IO.copy_stream(io, bufio) : io.read
    end

    bufio.is_a?(StringIO) ? bufio.string : (bufio || dest)
  end

  def pdftk!(*args, &block)
    cmd = ["pdftk", *args].map(&:to_s)
    if block_given?
      IO.popen(cmd, "rb", err: %i[child out], &block)
    else
      buf = IO.popen(cmd, "r", err: %i[child out], &:read)
    end

    if (code = $?.exitstatus) && code != 0
      # maybe switch to `Open3.popen3e`?
      raise Error.new(code, buf || "error message not captured")
    end

    buf
  end

  # @private
  def normalize_sources(sources)
    sources = sources.compact
      .map    { |src| Pathname.new(src) }
      .select { |src| src.exist? }
      .map(&:to_s)
    return sources if sources.size >= 2

    raise ArgumentError, "sources must contain at least two existing files"
  end

  # @private
  def normalize_io_arguments(dest)
    raise ArgumentError, "dest cannot be blank" if dest == ""

    return [StringIO.new, "-"] if dest.nil? || dest == "-"
    return [dest, "-"]         if dest.respond_to?(:write)

    [nil, dest]
  end
end
