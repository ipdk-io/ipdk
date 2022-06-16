/*********************************************************
* Copyright(c) 2021 Intel Corporation
***********************************************************/

#include <core.p4>
#include <psa.p4>
#include "protocols.p4"

parser packet_parser(packet_in packet,
                     out headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_ingress_parser_input_metadata_t istd,
                     in empty_metadata_t resub_meta,
                     in empty_metadata_t recirc_meta) {
    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(headers.eth);
        transition select(headers.eth.ethtype) {
                      ETHER_TYPE_IPV4: parse_ipv4;
		      default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(headers.ipv4);
        transition select (headers.ipv4.proto){
                      IP_PROTO_TCP: tcp;
                      IP_PROTO_UDP: udp;
		      default: accept;
        }
    }
    state tcp {
        packet.extract(headers.tcp);
        transition accept;
    }
    state udp {
            packet.extract(headers.udp);
            transition accept;
    }
}

control packet_deparser(packet_out packet,
                        out empty_metadata_t clone_i2e_meta,
                        out empty_metadata_t resubmit_meta,
                        out empty_metadata_t normal_meta,
                        inout headers_t headers,
                        in local_metadata_t local_metadata,
                        in psa_ingress_output_metadata_t istd) {
    apply {
        packet.emit(headers.eth);
        packet.emit(headers.ipv4);
        packet.emit(headers.tcp);
        packet.emit(headers.udp);
    }
}

parser egress_parser(packet_in buffer,
                     out headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_egress_parser_input_metadata_t istd,
                     in empty_metadata_t normal_meta,
                     in empty_metadata_t clone_i2e_meta,
                     in empty_metadata_t clone_e2e_meta) {
    state start {
        transition accept;
    }
}

control egress_deparser(packet_out packet,
                        out empty_metadata_t clone_e2e_meta,
                        out empty_metadata_t recirculate_meta,
                        inout headers_t headers,
                        in local_metadata_t local_metadata,
                        in psa_egress_output_metadata_t istd,
                        in psa_egress_deparser_input_metadata_t edstd) {
    apply {
    }
}
