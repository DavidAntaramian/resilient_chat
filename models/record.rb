class Record < Sequel::Model(:zabcdrecord)

  def first_name
    values.fetch(:ZFIRSTNAME)
  end

  def last_name
    values.fetch(:ZLASTNAME)
  end

  def bad?
    first_name.nil? and last_name.nil?
  end

  def to_s
    "[#{values.fetch(:Z_PK)}] #{first_name} #{last_name}"
  end
end

Record.db = ContactsDB