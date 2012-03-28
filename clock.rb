require 'rubygems'
require 'clockwork'
require 'json'
require 'twitter'
require 'redis'

include Clockwork
include Twitter
include JSON

# init REDIS
uri = URI.parse(ENV['REDISTOGO_URL'])
redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

# Configure Twitter Credentials
Twitter.configure do |c|
  c.consumer_key = ENV['CONSUMER_KEY']
  c.consumer_secret = ENV['CONSUMER_SECRET']
  c.oauth_token = ENV['OAUTH_TOKEN']
  c.oauth_token_secret = ENV['OAUTH_TOKEN_SECRET']
end

# Initialize your Twitter client
client = Twitter::Client.new

handler do |job|
  # target tag
  tag = ENV["TAG"]
  # target user
  user = ENV['USER']
  # target feed
  list = ENV['LIST']
  # include entities to checking hashtags
  opts = {:include_entities => true}
  # add since after first fetch to avoid duplicate posting
  since_id = redis.get('since_id')
  opts = opts.merge({:since_id => since_id}) if since_id
  # gel list tweets
  list = Twitter.list_timeline(user,list,opts)
  # integer to store tweet order num
  i = 0
  
  # loop in tweets
  list.each do |t|

    # dive if it has hashtags
    unless t.attrs["entities"].empty? && t.attrs["entities"]["hashtags"].empty?
      
      # collect tweets with target hastag
      t.attrs["entities"]["hashtags"].keep_if{|ht| ht["text"]==tag}.each do |gt|
        # save since id
        redis.set('since_id',t.id) if i==0
        # increment counter! important
        i+=1
        # remove tag and retweet it on target account
        client.update(t.text.gsub("##{tag}",""))
        # puts t.text.gsub("##{tag}","")
      end
    end
    
  end

end

# do it every 25 seconds
every(25.seconds, 'clone_tweets')