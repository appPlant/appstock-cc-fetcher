require 'dropbox_sdk'

desc 'Upload list for scraping'
task(:upload) { upload_to_drive }

namespace :check do
  desc 'Check accessibility of the external drive'
  task(:drive) { drive && puts('OK') }
end

private

# Upload the list to Dropbox.
def upload_to_drive
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
