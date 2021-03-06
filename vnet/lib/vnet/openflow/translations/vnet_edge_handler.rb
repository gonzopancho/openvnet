# -*- coding: utf-8 -*-

module Vnet::Openflow::Translations
  class VnetEdgeHandler

    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :id

    def initialize(params)
      # TODO refactor
      @id = 1
      @dp_info = params[:dp_info]

      flows = []
      flows << Flow.create(TABLE_EDGE_SRC,   1, {}, {:output => Vnet::Openflow::Controller::OFPP_CONTROLLER}, {:cookie => @id | COOKIE_TYPE_TRANSLATION} )
      @dp_info.datapath.add_flows(flows)
    end

    def packet_in(message)
      debug log_format('packet_in', dump_packet_in(message))

      return if not message.packet_info.arp

      port = @dp_info.port_manager.item(port_number: message.in_port,
                                        reinitialize: false,
                                        dynamic_load: false)

      case port[:type]
      when :host
        handle_packet_from_host_port(message)
      when :generic
        handle_packet_from_edge_port(message)
      else
        error log_format("unknown type of port", port[:type])
      end
    end

    def install
      debug log_format('install')
    end

    private

    def handle_packet_from_host_port(message)
      info log_format("handle_packet_from_host_port")
      flows = []

      in_port = message.in_port
      src_mac = message.eth_src
      dst_mac = message.eth_dst

      src_network_id = @dp_info.network_manager.network_id_by_mac(src_mac.value)

      if src_network_id.nil?
        error log_format("no corresponded translation entry has been found", "in_port: #{in_port}, src: #{src_mac}, dst: #{dst_mac}")
        return nil
      end

      vlan_vids = @dp_info.translation_manager.network_to_vlan(src_network_id)

      if vlan_vids.nil?
        error log_format("blank vlan_vid", "in_port: #{in_port}, src: #{src_mac}, dst: #{dst_mac}")
        return nil
      else
        info log_format("vlan_id found", vlan_vids)
      end

      edge_port = @dp_info.port_manager.item(port_type: :generic, reinitialize: false, dynamic_load: false)

      if edge_port.nil?
        error log_format("Edge ports have not been found.", "in_port: #{in_port}, src: #{src_mac}, dst: #{dst_mac}")
        return nil
      else
        info log_format("edge_port found", edge_port)
      end

      case vlan_vids
      when Array
        actions=[]
        vlan_vids.each do |vlan_vid|
          actions << {:mod_vlan_vid => vlan_vid, :output => edge_port[:port_number]}
        end
      else
        actions = {:mod_vlan_vid => vlan_vids, :output => edge_port[:port_number]}
      end

      dpn = MW::DatapathNetwork.batch.on_specific_datapath(@dp_info.datapath.datapath_map).all.commit.select { |t| t.network_id == src_network_id }
      dpn_broadcast = dpn.first.broadcast_mac_address

      flows << Flow.create(TABLE_EDGE_SRC, 2, {
                           :eth_src => src_mac
                          }, {}, {
                           :goto_table => TABLE_EDGE_DST,
                           :metadata => METADATA_TYPE_VIRTUAL_TO_EDGE,
                           :metadata_mask => METADATA_TYPE_MASK
                          })

      if dst_mac.broadcast?
        flows << Flow.create(TABLE_EDGE_DST, 2, {
                             :eth_type => 0x0806,
                             :eth_dst => MAC_BROADCAST,
                             :metadata => METADATA_TYPE_VIRTUAL_TO_EDGE,
                             :metadata_mask => METADATA_TYPE_MASK
                            }, actions, {})
      elsif dpn_broadcast == dst_mac.value
        flows << Flow.create(TABLE_EDGE_DST, 2, {
                             :eth_type => 0x0806,
                             :eth_dst => dst_mac,
                             :metadata => METADATA_TYPE_VIRTUAL_TO_EDGE,
                             :metadata_mask => METADATA_TYPE_MASK
                            }, {:eth_dst => MAC_BROADCAST}.merge(actions), {})
      else
        flows << Flow.create(TABLE_EDGE_DST, 2, {
                             :eth_dst => src_mac,
                             :metadata => METADATA_TYPE_EDGE_TO_VIRTUAL,
                             :metadata_mask => METADATA_TYPE_MASK
                            }, {
                             :output => message.in_port
                            }, {})
      end

      @dp_info.add_flows(flows)

      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    def handle_packet_from_edge_port(message)
      info log_format("handle_packet_from_edge_port")
      flows = []

      in_port = message.in_port
      src_mac = message.eth_src
      dst_mac = message.eth_dst
      vlan_vid = message.vlan_vid

      return if message.packet_info.arp_request && !dst_mac.broadcast?

      if vlan_vid == 0
        error log_format("blank vlan_vid", "in_port: #{in_port}, src: #{src_mac}, dst: #{dst_mac}")
        return nil
      end

      network_id = @dp_info.translation_manager.vlan_to_network(vlan_vid)

      if network_id.nil?
        error log_format("no corresponded translation entry has been found", "in_port: #{in_port}, src: #{src_mac}, dst: #{dst_mac}")
        return nil
      end

      md = md_create(:network => network_id)

      flows << Flow.create(TABLE_EDGE_SRC, 2, {
                           :eth_src => src_mac,
                           :vlan_vid => (vlan_vid | VLAN_TCI_DEI),
                           :vlan_vid_mask => VLAN_TCI_MASK_NO_PRIORITY
                          }, {
                           :strip_vlan => true
                          }, {
                           :goto_table => TABLE_EDGE_DST,
                           :metadata => METADATA_TYPE_EDGE_TO_VIRTUAL,
                           :metadata_mask => METADATA_TYPE_MASK
                          })
      flows << Flow.create(TABLE_EDGE_DST, 2, {
                           :eth_dst => MAC_BROADCAST,
                           :metadata => METADATA_TYPE_EDGE_TO_VIRTUAL,
                           :metadata_mask => METADATA_TYPE_MASK
                          }, {}, {
                           :goto_table => TABLE_VIRTUAL_DST,
                           :metadata => md[:metadata],
                           :metadata_mask => md[:metadata_mask]
                          })
      flows << Flow.create(TABLE_EDGE_DST, 2, {
                           :eth_dst => src_mac,
                           :metadata => METADATA_TYPE_VIRTUAL_TO_EDGE,
                           :metadata_mask => METADATA_TYPE_MASK
                          }, {
                           :mod_vlan_vid => vlan_vid,
                           :output => message.in_port
                          }, {})

      @dp_info.add_flows(flows)

      network = @dp_info.network_manager.item(id: network_id)

      @dp_info.send_packet_out(message, OFPP_TABLE)
    end

    def flow_options(vlan_vid, network_id)
      {:cookie => (vlan_vid << COOKIE_TAG_MASK) | network_id | COOKIE_TYPE_TRANSLATION}
    end

    def cookie(vlan_vid, network_id)
    end

    def log_format(message, values = nil)
      "#{@dpid_s} translation_handler: #{message}" + (values ? " (#{values})" : '')
    end

    def dump_packet_in(message)
      output_str = ""
      output_str << "in_port=#{message.in_port},"
      output_str << "src=#{message.eth_src},"
      output_str << "dst=#{message.eth_dst},"
      output_str << "eth_type=#{message.eth_type},"
      output_str << "vlan_tci=#{message.vlan_tci},"
      output_str << "vlan_vid=#{message.vlan_vid},"
      output_str << "arp?=#{message.packet_info.arp},"
      output_str << "arp_request?=#{message.packet_info.arp_request},"
      output_str << "arp_reply?=#{message.packet_info.arp_reply},"
      output_str << "arp_sha=#{message.packet_info.arp_sha},"
      output_str << "arp_tha=#{message.packet_info.arp_tha}"
      output_str
    end
  end
end
