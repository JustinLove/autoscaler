require 'platform-api'
require 'autoscaler/counter_cache_memory'

module Autoscaler
  # Wraps the Heroku Platform API to provide just the interface that we need for scaling.
  class HerokuPlatformScaler
    # @param [String] type process type this scaler controls
    # @param [String] token Heroku OAuth access token
    # @param [String] app Heroku app name
    def initialize(
        type: 'worker',
        token: ENV['AUTOSCALER_HEROKU_ACCESS_TOKEN'],
        app: ENV['AUTOSCALER_HEROKU_APP'])

      @client = PlatformAPI.connect_oauth(token)
      @type = type
      @app = app
      @workers = CounterCacheMemory.new
    end

    attr_reader :app
    attr_reader :type

    # Read the current worker count (value may be cached)
    # @return [Numeric] number of workers
    def workers
      @workers.counter {@workers.counter = heroku_get_workers}
    end

    # Set the number of workers (noop if workers the same)
    # @param [Numeric] n number of workers
    def workers=(n)
      unknown = false
      current = @workers.counter{unknown = true; 1}
      if n != current || unknown
        p "Scaling #{type} to #{n}"
        heroku_set_workers(n)
        @workers.counter = n
      end
    end

    # Callable object which responds to exceptions during api calls #
    # @example
    #   heroku.exception_handler = lambda {|exception| MyApp.logger.error(exception)}
    #   heroku.exception_handler = lambda {|exception| raise}
    #   # default
    #   lambda {|exception|
    #     p exception
    #     puts exception.backtrace
    #   }
    attr_writer :exception_handler

    # Object which supports #counter and #counter=
    # Defaults to CounterCacheMemory
    def counter_cache=(cache)
      @workers = cache
    end

    private
    attr_reader :client

    def heroku_get_workers
      client.formation.list(app)
        .select {|item| item['type'] == type}
        .map {|item| item['quantity']}
        .reduce(0, &:+)
    rescue Excon::Errors::Error => e
      exception_handler.call(e)
      0
    end

    def heroku_set_workers(n)
      client.formation.update(app, type, {:quantity => n})
    rescue Excon::Errors::Error, Heroku::API::Errors::Error => e
      exception_handler.call(e)
    end

    def exception_handler
      @exception_handler ||= lambda {|exception|
        p exception
        puts exception.backtrace
      }
    end
  end
end
