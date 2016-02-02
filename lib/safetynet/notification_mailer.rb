module Safetynet
  class NotificationMailer < ActionMailer::Base
    default from: "test@asdf.org"

    def delivery_denied_notification(address, channel, method, properties)
      mail_to = Rails.configuration.safetynet[:notification_email] || "asdf@asdf.org"
      mail(from: mail_to, to: mail_to, subject: "test", body: "test")
    end
  end
end