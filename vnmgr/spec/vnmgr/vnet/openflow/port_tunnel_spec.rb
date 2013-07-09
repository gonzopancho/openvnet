# -*- coding: utf-8 -*-
require 'spec_helper'
require 'trema'

include Vnmgr::VNet::Openflow::Constants

describe Vnmgr::VNet::Openflow::PortTunnel do
  describe "install" do
    it "create tunnel specific flows" do
      datapath = MockDatapath.new(double, 10)
      port = Vnmgr::VNet::Openflow::Port.new(datapath, double(port_no: 10), true)
      port.extend(Vnmgr::VNet::Openflow::PortTunnel)
      tunnel_manager = double(:tunnel_manager)
      tunnel_manager.should_receive(:update_all_networks)
      switch = double(:switch)
      switch.should_receive(:tunnel_manager).and_return(tunnel_manager)
      datapath.should_receive(:switch).and_return(switch)

      port.install
    end
  end
end