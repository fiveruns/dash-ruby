require File.dirname(__FILE__) << "/example_helper"

require 'rubygems'
require 'active_record'

words = if File.exists?("/usr/share/dict/words")
  File.read("/usr/share/dict/words").split
elsif File.exists?("/usr/dict/words")
  File.read("/usr/dict/words").split
else
  raise "words file not found"
end

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do 
  create_table :tickets do |t|
    t.integer :person_id
  end
  create_table :people do |t|
    t.string :name
    t.string :blurb
  end
end

# Pseudo model for testing purposes
class Ticket < ActiveRecord::Base
  belongs_to :person
end

class Person < ActiveRecord::Base
  has_many :tickets, :dependent => :destroy
end

@tickets = 0

dash do |metrics|
		  
  metrics.counter :tickets, "Ticket sale rate" do
    value = @tickets
    @tickets = 0
    value
  end
  
  finds = %w(ActiveRecord::Base.find ActiveRecord::Base.find_by_sql)
  metrics.time :find_time, 'Find Time', :methods => finds, :context => [:parent, 'foo', :child, 'bar']
  metrics.counter :finds, 'Finds', :incremented_by => finds, :context => [:parent, 'foo', :child, 'bar']

  creates = %w(ActiveRecord::Base.create)
  metrics.time :create_time, 'Create Time', :methods => creates, :context => [:parent, 'foo', :child, 'bar']
  metrics.counter :creates, 'Creates', :incremented_by => creates, :context => [:parent, 'foo', :child, 'bar']

  updates = %w(ActiveRecord::Base.update ActiveRecord::Base.update_all
               ActiveRecord::Base#update
               ActiveRecord::Base#save ActiveRecord::Base#save!)
  metrics.time :update_time, 'Update Time', :methods => updates, :context => [:parent, 'foo', :child, 'bar']
  metrics.counter :updates, 'Updates', :incremented_by => updates, :context => [:parent, 'foo', :child, 'bar']
  
  deletes  = %w(ActiveRecord::Base#destroy ActiveRecord::Base.destroy ActiveRecord::Base.destroy_all
                ActiveRecord::Base.delete ActiveRecord::Base.delete_all)
  metrics.time :delete_time, 'Delete Time', :methods => deletes, :context => [:parent, 'foo', :child, 'bar']
  metrics.counter :deletes, 'Deletes', :incremented_by => deletes, :context => [:parent, 'foo', :child, 'bar']
  
end



people = []

loop do
  sleep rand(6)
  person = if rand(2) == 1 && people.any?
    people.rand
  else
    returning Person.create(:name => words.rand) do |p|
      people << p
    end
  end
  count = 0
  rand(10).times do 
    person.tickets.create
    @tickets += 1
    count += 1
  end
  person.update_attribute(:blurb, words.rand) # Just for an update
  puts "#{person.name} bought #{count} ticket(s)"
  if rand(3) == 2
    person.destroy
    people.delete(person)
    puts "Annihilated #{person.name}"
  end
  begin
    if rand(10) % 2 == 0
      raise [ArgumentError, RuntimeError, StandardError].rand.new, 'This is bad!'
    end
  rescue => e
    Fiveruns::Dash.session.add_exception e, 'something' => 'sampley'
  end
end