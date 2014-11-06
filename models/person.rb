class Person < Sequel::Model(:people)
  one_to_many :phones, :class => "Person::Phone"
  one_to_many :emails, :class => "Person::Email"

  def first_name
    values.fetch(:first_name)
  end

  def last_name
    values.fetch(:last_name)
  end

  def to_s
    "#{first_name} #{last_name}"
  end

  class Phone < Sequel::Model
    many_to_one :person, :class => :Person

    def to_s
      values.fetch(:number)
    end
  end

  class Email < Sequel::Model
    many_to_one :person, :class => :Person

    def to_s
      values.fetch(:address)
    end
  end
end

Person.db = PeopleDB
Person::Phone.db = PeopleDB
Person::Phone.unrestrict_primary_key
Person::Email.db = PeopleDB
Person::Email.unrestrict_primary_key