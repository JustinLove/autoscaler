guard 'process', :name => 'redis', :command => 'redis-server spec/redis_test.conf' do
  watch('spec/redis_test.conf')
end

guard 'rspec',
    :version => 2,
    :cli => '--color --format d',
    :bundler => false,
    :spec_paths => ['spec'] do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+).rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
