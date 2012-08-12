# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "kefka"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Reginald Tan"]
  s.date = "2012-08-12"
  s.description = " It traces the execution path of a program and displays the source code of each method call in the callgraph "
  s.email = "redge.tan@gmail.com"
  s.executables = ["kefka"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README",
    "TODO"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README",
    "Rakefile",
    "VERSION",
    "app.rb",
    "bin/kefka",
    "examples/sample_a.rb",
    "examples/trace_specific_lines.rb",
    "kefka.gemspec",
    "lib/kefka.rb",
    "public/javascripts/app.js",
    "public/javascripts/jquery-1.7.2.js",
    "public/stylesheets/application.css",
    "test/helper.rb",
    "test/test_kefka.rb",
    "views/index.erb"
  ]
  s.homepage = "http://github.com/redgetan/kefka"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "A tool for reading an unfamiliar codebase"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<coderay>, [">= 0"])
      s.add_runtime_dependency(%q<sinatra>, [">= 0"])
      s.add_runtime_dependency(%q<method_source>, [">= 0"])
      s.add_runtime_dependency(%q<rgl>, [">= 0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<pry-doc>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<coderay>, [">= 0"])
      s.add_dependency(%q<sinatra>, [">= 0"])
      s.add_dependency(%q<method_source>, [">= 0"])
      s.add_dependency(%q<rgl>, [">= 0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<pry-doc>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<coderay>, [">= 0"])
    s.add_dependency(%q<sinatra>, [">= 0"])
    s.add_dependency(%q<method_source>, [">= 0"])
    s.add_dependency(%q<rgl>, [">= 0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<pry-doc>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end

