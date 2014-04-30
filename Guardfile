guard 'process', :name => 'redis', :command => 'redis-server spec/redis_test.conf' do
  watch('spec/redis_test.conf')
end

tag     = "--tag #{ENV['TAG']}"           if ENV['TAG']
example = "--example '#{ENV['EXAMPLE']}'" if ENV['EXAMPLE']
%w(sidekiq-2 sidekiq-3).each do |appraisal|
  guard :rspec, :cmd => "appraisal #{appraisal} rspec --color --format d #{tag} #{example}" do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+).rb$}) { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { "spec" }
  end
end

