require 'coderay'
require 'pry'
require 'awesome_print'
require 'logger'

class Kefka

  class Tracer

    def initialize(log_level = Logger::INFO)
      @method_table = {}
      @local_values = {}
      @event_disable = []
      @logger = Logger.new($stderr)
      @logger.level = log_level
    end

    def get_values_of_locals_from_binding(target)
      locals = target.eval("local_variables")
      locals.inject({}) do |result,l|
        val = target.eval(l.to_s)
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

    def disable_event_handlers?
      !@event_disable.empty?
    end

    # Things to IGNORE
    # 1. loading of rubygems/libraries
    def callgraph_handler(event, file, line, id, binding, classname)
      return if file == __FILE__

      @logger.info "#{event} - #{file}:#{line} #{classname} #{id}"

      if disable_event_handlers?
        if event == "end"
          @event_disable.pop
        end
        return
      end

      case event
      when "class"
        @event_disable << true
      when "call"
        # mark the start of method call

        # key must be uniquely identifiable -
        # Class methodname is not enough
        # perhaps include:
        #   1. line
        #   2. file
        key = "#{classname}_#{id}_#{file}_#{line}"
        caller[1] =~ /(\S+?):(\d+).*`(.+)'/
        called_from = { :file => $1, :line => $2, :method => $3 }

        @method_table[key] = [file, called_from, line]
      when "line"
      when "return"
        key = @method_table.keys
                           .select { |k| k =~ Regexp.new(Regexp.escape("#{classname}_#{id}_#{file}")) }
                           .first
        @method_table[key] << line if @method_table[key]
      else
        # do nothing
      end
    rescue Exception => e
      puts "\n#{e.class}: #{e.message} \n    from #{e.backtrace.join("\n")}"
      Process.kill("KILL", $$)
    end

    def local_values_handler(event, file, line, id, binding, classname)
      return if file == __FILE__ || halt_trace?

      @logger.info "#{event} - #{file}:#{line} #{classname} #{id}" if $DEBUG

      if disable_event_handlers?
        if event == "end"
          @event_disable.pop
        end
        return
      end

      case event
      when "class"
        @event_disable << true
      when "call"
      when "line"
        # variables that should not be tracked
        # 1. anything in current lib
        # 2. all local variables that are in TOP LEVEL BINDING before tracing
        #     - but these variables may be overwritten by the traced program,
        #       excluding them would mean not displaying certain relevant
        #       vars in that program
        key = "#{classname}_#{id}_#{file}_#{line}"
        @local_values[key] = get_values_of_locals_from_binding(binding)
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

    def method_table
      # unless already includes source
      unless @method_table.values.first.length == 5
        @method_table.each do |key,value|

          file, parent_caller, start_line, finish_line = value

          if finish_line.nil?
            # something have gone wrong
            puts "Couldn't find finish_line for method defined at #{file}:#{start_line}"
            ap @method_table
            raise StandardError, "finish_line is missing"
          end

          source = extract_source(file, start_line, finish_line)
          value << source
        end
      end

      @method_table
    end

    def syntax_highlight_with_line_numbers(text, start_line)
      CodeRay.scan(text, :ruby)
             .div(:line_numbers => :table, :line_number_start => start_line)
    end

    # what if finish_line is missing
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

    def local_values
      @local_values
    end

  end

end
