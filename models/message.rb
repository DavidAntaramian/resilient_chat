class Message < Sequel::Model(:message)

  many_to_one :handles
  many_to_many :chats, :join_table => :chat_message_join
  many_to_many :attachments, :join_table => :message_attachment_join

  MacEpoch = 978307200

  def date
    epoch = values.fetch(:date) + MacEpoch
    Time.at(epoch).strftime("%Y-%m-%dT%H:%M:%S.%L%z")
  end

  def group_chat?
    values.fetch(:handle_id) == 0
  end

  def is_from_me?
    case values.fetch(:is_from_me)
    when 0 then false
    else true
    end
  end
end

Message.db = MessagesDB