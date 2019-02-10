#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# https://www.decentlab.com/support

import logging
import os
import struct
from base64 import binascii
import json

PROTOCOL_VERSION = 2
SENSORS = [
    {'length': 2,
     'values': [{'name': 'Air temperature',
                 'convert': lambda x: 175.72 * x[0] / 65536 - 46.85,
                 'unit': '°C'},
                {'name': 'Air humidity',
                 'convert': lambda x: 125 * x[1] / 65536 - 6,
                 'unit': '%'}]},
    {'length': 1,
     'values': [{'name': 'Battery voltage',
                 'convert': lambda x: x[0] / 1000,
                 'unit': 'V'}]}
]


def decode(msg):
    """msg: payload as one of hex string, list, or bytearray"""
    bytes_ = bytearray(binascii.a2b_hex(msg)
                       if isinstance(msg, str)
                        else msg)
    version = bytes_[0]
    if version != PROTOCOL_VERSION:
        raise ValueError("protocol version {} doesn't match v2".format(version))

    devid = struct.unpack('>H', bytes_[1:3])[0]
    bin_flags = bin(struct.unpack('>H', bytes_[3:5])[0])
    flags = bin_flags[2:].zfill(struct.calcsize('>H') * 8)[::-1]

    words = [struct.unpack('>H', bytes_[i:i + 2])[0]
             for i
             in range(5, len(bytes_), 2)]

    cur = 0
    result = {'Device ID': devid, 'Protocol version': version}
    for flag, sensor in zip(flags, SENSORS):
        if flag != '1':
            continue

        x = words[cur:cur + sensor["length"]]
        cur += sensor["length"]
        for value in sensor['values']:
            if 'convert' not in value:
                continue

            result[value['name']] = {'value': value['convert'](x),
                                     'unit': value.get('unit', None)}

    return result


if __name__ == '__main__':

    import pprint
    payloads = [
        '02030e000364a079b10c60',
        '02030e00020c60',
    ]
    for pl in payloads:
        pprint.pprint(decode(pl))
        print("")
