require 'dropbox_sdk'

# Methods to be used in the Rakefile related to upload the list.
module UploadHelper
  # Upload the list to Dropbox.
  def upload_list
    file = open('tmp/stocks.txt')
    res  = drive.put_file('consorsbank.stocks.txt', file, true)

    puts "Uploaded #{res['size']} as rev #{res['revision']}/#{res['rev']}"
  rescue StandardError => e
    $stderr.puts "#{e.class}: #{e.message}"
  end

  # Dropbox client instance.
  # Throws an error if authentification fails.
  #
  # @return [ DropboxClient ]
  def drive
    @client ||= DropboxClient.new ENV['ACCESS_TOKEN']
  end
end
