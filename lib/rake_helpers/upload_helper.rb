
# Methods to be used in the Rakefile related to upload the list.
module UploadHelper
  # Upload the list to Dropbox.
  def upload_list
    require 'dropbox_sdk'

    file   = open('tmp/stocks.txt')
    client = DropboxClient.new ENV['ACCESS_TOKEN']

    res = client.put_file('consorsbank.stocks.txt', file, true)

    puts "Uploaded #{res['size']} as rev #{res['revision']}/#{res['rev']}"
  rescue StandardError => e
    $stderr.puts "#{e.class}: #{e.message}"
  end
end
