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
  Fireworq::Launcher.perform_async(job)
  job.to_json
end

################################################################
# Worker

module Fireworq
  class Launcher
    include Sidekiq::Worker

    def perform(job)
      url = URI.parse(job['url'])
      req = Net::HTTP::Post.new(url.path)
      req['content-type'] = 'application/json'
      req.body = job['payload'].to_json
      Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    end
  end
end
