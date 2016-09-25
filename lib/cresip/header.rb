# frozen_string_literal: true, encoding: ASCII-8BIT

class CresIP
    PacketTypes = {
        # Registering
        0x0f => :register,
        0x01 => :register_response, # panel
        0x0a => :register_response, # device
        0x02 => :register_success,
        
        0x03 => :program_stopping,

        # Feeback and requests
        0x05 => :action_info,
        0x12 => :serial_data,

        # Used for heartbeat
        0x0d => :echo_request,
        0x0e => :echo_response
    }
    PacketTypes.merge!(PacketTypes.invert)

    class PacketHeader < BinData::Record
        endian :big

        uint8  :packet_type
        uint16 :packet_size

        def type
            PacketTypes[packet_type]
        end
    end
end
