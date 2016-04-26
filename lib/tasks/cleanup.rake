
namespace :cleanup do
  desc 'Remove the tmp folder'
  task(:tmp) { rm_rf 'tmp' }

  desc 'Remove the tmp/stocks.txt file'
  task(:list) { rm_rf 'tmp/stocks.txt' }

  desc 'Remove the log files'
  task(:log) { rm_rf Dir['log/*.log'] }
end
