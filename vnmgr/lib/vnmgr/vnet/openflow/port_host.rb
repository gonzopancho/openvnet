# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortHost
    include Constants

    def install
      flows = []
      options = {:cookie => port_info.port_no | 0x100000000}

      # flows << Flow.create(TABLE_CLASSIFIER, 6, {:udp => nil, :in_port => OpenFlowController::OFPP_LOCAL,
      #                       :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_src => '0.0.0.0', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst => 67},
      #                     {:output => port_info.port_no}, options)
      # flows << Flow.create(TABLE_CLASSIFIER, 5, {:udp => nil, :in_port => port_info.port_no,
      #                       :dl_dst => 'ff:ff:ff:ff:ff:ff', :nw_src => '0.0.0.0', :nw_dst => '255.255.255.255', :tp_src => 68, :tp_dst =>67},
      #                     {:local => nil}, options)

      flows << Flow.create(TABLE_CLASSIFIER,     2, {:in_port => port_info.port_no}, {}, options.merge(:goto_table => TABLE_ROUTE_DIRECTLY))
      flows << Flow.create(TABLE_MAC_ROUTE,      0, {}, {:output => port_info.port_no}, options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {:metadata => port_info.port_no, :metadata_mask => 0xffffffff}, {:output => port_info.port_no}, options)

      # flows << Flow.create(TABLE_ROUTE_DIRECTLY, 0, {}, {:output => port_info.port_no}, options)
      flows << Flow.create(TABLE_LOAD_DST,       0, {}, {}, options.merge({:metadata => port_info.port_no, :metadata_mask => 0xffffffff, :goto_table => TABLE_LOAD_SRC}))
      flows << Flow.create(TABLE_LOAD_SRC,       4, {:in_port => port_info.port_no}, {}, options.merge(:goto_table => TABLE_METADATA_ROUTE))

      flows << Flow.create(TABLE_ARP_ANTISPOOF,  1, {:eth_type => 0x0806, :in_port => port_info.port_no}, {}, options.merge(:goto_table => TABLE_ARP_ROUTE))
      flows << Flow.create(TABLE_ARP_ROUTE,      0, {:eth_type => 0x0806}, {:output => port_info.port_no}, options)

      # flows << Flow.create(TABLE_METADATA_INCOMING, 2, {:in_port => OpenFlowController::OFPP_LOCAL}, {:output => port_info.port_no}, options)
      # flows << Flow.create(TABLE_METADATA_OUTGOING, 4, {:in_port => port_info.port_no}, {:local => nil}, options)

      self.datapath.add_flows(flows)
    end

  end

end
