require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    unless @columns
      data = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM "#{table_name}";
      SQL
      @columns ||= data.first.map(&:to_sym)
    end
    @columns
  end

  def self.finalize!
    columns.each do |column|

      define_method(column) {self.attributes[column]}

      define_method("#{column}=") {|value| self.attributes[column] = value}
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
    data = DBConnection.execute(<<-SQL)
      SELECT *
      FROM "#{table_name}"
    SQL
    parse_all(data)
  end

  def self.parse_all(results)
    # ...
    objects = []
    results.each do |params|
      objects << new(params)
    end
    objects
  end

  def self.find(id)
    # ...
    data = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM "#{table_name}"
      WHERE id = ?;
    SQL
    data.first ? new(data.first) : nil
  end

  def initialize(params = {})
    # ...
    params.each do |method, value|
      method = method.to_sym
      unless self.class.columns.include?(method)
        raise "unknown attribute '#{method}'"
      else
        self.send("#{method}=", value)
      end
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    attributes.values.map {|value| value}
  end

  def insert
    # ...
    # debugger
    columns = self.class.columns.drop(1)
    str = columns.map(&:to_s).join(', ')
    q_marks = ['?'] * columns.length

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{str})
    VALUES
      (#{q_marks.join(', ')})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
#   UPDATE
#     table_name
#   SET
#     col1 = ?, col2 = ?, col3 = ?
#   WHERE
#     id = ?
    attr_arr =  []
    attributes.each do |col, value|
      next if col == :id
      attr_arr << "#{col} = '#{value}'"
    end

    DBConnection.execute(<<-SQL)
    UPDATE
      #{self.class.table_name}
    SET
      #{attr_arr.join(', ')}
    WHERE
      id = #{self.id}
    SQL
  end

  def save
    # ...
    self.id ? update : insert
  end
end
