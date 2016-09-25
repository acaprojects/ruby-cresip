# Ruby CresIP

Constructs and parses Crestron IP protocol packets that make it easier to communicate with Crestron devices that would otherwise require a crestron controller.
It does not implement the transport layer so you can use it with native ruby, eventmachine, celluloid or the like.

[![Build Status](https://travis-ci.org/acaprojects/ruby-cresip.svg?branch=master)](https://travis-ci.org/acaprojects/ruby-cresip)

You'll still need to use Crestron Toolbox software to configure the devices.


## Install the gem

Install it with [RubyGems](https://rubygems.org/)

    gem install cresip

or add this to your Gemfile if you use [Bundler](http://gembundler.com/):

    gem 'cresip'



## Usage

```ruby
require 'cresip'

values = {}
cresip = CresIP.new do |message|
    case message
    when Action
        if message.feedback?
            values[message.join] = message.value
        else
            values[message.join] = message.value
            # The request is a set value so maybe perform some action
        end
    when Echo
        if not message.is_response?
            # Send a response using you TCP transport
            message.response.to_binary_s
        end
    when Register
        if not message.reg_success?
            # Send a response using you TCP transport
            message.register.to_binary_s
        end
    end
end
cresip.read(byte_string)


# You can also generate your own actions
act = CresIP::Action.new

# Supports Strings, Integers and true / false values
act.value = 'hello crestron'
act.join = 123

# Send this string over the wire to communicate
act.to_binary_s

```



## License and copyright

MIT
