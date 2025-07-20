module ActiveRecord
  module ConnectionAdapters
    module SchemaStatements
      # This code runs at the end of the `db:structure:dump` Rake task and is
      # responsible to dump the performed migrations.
      #
      # The issue with the original code is that adding a single new migration
      # would always produce a 2-line diff, for example:
      #
      #     -('1234');
      #     +('1234'),
      #     +('1235');
      #
      # This monkey patch changes the trailing comma to a leading one, and moves
      # the statement separator (the semi-colon) to a new line. In turn, the
      # diff will look like this:
      #
      #     +,('1235')
      #
      # Note: The Rails 7.1 follows a different approach: Instead of a leading
      # comma, it reverses the order of the versions (see PR 43363). This
      # introduces a difference in the order of operations: Presumably first
      # inserted versions were actually executed last. Another PR, #43414 (which
      # would have introduced leading commas anf from which this monkey patch
      # heavily borrows), was not accepted.
      #
      # - https://github.com/rails/rails/pull/43414
      # - https://github.com/rails/rails/pull/43363
      def insert_versions_sql(versions)
        sm_table = quote_table_name(schema_migration.table_name)

        if versions.is_a?(Array)
          sql = +"INSERT INTO #{sm_table} (version) VALUES\n "
          sql << versions.map { |v| "(#{quote(v)})" }.join("\n,")
          sql << "\n;"
          sql
        else
          "INSERT INTO #{sm_table} (version) VALUES\n (#{quote(versions)})\n;"
        end
      end
    end
  end
end
