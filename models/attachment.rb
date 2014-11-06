class Attachment < Sequel::Model(:attachment)
  many_to_many :messages, :join_table => :message_attachment_join
end