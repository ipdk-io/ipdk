/**********************************************************
* Copyright(c) 2021 Intel Corporation
***********************************************************/

#include <core.p4>
#include <psa.p4>
#include "protocols.p4"
#include "firewall_parser.p4"

control ingress(inout headers_t headers,
                inout local_metadata_t local_metadata1,
                in psa_ingress_input_metadata_t istd,
                inout psa_ingress_output_metadata_t ostd) {
//     action drop(){
//               ostd.drop = true;
//     }
    action ipv4_forward(PortId_t port) {
        ostd.egress_port = (PortId_t)port;
    }
    action set_direction(bit<8> dir){
        local_metadata1.direction = dir;
    }
    action set_nodirection(){
        local_metadata1.direction = DIRECTION_UNKNOWN;
    }
    action carry_port2(PortId_t port ) {
        ostd.egress_port = (PortId_t)port;
    }
    action forward_exception_port(bit<32> port) {
            /* sending packets to exception port */
        ostd.egress_port = (PortId_t)port;
    }
    action packet_exception() {
        if(local_metadata1.direction == DIRECTION_UNKNOWN){
            forward_exception_port(EXCEPTION_PORT);
        }
        if(local_metadata1.direction == DIRECTION_INGRESS){
            forward_exception_port(EXCEPTION_PORT_INGRESS);
		}
        if(local_metadata1.direction == DIRECTION_EGRESS){
            forward_exception_port(EXCEPTION_PORT_EGRESS);
		}
    }
    table fw_direction {
        key = {
            headers.ipv4.daddr: lpm;
        }
        actions={
            set_direction;
            set_nodirection;
	    forward_exception_port;
        }
        size = 1024;
        default_action =set_nodirection();
    }
    table egress_default {
      key = {
          istd.ingress_port : exact;
      }
      actions={
          carry_port2;
      }
    size =1024;
    }
    table firewall {
        key = {
            headers.ipv4.saddr: exact;
            headers.ipv4.daddr: exact;
            headers.ipv4.proto: exact;
            headers.tcp.sport: exact;
            headers.tcp.dport: exact;
        }
        actions = {
            ipv4_forward;
        //     drop;
	    packet_exception;
        }
        size = 1024;
        default_action = packet_exception();
    }
    apply {
	 if (headers.eth.isValid() &&
	       headers.ipv4.isValid()){
	       fw_direction.apply();
	} else {
		ostd.drop = true;
		return;
	}
	if(local_metadata1.direction == DIRECTION_UNKNOWN){
			forward_exception_port(EXCEPTION_PORT);
			egress_default.apply();
       	    		return;
       	}

        if(istd.parser_error != error.NoError){
            if(local_metadata1.direction == DIRECTION_INGRESS){
                forward_exception_port(EXCEPTION_PORT_INGRESS);
			}
            if(local_metadata1.direction == DIRECTION_EGRESS){
                forward_exception_port(EXCEPTION_PORT_EGRESS);
			}
            return;
        }
        firewall.apply();
    }
}

control egress(inout headers_t headers,
               inout local_metadata_t local_metadata,
               in psa_egress_input_metadata_t istd,
               inout psa_egress_output_metadata_t ostd) {
    apply {
    }
}

IngressPipeline(packet_parser(),
                ingress(),
                packet_deparser()) pipe;

EgressPipeline(egress_parser(),
               egress(),
               egress_deparser()) egress_pipe;

PSA_Switch(pipe,
           PacketReplicationEngine(),
           egress_pipe,
           BufferingQueueingEngine()) main;
