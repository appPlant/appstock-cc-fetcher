
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'bundler/setup'

require 'rake_helpers/rspec_helper'
require 'rake_helpers/fetch_helper'
require 'rake_helpers/cleanup_helper'
require 'rake_helpers/upload_helper'

include RSpecHelper
include FetchHelper
include CleanupHelper
include UploadHelper

set_spec_as_default_task

namespace :fetch do
  desc 'Run the fetcher for consorsbank.de'
  task(:stocks) { run_fetcher_and_create_list }
end

desc 'Upload list for scraping'
task(:upload) { upload_list }

namespace :cleanup do
  desc 'Remove the tmp folder'
  task(:tmp) { rm_tmp_folder }

  desc 'Remove the tmp/stocks.txt file'
  task(:list) { rm_list }

  desc 'Remove all logs'
  task(:log) { rm_logs }
end

namespace :check do
  desc 'Check accessibility of the external drive'
  task(:drive) { drive && puts('OK') }
end
