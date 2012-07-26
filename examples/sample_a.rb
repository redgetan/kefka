class Book
  def initialize
    @store = [1,2]
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
  display = Displayer.new($stdout)
  display.puts "Hello #{num}"
end

def init
  a = 1 + rand(9)
  (0..3).each do |x|
    a = a + x
  end
  a
end

hello

