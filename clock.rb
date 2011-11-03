require 'rubygems'
require 'clockwork'
include Clockwork

handler do |job|
  # do something
end

every(1.day, 'job_name')
