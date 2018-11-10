require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # ...

    where_arr = params.map do |col, value|
      "#{col} = '#{value}'"
    end
    where_str = where_arr.join(' AND ')




    data = DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{table_name}
    WHERE #{where_str}
    SQL

    self.parse_all(data)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
