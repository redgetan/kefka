module Kefka

  @@values = {}
  @@method_source = {}

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
        @@method_source[key] = [file, caller[1], line]
      when "line"
      when "return"
        key = "#{classname}_#{id}"
        @@method_source[key] << line if @@method_source[key]
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
      puts "\nTracing Execution using #{handler}...\n\n"
      start(handler)
      file.rewind if file.eof?
      code = file.read
      eval(code, TOPLEVEL_BINDING, file.path, 1)
      stop
    end

    def method_graph
      @@method_source
    end

    def display
      puts "\n==== Generating Method Callgraph...\n\n"
      @@method_source.each do |meth,props|
        puts
        puts meth
        puts

        file, parent_caller, start_line, finish_line = props

        File.open(file) { |f|
          (start_line - 1).times { f.readline }

          code = ""
          (finish_line - start_line + 1).times {
            code << f.readline
          }
          puts code
        }

        puts
      end
    end

    def values
      @@values
    end

  end

end
