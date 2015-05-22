class TestMailer < ActionMailer::Base
  default from: "from@example.com"

  def test_email
    mail(to: "to@example.com", subject: "test email")
  end
end
