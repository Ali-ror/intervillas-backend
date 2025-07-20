#!/usr/bin/env ruby

require "erb"
require "yaml"
require "pathname"
require "English"

HELP = <<~TEXT.freeze
  SYNOPSIS
      #{$PROGRAM_NAME} [OPTIONS...] [FILE]

  DESCRIPTION
      Kopiert die Produktiv-DB in die lokale Datenbank.
      Sollte vom RAILS_ROOT aus aufgerufen werden.

  OPTIONS
      -r, --rsync       Führt RSync durch.
      -m, --migrate     Führt lokale Datenbank-Migration durch.
      -v, --verbose     Gibt mehr Details aus.
      -x, --keep-mbp    Behält die MyBookingPal IDs bei.

  ARGUMENTS
      FILE
          Pfad zur Dump-Datei (*.sql.zst, optional).

          Wenn die Datei nicht existiert, wird ein neuer Dump mit Namen
          `tmp/$date.sql.zst` produziert. Andernfalls wird die Datenbank
          aus der angegebenen Datei wiederhergestellt.

  NOTES
      Für neue Dumps und Rsync (-r) ist SSH-Zugriff erforderlich
      (intervillas@intervillas-florida.com).
TEXT

require "dotenv"
Dotenv.load(".env.development.local", ".env.development", ".env.local", ".env")

def now = Time.now # rubocop:disable Rails

RAILS_ROOT = Pathname.new("../..").expand_path(__FILE__)

def db_config
  @db_config ||= begin
    erb = ERB.new(RAILS_ROOT.join("config/database.yml").read)
    YAML.parse(erb.result(binding)).transform
  end
end

def command(desc)
  cmd = yield
  printf "\n\033[1;32m%s\033[0m\n", desc
  puts cmd

  t_start = now
  system cmd

  if (s = $CHILD_STATUS.exitstatus) == 0
    $stderr.printf "\033[32mOK\033[0m \033[0;37m(%1.2fs)\033[0m\n", now - t_start
  else
    $stderr.printf "\033[31mFailed with status %d\033[0m \033[0;37m(%1.2fms)\033[0m\n", s, now - t_start
    exit s
  end
end

def find_bool(list, short, long)
  i = list.index("-#{short}") || list.index("--#{long}")
  return false unless i

  list.slice!(i, 1)
  true
end

def help!(exit_code)
  $stderr.puts HELP
  exit exit_code
end

SyncDev = Struct.new(:file, :rsync, :verbose, :migrate, :keep_mbp_foreign_ids) do
  def self.run(args)
    sync = parse(args)
    sync.dump_db!
    sync.restore_db!
    sync.migrate_db!
    sync.rsync!
  end

  def self.parse(args)
    help!(0) if find_bool(args, "h", "help")

    r = find_bool(args, "r", "rsync")
    v = find_bool(args, "v", "verbose")
    m = find_bool(args, "m", "migrate")
    x = find_bool(args, "x", "keep-mbp")

    args.each do |arg|
      if arg.start_with?("-")
        $stderr.printf "\033[31;1mERROR: unknown flag #{arg}\033[0m\n\n"
        help!(1)
      end
    end

    f = if args.size > 0
      file = Pathname(args.shift)
      file if file.exist?
    end

    f ||= RAILS_ROOT.join("tmp", now.strftime("%Y-%m-%d_%H%M.sql.zst"))
    new(f, r, v, m, x)
  end

  def dump_db!
    return if file.exist?

    dbname = db_config.fetch("production").fetch("database")
    command "Hole Daten aus Produktiv-DB" do
      "ssh intervillas@intervillas-florida.com pg_dump --clean --no-owner -Zzstd:7 #{dbname} > #{file}"
    end
  end

  def restore_db!
    command "Leere lokale Entwicklungs-DB" do
      "echo 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;' | #{psql_cmd}"
    end

    command "Spiele Produktiv-Daten lokal ein" do
      "zstdcat #{file} | #{psql_cmd}"
    end

    return if keep_mbp_foreign_ids

    command "Entferne MyBookingPal-Fremdschlüssel" do
      "echo 'update booking_pal_products set foreign_id = null' | #{psql_cmd}"
    end
  end

  def migrate_db!
    return unless migrate

    command "Migriere Datenbank" do
      "bundle exec rake db:migrate"
    end
  end

  def rsync!
    return unless rsync

    command "Synchronisiere data" do
      [
        "rsync", "-az", "-e ssh", "--info=progress2",       # neat progress display
        "--exclude 'blobs/va/ri/variants'",                 # discard ActiveStorage variants
        "--exclude 'variants/*'",                           # discard ImgProxy variants
        "--prune-empty-dirs",                               # discard empty directory
        "intervillas@intervillas-florida.com:shared/data",  # copy data (not contents of data)...
        "#{RAILS_ROOT}/",                                   # ... into RAILS_ROOT
        "--delete",                                         # delete files locally uploaded
        "--delete-excluded",                                # delete local ActiveStorage variants
      ].join(" ")
    end
  end

  private

  def psql_cmd
    @psql_cmd ||= begin
      redir  = verbose ? "" : ">/dev/null 2>&1"
      dbname = db_config.fetch("development").fetch("database")

      if (url = ENV.fetch("DATABASE_URL", "")) == ""
        port = ENV.fetch("PGPORT", "5432")
        host = "/var/run/postgresql".then { |socket|
          File.exist?(socket + "/.s.PGSQL.#{port}") ? socket : "localhost"
        }
        "psql -h #{host} -p #{port} -d #{dbname} -qw #{redir}"
      else
        "psql -qw #{url} #{redir}"
      end
    end
  end
end

SyncDev.run(ARGV.dup)
