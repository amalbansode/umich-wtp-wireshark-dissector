umichwtp = Proto("UMichWTP",  "UMich Wolverine Transport Protocol")

packet_type     = ProtoField.uint32("umichwtp.packet_type"    , "Type"           , base.DEC)
packet_seqnum   = ProtoField.uint32("umichwtp.packet_seqnum"  , "Sequence Number", base.DEC)
packet_length   = ProtoField.uint32("umichwtp.packet_length"  , "Length"         , base.DEC)
packet_checksum = ProtoField.uint32("umichwtp.packet_checksum", "Checksum"       , base.DEC)

-- WTP simply deals with bytes
packet_content  = ProtoField.bytes("umichwtp.packet_content"  , "Content"        , base.SPACE)

umichwtp.fields = { packet_type, packet_seqnum, packet_length, packet_checksum, packet_content }

function umichwtp.dissector(buffer, pinfo, tree)
  length = buffer:len()
  if length == 0 or length > 1472 then return end

  pinfo.cols.protocol = umichwtp.name

  -- Add WTP entry to the tree
  local subtree = tree:add(umichwtp, buffer(), "UMich Wolverine Transport Protocol")

  -- Parse and add WTP fields to the WTP subtree
  local type = buffer(0,4):uint()
  local type_name = get_packet_type_name(type)
  subtree:add(packet_type,     buffer(0,4)):append_text(" (" .. type_name .. ")")

  subtree:add(packet_seqnum,   buffer(4,4))
  subtree:add(packet_length,   buffer(8,4))
  subtree:add(packet_checksum, buffer(12,4))

  -- Only print packet content in the subtree if there is anything
  local payload_length = buffer(8,4):uint()
  if payload_length == 0 then return end
  subtree:add(packet_content,  buffer(16,payload_length))
end

-- The Packet Type field is an enumeration of four types
function get_packet_type_name(packet_type)
  local type_name = "Unknown"

      if packet_type == 0 then type_name = "START"
  elseif packet_type == 1 then type_name = "END"
  elseif packet_type == 2 then type_name = "DATA"
  elseif packet_type == 3 then type_name = "ACK" end

  return type_name
end

-- Set the UDP port to listen on as 1817 (UMich's founding year)
local udp_port = DissectorTable.get("udp.port")
udp_port:add(1817, umichwtp)
