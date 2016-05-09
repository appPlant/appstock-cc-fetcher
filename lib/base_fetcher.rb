require 'typhoeus'

# Extracted class that holds all common logic for pre-fetcher and fetcher.
# Each subclass needs to implement the `on_complete(res)` delegate.
class BaseFetcher
  # Intialize the fetcher.
  #
  # @return [ PreFetcher ] A new fetcher instance.
  def initialize
    @hydra  = Typhoeus::Hydra.new
    @stocks = []
  end

  protected

  # Run the hydra with the given links to scrape the stocks from the response.
  # By default all branches form search page will be used to return the stocks.
  #
  # @example Scrape all stocks from banking and chemical sector.
  #   run([4, 8])
  #   #=> ['DE0005140008', ...]
  #
  # @example Scrape all stocks from all branches.
  #   run()
  #   #=> ['DE0005140008', ...]
  #
  # @param [ Array<String> ] A list of absolute URLs.
  #
  # @return [ Array<String> ] Array of ISIN numbers of all found stocks.
  def run(uris)
    uris.each { |uri| scrape uri }

    @hydra.run
    @stocks.dup
  ensure
    @stocks.clear
  end

  # Scrape the listed stocks from the search result for a pre-given index.
  # The method workd async as the `on_complete` callback of the response
  # object delegates to the fetchers `on_complete` method.
  #
  # @example Scrape the banking sector.
  #   financeinfos_ajax?page=StocksFinder&branch=4
  #
  # @param [ String ] url An absolute URL of a page with search results.
  #
  # @return [ Void ]
  def scrape(url)
    req = Typhoeus::Request.new(url)

    req.on_complete(&method(:on_complete))

    @hydra.queue req
  end

  # Add host and protocol to the URI to be absolute.
  #
  # @example
  #   abs_url('euroWebDe/servlets/financeinfos_ajax')
  #   #=> 'https://www.consorsbank.de/euroWebDe/servlets/financeinfos_ajax'
  #
  # @param [ String ] A relative URI.
  #
  # @return [ String ] The absolute URI.
  def abs_url(url)
    url.start_with?('http') ? url : "https://www.consorsbank.de/#{url}"
  end
end
