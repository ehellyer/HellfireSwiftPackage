/*
 * A JavaScript implementation of the RSA Data Security, Inc. MD5 Message
 * Digest Algorithm, as defined in RFC 1321.
 * Version 2.2 Copyright (C) Paul Johnston 1999 - 2009
 * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
 * Distributed under the BSD License
 * See http://pajhome.org.uk/crypt/md5 for more info.
 */

/*
 *  SwiftHash
 *  Copyright (c) Khoa Pham 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

//
//  MD5Hash.swift
//  HellFire
//
//  This file has been modified slightly from it's original source to suite the needs of this project.
//  MD5 specs: https://www.ietf.org/rfc/rfc1321.txt
//  JS source: http://pajhome.org.uk/crypt/md5/md5.html
//  Created by Ed Hellyer on 2/1/20.
//
//  MD5 hash, developed by Ronald Rivest
//  Released April 1992 - Replaced MD4, 128 bit hash value
//  Collisions discovered in 1996
//  CA Certificate forged in December 2008 using MD5 collision.

import Foundation

internal class MD5Hash {
    
    //MARK: - Public API
    
    /// Performs an MD5 hash on the Swift unicode input string and returns the resulting hash as a Swift unicode string.
    /// - Parameter input: The Swift unicode input string to be hashed using the MD5 algorithm.
    /// - Returns: An MD5 hash of the input string as a Swift unicode string.
    func MD5(_ input: String) -> String {
        let utf8Array = self.utf8CharArray(input)
        let str = self.rstr_md5(utf8Array)
        return self.rstr2hex(str)
    }
    
    //MARK: - Private API
    
    /// Converts a Swift string into an array of C 'unsigned char' type 8 bit integers.
    /// - Parameter input: The input string to be converted.
    /// - Returns: A character byte array of unsigned 8-bit integers
    private func utf8CharArray(_ input: String) -> [CUnsignedChar] {
        return Array(input.utf8)
    }
    
    /// Converts an array of C 'unsigned char' type 8 bit integers into unicode scalar Swift string.
    /// - Parameter input: An array of C 'unsigned char' type 8 bit integers.
    /// - Returns: A unicode scalar Swift string.
    private func rstr2tr(_ input: [CUnsignedChar]) -> String {
        var output: String = ""
        
        input.forEach {
            output.append(String(Unicode.Scalar($0)))
        }
        
        return output
    }
    
    /// Convert a character byte array of unsigned 8-bit integers into Swift string.
    /// - Parameter input: Convert a character byte array of unsigned 8-bit integers.
    /// - Returns: A hexadecimal value of each input character is concatenated into a swift return string.
    private func rstr2hex(_ input: [CUnsignedChar]) -> String {
        let hexTab: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        var output: [Character] = []
        
        for i in 0..<input.count {
            let x = input[i]
            let value1 = hexTab[Int((x >> 4) & 0x0F)]
            let value2 = hexTab[Int(Int32(x) & 0x0F)]
            
            output.append(value1)
            output.append(value2)
        }
        
        return String(output)
    }
    
    // Convert a raw string to an array of little-endian words
    // Characters >255 have their high-byte silently ignored.
    private func rstr2binl(_ input: [CUnsignedChar]) -> [Int32] {
        var output: [Int: Int32] = [:]
        
        for i in stride(from: 0, to: input.count * 8, by: 8) {
            let value: Int32 = (Int32(input[i/8]) & 0xFF) << (Int32(i) % 32)
            
            output[i >> 5] = (output[i >> 5] ?? 0) | value
        }
        
        return dictionary2array(output)
    }
    
    // Convert an array of little-endian words to a string
    private func binl2rstr(_ input: [Int32]) -> [CUnsignedChar] {
        var output: [CUnsignedChar] = []
        
        for i in stride(from: 0, to: input.count * 32, by: 8) {
            let value: Int32 = zeroFillRightShift(input[i>>5], Int32(i % 32)) & 0xFF
            output.append(CUnsignedChar(value))
        }
        
        return output
    }
    
    /// Returns a character byte array of unsigned 8-bit integers that represents the hash of the input array.
    /// - Parameter input: A character byte array of unsigned 8-bit integers to be hashed
    /// - Returns: A character byte array of unsigned 8-bit integers
    private func rstr_md5(_ input: [CUnsignedChar]) -> [CUnsignedChar] {
        return binl2rstr(binl_md5(rstr2binl(input), input.count * 8))
    }
    
    
    /// Returns the sum of the two given values, wrapping the result in case of any overflow, as a signed Int32.
    ///
    /// The safe addition function discards any bits that overflow the 32 bit integer type.
    ///
    /// - Parameters:
    ///   - x: Int32 input
    ///   - y: Int32 input
    /// - Returns: Returns Int32 result.
    private func safe_add(_ x: Int32, _ y: Int32) -> Int32 {
        return x &+ y
    }
    
    // Bitwise rotate a 32-bit number to the left.
    private func bit_rol(_ num: Int32, _ cnt: Int32) -> Int32 {
        // num >>>
        return (num << cnt) | zeroFillRightShift(num, (32 - cnt))
    }
    
    
    // These funcs implement the four basic operations the algorithm uses.
    private func md5_cmn(_ q: Int32, _ a: Int32, _ b: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b)
    }
    
    private func md5_ff(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t)
    }
    
    private func md5_gg(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t)
    }
    
    private func md5_hh(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(b ^ c ^ d, a, b, x, s, t)
    }
    
    private func md5_ii(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(c ^ (b | (~d)), a, b, x, s, t)
    }
    
    
    // Calculate the MD5 of an array of little-endian words, and a bit length.
    private func binl_md5(_ input: [Int32], _ len: Int) -> [Int32] {
        /* append padding */
        
        var x: [Int: Int32] = [:]
        for (index, value) in input.enumerated() {
            x[index] = value
        }
        
        let value: Int32 = 0x80 << Int32((len) % 32)
        x[len >> 5] = unwrap(x[len >> 5]) | value
        
        // >>> 9
        let index = (((len + 64) >> 9) << 4) + 14
        x[index] = unwrap(x[index]) | Int32(len)
        
        var a: Int32 =  1732584193
        var b: Int32 = -271733879
        var c: Int32 = -1732584194
        var d: Int32 =  271733878
        
        for i in stride(from: 0, to: length(x), by: 16) {
            let olda: Int32 = a
            let oldb: Int32 = b
            let oldc: Int32 = c
            let oldd: Int32 = d
            
            a = md5_ff(a, b, c, d, unwrap(x[i + 0]), 7 , -680876936)
            d = md5_ff(d, a, b, c, unwrap(x[i + 1]), 12, -389564586)
            c = md5_ff(c, d, a, b, unwrap(x[i + 2]), 17,  606105819)
            b = md5_ff(b, c, d, a, unwrap(x[i + 3]), 22, -1044525330)
            a = md5_ff(a, b, c, d, unwrap(x[i + 4]), 7 , -176418897)
            d = md5_ff(d, a, b, c, unwrap(x[i + 5]), 12,  1200080426)
            c = md5_ff(c, d, a, b, unwrap(x[i + 6]), 17, -1473231341)
            b = md5_ff(b, c, d, a, unwrap(x[i + 7]), 22, -45705983)
            a = md5_ff(a, b, c, d, unwrap(x[i + 8]), 7 ,  1770035416)
            d = md5_ff(d, a, b, c, unwrap(x[i + 9]), 12, -1958414417)
            c = md5_ff(c, d, a, b, unwrap(x[i + 10]), 17, -42063)
            b = md5_ff(b, c, d, a, unwrap(x[i + 11]), 22, -1990404162)
            a = md5_ff(a, b, c, d, unwrap(x[i + 12]), 7 ,  1804603682)
            d = md5_ff(d, a, b, c, unwrap(x[i + 13]), 12, -40341101)
            c = md5_ff(c, d, a, b, unwrap(x[i + 14]), 17, -1502002290)
            b = md5_ff(b, c, d, a, unwrap(x[i + 15]), 22,  1236535329)
            
            a = md5_gg(a, b, c, d, unwrap(x[i + 1]), 5 , -165796510)
            d = md5_gg(d, a, b, c, unwrap(x[i + 6]), 9 , -1069501632)
            c = md5_gg(c, d, a, b, unwrap(x[i + 11]), 14,  643717713)
            b = md5_gg(b, c, d, a, unwrap(x[i + 0]), 20, -373897302)
            a = md5_gg(a, b, c, d, unwrap(x[i + 5]), 5 , -701558691)
            d = md5_gg(d, a, b, c, unwrap(x[i + 10]), 9 ,  38016083)
            c = md5_gg(c, d, a, b, unwrap(x[i + 15]), 14, -660478335)
            b = md5_gg(b, c, d, a, unwrap(x[i + 4]), 20, -405537848)
            a = md5_gg(a, b, c, d, unwrap(x[i + 9]), 5 ,  568446438)
            d = md5_gg(d, a, b, c, unwrap(x[i + 14]), 9 , -1019803690)
            c = md5_gg(c, d, a, b, unwrap(x[i + 3]), 14, -187363961)
            b = md5_gg(b, c, d, a, unwrap(x[i + 8]), 20,  1163531501)
            a = md5_gg(a, b, c, d, unwrap(x[i + 13]), 5 , -1444681467)
            d = md5_gg(d, a, b, c, unwrap(x[i + 2]), 9 , -51403784)
            c = md5_gg(c, d, a, b, unwrap(x[i + 7]), 14,  1735328473)
            b = md5_gg(b, c, d, a, unwrap(x[i + 12]), 20, -1926607734)
            
            a = md5_hh(a, b, c, d, unwrap(x[i + 5]), 4 , -378558)
            d = md5_hh(d, a, b, c, unwrap(x[i + 8]), 11, -2022574463)
            c = md5_hh(c, d, a, b, unwrap(x[i + 11]), 16,  1839030562)
            b = md5_hh(b, c, d, a, unwrap(x[i + 14]), 23, -35309556)
            a = md5_hh(a, b, c, d, unwrap(x[i + 1]), 4 , -1530992060)
            d = md5_hh(d, a, b, c, unwrap(x[i + 4]), 11,  1272893353)
            c = md5_hh(c, d, a, b, unwrap(x[i + 7]), 16, -155497632)
            b = md5_hh(b, c, d, a, unwrap(x[i + 10]), 23, -1094730640)
            a = md5_hh(a, b, c, d, unwrap(x[i + 13]), 4 ,  681279174)
            d = md5_hh(d, a, b, c, unwrap(x[i + 0]), 11, -358537222)
            c = md5_hh(c, d, a, b, unwrap(x[i + 3]), 16, -722521979)
            b = md5_hh(b, c, d, a, unwrap(x[i + 6]), 23,  76029189)
            a = md5_hh(a, b, c, d, unwrap(x[i + 9]), 4 , -640364487)
            d = md5_hh(d, a, b, c, unwrap(x[i + 12]), 11, -421815835)
            c = md5_hh(c, d, a, b, unwrap(x[i + 15]), 16,  530742520)
            b = md5_hh(b, c, d, a, unwrap(x[i + 2]), 23, -995338651)
            
            a = md5_ii(a, b, c, d, unwrap(x[i + 0]), 6 , -198630844)
            d = md5_ii(d, a, b, c, unwrap(x[i + 7]), 10,  1126891415)
            c = md5_ii(c, d, a, b, unwrap(x[i + 14]), 15, -1416354905)
            b = md5_ii(b, c, d, a, unwrap(x[i + 5]), 21, -57434055)
            a = md5_ii(a, b, c, d, unwrap(x[i + 12]), 6 ,  1700485571)
            d = md5_ii(d, a, b, c, unwrap(x[i + 3]), 10, -1894986606)
            c = md5_ii(c, d, a, b, unwrap(x[i + 10]), 15, -1051523)
            b = md5_ii(b, c, d, a, unwrap(x[i + 1]), 21, -2054922799)
            a = md5_ii(a, b, c, d, unwrap(x[i + 8]), 6 ,  1873313359)
            d = md5_ii(d, a, b, c, unwrap(x[i + 15]), 10, -30611744)
            c = md5_ii(c, d, a, b, unwrap(x[i + 6]), 15, -1560198380)
            b = md5_ii(b, c, d, a, unwrap(x[i + 13]), 21,  1309151649)
            a = md5_ii(a, b, c, d, unwrap(x[i + 4]), 6 , -145523070)
            d = md5_ii(d, a, b, c, unwrap(x[i + 11]), 10, -1120210379)
            c = md5_ii(c, d, a, b, unwrap(x[i + 2]), 15,  718787259)
            b = md5_ii(b, c, d, a, unwrap(x[i + 9]), 21, -343485551)
            
            a = safe_add(a, olda)
            b = safe_add(b, oldb)
            c = safe_add(c, oldc)
            d = safe_add(d, oldd)
        }
        
        return [a, b, c, d]
    }
    
    //MARK: - Private API Helper funcs
    
    private func length(_ dictionary: [Int: Int32]) -> Int {
        return (dictionary.keys.max() ?? 0) + 1
    }
    
    private func dictionary2array(_ dictionary: [Int: Int32]) -> [Int32] {
        var array = Array<Int32>(repeating: 0, count: dictionary.keys.count)
        
        for i in Array(dictionary.keys).sorted() {
            array[i] = unwrap(dictionary[i])
        }
        
        return array
    }
    
    private func unwrap(_ value: Int32?, _ fallback: Int32 = 0) -> Int32 {
        return value ?? fallback
    }
    
    private func zeroFillRightShift(_ num: Int32, _ count: Int32) -> Int32 {
        let value = UInt32(bitPattern: num) >> UInt32(bitPattern: count)
        return Int32(bitPattern: value)
    }
}
