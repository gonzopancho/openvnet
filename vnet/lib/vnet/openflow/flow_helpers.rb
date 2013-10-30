# -*- coding: utf-8 -*-

module Vnet::Openflow

  module FlowHelpers
    include MetadataHelpers

    Flow = Vnet::Openflow::Flow

    def is_ipv4_broadcast(address, prefix)
      address == IPV4_ZERO && prefix == 0
    end

    def match_ipv4_subnet_dst(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { :eth_type => 0x0800 }
      else
        { :eth_type => 0x0800,
          :ipv4_dst => address,
          :ipv4_dst_mask => IPV4_BROADCAST << (32 - prefix)
        }
      end
    end

    def match_ipv4_subnet_src(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { :eth_type => 0x0800 }
      else
        { :eth_type => 0x0800,
          :ipv4_src => address,
          :ipv4_src_mask => IPV4_BROADCAST << (32 - prefix)
        }
      end
    end

    def table_network_dst(network_type)
      case network_type
      when :physical then TABLE_PHYSICAL_DST
      when :virtual  then TABLE_VIRTUAL_DST
      else
        raise "Invalid network type value."
      end
    end

    def table_network_src(network_type)
      case network_type
      when :physical then TABLE_PHYSICAL_SRC
      when :virtual  then TABLE_VIRTUAL_SRC
      else
        raise "Invalid network type value."
      end
    end

    def flow_create(type, params)
      match = {}
      match_metadata = nil
      write_metadata = nil

      case type
      when :catch_arp_lookup
        table = TABLE_ARP_LOOKUP
        priority = 20
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = {
          :network => params[:network_id],
          :not_no_controller => nil
        }
      when :catch_flood_simulated
        table = TABLE_FLOOD_SIMULATED
        priority = 30
        match_metadata = { :network => params[:network_id] }
        write_metadata = { :interface => params[:interface_id] }
        goto_table = TABLE_OUTPUT_INTERFACE
      when :catch_interface_simulated
        table = TABLE_OUTPUT_INTERFACE
        priority = 30
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = { :interface => params[:interface_id] }
      when :catch_network_dst
        table = table_network_dst(params[:network_type])
        priority = 70
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = { :network => params[:network_id] }
      when :controller_port
        table = TABLE_CONTROLLER_PORT
      when :classifier
        table = TABLE_CLASSIFIER
      when :host_ports
        table = TABLE_HOST_PORTS
      when :network_dst
        table = table_network_dst(params[:network_type])
        match_metadata = { :network => params[:network_id] }
      when :network_src
        table = table_network_src(params[:network_type])
        match_metadata = { :network => params[:network_id] }
      when :network_src_arp_drop
        table = table_network_src(params[:network_type])
        priority = 85
        match_metadata = { :network => params[:network_id] }
      when :network_src_arp_match
        # Check for local flag since we trust that the local packets
        # are properly verified in earlier flows. 
        table = table_network_src(params[:network_type])
        priority = 86
        match_metadata = {
          :network => params[:network_id],
          :local => nil
        }
        goto_table = TABLE_ROUTER_CLASSIFIER
      when :network_src_ipv4_match
        table = table_network_src(params[:network_type])
        priority = 45
        match_metadata = {
          :network => params[:network_id],
          :local => nil
        }
        goto_table = TABLE_ROUTER_CLASSIFIER
      when :network_src_mac_match
        table = table_network_src(params[:network_type])
        priority = 35
        match_metadata = {
          :network => params[:network_id],
          :local => nil
        }
        goto_table = TABLE_ROUTER_CLASSIFIER
      when :router_dst_match
        table = TABLE_ROUTER_DST
        priority = 40
        match_metadata = { :network => params[:network_id] }
        goto_table = TABLE_NETWORK_DST_CLASSIFIER

      #
      # Refactored:
      #
      when :default
      when :controller_classifier
        table = TABLE_CONTROLLER_PORT
        write_metadata = { :interface => params[:write_interface_id] }
        goto_table = TABLE_INTERFACE_CLASSIFIER

      when :interface_classifier
        table = TABLE_INTERFACE_CLASSIFIER
        match_metadata = { :interface => params[:interface_id] }
        write_metadata = { :network => params[:write_network_id] }
        goto_table = TABLE_NETWORK_SRC_CLASSIFIER
      when :interface_egress_route
        table = TABLE_INTERFACE_EGRESS_ROUTES
        priority = params[:default_route] ? 20 : 30
        match_metadata = { :interface => params[:interface_id] }
        write_metadata = { :network => params[:write_network_id] }
        goto_table = TABLE_INTERFACE_EGRESS_MAC

      when :router_classifier
        table = TABLE_ROUTER_CLASSIFIER
        match_metadata = { :network => params[:network_id] }
        if params[:ingress_interface_id]
          priority = 10
          write_metadata = { :interface => params[:ingress_interface_id] }
          goto_table = TABLE_ROUTER_INGRESS
        else
          priority = 20
          goto_table = TABLE_ROUTER_INGRESS
        end          

      else
        return nil
      end

      table = params[:table] if params[:table]
      actions = params[:actions] if params[:actions]
      priority = params[:priority] if params[:priority]
      goto_table = params[:goto_table] if params[:goto_table]

      match_metadata = params[:match_metadata] if params[:match_metadata]

      if params[:write_metadata]
        if write_metadata
          write_metadata = write_metadata.merge(params[:write_metadata])
        else
          write_metadata = params[:write_metadata]
        end
      end

      match = params[:match] if params[:match]
      match = match.merge(md_create(match_metadata)) if match_metadata

      instructions = {}
      instructions[:cookie] = params[:cookie] || self.cookie
      instructions[:goto_table] = goto_table if goto_table
      instructions.merge!(md_create(write_metadata)) if write_metadata

      raise "Missing cookie." if instructions[:cookie].nil?

      Flow.create(table, priority, match, actions, instructions)
    end

  end

end
