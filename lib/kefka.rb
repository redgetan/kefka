require 'coderay'
require 'pry'
require 'rgl'

require 'logger'

class Kefka

  class Caller
    attr_reader :file, :line, :method_id

    def initialize(called_from)
      called_from =~ /(\S+?):(\d+).*`(.+)'/
      @file = $1
      @line = $2
      @method_id = $3
    end

    def to_hash
      { :file => @file, :line => @line, :method => @method_id }
    end
  end

  class Method

    attr_reader :classname, :id, :file, :line, :caller
    attr_accessor :syntax_highlight_source

    def initialize(options={})
      @classname = options[:classname]
      @id        = options[:id]
      @file      = options[:file]
      @line      = options[:line]
      @caller    = Caller.new(options[:caller])
    end

    def source_location
      return nil unless @file && @line
      [@file,@line]
    end

    def end_line
      @line + source.lines.count - 1
    end

    def source
      @source ||= begin
                    MethodSource.source_helper(source_location)
                  rescue MethodSource::SourceNotFoundError => e
                    warn "Warning: #{e.class} #{e.message}"
                    ""
                  end
    end

    def source_with_syntax_highlighting
      text = source
      CodeRay.scan(text, :ruby)
             .div(:line_numbers => :table, :line_number_start => @line)
    end

    def to_json(*a)
      result = {
        :classname => @classname,
        :id => @id,
        :file => @file,
        :line => @line,
        :end_line => end_line,
        :caller => @caller.to_hash
      }

      if @syntax_highlight_source
        result.merge!({ :source => source_with_syntax_highlighting })
      else
        result.merge!({ :source => source })
      end

      result.to_json(*a)
    end
  end

  class Tracer

    attr_reader :method_table, :local_values, :logger

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

    def callgraph_handler(event, file, line, id, binding, classname)
      return if file == __FILE__

      @logger.info "#{event} - #{file}:#{line} #{classname} #{id}"

      if disable_event_handlers?
        @event_disable.pop if event == "end"
        return
      end

      case event
      when "class"
        @event_disable << true
      when "call"
         method = Method.new(:classname => classname,
                             :id => id,
                             :file => file,
                             :line => line,
                             :caller => caller[1])

         key = method.source_location.join(":")
         @method_table[key] = method
      else
        # do nothing
      end
    rescue Exception => e
      puts "\n#{e.class}: #{e.message} \n    from #{e.backtrace.join("\n")}"
      Process.kill("KILL", $$)
    end

    def local_values_handler(event, file, line, id, binding, classname)
      # skip variables that should not be tracked
      # 1. anything in current lib (i.e __FILE__)
      # 2. all local variables that are in TOP LEVEL BINDING before tracing
      #     - but these variables may be overwritten by the traced program,
      #       excluding them would mean not displaying certain relevant
      #       vars in that program
      return if file == __FILE__

      @logger.info "#{event} - #{file}:#{line} #{classname} #{id}" if $DEBUG

      if disable_event_handlers?
        @event_disable.pop if event == "end"
        return
      end

      case event
      when "class"
        @event_disable << true
      when "call"
      when "line"
        key = [file, line].join(":")
        @local_values[key] = get_values_of_locals_from_binding(binding)
      else
        # do nothing
      end
    end

    def trace(file, handler = :callgraph_handler)
      start(handler)
      file.rewind if file.eof?
      code = file.read
      eval(code, TOPLEVEL_BINDING, file.path, 1)
      stop
    end

    def start(handler)
      set_trace_func method(handler).to_proc
    end

    def stop
      set_trace_func nil
    end

  end

end
