require "spec_helper"

describe Safetynet do
  class User
    include Safetynet
    attr_accessor :email

    safetynet :sms, {}, {sms: {limit: 1, timeframe: 5.minutes}}


    def initialize(attrs={})
      @email = attrs[:email]
    end

    def test_send_sms
      permit_delivery?(self)
    end
    def test_send_sms_1_second
      permit_delivery?(self, :sms, __method__, 1, 1.second)
    end
    def test_send_email
      permit_delivery?(self, :email)
    end
  end
  class DummyMailer < ActionMailer::Base
    include Safetynet
    safetynet :email, {except: [:test_send_email_uncaight]}, {email: {limit: 1, timeframe: 5.minutes}}

    def test_send_email(user)
      mail(to: user.email, from: user.email, subject: 'Dummy subject', body: 'Dummy email')
    end
    def test_send_email2(user, to)
      @user = user
      mail(to: to, from: user.email, subject: 'Dummy subject', body: 'Dummy email')
    end
    def test_send_mass_email(emails)
      mail(to: emails, from: "foo@example.com", subject: 'Dummy subject', body: 'Dummy email')
    end
    def test_send_email_uncaight(user)
      mail(to: user.email, from: user.email, subject: 'Dummy subject2', body: 'Dummy email2')
    end
  end


  let(:user) { User.new({email: 'test1@example.com'}) }
  let(:user2) { User.new({email: 'test2@example.com'}) }
  let(:admin_mailer) { double("AdminMailer") }


  describe 'after_action' do
    context 'On an ActionMailer with email safetynet' do
      it 'creates an after_action hook for watched methods' do
        expect_any_instance_of(DummyMailer).to receive(:check_safetynet_window).and_return(true)
        DummyMailer.test_send_email(user).deliver
      end
      it 'ignores unwatched methods' do
        expect_any_instance_of(DummyMailer).to receive(:check_safetynet_window).never
        DummyMailer.test_send_email_uncaight(user).deliver
      end
      it 'disallows watched methods outside the limit/threshold range' do
        mail1 = DummyMailer.test_send_email(user).deliver
        expect(mail1.perform_deliveries).to be(true)
        mail2 = DummyMailer.test_send_email(user).deliver
        expect(mail2.perform_deliveries).to be(false)
      end
      it 'sends an AdminMailer notification when limited' do
        DummyMailer.test_send_email(user).deliver
        expect(AdminMailer).to receive(:delivery_denied_notification)
          .and_return(double("Mailer", :deliver => true)).once
        DummyMailer.test_send_email(user).deliver
      end
      it 'treats methods independently' do
        mail1 = DummyMailer.test_send_email(user).deliver
        expect(mail1.perform_deliveries).to be(true)
        mail2 = DummyMailer.test_send_email(user).deliver
        expect(mail2.perform_deliveries).to be(false)

        mail3 = DummyMailer.test_send_email2(user, user.email)
        expect(mail3.perform_deliveries).to be(true)
        mail4 = DummyMailer.test_send_email2(user, user.email)
        expect(mail4.perform_deliveries).to be(false)
      end
      it 'treats communication channels independently' do
        mail1 = DummyMailer.test_send_email(user).deliver
        expect(mail1.perform_deliveries).to be(true)
        mail2 = DummyMailer.test_send_email(user).deliver
        expect(mail2.perform_deliveries).to be(false)

        expect(user.test_send_sms).to be(true)
        expect(user.test_send_sms).to be(false)
      end
      it 'always allows deliveries to example.com' do
        expect_any_instance_of(AdminMailer).to receive(:delivery_denied_notification).never
        mail = DummyMailer.test_send_email2(user, "test@example.com").deliver
        expect(mail.perform_deliveries).to be(true)
      end
      it 'disallows deliveries for employees with mismatched email and to address' do
        mail = DummyMailer.test_send_email2(employee.user, user.email)
        expect(mail.perform_deliveries).to be(false)
      end

      context 'multiple recipients' do
        it 'selectively removes email addresses from mass emails, and creates notices' do
          mail1 = DummyMailer.test_send_mass_email([user.email, "test@example.com"]).deliver
          expect(mail1.to).to eq([user.email, "test1@example.com"])
          expect(mail1.perform_deliveries).to be(true)
          expect_any_instance_of(AdminMailer).to receive(:delivery_denied_notification).once.with(user, :email, "test_send_mass_email",
            {limit: 1, timeframe: 300.seconds, message: "Safetynet has caught a method!"})
          mail2 = DummyMailer.test_send_mass_email([user.email, user2.email, "test@example.com"]).deliver
          expect(mail2.to).to eq([user2.email, "test@example.com"])
          expect(mail1.perform_deliveries).to be(true)
        end
        it 'permits all example.com emails' do
          mail1 = DummyMailer.test_send_mass_email(["test@example.com", "test1@example.com", "test2@example.com"]).deliver
          expect(mail1.to).to eq(["test@example.com", "test1@example.com", "test2@example.com"])
          expect(mail1.perform_deliveries).to be(true)
          expect_any_instance_of(AdminMailer).to receive(:delivery_denied_notification).never
        end
      end
    end
  end

  describe 'permit_delivery?' do
    context 'On a User model with sms safetynet' do
      it 'permits delivery with no previous communications' do
        expect(user.test_send_sms).to be(true)
      end
      it 'pays attention to timeframe and limit' do
        expect(user.test_send_sms_1_second).to be(true)
        expect(user.test_send_sms_1_second).to be(false)
        @future_time = Time.now + 2
        Time.stub(:now).and_return(@future_time)
        expect(user.test_send_sms_1_second).to be(true)
      end
      it 'creates a Safetynet::History record when permitted' do
        expect(Safetynet::History.where(address: user.email).count).to eq(0)
        expect(user.test_send_sms).to be(true)
        expect(Safetynet::History.where(address: user.email).count).to eq(1)
      end
      it 'limits the number of communications per channel for a timeframe' do
        expect(user.test_send_sms).to be(true)
        expect(user.test_send_sms).to be(false)
      end
      it 'does not create a Safetynet::History record when denied' do
        expect(Safetynet::History.where(address: user.email).count).to eq(0)
        expect(user.test_send_sms).to be(true)
        expect(Safetynet::History.where(address: user.email).count).to eq(1)
        expect(user.test_send_sms).to be(false)
        expect(Safetynet::History.where(address: user.email).count).to eq(1)
      end
      it 'sends an AdminMailer notification when limited' do
        user.test_send_sms
        expect(AdminMailer).to receive(:delivery_denied_notification)
          .and_return(double("Mailer", :deliver => true)).once
        user.test_send_sms
      end
      it 'watches communication channels independently' do
        expect(user.test_send_sms).to be(true)
        expect(user.test_send_sms).to be(false)
        expect(user.test_send_email).to be(true)
        expect(user.test_send_email).to be(false)
      end
      it 'watches users independently' do
        expect(user.test_send_sms).to be(true)
        expect(user.test_send_sms).to be(false)
        expect(user2.test_send_sms).to be(true)
        expect(user2.test_send_sms).to be(false)
      end
      it 'watches methods independently' do
        expect(user.test_send_sms).to be(true)
        expect(user.test_send_sms).to be(false)
        expect(user.test_send_sms_1_second).to be(true)
        expect(user.test_send_sms_1_second).to be(false)
      end
    end
  end
end
