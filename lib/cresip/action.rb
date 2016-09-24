# frozen_string_literal: true
# encoding: ASCII-8BIT


class CresIP
    PayloadType = {
        0x00 => :digital_feedback,
        0x01 => :analog_feedback,
        0x02 => :serial_feedback,
        0x03 => :update_request_incomming, # seems pointless and can be ignored
        0x08 => :date_and_time,
        0x27 => :digital_set,
        0x14 => :analog_set,
        0x12 => :serial_set
        #0x20 => :??
    }
    PayloadType.merge!(PayloadType.invert)

    class ActionHeader < BinData::Record
        endian :big

        uint8  :reserved
        uint16 :payload_size,  :value => lambda { payload.length + 1 }
        uint8  :payload_type
        string :payload, :read_length => lambda { payload_size - 1 }

        def type
            PayloadType[payload_type]
        end
    end


    # Digital Feedback: 05 0006 000003 00 1300
    # Analog Set:       05 0008 000005 14 004204d2
    # Date & Time:(dev) 05 000b 000008 08 0e230710092216
    #      (controller) 05 000b 000008 08 0e230709092216
    # Unknown:    (dev) 05 0009 000006 20 0103009201
    #             (dev) 05 000a 000007 20 01041500f203
    #      (controller) 05 0014 000011 20 110e1c050000444d204f757470757473
    # Update Incomming: 05 0005 000002 03 00    (device & server)
    #                   05 0006 000003 03 2107  (device)
    #                   05 0005 000002 03 16    (server)
    # Serial Set: (dev) 05 0013 000010 12 03444d2d54582d344b2d3330322d43
    class Action
        def initialize(header = PacketHeader.new, action = ActionHeader.new)
            @header = header
            @action = action
            @header.packet_type = PacketTypes[:action_info]

            if action.type && self.respond_to?(action.type, true)
                @join, @value = self.send(action.type, action.payload)
            end
        end

        attr_reader :header, :action, :join, :value

        def type
            @action.type
        end

        def payload
            @action.payload
        end

        Feedback = [:analog_feedback, :digital_feedback, :serial_feedback]
        def feedback?
            Feedback.include? @action.type
        end

        def to_binary_s
            action_resp = @action.to_binary_s
            @header.packet_size = action_resp.length
            "#{@header.to_binary_s}#{action_resp}"
        end

        def set_value(data, type: :set, join: @join)
            if data.is_a? String
                @action.payload_type = type == :set ? PayloadType[:serial_set] : PayloadType[:serial_feedback]
                @action.payload = encode_serial_set(join, data)
            elsif data.is_a? Integer
                @action.payload_type = type == :set ? PayloadType[:analog_set] : PayloadType[:analog_feedback]
                @action.payload = encode_analog_set(join, data)
            elsif data == true || data == false
                @action.payload_type = type == :set ? PayloadType[:digital_set] : PayloadType[:digital_feedback]
                @action.payload = encode_digital_set(join, data)
            else
                raise 'invalid data type'
            end

            @join = join
            @value = data
        end

        def set_join(number)
            @join = number
            # this keeps the binary representation up to date
            set_value(@value)
            number
        end


        protected


        def digital_feedback(string)
            bytes = string.bytes

            join = 1 + ((bytes[1] & 0x7F) << 8) + bytes[0]
            # value == true, high/press
            # value == false, low/release
            value = (bytes[1] & 0x80) == 0

            [join, value]
        end
        alias_method :digital_set, :digital_feedback

        def encode_digital_set(join, value)
            join -= 1
            high = (join & 0x7F00) >> 8
            high = high | 0x80 unless value
            low = join & 0xFF
            [low, high].pack('c*')
        end

        def analog_feedback(string)
            bytes = string.bytes

            if bytes.length == 4
                join = 1 + (bytes[0] << 8) + bytes[1]
                value = (bytes[2] << 8) + bytes[3]
            else
                join = 1 + bytes[0]
                value = (bytes[1] << 8) + bytes[2]
            end

            [join, value]
        end
        alias_method :analog_set, :analog_feedback

        def encode_analog_set(join, value)
            output = []
            join -= 1
            output << ((join & 0xFF00) >> 8)
            output << (join & 0xFF)
            output << ((value & 0xFF00) >> 8)
            output << (value & 0xFF)
            output.pack('c*')
        end

        # NOTE:: Have not seen this returned, untested
        # Ref: https://github.com/CommandFusion/CIP/blob/master/CommandFusion/CIPv1.1.js#L165
        def serial_feedback(string)
            rows = string.split("\r")
            joinLength = rows[0].index(',');
            join = rows[0][1...joinLength].to_i
            
            value = String.new
            rows.each_with_index do |row, i|
                text = row[(joinLength + 1)..-1];
                if row == 0
                    if row[0] == '#'
                        value << "\r#{row}" if row.length > 0
                    elsif row[0] == '@'
                        value << row
                    end
                else
                    if row.empty? && !(i == (rows.length - 1) && value.empty?)
                        value << "\r"
                    else
                        value << row
                    end
                end
            end

            [join, value]
        end

        def serial_set(string)
            join = string.getbyte(0)
            value = string[1..-1]
            [join, value]
        end

        def encode_serial_set(join, value)
            output = String.new
            output << join
            output << value
            output
        end
    end

end
