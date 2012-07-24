$LOAD_PATH.unshift("#{File.expand_path(File.dirname(__FILE__))}/lib")

require 'sinatra'
require 'kefka'
require 'yajl'

get '/' do
  erb :index
end

get '/trace' do
  content_type :json

  path = "examples/sample1.rb"
  file = File.open(path)
  Kefka.trace(file, :callgraph_handler)
  results = Kefka.method_graph
  json = Yajl::Encoder.encode(results)
  json
end

