desc "Run govuk-lint with similar params to CI"
task "lint" do
  sh "rubocop --format clang Gemfile bin config email_alert_service lib spec"
end
