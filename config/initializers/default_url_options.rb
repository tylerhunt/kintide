# Links generated outside a request (SMS messages, jobs) use the same
# host as mailer links.
Rails.application.config.after_initialize do
  Rails.application.routes.default_url_options =
    Rails.application.config.action_mailer.default_url_options
end
