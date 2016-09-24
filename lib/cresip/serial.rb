# encoding: ASCII-8BIT
# frozen_string_literal: true

# NOTE:: No example data

class CresIP
    class SerialData
        def initialize(header, payload)
            @header = header
            @payload = payload

            @value = parse_serial_data(payload.bytes)
        end

        attr_reader :header, :payload

        def type
            @header.type
        end


        protected


        Encodings = {
            3 => 'ASCII-8BIT',
            7 => 'UTF-16BE'
        }
        def parse_serial_data(bytes)
            len = (bytes[0] << 24) + (bytes[1] << 16) + (bytes[2] << 8) + bytes[3]
            join = 1 + (bytes[5] << 8) + bytes[6]
            encoding = bytes[7]
            string = bytes[8...(len + 4)].pack('c*')
            enc = Encodings[encoding]

            # Not sure if this will work as don't have any sample data.
            # Reference: https://github.com/ironiridis/control4go/blob/master/crestron/packets.go#L149
            string.force_encoding(enc) if enc
        end
    end
end
