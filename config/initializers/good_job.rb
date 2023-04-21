# config/initializers/good_job.rb
GoodJob::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare("admin", username) &&
    ActiveSupport::SecurityUtils.secure_compare(ENV.fetch("GOOD_JOB_ADMIN_PASSWORD"), password)
end
