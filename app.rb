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

  @kefka = Kefka.new
  @kefka.trace(file, :callgraph_handler)

  results = @kefka.method_table

  hash = Hash.new

  results.each { |k,v|
    source, start_line = v[4], v[2]
    hash[k] = [
      v[0],
      v[1],
      v[2],
      v[3],
      @kefka.syntax_highlight_with_line_numbers(source,start_line)
    ]
  }

  json = Yajl::Encoder.encode(hash)
  json
end

get '/locals' do
  content_type :json

  path = "examples/sample_a.rb"
  file = File.open(path)

  kefka = Kefka.new
  kefka.trace(file, :local_values_handler)
  results = kefka.local_values
  json = Yajl::Encoder.encode(results)
  json
end
