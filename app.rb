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
  #input = CodeRay.scan(@tracer.code, :ruby).div(:line_numbers => :table)

  method_graph = @tracer.method_graph

  # output call graph using dot if graphviz is installed
  #if is_graphviz_installed = system("which dot")
  #  method_graph.write_to_graphic_file("png", "#{File.expand_path(File.dirname(__FILE__))}/public/graph")
  #end

  # html code graph
  method_graph.vertices.each { |method| method.format = :html }

  # line graph
  line_graph = @tracer.line_graph

  # locals
  locals = @tracer.local_values

  {
    #:input => input,
    #:is_graphviz_installed => is_graphviz_installed,
    :vertices => method_graph.vertices,
    :edges => line_graph.edges,
    :locals => locals
  }.to_json
end
