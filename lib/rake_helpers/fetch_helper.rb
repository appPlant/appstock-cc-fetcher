require 'benchmark'
require 'fetcher'

# Methods to be used in the Rakefile related to fetching the data.
module FetchHelper
  # Run the fetcher and save the list of ISINS.
  #
  # @return [ Array<String> ] List of fetched ISIN numbers.
  def run_fetcher_and_create_list
    puts 'Fetching stocks from consorsbank...'

    stocks = []
    time   = Benchmark.realtime { stocks = Fetcher.new.run }

    puts "Fetched #{stocks.count} stocks from consorsbank"
    puts "Time elapsed #{time.round(2)} seconds"

    FetchHelper.create_list(stocks, 'tmp/stocks.txt')
  rescue StandardError => e
    $stderr.puts "#{e.class}: #{e.message}"
  end

  # Save the provided list of ISINS in a text file at the provided path.
  #
  # @param [ Array<String> ] List of fetched ISIN numbers.
  # @param [ String ] path The folder where to place the list.
  def self.create_list(stocks, path = 'tmp')
    FileUtils.mkdir_p File.dirname(path)
    File.open(path, 'w+') { |f| stocks.each { |stock| f << "#{stock}\n" } }
    puts "Placed file under #{path}"
  end
end
