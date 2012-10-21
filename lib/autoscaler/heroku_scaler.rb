require 'heroku-api'

module Autoscaler
  class HerokuScaler
    def initialize(
        type = 'worker',
        key = ENV['HERKOU_API_KEY'],
        app = ENV['HEROKU_APP'])
      @client = Heroku::API.new(:api_key => key)
      @type = type
      @app = app
      @workers = 0
      @known = Time.now - 1
    end

    attr_reader :app
    attr_reader :type

    def workers
      if known?
        @workers
      else
        know client.get_ps(app).body.count {|ps| ps['process'].match /#{type}\.\d?/ }
      end
    end

    def workers=(n)
      if n != @workers || !known?
        p "Scaling #{type} to #{n}"
        client.post_ps_scale(app, type, n)
        know n
      end
    end

    private
    attr_reader :client

    def know(n)
      @known = Time.now + 5
      @workers = n
    end

    def known?
      Time.now < @known
    end
  end
end
