# Sidekiq Heroku Autoscaler

[Sidekiq](https://github.com/mperham/sidekiq) performs background jobs.  While its threading model allows it to scale easier than worker-pre-process background systems, people running test or lightly loaded systems on [Heroku](http://www.heroku.com/) still want to scale down to zero to avoid racking up charges.

## Requirements

Tested on Ruby 2.1.7 and Heroku Cedar stack.

## Installation

    gem install autoscaler

## Getting Started

This gem uses the [Heroku Platform-Api](https://github.com/heroku/platform-api) gem, which requires an OAuth token from Heroku.  It will also need the heroku app name.  By default, these are specified through environment variables.  You can also pass them to `HerokuPlatformScaler` explicitly.

    AUTOSCALER_HEROKU_ACCESS_TOKEN=.....
    AUTOSCALER_HEROKU_APP=....

Install the middleware in your `Sidekiq.configure_` blocks

    require 'autoscaler/sidekiq'
    require 'autoscaler/heroku_platform_scaler'

    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.add Autoscaler::Sidekiq::Client, 'default' => Autoscaler::HerokuPlatformScaler.new
      end
    end

    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add(Autoscaler::Sidekiq::Server, Autoscaler::HerokuPlatformScaler.new, 60) # 60 second timeout
      end
    end

## Limits and Challenges

- HerokuPlatformScaler includes an attempt at current-worker cache that may be overcomplication, and doesn't work very well on the server
- Multiple scale-down loops may be started, particularly if there are multiple jobs queued when the servers comes up.  Heroku seems to handle multiple scale-down commands well.
- The scale-down monitor is triggered on job completion (and server middleware is only run around jobs), so if the server never processes any jobs, it won't turn off.
- The retry and schedule lists are considered - if you schedule a long-running task, the process will not scale-down.
- If background jobs trigger jobs in other scaled processes, please note you'll need `config.client_middleware` in your `Sidekiq.configure_server` block in order to scale-up.
- Exceptions while calling the Heroku API are caught and printed by default.  See `HerokuPlatformScaler#exception_handler` to override

## Experimental

### Strategies

You can pass a scaling strategy object instead of the timeout to the server middleware.  The object (or lambda) should respond to `#call(system, idle_time)` and return the desired number of workers.  See `lib/autoscaler/binary_scaling_strategy.rb` for an example.

### Initial Workers

`Client#set_initial_workers` to start workers on main process startup; typically:

    Autoscaler::Sidekiq::Client.add_to_chain(chain, 'default' => heroku).set_initial_workers

### Working caching

    scaler.counter_cache = Autoscaler::CounterCacheRedis.new(Sidekiq.method(:redis))

## Tests

The project is setup to run RSpec with Guard.  It expects a redis instance on a custom port, which is started by the Guardfile.

The HerokuPlatformScaler is not tested by default because it makes live API requests.  Specify `AUTOSCALER_HEROKU_APP` and `AUTOSCALER_HEROKU_ACCESS_TOKEN` on the command line, and then watch your app's logs.

    AUTOSCALER_HEROKU_APP=... AUTOSCALER_HEROKU_ACCESS_TOKEN=... guard
    heroku logs --app ...

## Authors

Justin Love, [@wondible](http://twitter.com/wondible), [https://github.com/JustinLove](https://github.com/JustinLove)

### Contributors

- Benjamin Kudria [https://github.com/bkudria](https://github.com/bkudria)
- claudiofullscreen [https://github.com/claudiofullscreen](https://github.com/claudiofullscreen)
- Fix Peña [https://github.com/fixr](https://github.com/fixr)
- Gabriel Givigier Guimarães [https://github.com/givigier](https://github.com/givigier)
- Matt Anderson [https://github.com/tonkapark](https://github.com/tonkapark)
- Thibaud Guillaume-Gentil [https://github.com/jilion](https://github.com/jilion)

## Licence

Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).
