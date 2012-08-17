require 'spec_helper'


def trace(source)
  file = File.open(StringIO.new(source))
  tracer = Kefka::Tracer.new
  tracer.trace(file)
  tracer
end

# start with user story
# understanding URI.parse
#
# key features
#   reduce clutter
#     only show variable values when line contains that var
#       variables include instance/class/local variable
#       on_ident (do not include method, i.e. if preceded by period)
#       on_ivar
#       on_cvar
#     all variable values within a method should replace their variable counterparts
#       when mouse hovers over a variable in that method
#     collapsible
#       only show bubbles at toplevel (main entry point of program), others are hidden
#       each bubble will have a # children counter which specifies how many bubbles it has down the chain
#         bubble children count = sum of each methodcall children count
#       expanding a bubble
#         can be a specific method call
#         can be all method calls within bubble
#         immediate children becomes visible to view
#
#
#
#
#

describe "Kefka::Inspector" do

  # file = File.open(file_path)
  # puts "\n#{e.class}: #{e.message} \n    from #{e.backtrace.join("\n")}"
  #
  context "when current line contains any local_variables" do
    it "should evaluate the local_variables for that line" do

    end
  end

  context "when current line does not contain any local_variables" do
    it "should not do anything" do

    end
  end
end

# Given a method_call, line_no, N-th visit
#   line_locals.should == { :x => 4, y => "reg" }
#
#
# Future: Given a method, determine code paths
#   given a vertex, show all adjacency lists
#
#
#
#
#
# determine what exactly the output of callgraph is gonna be
# could reperesent just methodname callgraph
# |----|
# |    |
# |    |
# |----|
#
# Method
#   has many locals (array)
#
# MethodLocal
#   has many line locals
#
#   callstack: call1<method:line> -> call2
#   iteration: 6
#   line_locals: [line_local, line_local, ..]
#
# LineLocal
#   iteration: 3 #{based on length of data array
#   data: { :x => 1, :y => 4}
#
# Call
#   method:
#   line:

#
# Use case
#   I'm at a method bubble
#
#   i wanna see all the execution paths that have gone through this bubble
#   i should be able to filter incoming paths   by their caller/callstack/n-th iteration
#   i should be able to filter a methods locals by their caller/callstack/n-th iteration
#
#
# 3 containers
#   codegraph - graph of what method source         called what method source (vertices)
#   callgraph - graph of what line of method source called what method source (links)
#
#   power     - line value
#
describe "Kekfa::Callgraph" do
  # holds methodcalls (entity)

  # {
  #   vertices => []
  # }
  it "#to_json" do

  end

  describe "edges" do
    # source is a methodcall
    # target is a methodcall
  end

  describe "links" do
    # source is a line
    #   line - identified by methodcall + lineno
    # target is a methodcall
  end

end

describe "Kefka::Method" do
  describe "#source_location" do
    it "should be an array containing file and line where method is defined" do
      file, line = "filename.rb", 20
      method = Method.new(:file => file, :line => line)
      method.source_location.should == [file, line]
    end
  end
end

#
# Callstack
#
#   "call" -> push method, line into stack if method && line
#   "call" -> store curr_method
#   "line" -> store curr_line

describe "Kefka::Call" do
  it "stores current method" do

  end
  it "stores current line" do

  end
end

#
#
describe "Kekfa::Tracer" do

  describe "Locals" do

    describe "line entered once" do
      before do
        @source = <<-RUBY
          def hello
            x = 1
            x += 2
          end

          hello
        RUBY
      end

      it "should able to get locals value" do
        locals = trace(@source).locals

        locals = locals.for_method(:hello).iter(0)

        locals.for_line(0).iter(0)[:x].should == nil
        locals.for_line(1).iter(0)[:x].should == 1
        locals.for_line(2).iter(0)[:x].should == 3
      end
    end

    describe "line entered multiple times" do

      describe "iteration" do
        before do
          @source = <<-RUBY
            def hello
              x = 1
              (0..3).each do
                x += 2
              end
            end

            hello
          RUBY
        end

        it "should able to get locals value" do
          locals = trace(@source).locals

          locals = locals.for_method(:hello).iter(0)

          locals.for_line(2).iter(0)[:x].should == 3
          locals.for_line(2).iter(1)[:x].should == 5
          locals.for_line(2).iter(2)[:x].should == 7
          locals.for_line(2).iter(3)[:x].should == 9
        end
      end

      describe "different call_source same method + diff line" do
        before do
          @source = <<-RUBY
            def hello(x)
              y = x
            end

            def day
              hello(3)
            end

            def night
              hello(8)
            end

            day
            night
          RUBY
        end

        it "should able to get locals value" do
          locals = trace(@source).locals

          locals = locals.for_method(:hello).iter(0)
          locals.for_line(0).iter(0)[:x].should == 3
          line_locals[0][0].var(:x).value.should == 3

          locals = locals.for_method(:hello).iter(1)
          locals.for_line(0).iter(0)[:x].should == 8
        end
      end

      describe "different call_source diff method + diff line" do

      end

      describe "recursion" do

      end
    end

  end

  describe "locals value storage" do
    describe "line entered once" do
      # sample_a.rb:30  -> x should be nil
      # sample_a.rb:31  -> x should be 4
      # sample_a.rb:32  -> x should be 8
      it "should show variable output" do

      end
    end

    describe "line entered more than once" do
      # sample_a.rb:46:0  -> x should be nil
      # sample_a.rb:46:1  -> x should be 4
      # sample_a.rb:46:2  -> x should be 8
      # sample_a.rb:46 -> array
      #   array index representh the N-th iteration
      #   idx 0 -> LocalValue
      #              keys -> x,a
      #              values ->
      #
      it "should show variable output" do

      end
    end
  end
  # should store locals_value_table
  it "should store locals_value_table" do
  end
  #
end

#class Inspector
  #def initialize

  #end

  #def

  #end
#end
