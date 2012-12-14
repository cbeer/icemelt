require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec/core/rake_task'
require 'childprocess'

task :default => :ci

desc "Continuous Integration build"
task :ci do
  Rake::Task['spec:functional'].invoke
 # Rake::Task['yard'].invoke
   	 process = ChildProcess.build('thin', 'start')
  	 process.io.inherit!
  	 process.start
  	 sleep 5
  Rake::Task['spec:integration'].invoke
  process.stop
end

RSpec::Core::RakeTask.new do |spec|
end


namespace :spec do

  RSpec::Core::RakeTask.new(:functional) do |spec|
    spec.rspec_opts = "--tag ~integration --tag ~acceptance"

  end
  
  RSpec::Core::RakeTask.new(:integration) do |spec|
    spec.rspec_opts = "--tag acceptance"
  end
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.options = ["--readme", "README.md"]
end
