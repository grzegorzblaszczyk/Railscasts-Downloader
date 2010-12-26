#!/usr/bin/env ruby
require 'iconv'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'rss'

puts "Quick'n'Dirty Railscasts Downloader 0.1 by Grzegorz Blaszczyk <grzegorz.blaszczyk@gmail.com>"
puts '============================================================================================'

url = URI.parse('http://feeds.feedburner.com/railscasts')
http = Net::HTTP.new(url.host, url.port)

http.open_timeout = http.read_timeout = 10
http.use_ssl = (url.scheme == "https")

headers = {
  'User-Agent'          => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12',
  'If-Modified-Since'   => 'store in a database and set on each request',
  'If-None-Match'       => 'store in a database and set on each request'
}
response, body = http.get(url.path, headers)
encoding = body.scan(
    /^<\?xml [^>]*encoding="([^\"]*)"[^>]*\?>/
).flatten.first

if encoding.empty?
  if response["Content-Type"] =~ /charset=([\w\d-]+)/
    puts "Feed #{url} is #{encoding} according to Content-Type header"
    encoding = $1.downcase
  else
    puts "Unable to detect content encoding for #{href}, using default."
    encoding = "ISO-8859-1"
  end
else
  puts "Feed #{url} is #{encoding} according to XML"
end

ic = Iconv.new('UTF-8', encoding)
body = ic.iconv(body)

feed = RSS::Parser.parse(body, false)

for item in feed.items
  url = item.enclosure.url
  puts "Downloading url: #{url}"
  filename = url.split('/').last
  unless File.size?(filename)
    open(filename, 'wb') do |file|
      file << open(url).read
    end
  else
    puts "File #{filename} exists."
  end
end


