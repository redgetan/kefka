require 'coderay'
require 'rgl/adjacency'

require 'logger'

class Kefka

  class Method

    attr_reader :classname, :id, :file, :line, :caller
    attr_accessor :format

    def initialize(options={})
      @classname = options[:classname]
      @id        = options[:id]
      @file      = options[:file]
      @line      = options[:line]
      @caller    = options[:caller]
      @format    = options[:format] || :plain
    end

    def source_location
      return nil unless @file && @line
      [@file,@line]
    end

    def end_line
      @line + source.lines.count - 1
    end

    def key
      source_location.join(":")
    end

    def contains?(file, line)
      @file == file && @line < line && end_line > line
    end

    def source
      @source ||= begin
                    MethodSource.source_helper(source_location)
                  rescue MethodSource::SourceNotFoundError => e
                    warn "Warning: #{e.class} #{e.message}"
                    ""
                  end
    end

    def formatted_source
      if @format == :html
        CodeRay.scan(source, :ruby)
               .div(:line_numbers => :table, :line_number_start => @line)
      else
        source
      end
    end

    def to_s
      formatted_source
    end

    def to_json(*a)
      {
        :classname => @classname,
        :id => @id,
        :file => @file,
        :line => @line,
        :end_line => end_line,
        #:caller => @caller,
        :source => formatted_source
      }.to_json(*a)
    end
  end

  class MethodTable
    extend Forwardable
    def_delegators :@store, :[], :[]=, :keys, :values, :to_json

    def initialize
      @store = Hash.new
    end

    def find_from_caller(target_caller)
      target_caller =~ /(\S+?):(\d+).*`(.+)'/
      file, line, method_id = $1, $2.to_i, $3
      find_method_containing(file, line)
    end

    def find_method_containing(file,line)
      @store.values.select { |method| method.contains?(file, line) }.first
    end
  end

  #class MethodGraph
    #extend Forwardable
    #def_delegators :@graph, :vertices, :edges
    #def name

    #end
    #def self.[](*args)
      #@graph = RGL::DirectedAdjacencyGraph.new(*args)
    #end
  #end

  class Tracer

    attr_reader :method_table, :local_values, :logger

    def initialize(log_level = Logger::INFO)
      @method_table = MethodTable.new
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

      @logger.debug "#{event} - #{file}:#{line} #{classname} #{id}"

      if disable_event_handlers?
        @event_disable.pop if event == "end"
        return
      end

      case event
      when "class"
        @event_disable << true
      when "call"
        from_method = @method_table.find_from_caller(caller[1])

        method = Method.new(
          :classname => classname,
          :id => id,
          :file => file,
          :line => line,
          :caller => { :method => from_method, :line => line}
        )

        @method_table[method.key] = method
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

      @logger.debug "#{event} - #{file}:#{line} #{classname} #{id}" if $DEBUG

      if disable_event_handlers?
        @event_disable.pop if event == "end"
        return
      end

      case event
      when "class"
        @event_disable << true
      when "line"
        key = [file, line].join(":")
        @local_values[key] = get_values_of_locals_from_binding(binding)
      else
        # do nothing
      end
    end

    def trace(file_path, handler = :callgraph_handler)
      file = File.open(file_path)

      thread = Thread.new {
        code = file.read
        eval(code, TOPLEVEL_BINDING, file.path, 1)
      }

      thread.set_trace_func method(handler).to_proc
      thread.join
    end

  end

end
