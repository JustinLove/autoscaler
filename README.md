# Sidekiq Heroku Autoscaler

[Sidekiq](https://github.com/mperham/sidekiq) performs background jobs.  While it's threading model allows it to scale easier than worker-pre-process background systems, people running test or lightly loaded systems on [Heroku](http://www.heroku.com/) still want to scale down to zero to avoid racking up charges.

## Requirements

Tested on Ruby 1.9.2 and Heroku Cedar stack.

## Installation

    gem install sidekiq

## Getting Started

This gem uses the [Herkou-Api](https://github.com/heroku/heroku.rb) gem, which requires an API key from Heroku.  It will also need the heroku app name.  By default, these are specified through environment variables.  You can also pass them to HerkouScaler explicitly.

    HEROKU_API_KEY=.....
    HEROKU_APP=....

Install the middleware in your `Sidekiq.configure_` blocks

    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.add Autoscaler::Sidekiq::Client, 'default' => Autoscaler::HerokuScaler.new
      end
    end

    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add(Autoscaler::Sidekiq::Server, Autoscaler::HerokuScaler.new, 60)
      end
    end

## Limits and Challenges

- HerokuScaler includes an attempt at current-worker cache that may be overcomplication, and doesn't work very well (see next)
- Multiple threads often send scaling requests at once.  Heroku seems to handle this well.
- Workers sleep-loop and are not actually returned to the pool; when a job or timeout happen, they can all release at once.

### Long Jobs

Since the shutdown check gets performed every time a job completes, the timeout will need to be longer than the longest job.  For mixed workloads, you might want to have multiple sidekiq processes defined.  I use one with many workers for general work, and a single-worker process for long import jobs.  See `examples/complex.rb`

## Tests

The project is setup to run RSpec with Guard.

The HerokuScaler is not tested by default because it makes live API requests.  Specify `HEROKU_APP` and `HEROKU_API_KEY` on the command line, and then watch your app's logs.

    HEROKU_APP=... HEROKU_API_KEY=... guard
    heroku logs --app ...

## Authors

Justin Love, [@wondible](http://twitter.com/wondible), [https://github.com/JustinLove](https://github.com/JustinLove)

Ported to Heroku-Api by Fix Peña, [https://github.com/fixr](https://github.com/fixr)

## Licence

Released under the [MIT license](http://www.opensource.org/licenses/mit-license.php).
