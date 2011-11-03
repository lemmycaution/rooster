require 'rubygems'
require 'clockwork'
require 'json'
require 'twitter'
include Clockwork
include Twitter
include JSON

Twitter.configure do |config|
  config.consumer_key = "3Ltc5g9E4UEmN3lAJj4iQ"
  config.consumer_secret = "E7sO3zsr3Tnkofv7IEDWgAmREwNPidkXZwbyjqVP4"
  config.oauth_token = "404387470-mpNAB6TM91ggskMrWDek0fKK3KWFYBqrEdDCX9Ok"
  config.oauth_token_secret = "Jn4hBDsDgI1cX5Tmx8nuhY4k60xPFbAXzZl2wLpis"
end

# Initialize your Twitter client
client = Twitter::Client.new

handler do |job|
  
  tag = "gp"
  user = "masterlistweet"
  list = "feed-list"
  
  opts = {:include_entities => true}
  opts = opts.merge({:since_id => @since_id}) if @since_id
  puts "opts:#{opts.inspect}"
  list = Twitter.list_timeline(user,list,opts)
  i = 0
  list.each do |t|
    unless t.entities.hashtags.empty?
      t.entities.hashtags.find_all{|ht| ht.text==tag}.each do |gt|
        @since_id = t.id if i==0
        i+=1

        puts client.update("#{t.text} @#{t.user.screen_name}")
      end
    end
  end

end

every(1.minute, 'job_name')