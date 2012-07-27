require 'forwardable'
require 'date'

class Book
  #extend Forwardable
  #def_delegators :@store, :first, :last

  def initialize
    @store = [1,2]
  end

  def []
    "array accessor"
  end
end

class Displayer
  def initialize(out)
    @out = out
  end

  def puts(val)
    @out.puts val
  end
end

def hello
  num = init
  x = 4
  x = x * 2
  b = Book.new

  #if b.first
    #puts "lol"
  #end

  c = b[]
  display = Displayer.new($stdout)
  display.puts "Hello #{num}"
end

def init
  a = 1 + rand(9)
  (0..3).each do |x|
    a = a + time_diff
  end
  a
end

# function called inside a loop
def time_diff
  before = Time.now
  after  = Time.now
  (after - before).to_i
end

hello

