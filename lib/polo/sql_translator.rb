module Polo
  class SqlTranslator

    def initialize(object, options={})
      @record = object
      @options = options
    end

    def to_sql
      records = Array.wrap(@record)

      sqls = records.map do |record|
        raw_sql(record)
      end

      if @options[:on_duplicate] == :ignore
        sqls = ignore_transform(sqls)
      end

      if @options[:on_duplicate] == :override
        sqls = on_duplicate_key_update(sqls, records)
      end

      sqls
    end

    private

    def on_duplicate_key_update(sqls, records)
      insert_and_record = sqls.zip(records)
      insert_and_record.map do |insert, record|
        values_syntax = record.attributes.keys.map do |key|
          "#{key} = VALUES(#{key})"
        end

        on_dup_syntax = "ON DUPLICATE KEY UPDATE #{values_syntax.join(', ')}"

        "#{insert} #{on_dup_syntax}"
      end
    end

    def ignore_transform(inserts)
      inserts.map do |insert|
        insert.gsub("INSERT", "INSERT IGNORE")
      end
    end

    def raw_sql(record)
      connection = ActiveRecord::Base.connection
      attributes = record.attributes

      keys = attributes.keys.map do |key|
        "`#{key}`"
      end

      values = attributes.values.map do |value|
        connection.quote(value)
      end

      "INSERT INTO `#{record.class.table_name}` (#{keys.join(', ')}) VALUES (#{values.join(', ')})"
    end
  end
end
