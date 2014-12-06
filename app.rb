require 'sinatra'
require 'rss'
require 'open-uri'
require 'json'
require 'date'
require 'uri'

$morph_api_key = ENV['MORPH_API_KEY']
$api_url = "https://api.morph.io/hecticjeff/community-farm/data.json?key=#{URI.encode_www_form_component($morph_api_key)}&query=select%20*%20from%20%27data%27%20order%20by%20date%20desc%20limit%2010"
$url = 'http://www.thecommunityfarm.co.uk/boxes/box_display.php'

get '/' do
  response = JSON.parse(open($api_url).read)
  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.id = $url
    maker.channel.author = 'Community Farm'
    maker.channel.updated = Time.now.to_s
    # maker.channel.about = 'http://www.ruby-lang.org/en/feeds/news.rss'
    maker.channel.title = 'Community Farm - Veg No Potatoes'


    response.each do |week|
      puts(week)
      maker.items.new_item do |item|
        item.id = $url + '#' + week['date']
        item.link = $url
        item.title = 'Veg No Potatoes'
        item.content.content = week['contents'].gsub("\n", '<br>')
        item.updated = DateTime.parse(week['date']).iso8601
      end
    end
  end

  content_type 'application/xml'

  rss.to_s
end
