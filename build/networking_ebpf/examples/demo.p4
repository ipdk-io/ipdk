#include <core.p4>
#include <psa.p4>

const bit<16> ETH_TYPE_IPV4 = 0x0800;
const bit<16> ETH_TYPE_ARP = 0x0806;
const bit<8> PROTO_ICMP = 1;
const bit<8> PROTO_TCP = 6;
const bit<8> PROTO_UDP = 17;

const bit<16> ARP_OPCODE_REPLY = 2;

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<6>      dscp;
    bit<2>      ecn;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_t {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_t {
    bit<16> sport;
    bit<16> dport;
    bit<16> len;
    bit<16> checksum;
}

header arp_t {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
}

header arp_ipv4_t {
    mac_addr_t  src_hw_addr;
    ipv4_addr_t src_ipv4_addr;
    mac_addr_t  dst_hw_addr;
    ipv4_addr_t dst_ipv4_addr;
}

struct metadata {
    bit<16> l4_sport;
    bit<16> l4_dport;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
    udp_t      udp;
    arp_t      arp;
    arp_ipv4_t arp_ipv4;
}

struct empty_t {}

// ---------------------------------------------------------
//                      I N G R E S S
// ---------------------------------------------------------

parser DemoIngressParser(packet_in packet,
                         out       headers hdr,
                         inout     metadata meta,
                         in        psa_ingress_parser_input_metadata_t istd,
                         in        empty_t resubmit_meta,
                         in        empty_t recirculate_meta) {
    
    InternetChecksum() ck;
    
    state start {
        meta.l4_dport = 0;
        meta.l4_sport = 0;
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETH_TYPE_IPV4: parse_ipv4;
            ETH_TYPE_ARP:  parse_arp;
            default:       reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);

        ck.clear();
        ck.subtract(hdr.ipv4.checksum);
        ck.subtract({
                hdr.ipv4.ttl, hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        hdr.ipv4.checksum = ck.get_state();
        
        transition select(hdr.ipv4.protocol) {
            PROTO_ICMP: accept;
            PROTO_TCP:  parse_tcp;
            PROTO_UDP:  parse_udp;
            default:    reject;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        meta.l4_dport = hdr.tcp.dport;
        meta.l4_sport = hdr.tcp.sport;

        ck.clear();
        ck.subtract(hdr.tcp.checksum);
        ck.subtract({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        hdr.tcp.checksum = ck.get_state();

        transition accept;
    }
        

    state parse_udp {
        packet.extract(hdr.udp);
        meta.l4_dport = hdr.udp.dport;
        meta.l4_sport = hdr.udp.sport;
        transition select(hdr.udp.checksum) {
            0:       accept;
            default: update_udp_checksum;
        }
    }

    state update_udp_checksum {
        ck.clear();
        ck.subtract(hdr.udp.checksum);
        ck.subtract({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        // we can't get internal state due to its value is allowed to be 0,
        // so we will be unable to detect if checksum is valid when use internal state.
        hdr.udp.checksum = ck.get();

        transition accept;
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition select(hdr.arp.hw_type, hdr.arp.proto_type) {
            (0x0001, ETH_TYPE_IPV4): parse_arp_ipv4;  // Ethernet + IPv4 protocol stack
            default:                 reject;
        }
    }

    state parse_arp_ipv4 {
        packet.extract(hdr.arp_ipv4);
        transition accept;
    }
}

control DemoIngress(inout headers hdr,
                    inout metadata meta,
                    in    psa_ingress_input_metadata_t  istd,
                    inout psa_ingress_output_metadata_t ostd) {
    Meter<PortId_t>(100, PSA_MeterType_t.BYTES) meter;

    action forward(PortId_t port, mac_addr_t src_addr, mac_addr_t dst_addr) {
        PortId_t idx = port;
        if (meter.execute(idx) != PSA_MeterColor_t.RED) {
            send_to_port(ostd, port);
            hdr.ethernet.src_addr = src_addr;
            hdr.ethernet.dst_addr = dst_addr;
        } else {
            ingress_drop(ostd);
        }
    }

    action send_arp_reply(mac_addr_t src_addr) {
        forward(istd.ingress_port, src_addr, hdr.arp_ipv4.src_hw_addr);

        hdr.arp.opcode = ARP_OPCODE_REPLY;
        hdr.arp_ipv4.dst_hw_addr = hdr.arp_ipv4.src_hw_addr;
        hdr.arp_ipv4.src_hw_addr = src_addr;
        ipv4_addr_t tmp = hdr.arp_ipv4.dst_ipv4_addr;
        hdr.arp_ipv4.dst_ipv4_addr = hdr.arp_ipv4.src_ipv4_addr;
        hdr.arp_ipv4.src_ipv4_addr = tmp;
    }

    table tbl_arp_ipv4 {
        key = {
            istd.ingress_port          : exact;
            hdr.arp.opcode             : exact;
            hdr.arp_ipv4.dst_ipv4_addr : lpm;
        }
        actions = {
            NoAction;
            ingress_drop(ostd);
            send_arp_reply;
        }
        size = 256;
        default_action = ingress_drop(ostd);
    }
    
    ActionSelector(PSA_HashAlgorithm_t.CRC16, 32w512, 32w16) as;

    action forward_balance(PortId_t port, mac_addr_t src_addr, mac_addr_t dst_addr,
                           ipv4_addr_t dst_ip) {
        forward(port, src_addr, dst_addr);
        hdr.ipv4.dst_addr = dst_ip;
    }

    action forward_set_vip(PortId_t port, mac_addr_t src_addr, mac_addr_t dst_addr,
                           ipv4_addr_t vip) {
        forward(port, src_addr, dst_addr);
        hdr.ipv4.src_addr = vip;
    }

    table tbl_routing {
        key = {
            hdr.ipv4.dst_addr : lpm;
            hdr.ipv4.protocol : selector;
            hdr.ipv4.src_addr : selector;
            hdr.ipv4.dst_addr : selector;
            meta.l4_sport     : selector;
            meta.l4_dport     : selector;
        }
        actions = {
            NoAction;
            forward;
            forward_balance;
            forward_set_vip;
        }
        size = 256;
        psa_implementation = as;
    }

    action set_priority() {
        ostd.class_of_service = (ClassOfService_t) 10;
    }

    table qos_classifier {
        key = {
            hdr.ipv4.protocol : exact;
        }
        actions = {
            NoAction;
            set_priority;
        }
        size = 4;
        default_action = NoAction;
    }

    apply {
        if (hdr.arp.isValid()) {
            if (hdr.arp_ipv4.isValid()) {
                tbl_arp_ipv4.apply();
            } else {
                ingress_drop(ostd);
            }
            exit;
        }

        tbl_routing.apply();
        qos_classifier.apply();

        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        if (hdr.ipv4.ttl < 2) {
            ingress_drop(ostd);
        }
    }
}

control DemoIngressDeparser(packet_out packet,
                            out        empty_t clone_i2e_meta,
                            out        empty_t resubmit_meta,
                            out        empty_t normal_meta,
                            inout      headers hdr,
                            in         metadata meta,
                            in         psa_ingress_output_metadata_t istd) {
    
    InternetChecksum() ck;

    apply {
        if (hdr.ipv4.isValid()) {
            ck.set_state(hdr.ipv4.checksum);
            ck.add({
                    hdr.ipv4.ttl, hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr
                });
            hdr.ipv4.checksum = ck.get();
        }

        if (hdr.tcp.isValid()) {
            ck.set_state(hdr.tcp.checksum);
            ck.add({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr
                });
            hdr.tcp.checksum = ck.get();
        }

        if (hdr.udp.isValid() && hdr.udp.checksum != 0) {
            ck.clear();
            ck.subtract(hdr.udp.checksum);
            ck.add({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr
                });
            hdr.udp.checksum = ck.get();
        }

        packet.emit(hdr.ethernet);

        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);

        packet.emit(hdr.arp);
        packet.emit(hdr.arp_ipv4);
    }
}

// ---------------------------------------------------------
//                      E G R E S S
// ---------------------------------------------------------

parser DemoEgressParser(packet_in buffer,
                        out       headers hdr,
                        inout     metadata meta,
                        in        psa_egress_parser_input_metadata_t istd,
                        in        empty_t normal_meta,
                        in        empty_t clone_i2e_meta,
                        in        empty_t clone_e2e_meta) {

    state start {
        transition accept;
    }
}

control DemoEgress(inout headers hdr,
                   inout metadata meta,
                   in    psa_egress_input_metadata_t  istd,
                   inout psa_egress_output_metadata_t ostd) {

    apply {
    }
}

control DemoEgressDeparser(packet_out packet,
                           out        empty_t clone_e2e_meta,
                           out        empty_t recirculate_meta,
                           inout      headers hdr,
                           in         metadata meta,
                           in         psa_egress_output_metadata_t istd,
                           in         psa_egress_deparser_input_metadata_t edstd) {

    apply {
    }
}

IngressPipeline(DemoIngressParser(), DemoIngress(), DemoIngressDeparser()) ip;
EgressPipeline(DemoEgressParser(), DemoEgress(), DemoEgressDeparser()) ep;

PSA_Switch(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
