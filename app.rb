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

  path = "#{File.expand_path(File.dirname(__FILE__))}/examples/sample_a.rb"
  file = File.open(path)

  @tracer = Kefka::Tracer.new
  @tracer.trace(file, :callgraph_handler)

  # input code
  code = CodeRay.scan(@tracer.code, :ruby).div(:line_numbers => :table)

  graph = @tracer.method_graph

  # output call graph using dot if graphviz is installed
  if graphviz_installed = system("which dot")
    graph.write_to_graphic_file("png", "#{File.expand_path(File.dirname(__FILE__))}/public/graph")
  end

  # html code graph
  graph.vertices.each { |method| method.format = :html }

  {
    :code => code,
    :graphviz_installed => graphviz_installed,
    :graph => graph
  }.to_json
end

get '/locals' do
  content_type :json

  path = "#{File.expand_path(File.dirname(__FILE__))}/examples/sample_a.rb"
  file = File.open(path)

  tracer = Kefka::Tracer.new
  tracer.trace(file, :local_values_handler)
  results = tracer.local_values
  results.to_json
end
