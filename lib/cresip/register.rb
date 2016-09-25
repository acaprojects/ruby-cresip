# frozen_string_literal: true, encoding: ASCII-8BIT

=begin Example Data
    server:
        0f 0001 02 (request IP ID Register, switch should send IPID)
    switch:
        0a 000a 00 05 a34240 02 00000000
        (IPID: 0x03 to 0xFE === 05) (byte 5)
        (RESP: 0x02)
    server:
        02 0004 00000003 (IP ID registry success)
        failed response: 02 0003 ffff02
=end

class CresIP
    class Register
        def initialize(header = PacketHeader.new, payload = "\x02")
            @header = header
            @payload = payload

            if @header.type == nil
                @header.packet_type = PacketTypes[:register]
            end
        end

        attr_reader :header, :payload

        def type
            @header.type
        end

        def registering?
            @header.type == :register_response
        end

        def reg_success?
            @header.type == :register_success && @payload.length == 4
        end

        def respond(success = true)
            head = PacketHeader.new
            head.packet_type = PacketTypes[:register_success]

            if success
                Register.new(head, "\x00\x00\x00\x03")
            else
                Register.new(head, "\xff\xff\x02")
            end
        end

        def register(ipid = 5, type = 0x0a)
            # IPID Range: 0x03..0xFE

            head = PacketHeader.new
            # I think 0x0A is a switcher register response
            # and     0x01 is touch screen 
            head.packet_type = type
            payload = if type == 0x0a
                # 0a000a00 ipid a342400200000000
                "\x00#{ipid.chr}\xa3\x42\x40\x02\x00\x00\x00\x00"
            else
                # 0100077F00000100 ipid 40
                "\x7F\x00\x00\x01\x00#{ipid.chr}\x40"
            end
            Register.new(head, payload)
        end

        def to_binary_s
            @header.packet_size = @payload.bytesize
            "#{@header.to_binary_s}#{@payload}"
        end
    end
end
