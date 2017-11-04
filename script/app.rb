require 'net/http'
require 'uri'

require 'sinatra'
require 'sidekiq'
require 'json'

################################################################
# Web API

set :environment, :production
set :logging, false

post '/job/:category' do
  request.body.rewind
  job = JSON.parse(request.body.read)
  run_after = job['run_after'] || 0

  # Ignore handling these options since it is not easy to make them
  # take effect in Sidekiq jobs:
  # - retry_delay
  # - max_retries

  Fireworq::Launcher.perform_in(run_after, job)
  job.to_json
end

################################################################
# Worker

module Fireworq
  class Launcher
    include Sidekiq::Worker
    sidekiq_options queue: ENV['QUEUE_NAME']

    def perform(job)
      url = URI.parse(job['url'])
      req = Net::HTTP::Post.new(url.path)
      req['content-type'] = 'application/json'
      req.body = job['payload'].to_json
      Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      # Ignore the response (especially an error response); it is not
      # easy to control retry timing in Sidekiq.
    end
  end
end
