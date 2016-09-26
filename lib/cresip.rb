# frozen_string_literal: true, encoding: ASCII-8BIT

require 'bindata'

require 'cresip/header'
require 'cresip/register'
require 'cresip/action'
require 'cresip/echo'
require 'cresip/serial'


=begin
    For testing 3series device control you can use the reserved joins
    Analog Joins:  17201 == LCD Brightness
    Digital Joins: 17229 == LCD Backlight On
                   17230 == LCD Backlight Off
=end


class CresIP
    HeartBeatRate = 5000 #ms
    DefaultPort = 41794
    TLSPort = 41796

    UnknownRequest = Struct.new(:header, :payload)

    def initialize(callback = nil, &block)
        @callback = callback || block
        @buffer = String.new
    end

    def read(data)
        @buffer << data
        while @buffer.length >= 3 do
            header = PacketHeader.new
            header.read(@buffer[0..2])
            length = header.packet_size + 3

            break if @buffer.length < length

            payload = @buffer[3...length]
            @buffer = @buffer[length..-1]

            parse_packet(header, payload)
        end
    end

    def parse_packet(header, payload)
        case header.type
        when :register, :register_response, :register_success
            @callback.call Register.new(header, payload)

        when :program_stopping
            # Should we bother with a callback?

        when :echo_request, :echo_response
            @callback.call Echo.new(header, payload)

        when :action_info
            action_header = ActionHeader.new
            action_header.read(payload)
            @callback.call Action.new(header, action_header)

        when :serial_data
            @callback.call SerialData.new(header, payload)
        
        else
            @callback.call UnknownRequest.new(header, payload)
        end
    end
end
