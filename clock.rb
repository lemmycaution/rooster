require 'rubygems'
require 'clockwork'
require 'json'
require 'twitter'

include Clockwork
include Twitter
include JSON

# load Twitter Credentials
cred = YAML::load( File.open( 'cred.yml' ) )

# Configure Twitter Credentials
Twitter.configure do |config|
  config.consumer_key = cred['consumer_key']
  config.consumer_secret = cred['consumer_secret']
  config.oauth_token = cred['oauth_token']
  config.oauth_token_secret = cred['oauth_token_secret']
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
  opts = opts.merge({:since_id => @since_id}) if @since_id
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
        @since_id = t.id if i==0
        # increment counter! important
        i+=1
        # retweet it on target account
        puts client.update("#{t.text}")
      end
    end
    
  end

end

# do it every minute
every(25.seconds, 'job_name')