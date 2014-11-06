class Phone < Sequel::Model(:zabcdphonenumber)

  def number
    values.fetch(:ZFULLNUMBER).gsub(/[^[:digit:]]/, '').sub(/^1/, '')
  end
end

Phone.db = ContactsDB