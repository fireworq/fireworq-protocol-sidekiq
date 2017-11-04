#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

ROOT = File.expand_path(File.join(File.dirname($0), '..'))
ENV_FILE = File.join(ROOT, 'tmp', '.env')
Dir.chdir(ROOT)

opts = {
  :web_port          => 8080,
  :web_max_workers   => 10,
  :queue_max_workers => 5,
  :queue_name        => 'fireworq',
}

opt = OptionParser.new
opt.on('--web-port <port>') {|v| opts[:web_port] = v.to_i }
opt.on('--web-max-workers <num>') {|v| opts[:web_max_workers] = v.to_i }
opt.on('--queue-max-workers <num>') {|v| opts[:queue_max_workers] = v.to_i }
opt.on('--queue-name <name>') {|v| opts[:queue_name] = v }
opt.parse!(ARGV)

FileUtils.mkdir_p(File.dirname(ENV_FILE))
File.open(ENV_FILE, 'w') do |f|
  f.puts <<"EOF"
ROOT=#{ROOT}
RUBYLIB=.:#{ENV['RUBYLIB']}
WEB_PORT=#{opts[:web_port]}
WEB_MAX_WORKERS=#{opts[:web_max_workers]}
QUEUE_MAX_WORKERS=#{opts[:queue_max_workers]}
QUEUE_NAME=#{opts[:queue_name]}
EOF
end

cmd = 'bundle'
args = %w(exec foreman start -e)
args << ENV_FILE
exec cmd, *args
