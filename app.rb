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

  file_path = "#{File.expand_path(File.dirname(__FILE__))}/examples/sample_a.rb"

  @tracer = Kefka::Tracer.new(Logger::INFO)
  @tracer.trace(file_path)

  # input code
  input = CodeRay.scan(@tracer.code, :ruby).div(:line_numbers => :table)

  graph = @tracer.method_graph

  # output call graph using dot if graphviz is installed
  #if is_graphviz_installed = system("which dot")
  #  graph.write_to_graphic_file("png", "#{File.expand_path(File.dirname(__FILE__))}/public/graph")
  #end

  # html code graph
  graph.vertices.each { |method| method.format = :html }

  # locals
  locals = @tracer.local_values

  {
    :input => input,
    #:is_graphviz_installed => is_graphviz_installed,
    :graph => graph,
    :locals => locals
  }.to_json
end
