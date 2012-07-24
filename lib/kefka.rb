require 'forwardable'
require 'coderay'

# set_trace_func runs
#   on_event:
#     create/update method_object (hash_table)
#     create/update callgraph     (tree)
#       on_event:
#         stream serialized changes to Front-End Visualizer (Web-page)
#           on_event:
#             use d3.js to show resulting graph (tree)
#
module Kefka

  @@values = {}
  @@method_table = {}

  class << self

    def get_values_of_locals_from_binding(binding)
      locals = binding.eval("local_variables")
      locals.inject({}) do |result,l|
        val = binding.eval(l.to_s)
        val = begin
                # deep copy
                Marshal.load(Marshal.dump(val)) if val
              rescue TypeError
                "_unknown_"
              end

        result.merge!({ l => val })
        result
      end
    end

    # Things to IGNORE
    # 1. loading of rubygems/libraries
    def callgraph_handler(event, file, line, id, binding, classname)
      # do not trace current file (TODO: and anything in this library)
      return if file == __FILE__
      case event
      when "call"
        # mark the start of method call

        # key must be uniquely identifiable -
        # Class methodname is not enough
        # perhaps include:
        #   1. line
        #   2. file
        key = "#{classname}_#{id}"
        @@method_table[key] = [file, caller[1], line]
      when "line"
      when "return"
        key = "#{classname}_#{id}"
        @@method_table[key] << line if @@method_table[key]
      else
        # do nothing
      end
    rescue Exception => e
      puts "#{e.message} from  --  #{e.backtrace.join("\n")}"
    end

    def locals_values_handler(event, file, line, id, binding, classname)

      return if file == __FILE__

      case event
      when "call"
        #puts "Entering method #{classname} - #{id}"
      when "line"
        # variables that should not be tracked
        # 1. anything in current lib
        # 2. all local variables that are in TOP LEVEL BINDING before tracing
        #     - but these variables may be overwritten by the traced program,
        #       excluding them would mean not displaying certain relevant
        #       vars in that program
        key = "#{file}_#{line}".to_sym
        @@values[key] = get_values_of_locals_from_binding(binding)
      else
        # do nothing
      end
    end

    def start(handler)
      set_trace_func method(handler).to_proc
    end

    def stop
      set_trace_func nil
    end

    def trace(file, handler = :callgraph_handler)
      start(handler)
      file.rewind if file.eof?
      code = file.read
      eval(code, TOPLEVEL_BINDING, file.path, 1)
      stop
    end


    def method_graph
      # unless already includes source
      unless @@method_table.values.first.length == 5
        @@method_table.each do |key,value|

          file, parent_caller, start_line, finish_line = value

          source = syntax_highlight(extract_source(file, start_line, finish_line))
          value << source
        end
      end

      @@method_table
    end

    def syntax_highlight(text)
     CodeRay.scan(text, :ruby).div(:line_numbers => :table)
    end

    def extract_source(file,start_line, finish_line)
      code = ""

      File.open(file) do |f|
        (start_line - 1).times { f.readline }

        (finish_line - start_line + 1).times {
          code << f.readline
        }
      end

      code
    end

    def values
      @@values
    end

  end

end
