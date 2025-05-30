# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/manifest/task"
require "rake/testtask"
require "rdoc/task"
require "rubocop/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

RuboCop::RakeTask.new

desc "Generate documentation for the acts_as_retired plugin."
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "ActsAsRetired"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include("README")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

desc "Clean automatically generated files"
task :clean do
  FileUtils.rm_rf "pkg"
end

Rake::Manifest::Task.new do |t|
  t.patterns = ["{lib}/**/*", "LICENSE", "*.md"]
end

task build: ["manifest:check"]

desc "Default: run tests and check manifest"
task default: ["test", "manifest:check"]
