$LOAD_PATH.unshift("#{File.expand_path(File.dirname(__FILE__))}/lib")

require 'sinatra'
require 'kefka'
require 'yajl'

get '/' do
  erb :index
end

get '/callgraph' do
  content_type :json

  path = "examples/sample_a.rb"
  file = File.open(path)
  Kefka.trace(file, :callgraph_handler)
  results = Kefka.method_table
  json = Yajl::Encoder.encode(results)
  json
end

get '/locals' do
  content_type :json

  path = "examples/sample_a.rb"
  file = File.open(path)
  Kefka.trace(file, :local_values_handler)
  results = Kefka.local_values
  json = Yajl::Encoder.encode(results)
  json
end
