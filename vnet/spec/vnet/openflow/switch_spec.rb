# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

describe Vnet::Openflow::Switch do
  include_context :ofc_double

  describe "switch_ready" do
    it "sends messages" do
      datapath = MockDatapath.new(ofc, 1)
      Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)
      switch = Vnet::Openflow::Switch.new(datapath)
      switch.switch_ready

      expect(datapath.sent_messages.size).to eq 2
      expect(datapath.added_flows.size).to eq DATAPATH_IDLE_FLOWCOUNT
      expect(datapath.added_ovs_flows.size).to eq 0
    end
  end

  describe "handle_port_desc" do
    context "tunnel" do
      it "should create a port object whose datapath_id is 1" do
        dp = MockDatapath.new(ofc, 1)
        Vnet::Openflow::TunnelManager.any_instance.stub(:create_all_tunnels)

        tunnel = double(:tunnel)

        Vnet::Openflow::TunnelManager.any_instance.stub(:item).and_return(tunnel)

        dp.create_mock_port_manager
        port_desc = double(:port_desc)
        port_desc.should_receive(:port_no).exactly(2).times.and_return(5)
        port_desc.should_receive(:name).exactly(1).times.and_return('t-a')
        port_desc.should_receive(:hw_addr).exactly(1).times.and_return(nil)
        port_desc.should_receive(:advertised).exactly(1).times.and_return(0)
        port_desc.should_receive(:supported).exactly(1).times.and_return(0)

        port = double(:port)
        port_info = double(:port_info)
        port.should_receive(:port_number).exactly(1).times.and_return(5)
        port.should_receive(:id).exactly(1).times.and_return(5)

        Vnet::Openflow::Ports::Base.stub(:new).and_return(port)

        dp.port_manager.insert(port_desc)

        expect(dp.port_manager.ports[5]).to eq port
      end
    end

    #TODO
    context "eth" do
    end
  end
end
