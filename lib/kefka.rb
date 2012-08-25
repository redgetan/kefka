require 'coderay'
require 'rgl/adjacency'
require 'rgl/dot'
require 'method_source'

require 'ripper'
require 'forwardable'
require 'logger'

class Kefka

  class Method

    attr_reader :classname, :id, :file, :line
    attr_accessor :source, :format, :depth

    def initialize(options={})
      raise ArgumentError, "missing file + line" unless options[:file] && options[:line]
      @classname  = options[:classname]
      @id         = options[:id]
      @file       = options[:file]
      @start_line = options[:line]
      @format     = options[:format] || :plain
    end

    def source_location
      [@file,@start_line]
    end

    def end_line
      @start_line + source.lines.count - 1
    end

    def key
      source_location ? source_location.join(":") : nil
    end

    def contains?(file, line)
      @file == file && @start_line <= line && end_line > line
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
               .div(:line_numbers => :table, :line_number_start => @start_line)
      else
        source
      end
    end

    def source_at_line(line)
      # what if source is not known, ie. eval
      index = line - @start_line
      source.lines.take(index + 1)[index]
    end

    def to_s
      "#{classname} #{id}"
    end

    def eql?(other)
      self.key == other.key
    end

    alias :== :eql?

    def hash
      [@file,@start_line].hash
    end

    def to_json(*a)
      {
        :classname => @classname,
        :id => @id,
        :file => @file,
        :line => @start_line,
        :end_line => end_line,
        :depth => depth,
        :source => formatted_source
      }.to_json(*a)
    end
  end

  class MethodGraph
    extend Forwardable
    def_delegators :@graph, :vertices, :edges,
                   :write_to_graphic_file

    def initialize
      @graph =  RGL::DirectedAdjacencyGraph.new
    end

    def assign_depth(u,v)
      u.depth = 0 unless u.depth
      v.depth = u.depth + 1
    end

    def add_edge(u,v)
      assign_depth(u,v)
      @graph.add_edge(u,v)
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

  module LocalsHelper
    # @target - binding
    def self.get_locals(target, line_source)
      scope_locals = target.eval("local_variables")
      scope_locals.map! { |local| local.to_s }

      tokens = Ripper.lex(line_source)

      lvar, ivar, cvar = [], [], []

      tokens.each { |token|
        type = token[1]

        case type
        when :on_ident; lvar << token[2] if scope_locals.include? token[2]
        when :on_ivar;  ivar << token[2]
        when :on_cvar;  cvar << token[2]
        else # do nothing
        end
      }

      [lvar,ivar,cvar].flatten
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

    def trace(file_path)
      file = File.open(file_path)

      thread = Thread.new {
        @code = file.read
        #@callstack << create_top_level_method(file_path)
        eval(@code, TOPLEVEL_BINDING, file.path, 1)
      }

      thread.set_trace_func method(:trace_handler).to_proc
      thread.join
    end

    def disable_event_handlers?
      !@event_disable.empty?
    end

    def trace_handler(event, file, line, id, binding, classname)
      return if file == __FILE__

      @logger.debug "#{event} - #{file}:#{line} #{classname} #{id}"

      # skip event handling when iseq is happening inside class loading
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
      when "line"
        # skip variables that should not be tracked
        # 1. anything in current lib (i.e __FILE__)
        # 2. all local variables that are in TOP LEVEL BINDING before tracing
        #     - but these variables may be overwritten by the traced program,
        #       excluding them would mean not displaying certain relevant
        #       vars in that program
        #current_method = @callstack.last

        # given current file & line, determine what method I am in

        method = @method_graph.vertices
                              .select { |method| method.contains?(file,line) }
                              .first

        # skip if not in any previously called method
        if method
          line_source = method.source_at_line(line)

          iseq_key = [file, line].join(":")
          @local_values[iseq_key] = get_values_of_locals_from_binding(binding, line_source)
        end
      when "return"
        @callstack.pop
      else
        # do nothing
      end
    rescue Exception => e
      puts "\n#{e.class}: #{e.message} \n    from #{e.backtrace.join("\n")}"
      Process.kill("KILL", $$)
    end

    def get_values_of_locals_from_binding(target, line_source)
      locals = LocalsHelper.get_locals(target,line_source)
      locals.inject({}) do |result,l|
        val = target.eval(l.to_s)
        val = deep_copy(val)
        result.merge!({ l => val })
        result
      end
    end

    def deep_copy(val)
      Marshal.load(Marshal.dump(val))
    rescue TypeError
      "_unknown_"
    end


    def create_top_level_method(file)
      method = Method.new(
        :classname => "Object",
        :id => "<main>",
        :file => file,
        :line => 1
      )
      method.source = File.readlines(file).join
      return method
    end

  end

end
