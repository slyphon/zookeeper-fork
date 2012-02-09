# figure out what platform driver we're wrapping

if defined?(::JRUBY_VERSION)
  $LOAD_PATH.unshift(File.expand_path('../../../java', __FILE__)).uniq!
else
  $LOAD_PATH.unshift(File.expand_path('../../../ext', __FILE__)).uniq!
end

require 'zookeeper_base'

module Zookeeper
  if defined?(::JRUBY_VERSION)
    class Client < Zookeeper::JavaBase
    end
  else
    class Client < Zookeeper::ZookeeperBase
    end
  end
end

Zookeeper::Client.class_eval do
  include Zookeeper::ClientMethods
end

