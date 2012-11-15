require 'singleton'
module Autoscaler

  ##
  # Provides convenient access to the Configuration singleton.
  #
  def self.configure(&block)
    if block_given?
      block.call(Configuration.instance)
    else
      Configuration.instance
    end
  end

  ##
  # This class handles the configuration
  # Configuration can be done in two ways:
  #
  # 1) Using Autoscaler.configure and passing a block
  #    (useful for configuring multiple things at once):
  #
  #   Autoscaler.configure do |config|
  #     config.type      = ...
  #     config.key        = ...
  #     config.app        = ...
  #   end
  #
  # 2) Using the Autoscaler::Configuration singleton directly:
  #
  #   Autoscaler::Configuration.type = ...
  #
  # Default values are defined in Configuration#set_defaults.
  #

  class Configuration
    include Singleton

    OPTIONS = [
      :type,
      :key,
      :app,
      :max_workers
    ]

    attr_accessor *OPTIONS

    def initialize # :nodoc
      set_defaults
    end

    def set_defaults
      @type        = 'worker'                   # the default queue type
      @key          = ENV['HEROKU_API_KEY']     # key of heroku's api
      @app          = ENV['HEROKU_APP']         # name of the app on heroku
      @max_workers  = 1                         # Maximum number of workers
    end

    instance_eval(OPTIONS.map do |option|
      o = option.to_s
      <<-EOS
      def #{o}
        instance.#{o}
      end

      def #{o}=(value)
        instance.#{o} = value
      end
      EOS
    end.join("\n\n"))

    class << self
      def set_defaults
        instance.set_defaults
      end
    end

  end
end