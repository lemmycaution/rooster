require 'rubygems'
require 'clockwork'
require 'json'
require 'twitter'
require 'redis'

include Clockwork
include Twitter
include JSON

# load Config
config = YAML::load( File.open( 'config.yml' ) )

# init REDIS
uri = URI.parse(config['redis'])
redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

# Configure Twitter Credentials
Twitter.configure do |c|
  c.consumer_key = config['consumer_key']
  c.consumer_secret = config['consumer_secret']
  c.oauth_token = config['oauth_token']
  c.oauth_token_secret = config['oauth_token_secret']
end

# Initialize your Twitter client
client = Twitter::Client.new

handler do |job|
  # target tag
  tag = "gp"
  # target user
  user = "masterlistweet"
  # target feed
  list = "feed-list"
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
        # remove #gp and retweet it on target account
        puts client.update("#{t.text.gsub("#gp","")}")
      end
    end
    
  end

end

# do it every minute
every(25.seconds, 'job_name')