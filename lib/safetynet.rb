require 'active_support/concern'
require 'active_support/core_ext/numeric/time'
require 'safetynet/history'
require 'safetynet/notification_mailer'

module Safetynet
  extend ActiveSupport::Concern

  # Saves a record for the current method
  def save_safetynet_delivery(address, channel, method)
    Safetynet::History.create({
      address: address,
      method: method,
      channel: channel.to_s,
      created_at: Time.now
    })
  end

  # Returns true if delivery is permitted through the given channel
  #   user        A model to monitor
  #   channel     email|sms (symbol)
  #   method      Name of watched method
  #   limit       Maximum # of methods for this channel
  #   timeframe   Minimum allowed timeframe between last method and next (default: 30.minutes)
  # 
  # Standalone usage on a User model
  #   * Defaults to configured channel, caller method,
  #   * and rails configuration limit & timeframe for the channel
  #
  #   class User < ActiveRecord::Base
  #     include Safetynet
  #     safetynet :sms
  #
  #     def send_sms
  #       if permit_delivery?(self)
  #         ...
  #       end
  #     end
  #   end
  def permit_delivery?(address, channel=nil, method=nil, limit=nil, timeframe=nil)
    # Skip check if address is whitelisted
    return true if is_whitelisted?(address)

    options = self.class.safetynet_options
    # Set defaults from current config and call stack
    channel = self.class.safetynet_channel if channel.nil?
    method = caller_locations(1, 1)[0].label if method.nil?
    limit = options[channel][:limit] if limit.nil?
    timeframe = options[channel][:timeframe] if timeframe.nil?

    # Query the model to determine if delivery is permitted
    permit_delivery = true
    if limit != false
      count_query = Safetynet::History.where({
        address: address,
        channel: channel,
        method: method
      })

      if timeframe != false
        count_query = count_query.where('created_at >= ?', Time.now - timeframe)
      end

      # If our sending is over the limit, deny
      if count_query.count >= limit
        permit_delivery = false
      end
    end

    if permit_delivery
      save_safetynet_delivery(address, channel, method)
    else
      Safetynet::NotificationMailer.delivery_denied_notification(address, channel, method, {
        limit: limit,
        timeframe: timeframe,
        message: 'Safetynet has caught a method!'
      }).deliver
    end

    permit_delivery
  end

  # Hook added to after_filter to disable current action or mail delivery
  def check_safetynet_window
    # Skip check if email is already stopped
    return false if mail.perform_deliveries == false

    channel = self.class.safetynet_channel
    options = self.class.safetynet_options
    method = action_name
    limit = options[channel][:limit]
    timeframe = options[channel][:timeframe]

    # Update the mail.to array with those who are whitelisted and permitted
    mail.to = mail.to.keep_if do |email|
      next true if is_whitelisted?(email)
      permit_delivery?(email, channel, method, limit, timeframe)
    end

    permit_delivery = mail.to.any?

    if channel == :email
      mail.perform_deliveries = permit_delivery
    end
    permit_delivery
  end

  # Permits all whitelisted addresses by regex
  def is_whitelisted?(address)
    !!(self.class.safetynet_options[:whitelist].match(address))
  end

  module ClassMethods
    # safetynet
    #   channel                     email|sms (symbol)
    #   filters                     Hash of method names to watch (email only) that fits after_action requirements
    #   options = {
    #     email: {                  Hash for each channel (matches to field on User model) and includes:
    #       limit: 1,               Maximum # of methods for this channel (default: 1)
    #       timeframe: 30.minutes   Minimum allowed timeframe between last method and next (default: 30.minutes)
    #     }
    #   }
    #   Options merges Rails.configuration.safetynet before any class-specific options
    def safetynet(channel, filters={}, options={})
      @safetynet_channel = channel
      @safetynet_options = {
        whitelist: /@example.com/,
        email: {
          limit: 1,
          timeframe: 30.minutes
        }
      }.merge(Rails.configuration.safetynet).merge(options)

      # If class is a rails mailer, add after_action hook
      if (self.ancestors & [ActionMailer::Base]).any?
        if filters.empty?
          after_action :check_safetynet_window
        else
          after_action :check_safetynet_window, filters
        end
      end
    end
    # Accessed in instance methods by calling self.class.safetynet_channel
    def safetynet_channel
      @safetynet_channel
    end
    # Accessed in instance methods by calling self.class.safetynet_options
    def safetynet_options
      @safetynet_options
    end
  end
end

ActiveRecord::Base.send :include, Safetynet