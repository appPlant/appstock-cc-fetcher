require 'typhoeus'
require 'nokogiri'
require 'open-uri'

require 'escape_utils'
require 'escape_utils/html/cgi'

# The `Fetcher` class scrapes consorsbank.de to get a list of all stocks.
# To do so it extracts all branches from the search form to make a search
# request to get all stocks per branch. In case of a paginated response it
# follows all subsequent linked pages.
#
# @example Get a list of all stocks.
#   fetcher.run
#   #=> ['DE0005140008', ...]
#
# @example Get a list of all stocks from banking and chemical sector.
#   fetcher.run([4, 8])
#   #=> ['DE0005140008', ...]
#
# @example Get a list of all stock branches.
#   fetcher.branches
#
# @example Scrape stocks for car rental services.
#   fetcher.stocks('financeinfos_ajax?page=StocksFinder&branch=52')
#   #=> [https://www.consorsbank.de/ev/aktie/sixt-se-DE0007231326,
#        https://www.consorsbank.de/ev/aktie/amerco-US0235861004, ...]
#
# @example Linked pages of the banking branch.
#   linked_pages('financeinfos_ajax?page=StocksFinder&version=2&branch=4')
#   #=> 'financeinfos_ajax?page=StocksFinder&version=2&branch=4&pageoffset=1'
#       'financeinfos_ajax?page=StocksFinder&version=2&branch=4&pageoffset=2'
class Fetcher
  # Intialize the fetcher.
  #
  # @return [ Fetcher ] A new fetcher instance.
  def initialize
    @hydra  = Typhoeus::Hydra.new
    @stocks = []
  end

  # Get a list of all branches from the OptionsBranch page.
  #
  # @see /euroWebDe/servlets/financeinfos_ajax?page=OptionsBranch&version=2
  #
  # @example Get the branches found at consorsbank.de.
  #   branches
  #   #=> [1, 2, 3, ...]
  #
  # @return [ Array<String> ] A list of branch IDs.
  def branches
    uri  = 'euroWebDe/servlets/financeinfos_ajax?page=OptionsBranch&version=2'
    page = Nokogiri::HTML(open(abs_url(uri)))
    sel  = 'row:not(:first-child) key text()'

    page.css(sel).map(&:text)
  rescue Timeout::Error
    []
  end

  # Scrape all stocks found on the specified search result page.
  #
  # @example Scrape stocks for car rental services.
  #   stocks('financeinfos_ajax?page=StocksFinder&branch=52')
  #   #=> [https://www.consorsbank.de/ev/aktie/sixt-se-DE0007231326,
  #        https://www.consorsbank.de/ev/aktie/amerco-US0235861004, ...]
  #
  # @param [ Nokogiri::HTML ] page A parsed search result page.
  #
  # @return [ Array<String> ] List of ISIN numbers.
  def stocks(page)
    page.css('row link_target text()').map { |link| link.text[-12..-1] }
  end

  # Determine whether the fetcher has to follow linked lists in case of
  # pagination. Its only required to follow if the URL of the response
  # does not include the `pageoffset` query attribute.
  #
  # @example Follow paginating of the 1st result page of the banking branch.
  #   follow_linked_pages? '...?page=StocksFinder&branch=4'
  #   #=> true
  #
  # @example Follow paginating of the 2nd result page of the banking branch.
  #   follow_linked_pages? '...?page=StocksFinder&branch=4&pageoffset=2'
  #   #=> false
  #
  # @param [ String ] url The URL of the HTTP request.
  #
  # @return [ Boolean ] true if the linked pages have to be scraped as well.
  def follow_linked_pages?(url)
    url.length <= 149 # URL with pageoffset has length > 136
  end

  # Scrape all linked lists found on the specified search result page.
  #
  # @example Linked pages of the banking branch.
  #   linked_pages('financeinfos_ajax?page=StocksFinder&version=2&branch=4')
  #   #=> 'financeinfos_ajax?page=StocksFinder&version=2&branch=4&pageoffset=1'
  #       'financeinfos_ajax?page=StocksFinder&version=2&branch=4&pageoffset=2'
  #
  # @param [ Nokogiri::HTML ] page A parsed search result page.
  # @param [ String] The URL of the page.
  #
  # @return [ Array<String> ] List of URIs pointing to each linked page.
  def linked_pages(page, url = '')
    amount = page.at_css('amount text()').text.to_i
    total  = page.at_css('amount_total text()').text.to_i

    return [] if amount == 0 || amount >= total

    (1..(total / amount)).map { |offset| abs_url "#{url}&pageoffset=#{offset}" }
  rescue NoMethodError
    []
  end

  # Get absolute URL for the StocksFinder page for the specified branch.
  #
  # @param [ Int ] branch_id ID of the branch.
  # @param [ Int] page The page offset, default to 1.
  #
  # @return [ String ] The absolute URL.
  def branch_url(branch_id, page: 1)
    base = 'euroWebDe/servlets/financeinfos_ajax?page=StocksFinder&version=2&FIGURE0=PER.EVALUATION&YEAR0=2016' # rubocop:disable Metrics/LineLength
    url  = "#{base}&branch=#{branch_id.to_i}&blocksize=50"

    url << "&pageoffset=#{page}" if page > 1

    abs_url(url)
  end

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
  # @param [ Array<Int> ] Optional list of branch IDs.
  #
  # @return [ Array<String> ] Array of ISIN numbers of all found stocks.
  def run(indizes = branches)
    indizes.each { |branch| scrape branch_url(branch) }
    @hydra.run
    @stocks.dup
  ensure
    @stocks.clear
  end

  private

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

  # Callback of the `scrape` method once the request is complete.
  # The containing stocks will be saved to into a file. If the list is
  # paginated then the linked pages will be added to the queue.
  #
  # @param [ Typhoeus::Response ] res The response of the HTTP request.
  #
  # @return [ Void ]
  def on_complete(res)
    url   = res.request.url
    page  = Nokogiri::HTML(res.body)
    isins = stocks(page)

    linked_pages(page, url).each { |p| scrape p } if follow_linked_pages? url
  rescue
    $stderr.puts "[Error] #{url}"
  ensure
    @stocks.concat(isins) if defined? isins
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
