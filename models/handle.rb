class Handle < Sequel::Model(:handle)
  one_to_many :messages
  many_to_many :chats, :join_table => :chat_handle_join

  def format
    id = values.fetch(:id)
    case
    when /^.*@.*$/ =~ id
      :email_address
    when /^\+\d*$/ =~ id
      :phone_number
    end
  end

  def phone_number
    values.fetch(:id).gsub(/[^[:digit:]]/, '').sub(/^1/, '')
  end
end

Handle.db = MessagesDB