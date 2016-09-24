# frozen_string_literal: true
# encoding: ASCII-8BIT

=begin Example Data
    Device sent:     0d 0002 0000
    Controller sent: 0e 0002 0000
=end

class CresIP
    class Echo
        def initialize(header, payload)
            @header = header
            @payload = payload
        end

        attr_reader :header, :payload

        def type
            @header.type
        end

        def is_response?
            @header.type == :echo_response
        end

        def response
            head = PacketHeader.new
            head.packet_type = PacketTypes[:echo_response]
            head.packet_size = @payload.length
            Echo.new(head, @payload)
        end

        def to_binary_s
            "#{@header.to_binary_s}#{@payload}"
        end
    end
end
