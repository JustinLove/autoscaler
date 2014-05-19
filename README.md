# Sidekiq Heroku Autoscaler

[Sidekiq](https://github.com/mperham/sidekiq) performs background jobs.  While it's threading model allows it to scale easier than worker-pre-process background systems, people running test or lightly loaded systems on [Heroku](http://www.heroku.com/) still want to scale down to zero to avoid racking up charges.

## Requirements

Tested on Ruby 1.9.2 and Heroku Cedar stack.

## Installation

    gem install autoscaler

## Getting Started

This gem uses the [Heroku-Api](https://github.com/heroku/heroku.rb) gem, which requires an API key from Heroku.  It will also need the heroku app name.  By default, these are specified through environment variables.  You can also pass them to HerokuScaler explicitly.

    HEROKU_API_KEY=.....
    HEROKU_APP=....

Install the middleware in your `Sidekiq.configure_` blocks

    require 'autoscaler/sidekiq'
    require 'autoscaler/heroku_scaler'

    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.add Autoscaler::Sidekiq::Client, 'default' => Autoscaler::HerokuScaler.new
      end
    end

    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add(Autoscaler::Sidekiq::Server, Autoscaler::HerokuScaler.new, 60) # 60 second timeout
      end
    end

## Limits and Challenges

- HerokuScaler includes an attempt at current-worker cache that may be overcomplication, and doesn't work very well on the server
- Multiple scale-down loops may be started, particularly if there are multiple jobs queued when the servers comes up.  Heroku seems to handle multiple scale-down commands well.
- The scale-down monitor is triggered on job completion (and server middleware is only run around jobs), so if the server nevers processes any jobs, it won't turn off.
- The retry and schedule lists are considered - if you schedule a long-running task, the process will not scale-down.
- If background jobs trigger jobs in other scaled processes, please note you'll need `config.client_middleware` in your `Sidekiq.configure_server` block in order to scale-up.
- Exceptions while calling the Heroku API are caught and printed by default.  See `HerokuScaler#exception_handler` to override

## Experimental

### Strategies

You can pass a scaling strategy object instead of the timeout to the server middleware.  The object (or lambda) should respond to `#call(system, idle_time)` and return the desired number of workers.  See `lib/autoscaler/binary_scaling_strategy.rb` for an example.

### Initial Workers

`Client#set_initial_workers` to start workers on main process startup; typically:

    Autoscaler::Sidekiq::Client.add_to_chain(chain, 'default' => heroku).set_initial_workers

### Working caching

    scaler.counter_cache = Autoscaler::CounterCacheRedis(Sidekiq.method(:redis))

## Tests

The project is setup to run RSpec with Guard.  It expects a redis instance on a custom port, which is started by the Guardfile.

The HerokuScaler is not tested by default because it makes live API requests.  Specify `HEROKU_APP` and `HEROKU_API_KEY` on the command line, and then watch your app's logs.

    HEROKU_APP=... HEROKU_API_KEY=... guard
    heroku logs --app ...

## Authors

Justin Love, [@wondible](http://twitter.com/wondible), [https://github.com/JustinLove](https://github.com/JustinLove)

Ported to Heroku-Api by Fix Peña, [https://github.com/fixr](https://github.com/fixr)

Retry/schedule sets by Matt Anderson [https://github.com/tonkapark](https://github.com/tonkapark) and Thibaud Guillaume-Gentil [https://github.com/jilion](https://github.com/jilion)

## Licence

Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).
