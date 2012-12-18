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
 ENV['DATA_ROOT'] = File.expand_path('spec/integration_data')
  begin
 # Rake::Task['yard'].invoke
   	 process = ChildProcess.build('thin', 'start')
  	 process.io.inherit!
  	 process.start
  	 sleep 5
  Rake::Task['spec'].invoke
ensure
  FileUtils.rm_r(File.expand_path('spec/integration_data'), :force => true)
  begin
    process.poll_for_exit(10)
  rescue ChildProcess::TimeoutError
    process.stop # tries increasingly harsher methods to kill the process.
  end
end
end

RSpec::Core::RakeTask.new do |spec|
end

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.options = ["--readme", "README.md"]
end
