# The low-level wrapper-specific methods for the C lib
# subclassed by the top-level Zookeeper class
class ZookeeperBase < CZookeeper
  include ZookeeperCommon
  include ZookeeperCallbacks
  include ZookeeperConstants
  include ZookeeperExceptions
  include ZookeeperACLs
  include ZookeeperStat

  class DispatchShutdownException < StandardError; end

  ZKRB_GLOBAL_CB_REQ   = -1

  # debug levels
  ZOO_LOG_LEVEL_ERROR  = 1
  ZOO_LOG_LEVEL_WARN   = 2
  ZOO_LOG_LEVEL_INFO   = 3
  ZOO_LOG_LEVEL_DEBUG  = 4

  # @private
  KILL_TOKEN = Object.new unless defined?(KILL_TOKEN)

  # @private
  MAGIC_SHUTDOWN_NUMBER = 42

  def reopen(timeout = 10, watcher=nil)
    warn "WARN: ZookeeperBase#reopen watcher argument is now ignored" if watcher

    if watcher and (watcher != @default_watcher)
      raise "You cannot set the watcher to a different value this way anymore!"
    end
    
#     @default_watcher ||= watcher

    close

    @req_mutex.synchronize do
      # flushes all outstanding watcher reqs.
      @watcher_reqs.clear
      set_default_global_watcher
    end

    @start_stop_mutex.synchronize do
#       $stderr.puts "%s: calling init, self.obj_id: %x" % [self.class, object_id]
      init(@host)

      # XXX: replace this with a callback
      if timeout > 0
        time_to_stop = Time.now + timeout
        until state == Zookeeper::ZOO_CONNECTED_STATE
          break if Time.now > time_to_stop
          sleep 0.1
        end
      end
    end

    setup_event_delivery_thread!
    setup_dispatch_thread!
    state
  end

  def initialize(host, timeout = 10, watcher=nil)
    @watcher_reqs = {}
    @completion_reqs = {}
    @req_mutex = Monitor.new
    @current_req_id = 1
    
    # approximate the java behavior of raising java.lang.IllegalArgumentException if the host
    # argument ends with '/'
    raise ArgumentError, "Host argument #{host.inspect} may not end with /" if host.end_with?('/')

    @host = host

    # the event queue follows the same pattern as in the java implementation,
    # events from the backend are shunted into this queue first. get_next_event
    # only deals with this object, allowing for a separation between backend/C and
    # user-dispatch code
    @event_queue = nil

    @event_delivery_thread = nil

    @start_stop_mutex = Monitor.new

    @default_watcher = (watcher or get_default_global_watcher)

    # used by the C layer. CZookeeper sets this to true when the init method
    # has completed. we set this value to false to signal to the C code
    # (especially the event delivery loop) that we're ready for shutdown
    #
    # you should grab the @start_stop_mutex before messing with this flag
    @_running = nil

    # This is set to true after destroy_zkrb_instance has been called and all
    # CZookeeper state has been cleaned up
    @_closed = false  # also used by the C layer

    # the actual C data is stashed in this ivar. never *ever* touch this
    @_data = nil

    yield self if block_given?

    reopen(timeout)
  end
  
  # if either of these happen, the user will need to renegotiate a connection via reopen
  def assert_open
    raise ZookeeperException::SessionExpired if state == ZOO_EXPIRED_SESSION_STATE
    raise ZookeeperException::NotConnected   unless connected?
  end

  def connected?
    state == ZOO_CONNECTED_STATE
  end

  def connecting?
    state == ZOO_CONNECTING_STATE
  end

  def associating?
    state == ZOO_ASSOCIATING_STATE
  end

  def close
    stop_running!

    @start_stop_mutex.synchronize do
      if !@_closed and @_data
        close_handle
      end
    end

    stop_event_delivery_thread!
    stop_dispatch_thread!

    close_selectable_io!
    close_event_queue!
  end

  # the C lib doesn't strip the chroot path off of returned path values, which
  # is pretty damn annoying. this is used to clean things up.
  def create(*args)
    # since we don't care about the inputs, just glob args
    rc, new_path = super(*args)
    [rc, strip_chroot_from(new_path)]
  end

  def set_debug_level(int)
    warn "DEPRECATION WARNING: #{self.class.name}#set_debug_level, it has moved to the class level and will be removed in a future release"
    self.class.set_debug_level(int)
  end

  # set the watcher object/proc that will receive all global events (such as session/state events)
  def set_default_global_watcher
    warn "DEPRECATION WARNING: #{self.class}#set_default_global_watcher ignores block" if block_given?

    @req_mutex.synchronize do
#       @default_watcher = block # save this here for reopen() to use
      @watcher_reqs[ZKRB_GLOBAL_CB_REQ] = { :watcher => @default_watcher, :watcher_context => nil }
    end
  end

  def closed?
    @start_stop_mutex.synchronize { false|@_closed }
  end

  def running?
    @start_stop_mutex.synchronize { false|@_running }
  end

  def state
    return ZOO_CLOSED_STATE if closed?
    super
  end

  def session_id
    client_id.session_id
  end

  def session_passwd
    client_id.passwd
  end

  def get_next_event(blocking=true)
    return nil unless running?
    @event_queue.pop(!blocking).tap do |event|
      logger.debug { "get_next_event delivering event: #{event.inspect}" }
      raise DispatchShutdownException if event == KILL_TOKEN
    end
  rescue ThreadError
    nil
  end

