# Ruby wrapper for the Zookeeper C API

require 'thread'
require 'monitor'

# establish the namespace
module Zookeeper
end

require 'zookeeper/acls'
require 'zookeeper/constants'
require 'zookeeper/exceptions'
require 'zookeeper/common'
require 'zookeeper/callbacks'
require 'zookeeper/stat'
require 'zookeeper/client_methods'
require 'logger'

# figure out what platform driver we're wrapping

if defined?(::JRUBY_VERSION)
  $LOAD_PATH.unshift(File.expand_path('../java', File.dirname(__FILE__))).uniq!
else
  raise "Only working for jruby right now, kthxbai!"

  $LOAD_PATH.unshift(File.expand_path('../ext', File.dirname(__FILE__))).uniq!
  require 'zookeeper_c'
end

require 'zookeeper_base'

# finally construct the client
require 'zookeeper/client'

module Zookeeper
  # this is for backwards compatibility
  include Constants

  unless defined?(@@logger)
    @@logger = Logger.new('/dev/null').tap { |l| l.level = Logger::FATAL } # UNIX: FOR GREAT JUSTICE !!
  end

  def self.logger
    @@logger
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.new(*args)
    Zookeeper::Client.new(*args)
  end
end

