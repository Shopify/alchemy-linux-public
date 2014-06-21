#!/usr/bin/env ruby

require 'httparty'
require 'yaml'
require 'yaml'
require 'uri'

$config = YAML::load( File.open( 'private.yml' ) )
$creds = $config['tinycc']


def minify( post_url, slug )
  post_uri = URI.escape(post_url)
  url = "http://tiny.cc/?c=rest_api&m=shorten&version=2.0.3&format=json&shortUrl=#{slug}&longUrl=#{post_uri}&login=#{$creds['user']}&apiKey=#{$creds['key']}"
  response = HTTParty.get(url)
  mini =  JSON.parse(response.body)['results']['short_url']
  return mini
end


def publish( slug, path )
  rest_component = path.gsub("_posts/","").gsub(".markdown","").gsub("/","").split("-")[3..-1].join("-")
  post_url = "http://blog.srvthe.net/#{rest_component}/"
  mini_url = minify(post_url,slug)

  puts `t update "Check out my new blog post! #{mini_url}"`
  puts `fbcmd status "Check out my new blog post! #{post_url}"`

  puts "Post published!"
end


def new(title, type)

  dateshort = Time.now().strftime("%Y-%m-%d")
  datelong  = Time.now().strftime("%Y-%m-%d %H-%M-%S")

  fname = "#{dateshort}-#{title.downcase.split(' ').join('-')}.markdown"
  header_data = {
    "title"     => title,
    "modified"  => datelong,
    "layout"    => type,
    "tags"      => [],
    "permalink" => "index.html",
    "comments"  => true
  }

  header = YAML.dump(header_data)
  header = "#{header}---"

  outname = "_posts/"+fname
  outfile = File.open(outname,"w")
  outfile.write(header)
  outfile.close
  
  puts "Post file created at #{outname}"

end


command = ARGV[0]

if command == 'new'
  type    = ARGV[1]
  title   = ARGV[2]

  new(title, type)
elsif command == 'publish'
  slug    = ARGV[1]
  path    = ARGV[2]

  publish(slug, path)
end
