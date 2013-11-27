# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnet::Constants::Openflow

describe Vnet::Openflow::TunnelManager do

  describe "update_virtual_network" do
    before do
      Fabricate(:datapath_1, :dc_segment_id => 1)
      Fabricate(:datapath_2, :dc_segment_id => 2)
      Fabricate(:datapath_3, :dc_segment_id => 2)
      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 1, network_id: 2, broadcast_mac_address: 2)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, broadcast_mac_address: 3)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 2, broadcast_mac_address: 4)
      Fabricate(:datapath_network, datapath_id: 3, network_id: 1, broadcast_mac_address: 5)
    end

    let(:datapath) do
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16)).tap do |datapath|
        datapath.create_mock_datapath_map

        # datapath.switch = double(:cookie_manager => Vnet::Openflow::CookieManager.new)
        # datapath.switch.cookie_manager.create_category(:tunnel, 0x6, 48)
        #
        # datapath.cookie_manager = Vnet::Openflow::CookieManager.new
      end
    end

    let(:tunnel_manager) do
      datapath.dp_info.tunnel_manager.tap do |tunnel_manager|
        tunnel_manager.insert(3)
        tunnel_manager.insert(4)
        tunnel_manager.insert(5)
      end
    end

    it "should only add broadcast mac addressess flows at start" do
      tunnel_manager

      flows = datapath.added_flows

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(flows.size).to eq 3

      # TunnelManager no longer creates the drop flows for broadcast
      # mac addresses, move.

      # expect(flows.size).to eq 6

      # expect(flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:11:11:11')},
      #   nil,
      #   {:cookie => 1 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[1]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:11:11:11')},
      #   nil,
      #   {:cookie => 1 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[2]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:22:22:22')},
      #   nil,
      #   {:cookie => 2 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[3]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('bb:bb:bb:22:22:22')},
      #   nil,
      #   {:cookie => 2 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[4]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_SRC_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('cc:cc:cc:11:11:11')},
      #   nil,
      #   {:cookie => 3 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})

      # expect(flows[5]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_NETWORK_DST_CLASSIFIER,
      #   90,
      #   {:eth_dst => Trema::Mac.new('cc:cc:cc:11:11:11')},
      #   nil,
      #   {:cookie => 3 | (COOKIE_PREFIX_DP_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

    it "should add flood flow network 1" do
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: "t-test2",
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: "t-test3",
                                 port_number: 10)

      datapath.added_flows.clear

      tunnel_manager.update(event: :update_network, network_id: 1)

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 1

      # expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_TUNNEL_PORTS,
      #   1,
      #   {:metadata => 1 | METADATA_TYPE_COLLECTION,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [{:output => 9}, {:output => 10}],
      #   {:cookie => 1 | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)})

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_FLOOD_TUNNELS,
        1,
        {:metadata => 1 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
        [{:tunnel_id => 1 | TUNNEL_FLAG_MASK}, {:output => 9}, {:output => 10}],
        {:cookie => 1 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

    it "should add flood flow for network 2" do
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: "t-test2",
                                 port_number: 9)
      tunnel_manager.update_item(event: :set_port_number,
                                 port_name: "t-test3",
                                 port_number: 10)

      datapath.added_flows.clear

      tunnel_manager.update(event: :update_network, network_id: 2)

      expect(datapath.added_ovs_flows.size).to eq 0
      expect(datapath.added_flows.size).to eq 1

      # expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
      #   TABLE_FLOOD_TUNNEL_PORTS,
      #   1,
      #   {:metadata => 2 | METADATA_TYPE_COLLECTION,
      #    :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
      #   [{:output => 9}],
      #   {:cookie => 2 | (COOKIE_PREFIX_COLLECTION << COOKIE_PREFIX_SHIFT)})

      expect(datapath.added_flows[0]).to eq Vnet::Openflow::Flow.create(
        TABLE_FLOOD_TUNNELS,
        1,
        {:metadata => 2 | METADATA_TYPE_NETWORK,
         :metadata_mask => METADATA_VALUE_MASK | METADATA_TYPE_MASK},
        [{:tunnel_id => 2 | TUNNEL_FLAG_MASK}, {:output => 9}],
        {:cookie => 2 | (COOKIE_PREFIX_NETWORK << COOKIE_PREFIX_SHIFT)})
    end

  end

  describe "remove_network_id_for_dpid" do
    before do
      Fabricate("datapath_1")
      Fabricate("datapath_2")
      Fabricate(:datapath_network, datapath_id: 1, network_id: 1, broadcast_mac_address: 1)
      Fabricate(:datapath_network, datapath_id: 2, network_id: 1, broadcast_mac_address: 2)
    end

    let(:ofctl) { double(:ofctl) }
    let(:datapath) {
      MockDatapath.new(double, ("0x#{'a' * 16}").to_i(16), ofctl).tap { |dp|
        dp.create_mock_datapath_map
      }
    }

    subject do
      datapath.dp_info.tunnel_manager.tap do |tm|
        tm.insert(2)
      end
    end

    it "should delete tunnel when the network is deleted on the local datapath" do
      subject.remove_network_id_for_dpid(1, ("0x#{'a' * 16}").to_i(16))
      expect(datapath.dp_info.deleted_tunnels[0]).to eq "t-test2"
    end

    it "should delete tunnel when the network is deleted on the remote datapath" do
      subject.remove_network_id_for_dpid(1, ("0x#{'b' * 16}").to_i(16))
      expect(datapath.dp_info.deleted_tunnels[0]).to eq "t-test2"
    end
  end
end
