# Ruby wrapper for the Zookeeper C API

require 'thread'
require 'monitor'

# establish the namespace
module Zookeeper
end

require 'zookeeper/null_logger'
require 'zookeeper/acls'
require 'zookeeper/constants'
require 'zookeeper/exceptions'
require 'zookeeper/common'
require 'zookeeper/callbacks'
require 'zookeeper/stat'
require 'zookeeper/client_methods'
require 'logger'

# finally construct the client
require 'zookeeper/client'

module Zookeeper
  # this is for backwards compatibility
  include Constants

  unless defined?(@@logger)
    @@logger = NullLogger.new
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

