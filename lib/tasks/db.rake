# frozen_string_literal: true
# Idea from here: https://gist.github.com/matthewrudy/4400b3eee9f8dd7e15e4674359886c58

STRUCTURE_FILE = Rails.root.join("db/structure.sql")

def clean_structure_file
  original = STRUCTURE_FILE.read
  cleaned  = original.dup

  # CRLF to LF
  cleaned.gsub!(/\r\n/, "\n")

  # trailing whitespace
  cleaned.gsub!(/ +$/, "")

  # initdb comment (PG 15+, Docker)
  cleaned.gsub!("-- *not* creating schema, since initdb creates it\n", "")

  # object comments (initdb adds one)
  cleaned.gsub!(/^COMMENT ON.*$/, "")

  # statement comments precede the actual creation and provide no
  # additional value:
  #
  #   --
  #   -- Name: some_seq; Type: SEQUENCE; Schema: public; Owner: -
  #   --
  #
  #   CREATE SEQUENCE public.some_seq ...
  cleaned.gsub!(/--\n-- Name: [-\s\w]+; Type: [-\s\w]+; Schema: [-\s\w]+; Owner: -\n--\n/m, "")

  # excessive new lines
  cleaned.gsub!(/\n{3,}/, "\n\n")

  # last line
  cleaned.gsub!(/\n+\Z/, "\n")

  STRUCTURE_FILE.open("w") { _1.write(cleaned) } unless original == cleaned
end

namespace :db do
  Rake::Task["schema:dump"].enhance do
    clean_structure_file
  end

  Rake::Task["migrate"].enhance do
    clean_structure_file
  end

  namespace :schema do
    desc "clean the structure.sql file"
    task :clean do
      clean_structure_file
    end
  end
end