protected
  # use this method to set the @_running flag to false
  def stop_running!
    @start_stop_mutex.synchronize do
      if @_running
        logger.debug { "#{self.class}##{__method__}" }
        @_running = false
      end
    end
  end

  def close_selectable_io!
    if @selectable_io
      logger.debug { "#{self.class}##{__method__}" }
    
      # this is set up in the C init method, but it's easier to 
      # do the teardown here, as this is our half of a pipe. The
      # write half is controlled by the C code and will be closed properly 
      # when close_handle is called
      begin
        @selectable_io.close
      rescue IOError
      end
    end
  end

  # this is a hack: to provide consistency between the C and Java drivers when
  # using a chrooted connection, we wrap the callback in a block that will
  # strip the chroot path from the returned path (important in an async create
  # sequential call). This is the only place where we can hook *just* the C
  # version. The non-async manipulation is handled in ZookeeperBase#create.
  # 
  def setup_completion(req_id, meth_name, call_opts)
    if (meth_name == :create) and cb = call_opts[:callback]
      call_opts[:callback] = lambda do |hash|
        # in this case the string will be the absolute zookeeper path (i.e.
        # with the chroot still prepended to the path). Here's where we strip it off
        hash[:string] = strip_chroot_from(hash[:string])

        # call the original callback
        cb.call(hash)
      end
    end

    # pass this along to the ZookeeperCommon implementation
    super(req_id, meth_name, call_opts)
  end

  # if we're chrooted, this method will strip the chroot prefix from +path+
  def strip_chroot_from(path)
    return path unless (chrooted? and path and path.start_with?(chroot_path))
    path[chroot_path.length..-1]
  end

  def barf_unless_running!
    @start_stop_mutex.synchronize do
      raise ShuttingDownException unless (@_running and not @_closed)
      yield
    end
  end

  # This thread shunts events off of the backend queue and puts them into a 
  # ruby queue. this allows for a simpler shutdown sequence
  def setup_event_delivery_thread!
    @event_queue ||= ZookeeperCommon::QueueWithPipe.new

    @event_delivery_thread ||= Thread.new do
      begin
        while true
          ev = get_next_event_from_backend(true) # always be blocking

          break if ev == MAGIC_SHUTDOWN_NUMBER

          @event_queue << ev
        end
      rescue Errno::EBADF
        logger.debug { "got Errno::EBADF from backend" }
      ensure
        logger.debug { "event_delivery_thread is exiting!" }
      end
    end
  end

  def stop_event_delivery_thread!
    if @event_delivery_thread
      logger.debug { "#{self.class}##{__method__}" }

      unless @_closed
        wake_event_loop! # this is a C method
      end
      @event_delivery_thread.join 
      @event_delivery_thread = nil
    end
  end

  def setup_dispatch_thread!
    @dispatcher ||= Thread.new do
      begin
        while running?
          begin                     # calling user code, so protect ourselves
            dispatch_next_callback
          rescue DispatchShutdownException 
            # we are shutting down
          rescue Exception => e
            $stderr.puts "Error in dispatch thread, #{e.class}: #{e.message}\n" << e.backtrace.map{|n| "\t#{n}"}.join("\n")
          end
        end
      ensure
        logger.debug { "dispatch thread exiting!" }
      end
    end
  end
  
  # this method is part of the reopen/close code, and is responsible for
  # shutting down the dispatch thread. 
  #
  # @dispatch will be nil when this method exits
  #
  def stop_dispatch_thread!
    # the event delivery thread should be down before running this
    stop_event_delivery_thread!

    if @dispatcher
      logger.debug { "#{self.class}##{__method__}" }

      @event_queue << KILL_TOKEN

      unless @dispatcher.join(3)
        warn "WARNING: Zookeeper dispatcher thread hung! continuing to prevent lockup, bad things may happen!"
      end

      @dispatcher = nil
    end
  end

  def close_event_queue!
    if @event_queue
      @event_queue.close
      @event_queue = nil
    end
  end


  # TODO: Make all global puts configurable
  def get_default_global_watcher
    Proc.new { |args|
      logger.debug { "Ruby ZK Global CB called type=#{event_by_value(args[:type])} state=#{state_by_value(args[:state])}" }
      true
    }
  end

  def chrooted?
    !chroot_path.empty?
  end

  def chroot_path
    if @chroot_path.nil?
      @chroot_path = 
        if idx = @host.index('/')
          @host.slice(idx, @host.length)
        else
          ''
        end
    end

    @chroot_path
  end

  # This method is the hook into the C code, and is responsible for setting up
  # all the state in the zkc library.
  # 
  def init(host)
    super
  end
end

