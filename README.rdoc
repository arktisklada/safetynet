# Safetynet

Stop communication problems before they happen

Safetynet keeps track of email communications by user/email and ActionMailer message. If the same message is sent to the same user multiple times within the allowed timeframe, it will be blocked from delivery and notify system admins. The messages are filterable in a way similar to controller filters, and the checking method can be called by itself outside the normal hooks for additional throttling (i.e. SMS sending, push notifications, etc.).

## Rails Installation

Add this line to your application's Gemfile:

    gem 'safetynet'

And then execute:

    $ bundle
    $ rails generate safetynet
    $ rake db:migrate

The generator creates two files:

  1. a file under `config/initializers/safetynet.rb` configuring Safetynet with project-specific settings.
  2. a migration file to create the safetynet_histories table


## Usage

###Applied to a mailer

Add the safetynet method to an ActionMailer::Base class with the following structure:

    safetynet({
      channel,
      filters,
      options: {
        email: {
          limit: 1,
          timeframe: 30.minutes
        }
      }
    })

And a description of each:

|Field|Type|Description|
|:-|:-|:-|
|**channel**   |Symbol  |The category of methods to watch (email/sms/etc.) -- see options below|
|**filters**   |Hash    |Hash of method names to watch (email only) that fits after_action requirements|
|**options**   |Hash    |Contains a hash for each channel and includes the next 2 fields|
|**limit**     |Integer |Maximum # of methods for this channel (default: 1)|
|**timeframe** |Integer |Minimum allowed timeframe between last successful method call (default: 30.minutes)|


**Note:** Defaults to configured channel, method, and Safetynet configuration limit & timeframe for the channel

####Example:

    class UserMailer < ActionMailer::Base
      include Safetynet
      safetynet :email, {except: [:user_registration_email, :forgot_password_email]}
    end



###Standalone usage on a class


####Example:

    class User < ActiveRecord::Base
      include Safetynet
    safetynet :sms

      def send_sms
        if permit_delivery?(self)
          ...
        end
      end
    end


## Contributing

1. Create an issue
2. Fork it ( https://github.com/arktisklada/safetynet/fork )
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
