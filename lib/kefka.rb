require 'coderay'
require 'rgl/adjacency'
require 'rgl/dot'
require 'method_source'

require 'forwardable'
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
      @format    = options[:format] || :plain
    end

    def source_location
      [@file,@line]
    end

    def end_line
      @line + source.lines.count - 1
    end

    def key
      source_location ? source_location.join(":") : nil
    end

    def contains?(file, line)
      @file == file && @line < line && end_line > line
    end

    def source
      @source ||= begin
                    MethodSource.source_helper(source_location)
                  rescue MethodSource::SourceNotFoundError => e
                    warn "Warning: #{e.class} #{e.message}"
                    nil
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
      "#{classname} #{id}"
    end

    def eql?(other)
      self.key == other.key
    end

    def hash
      [@file,@line].hash
    end

    def to_json(*a)
      {
        :classname => @classname,
        :id => @id,
        :file => @file,
        :line => @line,
        :end_line => end_line,
        :source => formatted_source
      }.to_json(*a)
    end
  end

  class MethodGraph
    extend Forwardable
    def_delegators :@graph, :vertices, :edges, :add_edge,
                   :write_to_graphic_file

    def initialize
      @graph =  RGL::DirectedAdjacencyGraph.new
    end

    def to_json
      {
        :vertices => vertices,
        :edges => edges.map { |edge|
          {
            :source => edge.source.key,
            :target => edge.target.key
          }
        }
      }.to_json
    end
  end

  class Tracer

    attr_reader :local_values, :logger, :callstack, :method_graph,
                :code

    def initialize(log_level = Logger::INFO)
      @method_graph = MethodGraph.new
      @callstack = []
      @local_values = {}
      @event_disable = []
      @logger = Logger.new($stderr)
      @logger.level = log_level
    end

    def get_locals(target)
      target.eval("local_variables")
    end

    def deep_copy(val)
      Marshal.load(Marshal.dump(val))
    rescue TypeError
      "_unknown_"
    end

    def get_values_of_locals_from_binding(target)
      locals = get_locals(target)
      locals.inject({}) do |result,l|
        val = target.eval(l.to_s)
        val = deep_copy(val)
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
        method_caller = @callstack.last

        method = Method.new(
          :classname => classname,
          :id => id,
          :file => file,
          :line => line
        )

        if method_caller
          @method_graph.add_edge(method_caller,method)
        end

        @callstack << method
      when "return"
        @callstack.pop
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

    def print_callgraph
      public_dir = "#{File.expand_path(File.dirname(__FILE__))}/../public"
      @method_graph.write_to_graphic_file("png", "#{public_dir}/graph")
    end

    def trace(file_path, handler = :callgraph_handler)
      file = File.open(file_path)

      thread = Thread.new {
        @code = file.read
        eval(@code, TOPLEVEL_BINDING, file.path, 1)
      }

      thread.set_trace_func method(handler).to_proc
      thread.join
    end

  end

end
