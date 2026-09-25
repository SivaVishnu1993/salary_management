# Wrap every example so an N+1 (or unused eager load) raises in the offending spec.
RSpec.configure do |config|
  config.before do
    Bullet.start_request
  end

  config.after do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end
