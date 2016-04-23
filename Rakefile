
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--format documentation --color --require spec_helper'
  end

  task default: :spec
rescue LoadError; end # rubocop:disable Lint/HandleExceptions

desc 'Run Stock-Fetcher for consorsbank.de'
task :fetch do
  require 'securerandom'
  require 'benchmark'
  require 'fetcher'

  path   = File.join(__dir__, "vendor/mount/#{SecureRandom.uuid}.txt")
  stocks = []

  time = Benchmark.realtime do
    stocks = Fetcher.new.run
  end

  FileUtils.mkdir_p File.dirname(path)
  File.open(path, 'w+') { |f| stocks.each { |stock| f << "#{stock}\n" } }

  puts "Fetched #{stocks.count} stocks from consorsbank"
  puts "Time elapsed #{time.round(2)} seconds"
end
