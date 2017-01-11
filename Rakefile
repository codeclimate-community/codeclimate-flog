# -*- ruby -*-

require "hoe"

Hoe.plugin :minitest

Hoe.spec "blah" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  license "MIT"
end

task :test => %w[image run]

IMAGE_NAME = "codeclimate/codeclimate-flog"

## TODO: I haven't figured out testing in docker yet...

# task "test:local" => :test

# task "test:remote" do
#   sh %(docker run --rm #{IMAGE_NAME} sh -c "cd /usr/src/app && rake test:local")
# end

task :image do
  sh "docker build --rm -t #{IMAGE_NAME} ."
end

ENV["CODECLIMATE_DEBUG"] = "1"

task :run do
  sh "codeclimate analyze --dev"
end

task :purge do
  sh "docker ps -a  | awk '!/gc-config/ && /Exited/ { print $1 }' | xargs docker rm"
  sh "docker images | grep none.*none | awk '{print $3}' | xargs docker rmi"
end

# vim: syntax=ruby
