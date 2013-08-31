require 'heroku-api'

module Autoscaler
  # Wraps the Heroku API to provide just the interface that we need for scaling.
  class HerokuScaler
    # @param [String] type process type this scaler controls
    # @param [String] key Heroku API key
    # @param [String] app Heroku app name
    def initialize(
        type = 'worker',
        key = ENV['HEROKU_API_KEY'],
        app = ENV['HEROKU_APP'])
      @client = Heroku::API.new(:api_key => key)
      @type = type
      @app = app
      @workers = 0
      @known = Time.now - 1
    end

    attr_reader :app
    attr_reader :type

    # Read the current worker count (value may be cached)
    # @return [Numeric] number of workers
    def workers
      if known?
        @workers
      else
        know heroku_get_workers
      end
    end

    # Set the number of workers (noop if workers the same)
    # @param [Numeric] n number of workers
    def workers=(n)
      if n != @workers || !known?
        p "Scaling #{type} to #{n}"
        heroku_set_workers(n)
        know n
      end
    end

    # Callable object which responds to exceptions during api calls
    #
    # @example
    #   heroku.exception_handler = lambda {|exception| MyApp.logger.error(exception)}
    #   heroku.exception_handler = lambda {|exception| raise}
    #   # default
    #   lambda {|exception|
    #     p exception
    #     puts exception.backtrace
    #   }
    attr_writer :exception_handler

    private
    attr_reader :client

    def know(n)
      @known = Time.now + 5
      @workers = n
    end

    def known?
      Time.now < @known
    end

    def heroku_get_workers
      client.get_ps(app).body.count {|ps| ps['process'].match /#{type}\.\d?/ }
    rescue Excon::Errors::Error => e
      exception_handler.call(e)
      @workers
    end

    def heroku_set_workers(n)
      client.post_ps_scale(app, type, n)
    rescue Excon::Errors::Error => e
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
