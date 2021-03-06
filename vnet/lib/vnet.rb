# -*- coding: utf-8 -*-

#require 'active_support/all'
#require 'active_support/core_ext'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/object'
require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'ext/kernel'
require 'fuguta'
require 'json'

module Vnet

  ROOT = ENV['VNET_ROOT'] || File.expand_path('../../', __FILE__)
  CONFIG_PATH = ENV['VNET_CONFIG_PATH'] || "/etc/wakame-vnet"
  LOG_DIR = ENV['VNET_LOG_DIR'] || "/var/log/wakame-vnet"

  module Configurations
    autoload :Base,   'vnet/configurations/base'
    autoload :Common, 'vnet/configurations/common'
    autoload :Webapi, 'vnet/configurations/webapi'
    autoload :Vnmgr,  'vnet/configurations/vnmgr'
    autoload :Vna,    'vnet/configurations/vna'
  end

  module Constants
    autoload :Openflow, 'vnet/constants/openflow'
    autoload :OpenflowFlows, 'vnet/constants/openflow_flows'
    autoload :VnetAPI, 'vnet/constants/vnet_api'
  end

  autoload :Event, 'vnet/event'
  module Event
    autoload :Dispatchable, 'vnet/event/dispatchable'
    autoload :Notifications, 'vnet/event/notifications'
  end

  module Endpoints
    autoload :Errors, 'vnet/endpoints/errors'
    autoload :ResponseGenerator, 'vnet/endpoints/response_generator'
    module V10
      autoload :Helpers, 'vnet/endpoints/1.0/helpers'
      autoload :VnetAPI, 'vnet/endpoints/1.0/vnet_api'
      module Responses
        autoload :Datapath, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetwork, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLink, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :IpAddress, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLease, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :Interface, 'vnet/endpoints/1.0/responses/interface'
        autoload :MacAddress, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLease, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :Network, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkService, 'vnet/endpoints/1.0/responses/network_service'
        autoload :Route, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLink, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SecurityGroup, 'vnet/endpoints/1.0/responses/security_group'
        autoload :VlanTranslation, 'vnet/endpoints/1.0/responses/vlan_translation'

        autoload :DatapathCollection, 'vnet/endpoints/1.0/responses/datapath'
        autoload :DatapathNetworkCollection, 'vnet/endpoints/1.0/responses/datapath_network'
        autoload :DatapathRouteLinkCollection, 'vnet/endpoints/1.0/responses/datapath_route_link'
        autoload :DhcpRangeCollection, 'vnet/endpoints/1.0/responses/dhcp_range'
        autoload :InterfaceCollection, 'vnet/endpoints/1.0/responses/interface'
        autoload :IpAddressCollection, 'vnet/endpoints/1.0/responses/ip_address'
        autoload :IpLeaseCollection, 'vnet/endpoints/1.0/responses/ip_lease'
        autoload :MacAddressCollection, 'vnet/endpoints/1.0/responses/mac_address'
        autoload :MacLeaseCollection, 'vnet/endpoints/1.0/responses/mac_lease'
        autoload :NetworkCollection, 'vnet/endpoints/1.0/responses/network'
        autoload :NetworkServiceCollection, 'vnet/endpoints/1.0/responses/network_service'
        autoload :RouteCollection, 'vnet/endpoints/1.0/responses/route'
        autoload :RouteLinkCollection, 'vnet/endpoints/1.0/responses/route_link'
        autoload :SecurityGroupCollection, 'vnet/endpoints/1.0/responses/security_group'
        autoload :VlanTranslationCollection, 'vnet/endpoints/1.0/responses/vlan_translation'
      end
    end
  end

  module Initializers
    autoload :DB, 'vnet/initializers/db'
  end

  module Models
    class InvalidUUIDError < StandardError; end
    autoload :Base, 'vnet/models/base'
    autoload :Datapath, 'vnet/models/datapath'
    autoload :DatapathNetwork, 'vnet/models/datapath_network'
    autoload :DatapathRouteLink, 'vnet/models/datapath_route_link'
    autoload :DcSegment, 'vnet/models/dc_segment'
    autoload :DhcpRange, 'vnet/models/dhcp_range'
    autoload :Interface, 'vnet/models/interface'
    autoload :InterfaceSecurityGroup, 'vnet/models/interface_security_group'
    autoload :IpAddress, 'vnet/models/ip_address'
    autoload :IpLease, 'vnet/models/ip_lease'
    autoload :MacAddress, 'vnet/models/mac_address'
    autoload :MacLease, 'vnet/models/mac_lease'
    autoload :Network, 'vnet/models/network'
    autoload :NetworkService, 'vnet/models/network_service'
    autoload :Route, 'vnet/models/route'
    autoload :RouteLink, 'vnet/models/route_link'
    autoload :SecurityGroup, 'vnet/models/security_group'
    autoload :Taggable, 'vnet/models/base'
    autoload :Tunnel, 'vnet/models/tunnel'
    autoload :VlanTranslation, 'vnet/models/vlan_translation'
  end

  module ModelWrappers
    autoload :Base, 'vnet/model_wrappers/base'
    autoload :Datapath, 'vnet/model_wrappers/datapath'
    autoload :DatapathNetwork, 'vnet/model_wrappers/datapath_network'
    autoload :DatapathRouteLink, 'vnet/model_wrappers/datapath_route_link'
    autoload :DcSegment, 'vnet/model_wrappers/dc_segment'
    autoload :DhcpRange, 'vnet/model_wrappers/dhcp_range'
    autoload :Helpers, 'vnet/model_wrappers/helpers'
    autoload :Interface, 'vnet/model_wrappers/interface'
    autoload :InterfaceSecurityGroup, 'vnet/model_wrappers/interface_security_group'
    autoload :IpAddress, 'vnet/model_wrappers/ip_address'
    autoload :IpLease, 'vnet/model_wrappers/ip_lease'
    autoload :MacAddress, 'vnet/model_wrappers/mac_address'
    autoload :MacLease, 'vnet/model_wrappers/mac_lease'
    autoload :Network, 'vnet/model_wrappers/network'
    autoload :NetworkService, 'vnet/model_wrappers/network_service'
    autoload :SecurityGroup, 'vnet/model_wrappers/security_group'
    autoload :Route, 'vnet/model_wrappers/route'
    autoload :RouteLink, 'vnet/model_wrappers/route_link'
    autoload :Tunnel, 'vnet/model_wrappers/tunnel'
    autoload :VlanTranslation, 'vnet/model_wrappers/vlan_translation'
  end

  autoload :NodeApi, 'vnet/node_api'
  module NodeApi
    autoload :RpcProxy, 'vnet/node_api/proxies'
    autoload :DirectProxy, 'vnet/node_api/proxies'
    autoload :Base, 'vnet/node_api/base'
    autoload :Datapath, 'vnet/node_api/models.rb'
    autoload :DatapathNetwork, 'vnet/node_api/models.rb'
    autoload :DcSegment, 'vnet/node_api/models.rb'
    autoload :DhcpRange, 'vnet/node_api/models.rb'
    autoload :Interface, 'vnet/node_api/interface.rb'
    autoload :IpAddress, 'vnet/node_api/models.rb'
    autoload :IpLease, 'vnet/node_api/ip_lease.rb'
    autoload :MacAddress, 'vnet/node_api/models.rb'
    autoload :MacLease, 'vnet/node_api/mac_lease.rb'
    autoload :Network, 'vnet/node_api/models.rb'
    autoload :NetworkService, 'vnet/node_api/network_service.rb'
    autoload :Route, 'vnet/node_api/models.rb'
    autoload :RouteLink, 'vnet/node_api/models.rb'
    autoload :SecurityGroup, 'vnet/node_api/models.rb'
    autoload :Tunnel, 'vnet/node_api/models.rb'
    autoload :VlanTranslation, 'vnet/node_api/models.rb'
  end

  module NodeModules
    autoload :Rpc, 'vnet/node_modules/rpc'
    autoload :EventHandler, 'vnet/node_modules/event_handler'
    autoload :ServiceOpenflow, 'vnet/node_modules/service_openflow'
    autoload :SwitchManager, 'vnet/node_modules/service_openflow'
  end

  module Openflow
    autoload :AddressHelpers, 'vnet/openflow/address_helpers'
    autoload :ArpLookup, 'vnet/openflow/arp_lookup'
    autoload :ConnectionManager, 'vnet/openflow/connection_manager'
    autoload :Controller, 'vnet/openflow/controller'
    autoload :Datapath, 'vnet/openflow/datapath'
    autoload :DatapathInfo, 'vnet/openflow/datapath'
    autoload :DatapathManager, 'vnet/openflow/datapath_manager'
    autoload :DcSegmentManager, 'vnet/openflow/dc_segment_manager'
    autoload :DpInfo, 'vnet/openflow/dp_info'
    autoload :Flow, 'vnet/openflow/flow'
    autoload :FlowHelpers, 'vnet/openflow/flow_helpers'
    autoload :Interface, 'vnet/openflow/interface'
    autoload :InterfaceManager, 'vnet/openflow/interface_manager'
    autoload :Manager, 'vnet/openflow/manager'
    autoload :MetadataHelpers, 'vnet/openflow/metadata_helpers'
    autoload :NetworkManager, 'vnet/openflow/network_manager'
    autoload :OvsOfctl, 'vnet/openflow/ovs_ofctl'
    autoload :PacketHelpers, 'vnet/openflow/packet_handler'
    autoload :PortManager, 'vnet/openflow/port_manager'
    autoload :RouteManager, 'vnet/openflow/route_manager'
    autoload :SecurityGroupManager, 'vnet/openflow/security_group_manager'
    autoload :Service, 'vnet/openflow/service'
    autoload :ServiceManager, 'vnet/openflow/service_manager'
    autoload :Switch, 'vnet/openflow/switch'
    autoload :TremaTasks, 'vnet/openflow/trema_tasks'
    autoload :TranslationManager, 'vnet/openflow/translation_manager'
    autoload :Tunnel, 'vnet/openflow/tunnel'
    autoload :TunnelManager, 'vnet/openflow/tunnel_manager'

    module Connections
      autoload :Base, 'vnet/openflow/connections/base'
      autoload :TCP, 'vnet/openflow/connections/tcp'
      autoload :UDP, 'vnet/openflow/connections/udp'
    end

    module Datapaths
      autoload :Base, 'vnet/openflow/datapaths/base'
    end

    module Interfaces
      autoload :Base, 'vnet/openflow/interfaces/base'
      autoload :Edge, 'vnet/openflow/interfaces/edge'
      autoload :Host, 'vnet/openflow/interfaces/host'
      autoload :IfBase, 'vnet/openflow/interfaces/if_base'
      autoload :Remote, 'vnet/openflow/interfaces/remote'
      autoload :Simulated, 'vnet/openflow/interfaces/simulated'
      autoload :Vif, 'vnet/openflow/interfaces/vif'
    end

    module Networks
      autoload :Base, 'vnet/openflow/networks/base'
      autoload :Physical, 'vnet/openflow/networks/physical'
      autoload :Virtual, 'vnet/openflow/networks/virtual'
    end

    module Ports
      autoload :Base, 'vnet/openflow/ports/base'
      autoload :Generic, 'vnet/openflow/ports/generic'
      autoload :Host, 'vnet/openflow/ports/host'
      autoload :Local, 'vnet/openflow/ports/local'
      autoload :Tunnel, 'vnet/openflow/ports/tunnel'
      autoload :Vif, 'vnet/openflow/ports/vif'
    end

    module Routes
      autoload :Base, 'vnet/openflow/routes/base'
    end

    module Routers
      autoload :RouteLink, 'vnet/openflow/routers/route_link'
    end

    module SecurityGroups
      autoload :Group, 'vnet/openflow/security_groups/group'
      autoload :Rule, 'vnet/openflow/security_groups/rules'
      autoload :ICMP, 'vnet/openflow/security_groups/rules'
      autoload :TCP, 'vnet/openflow/security_groups/rules'
      autoload :UDP, 'vnet/openflow/security_groups/rules'
    end

    module Services
      autoload :Base, 'vnet/openflow/services/base'
      autoload :Dhcp, 'vnet/openflow/services/dhcp'
      autoload :Router, 'vnet/openflow/services/router'
    end

    module Tunnels
      autoload :Base, 'vnet/openflow/tunnels/base'
    end

    module Translations
      autoload :VnetEdgeHandler, 'vnet/openflow/translations/vnet_edge_handler'
    end

  end

end
