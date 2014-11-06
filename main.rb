#!/usr/bin/env ruby
require 'bundler/setup'
require 'sequel'
require 'logger'
require 'elasticsearch'
require 'methadone'
require 'base64'

logger = Logger.new(STDOUT)
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime} (#{severity}): #{msg}\n"
end

include Methadone::Main
include Methadone::CLILogging

leak_exceptions true

main do |messages_db_file, contacts_db_file|
  logger.level = options[:debug] ? Logger::DEBUG : Logger::INFO

  client = Elasticsearch::Client.new

  MessagesDB = Sequel.sqlite(messages_db_file)
  ContactsDB = Sequel.sqlite(contacts_db_file)
  PeopleDB = Sequel.sqlite(':memory:')

  PeopleDB.create_table(:people) do
    primary_key :id
    String :first_name
    String :last_name
  end

  PeopleDB.create_table(:emails) do
    String :address, :primary_key => true
    foreign_key :person_id, :people
  end

  PeopleDB.create_table(:phones) do
    String :number, :primary_key => true
    foreign_key :person_id, :people
  end

  Dir.glob(__dir__ + '/models/*') {|file| require file}

  Record.all.each do |record|
    unless record.bad?
      logger.debug("Starting to process #{record}")
      p = Person.new(first_name: record.first_name, last_name: record.last_name)
      p.save
      Phone.where(:ZOWNER => record.Z_PK).each do |phone|
        unless Person::Phone[phone.number]
          logger.debug("Adding phone number #{phone.number} for #{p}")
          Person::Phone.new(:number => phone.number, :person_id => p.id).save
        end
      end
      Email.where(:ZOWNER => record.Z_PK).each do |email|
        logger.debug("Adding email address #{email.address} for #{p}")
        Person::Email.new(:address => email.address, :person_id => p.id).save
      end
    end
  end


  Message.where(:service => "iMessage").or(:service => "SMS").exclude(:handle_id => 0).each do |message|
    document_exists = client.get(index: "chat", type: "sms", id: message.guid, ignore: 404)

    unless document_exists
      handle = Handle[message.handle_id]
      case handle.format
      when :email_address then contact = Person::Email[handle.id]
      when :phone_number then contact = Person::Phone[handle.phone_number]
      end

      if contact
        person = contact.person
        sender = {
          firstname: person.first_name,
          lastname: person.last_name,
          name: "#{person}"
        }
        case handle.format
        when :email_address then sender[:email] = handle.id
        when :phone_number then sender[:phone] = handle.id
        end
      else
        case handle.format
        when :email_address then sender = {email: handle.id}
        when :phone_number then sender = {phone: handle.id}
        end
      end

      data = {
        text: message.text,
        sent: message.date,
        is_from_me: message.is_from_me?,
        contact: sender,
        service: message.service
      }

      data[:to] = sender[:name] if message.is_from_me? and contact
      data[:from] = sender[:name] if !message.is_from_me? and contact

      image_mime_type = /^image.*$/

      if options[:attachments] && message.attachments.count > 0
        attachments = []
        message.attachments.each do |attachment|
          filename = File.expand_path(attachment.filename)
          if attachment.mime_type =~ image_mime_type and File.exists?(filename)
            filedata = IO.read(filename, mode: "r")
            encoded_data = Base64.strict_encode64(filedata)
            attachments.push({data: encoded_data, mime_type: attachment.mime_type})
          end
        end

        data[:attachments] = attachments if attachments.length
      end

      client.index(index:'chat',type:'sms',id: message.guid, op_type: 'create', body: data)
    end
  end
end

version '0.0.1'
description 'Imports iMessage records into ElasticSearch'
arg :messages_db_file, :required, "The primary SQLite database where the messages are stored"
arg :contacts_db_file, :required, "The primary SQLite database where the contacts are stored"

on("--attachments", "Upload attachments")
on("--debug", "Write debug messages")

go!