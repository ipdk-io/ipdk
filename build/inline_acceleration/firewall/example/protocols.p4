/**********************************************************
* Copyright(c) 2021 Intel Corporation
***********************************************************/

#ifndef _PROTOCOLS_H_
#define _PROTOCOLS_H_

const bit<16> ETHER_TYPE_IPV4           = 0x0800;
const bit<16> ETHER_TYPE_IPV6           = 0x86DD;
const bit<16> ETHER_TYPE_VLAN           = 0x8100;
const bit<8> IP_PROTO_ICMP              = 1;
const bit<8> IP_PROTO_TCP               = 6;
const bit<8> IP_PROTO_UDP               = 17;
const bit<8> IP_PROTO_ESP               = 50;

const bit<8> GTP_V1                     = 0x1;
const bit<16> UDP_PORT_GTPC             = 2123;
const bit<16> UDP_PORT_GTPU             = 2152;
const bit<8> GTPU_MESSAGE_TYPE_GPDU     = 255;
const bit<32> EXCEPTION_PORT_INGRESS    = 1;/*Exception port for Ingress flows*/
const bit<32> EXCEPTION_PORT_EGRESS     = 2;/*Exception port for Egress flows*/
const bit<32> EXCEPTION_PORT            = 1;/*Exception port*/
const bit<8> DIRECTION_UNKNOWN          = 0;
const bit<8> DIRECTION_INGRESS          = 1;
const bit<8> DIRECTION_EGRESS           = 2;

error {
    InvalidEthernetType,
    BadIPv4HeaderChecksum
}

struct empty_metadata_t {
}

header ethernet_t {
    bit<48> dmac;           /* destination mac address */
    bit<48> smac;           /* source mac address */
    bit<16> ethtype;        /* ethernet type */
}

header ipv4_t {
    bit<8> ver_ihl;         /* version:4, ihl:4 */
    bit<8> diffserv;        /* dscp:6, ecn:2 */
    bit<16> total_len;      /* length of payload including IP header */
    bit<16> identification; /* ID of fragments */
    bit<16> flags_offset;   /* rsvd:1, df:1, mf:1, frag_off:13 */
    bit<8> ttl;             /* time-to-live */
    bit<8> proto;           /* next protocol after ipv4 headr */
    bit<16> checksum;       /* checksum */
    bit<32> saddr;          /* source IP address */
    bit<32> daddr;          /* destination IP address */
}

header udp_t {
    bit<16> sport;          /* source UDP port */
    bit<16> dport;          /* destination UDP port */
    bit<16> length;         /* length of payload including UDP header */
    bit<16> checksum;       /* checksum for header and payload */
}

header tcp_t {
    bit<16>  sport;         /* source TCP port */
    bit<16>  dport;         /* destination TCP port */
    bit<32>  seqno;         /* segment sequence number */
    bit<32>  ackno;         /* acknowledgement number  */
    bit<16>  offset_flags;  /* offset:4 (size of header in 4-bytes), rsvd:3, flags:9 */
                            /* flags: NS:1, CWR:1, ECE:1, URG:1, ACK:1, PSH:1, RST:1, SYN:1, FIN:1 */
    bit<16>  window;        /* size of receive window */
    bit<16>  csum;          /* checksum for header and payload */
    bit<16>  urgptr;        /* offset from seq number of last urgent byte */
}

header gtp1_t {
    bit<8> ver_flags;       /* version:3, proto_type:1, rsvd:1, extention_header(E):1, seq_num(S):1, npdu_num(PN):1 */
    bit<8> msgtype;         /* GTP message type */
    bit<16> msglen;         /* length of payload including GTP optional header */
    bit<32> teid;           /* tunnel endpoint ID */
}

header gtp1_opt_t {
    bit<16> seqno;          /* sequence number, interpreted only if S bit is on */
    bit<8> npdu;            /* N-PDU number, interpreted only if PN bit is on */
    bit<8> next_hdr;        /* extension header type, interpreted only if E bit is on */
}

struct headers_t {
    ethernet_t eth;         /* ethernet header */
    ipv4_t ipv4;            /* IPv4 header */
    udp_t udp;              /* UDP header */
    tcp_t tcp;              /* TCP header */
    gtp1_t gtp;             /* GTPv1 header */
    ipv4_t inner_ipv4;      /* Inner IPv4 header */
    udp_t inner_udp;        /* Inner UDP header */
    gtp1_opt_t gtp_opt;     /* gtp optional header */
}

struct local_metadata_t {
    bit<48> dmac;           /* destination MAC address */
    bit<48> smac;           /* source MAC address */
    bit<32> saddr;          /* source IPv4 address */
    bit<32> daddr;          /* destination IPv4 address */
    bit<8>  direction;     /* direction */
    bit<16> sport;          /* source UDP/TCP port */
    bit<16> dport;          /* destination UDP/TCP port */
    bit<32> teid;           /* tunnel endpoint ID */
}

#endif // _PROTOCOLS_H_
