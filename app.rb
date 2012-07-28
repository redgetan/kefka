$LOAD_PATH.unshift("#{File.expand_path(File.dirname(__FILE__))}/lib")

require 'sinatra'
require 'kefka'
require 'yajl'
require 'yajl/json_gem'

get '/' do
  erb :index
end

get '/callgraph' do
  content_type :json

  path = "examples/sample_a.rb"
  file = File.open(path)

  @tracer = Kefka::Tracer.new
  @tracer.trace(file, :callgraph_handler)

  results = @tracer.method_table

  results.reject! { |k,v|
    if k =~ /prelude/
      @tracer.logger.warn("One of methods in table contains Thread method wherein" +
                          "source_location is invalid - <internal:prelude>")
      true
    end
  }
  results.values.each { |method| method.syntax_highlight_source = true }
  results.to_json
end

get '/locals' do
  content_type :json

  path = "examples/sample_a.rb"
  file = File.open(path)

  tracer = Kefka::Tracer.new
  tracer.trace(file, :local_values_handler)
  results = tracer.local_values
  results.to_json
end
