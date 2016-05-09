require 'json'
require 'base_fetcher'
require 'pre_fetcher'

# The `Fetcher` class scrapes consorsbank.de to get a list of all stocks.
# It uses the `PreFetcher` to scrape the search results and strikes out all
# stocks that aren't available in real.
#
# @example Get a list of all stocks.
#   fetcher.run
#   #=> ['DE0005140008', ...]
#
# @see `PreFetcher` for more details.
class Fetcher < BaseFetcher
  # Fetch stocks for the given branches and keep only those stocks which are
  # available in real.
  #
  # @see `PreFetcher#run` for further documentation.
  #
  # @param [ Array<Int> ] branches Optional list of branch IDs.
  #
  # @return [ Array<String> ] Array of ISIN numbers of all found stocks.
  def run(*branches)
    stocks = PreFetcher.new.run(*branches)

    super stocks.each_slice(10).map { |isins| basic_field_url isins }
  end

  private

  # Callback of the `scrape` method once the request is complete.
  # The containing stocks will be saved to into a file. If the list is
  # paginated then the linked pages will be added to the queue.
  #
  # @param [ Typhoeus::Response ] res The response of the HTTP request.
  #
  # @return [ Void ]
  def on_complete(res)
    return unless res.success?

    stocks = JSON.parse(res.body, symbolize_names: true)

    stocks.each do |stock|
      isin = stock[:BasicV1][:ID][:ISIN] if stock[:BasicV1]
      @stocks << isin if isin
    end
  end

  # Build url to request the content of the BasicV1 field of a stock.
  #
  # @example URL for single stock.
  #   url_for ['US30303M1027']
  #   #=> 'stocks?field=BasicV1&id=US30303M1027'
  #
  # @example URL for multiple stocks.
  #   url_for ['US30303M1027', 'US30303M1027']
  #   #=> 'stocks?field=BasicV1&id=US30303M1027&id=US30303M1027'
  #
  # @param [ Array<String> ] isins The ISIN numbers of the specified stock.
  #
  # @return [ String]
  def basic_field_url(isins)
    url = abs_url('ev/rest/de/marketdata/stocks?field=BasicV1')

    isins.each_with_object(url) { |isin, uri| uri << "&id=#{isin}" }
  end
end
