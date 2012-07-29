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

  results.values.each { |method| method.format = :html }
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
