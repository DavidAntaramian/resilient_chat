class Email < Sequel::Model(:zabcdemailaddress)

  def address
    values.fetch(:ZADDRESSNORMALIZED)
  end
end

Email.db = ContactsDB