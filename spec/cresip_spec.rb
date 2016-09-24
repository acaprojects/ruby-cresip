# encoding: ASCII-8BIT

require 'cresip'


describe CresIP do
    before :each do
        @packets = []
        @cip = CresIP.new do |packet|
            @packets << packet
        end
    end

    it "should parse echo requests" do
        @cip.read("\x0d\x00\x02\x00\x00")
        expect(@packets.length).to be(1)

        echo = @packets[0]
        expect(echo.to_binary_s).to eq("\x0d\x00\x02\x00\x00")
        expect(echo.is_response?).to be(false)
        expect(echo.response.is_response?).to be(true)
        expect(echo.response.to_binary_s).to eq("\x0e\x00\x02\x00\x00")
    end

    it "should parse digital requests" do
        @cip.read("\x05\x00\x06\x00\x00\x03\x00\x13\x00")
        expect(@packets.length).to be(1)

        # Test basic parsing
        req = @packets[0]
        expect(req.to_binary_s).to eq("\x05\x00\x06\x00\x00\x03\x00\x13\x00")
        expect(req.feedback?).to be(true)
        expect(req.join).to be(20)
        expect(req.value).to be(true)

        # Test changing the value and type
        req.set_value(false)
        expect(req.value).to be(false)
        expect(req.join).to be(20)
        expect(req.feedback?).to be(false)
        expect(req.to_binary_s).to eq("\x05\x00\x06\x00\x00\x03\x27\x13\x80")

        # Test changing the join value and type
        req.set_value(false, type: :feedback, join: 22)
        expect(req.value).to be(false)
        expect(req.join).to be(22)
        expect(req.feedback?).to be(true)
        expect(req.to_binary_s).to eq("\x05\x00\x06\x00\x00\x03\x00\x15\x80")

        # Test generated values parse properly
        @cip.read(req.to_binary_s)
        expect(@packets.length).to be(2)

        req2 = @packets[-1]
        expect(req2.value).to be(false)
        expect(req2.join).to be(22)
        expect(req2.feedback?).to be(true)
    end

    it "should parse analog requests" do
        @cip.read("\x05\x00\x08\x00\x00\x05\x14\x00\x42\x04\xd2")
        expect(@packets.length).to be(1)

        # Test basic parsing
        req = @packets[0]
        expect(req.to_binary_s).to eq("\x05\x00\x08\x00\x00\x05\x14\x00\x42\x04\xd2")
        expect(req.feedback?).to be(false)
        expect(req.join).to be(67)
        expect(req.value).to be(1234)

        # Test changing the value
        req.set_value(45)
        expect(req.value).to be(45)
        expect(req.join).to be(67)
        expect(req.feedback?).to be(false)
        expect(req.to_binary_s).to eq("\x05\x00\x08\x00\x00\x05\x14\x00\x42\x00\x2d")

        # Test changing the value, type and join
        req.set_value(46, type: :feedback, join: 22)
        expect(req.value).to be(46)
        expect(req.join).to be(22)
        expect(req.feedback?).to be(true)
        expect(req.to_binary_s).to eq("\x05\x00\x08\x00\x00\x05\x01\x00\x15\x00\x2e")

        # Test generated values parse properly
        @cip.read(req.to_binary_s)
        expect(@packets.length).to be(2)

        req2 = @packets[-1]
        expect(req2.value).to be(46)
        expect(req2.join).to be(22)
        expect(req2.feedback?).to be(true)
    end

    it "should parse serial requests" do
        @cip.read("\x05\x00\x18\x00\x00\x15\x12\x15\x53\x74\x72\x65\x61\x6d\x69\x6e\x67\x20\x44\x6f\x77\x6e\x73\x63\x61\x6c\x65")
        expect(@packets.length).to be(1)

        # Test basic parsing
        req = @packets[0]
        expect(req.to_binary_s).to eq("\x05\x00\x18\x00\x00\x15\x12\x15\x53\x74\x72\x65\x61\x6d\x69\x6e\x67\x20\x44\x6f\x77\x6e\x73\x63\x61\x6c\x65")
        expect(req.feedback?).to be(false)
        expect(req.join).to be(21)
        expect(req.value).to eq('Streaming Downscale')

        # Test changing the value
        req.set_value('Input 16', join: 15)
        expect(req.value).to eq('Input 16')
        expect(req.join).to be(15)
        expect(req.feedback?).to be(false)
        expect(req.to_binary_s).to eq("\x05\x00\x0d\x00\x00\x0a\x12\x0f\x49\x6e\x70\x75\x74\x20\x31\x36")

        # Test generated values parse properly
        @cip.read(req.to_binary_s)
        expect(@packets.length).to be(2)

        req2 = @packets[-1]
        expect(req.value).to eq('Input 16')
        expect(req.join).to be(15)
        expect(req.feedback?).to be(false)
    end

    it "should work with unknown requests" do
        # I don't know the format of the date and time data
        @cip.read("\x05\x00\x0b\x00\x00\x08\x08\x0e\x23\x07\x10\x09\x22\x16")
        expect(@packets.length).to be(1)
        
        # Test basic parsing
        req = @packets[0]
        expect(req.to_binary_s).to eq("\x05\x00\x0b\x00\x00\x08\x08\x0e\x23\x07\x10\x09\x22\x16")
        expect(req.feedback?).to be(false)
        expect(req.join).to be(nil)
        expect(req.value).to be(nil)
        expect(req.type).to be(:date_and_time)

        # Not sure what the point of the updates incomming packet are
        @cip.read("\x05\x00\x06\x00\x00\x03\x03\x21\x07")
        expect(@packets.length).to be(2)
        
        # Test basic parsing
        req = @packets[-1]
        expect(req.to_binary_s).to eq("\x05\x00\x06\x00\x00\x03\x03\x21\x07")
        expect(req.feedback?).to be(false)
        expect(req.join).to be(nil)
        expect(req.value).to be(nil)
        expect(req.type).to be(:update_request_incomming)

        # Pretty sure this is a DM switch packet...
        @cip.read("\x05\x00\x0a\x00\x00\x07\x20\x01\x04\x15\x00\xf2\x03")
        expect(@packets.length).to be(3)
        
        # Test basic parsing
        req = @packets[-1]
        expect(req.to_binary_s).to eq("\x05\x00\x0a\x00\x00\x07\x20\x01\x04\x15\x00\xf2\x03")
        expect(req.feedback?).to be(false)
        expect(req.join).to be(nil)
        expect(req.value).to be(nil)
        expect(req.type).to be(nil)
    end

    it 'should buffer messages' do
        @cip.read("\x05\x00\x0b\x00\x00\x08\x08\x0e\x23\x07\x10\x09\x22")
        expect(@packets.length).to be(0)

        @cip.read("\x16\x05\x00\x0b\x00\x00\x08\x08\x0e\x23\x07\x10\x09\x22\x16")
        expect(@packets.length).to be(2)
    end
end
