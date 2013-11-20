# Changelog

## 0.6.1

- EntireQueuSystem#queued always returns an integer

## 0.6.0

- Excon errors from the Heroku API are caught be default.  See `HerokuScaler#exception_handler` to override behavior
- Client side scaling occurs after enquing the job, previously it was before.

## 0.5.0

- Experimental: `Client#set_initial_workers` to start workers on main process startup; typically:
    Autoscaler::Sidekiq::Client.add_to_chain(chain, 'default' => heroku).set_initial_workers
- Ensure that timeout is documented as being in seconds
- Convert gemspec to wildcard file selection

## 0.4.1

- Missing file from gemspec

## 0.4.0

- Experimental: The default scaling logic is contained in BinaryScalingStrategy.  A strategy object can be passed instead of timeout to the server middleware.

## 0.3.0

- Downscale method changed from busy-waiting workers to a separate monitor process
- Minimum Sidekiq version raised to 2.7 to take advantage of Worker API
- Internal refactoring
- Autoscaler::StubScaler may be used for local testing

## 0.2.1

- Separate background activity flags to avoid crosstalk between processes

## 0.2.0

- Raise minimum Sidekiq version to 2.6.1 to take advantage of Stats API
- Inspect scheduled and retry sets to see if they match `specified_queues`
- Testing: Refactor server middleware tests

## 0.1.0

- The `retry` and `scheduled` queues are now considered for shutdown
- Testing: Guard starts up an isolated redis instance

## 0.0.3

- Typo correction

## 0.0.2

- Loosen Sidekiq version dependency
- Add changelog
- Add changelog, readme, and examples to gem files list
