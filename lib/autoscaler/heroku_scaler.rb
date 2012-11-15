require 'heroku-api'

module Autoscaler
  # Wraps the Heroku API to provide just the interface that we need for scaling.
  class HerokuScaler
    # @param [String] type process type this scaler controls
    # @param [String] key Heroku API key
    # @param [String] app Heroku app name
    # @param [String] max_workers Heroku maximum workers
    def initialize( 
        type = Autoscaler::Configuration.type, 
        key = Autoscaler::Configuration.key, 
        app = Autoscaler::Configuration.app, 
        max_workers = Autoscaler::Configuration.max_workers)
      @type         = type
      @app          = app
      @max_workers  = max_workers
      @workers      = 0
      @known        = Time.now - 1
    end

    attr_reader :app
    attr_reader :type
    attr_reader :max_workers

    # Read the current worker count (value may be cached)
    # @return [Numeric] number of workers
    def workers
      if known?
        @workers
      else
        know client.get_ps(app).body.count {|ps| ps['process'].match /#{type}\.\d?/ }
      end
    end

    # Set the number of workers (noop if workers the same)
    # @param [Numeric] n number of workers
    def workers=(n)
      n = [n, @max_workers].min
      
      if n != @workers || !known?
        p "Scaling #{type} to #{n}"
        client.post_ps_scale(app, type, n)
        know n
      end
    end

    def client
      @client ||= Heroku::API.new(:api_key => @key)
    end

    private

    def know(n)
      @known = Time.now + 5
      @workers = n
    end

    def known?
      Time.now < @known
    end
  end
end
