---
name: crypto-challenge
description: |
  Crypto challenge solver — RSA, XOR, AES, hash, encoding, ciphers.
  Kata kunci: crypto, rsa, xor, aes, base64, hex, caesar, vigenere, hash, md5, sha, crack, decrypt, cipher.
---

# SKILL: Crypto Challenges — CTF Focus

> **Trigger:** User minta decrypt, crack hash, solve crypto challenge, atau analisis cipher.

---

## 0. Quick Decode — Coba Ini Dulu

```bash
# Base64
echo "ZmxhZ3t0ZXN0fQ==" | base64 -d

# Hex
echo "666c61677b746573747d" | xxd -r -p

# URL encoding
python3 -c "import urllib.parse; print(urllib.parse.unquote('%66%6c%61%67'))"

# ROT13
echo "synt{grfg}" | tr 'A-Za-z' 'N-ZA-Mn-za-m'

# Binary
echo "01100110 01101100 01100001 01100111" | perl -pe 's/(\d{8})/chr(oct("0$1"))/ge'

# Octal
echo "146 154 141 147" | awk '{printf "%c", $1}'

# Unicode
python3 -c "print(chr(0x66)+chr(0x6c)+chr(0x61)+chr(0x67))"

# Morse
python3 -c "
morse = {'.-':'A','-...':'B','-.-.':'C','-..':'D','.':'E','..-.':'F','--.':'G','....':'H','..':'.','---':'K','.-..':'L','--':'M','-.':'N','---':'O','.--.':'P','.-.':'R','...':'S','-':'T','..-':'U','...-':'V','.--':'W','-..-':'X','-.--':'Y'}
code = '.... . .-.. .-.. ---'
print(' '.join(morse.get(c, '?') for c in code.split(' ')))
"

# Atbash cipher (A=Z, B=Y, ...)
python3 -c "
s = 'SYNT{GRFG}'
print(s.translate(str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz', 'ZYXWVUTSRQPONMLKJIHGFEDCBAzyxwvutsrqponmlkjihgfedcba')))
"
```

---

## 1. RSA

### RSA Theory (Singkat)

```
p, q = prime
n = p * q
e = public exponent (biasanya 65537)
d = private exponent (d * e mod phi(n) = 1)
phi(n) = (p-1) * (q-1)
c = m^e mod n
m = c^d mod n
```

### RSA Attacks

```python
# 1. Factor n → get p, q
# Online: factordb.com
# Tool: yafu, msieve, RsaCtfTool

# 2. Small e attack (e=3, small m)
# c = m^3 mod n
# Kalau m^3 < n, maka m = int(c^(1/3))

import gmpy2
c = 0x...
n = 0x...
e = 3

m, exact = gmpy2.iroot(c, e)
if exact:
    print(f"Flag: {bytes.fromhex(hex(m)[2:])}")

# 3. Wiener attack (large d)
# Tool: RsaCtfTool
python3 RsaCtfTool.py --publickey pub.pem --private

# 4. Common modulus attack
# Same n, different e
# c1 = m^e1 mod n
# c2 = m^e2 mod n
# s, t = egcd(e1, e2)
# m = (c1^s * c2^t) mod n

# 5. Hastad broadcast attack
# Same m, different n
# c1 = m^e mod n1
# c2 = m^e mod n2
# c3 = m^e mod n3
# Use CRT to solve

# 6. Partial key exposure
# Known bits of d
# Tool: RsaCtfTool

# 7. Multiplicative property
# c1 = m1^e mod n
# c2 = m2^e mod n
# c1*c2 = (m1*m2)^e mod n
```

### RSA Tool Usage

```bash
# RsaCtfTool (auto attack)
python3 RsaCtfTool.py --publickey key.pub --uncipherfile cipher.txt

# openssl extract key info
openssl rsa -pubin -in key.pub -text -noout

# yafu factorization
yafu "factor(n_value)"

# msieve
msieve -v n_value

# factordb.com
# Submit n, get p and q if factorable
```

---

## 2. XOR

### XOR Basics

```python
# XOR properties
# a ^ a = 0
# a ^ 0 = a
# a ^ b = c  →  c ^ b = a

# Single-byte XOR brute force
data = bytes.fromhex('...')
for key in range(256):
    result = bytes([b ^ key for b in data])
    if b'flag' in result or b'ctf' in result:
        print(f"Key: {key} (0x{key:02x}) → {result}")

# Known plaintext attack
# known = "flag{"
# encrypted = bytes.fromhex('...')
# key = bytes([e ^ k for e, k in zip(encrypted, known)])

# Repeating key XOR
def xor_repeating(data, key):
    return bytes([d ^ key[i % len(key)] for i, d in enumerate(data)])

# Break repeating key XOR
# 1. Find key length (Hamming distance)
# 2. Break each byte as single-byte XOR

import string

def hamming_distance(s1, s2):
    return sum(bin(a ^ b).count('1') for a, b in zip(s1, s2))

# Find key length
key_lengths = []
for kl in range(2, 40):
    chunks = [encrypted[i:i+kl] for i in range(0, len(encrypted), kl)][:4]
    distances = [hamming_distance(chunks[i], chunks[i+1]) for i in range(len(chunks)-1)]
    if distances:
        avg_dist = sum(distances) / len(distances)
        key_lengths.append((kl, avg_dist / kl))

key_lengths.sort(key=lambda x: x[1])
# Smallest normalized distance = likely key length
```

### XOR Solver Script

```python
#!/usr/bin/env python3
import sys
from itertools import cycle

def xor_single(data, key):
    return bytes([b ^ key for b in data])

def xor_multi(data, key):
    return bytes([b ^ k for b, k in zip(data, cycle(key))])

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: xor_solve.py <hex_file> [key]")
        sys.exit(1)
    
    with open(sys.argv[1], 'rb') as f:
        data = bytes.fromhex(f.read().strip())
    
    if len(sys.argv) > 2:
        key = sys.argv[2].encode()
        result = xor_multi(data, key)
    else:
        # Brute single byte
        for k in range(256):
            result = xor_single(data, k)
            try:
                decoded = result.decode('utf-8')
                if any(word in decoded.lower() for word in ['flag', 'ctf', 'key', 'pass']):
                    print(f"Key: {k} (0x{k:02x})")
                    print(f"Result: {decoded}")
            except:
                pass
    print(result)
```

---

## 3. AES/DES

### AES Modes

| Mode | Cek | Fix |
|------|-----|-----|
| ECB | Blok-blok identik | Known plaintext / ECB oracle |
| CBC | IV visible | Padding oracle attack |
| CTR | Nonce visible | Nonce reuse attack |
| GCM | Tag visible | Tag forge (kalau key known sebagian) |

### Padding Oracle Attack

```python
# Padding Oracle Attack (CBC mode)
# Requires: oracle yang bilang "padding valid/invalid"

from pwn import *
import sys

def attack(ciphertext, iv, oracle):
    decrypted = b''
    block_size = 16
    
    for block_idx in range(len(ciphertext) // block_size):
        block = ciphertext[block_idx * block_size:(block_idx + 1) * block_size]
        intermediate = b''
        
        for byte_idx in range(block_size - 1, -1, -1):
            padding = bytes([block_size - byte_idx] * (block_size - byte_idx))
            
            for guess in range(256):
                prefix = iv[:byte_idx] if block_idx == 0 else ciphertext[(block_idx-1)*block_size:block_idx*block_size]
                prefix = prefix[:byte_idx]
                
                modified = prefix + bytes([guess]) + xor_bytes(intermediate, padding[1:])
                
                if oracle(modified + block):
                    intermediate = bytes([guess]) + intermediate
                    break
            else:
                return None
        
        decrypted += intermediate
    
    return decrypted
```

### AES ECB Attack

```python
# ECB Detection
from collections import Counter

def is_ecb(ciphertext, block_size=16):
    blocks = [ciphertext[i:i+block_size] for i in range(0, len(ciphertext), block_size)]
    return len(blocks) != len(set(blocks))

# ECB Byte-at-a-time
def ecb_oracle_encrypt(plaintext, oracle):
    return oracle(plaintext)

def find_block_size(oracle):
    initial_len = len(oracle(b'A'))
    for i in range(1, 128):
        new_len = len(oracle(b'A' * i))
        if new_len != initial_len:
            return new_len - initial_len
    return None

def ecb_byte_at_a_time(oracle, block_size=16):
    known = b''
    for i in range(100):
        block_num = (len(known) + i) // block_size
        padding_len = block_size - 1 - (len(known) + i) % block_size
        padding = b'A' * padding_len
        
        target = oracle(padding)[block_num * block_size:(block_num + 1) * block_size]
        
        for b in range(256):
            test = padding + known + bytes([b])
            result = oracle(test)
            if result[:block_num * block_size + block_size] == target[:block_num * block_size + block_size]:
                known += bytes([b])
                break
    return known
```

---

## 4. Hash Cracking

### Hash Identification

```bash
# hashid (identify hash type)
hashid '5d41402abc4b2a76b9719d911017c592'
hashid -f 'hash.txt'

# TDR (The Devil's Rainbow)
tdr '5d41402abc4b2a76b9719d911017c592'

# Name-That-Hash
nth -t '5d41402abc4b2a76b9719d911017c592'
```

### Hashcat

```bash
# MD5
hashcat -m 0 hash.txt wordlist.txt

# SHA1
hashcat -m 100 hash.txt wordlist.txt

# SHA256
hashcat -m 1400 hash.txt wordlist.txt

# bcrypt
hashcat -m 3200 hash.txt wordlist.txt

# NTLM (Windows)
hashcat -m 1000 hash.txt wordlist.txt

# With rules
hashcat -m 0 hash.txt wordlist.txt -r rules/best64.rule

# With mask (brute force)
hashcat -m 0 hash.txt -a 3 ?a?a?a?a?a?a  # 6 char alphanumeric

# Mask symbols
?l = lowercase
?u = uppercase
?d = digit
?s = special
?a = all
```

### John the Ripper

```bash
# Auto-detect
john hash.txt

# Specify format
john --format=raw-md5 hash.txt
john --format=raw-sha1 hash.txt
john --format=nt hash.txt  # Windows NTLM

# Wordlist
john --wordlist=passwords.txt hash.txt

# Rules
john --wordlist=passwords.txt --rules=best64 hash.txt

# Show cracked
john --show hash.txt

# Incremental (brute force)
john --incremental hash.txt
```

### Online Resources

| Resource | Untuk |
|----------|-------|
| crackstation.net | MD5, SHA1 lookup |
| hashes.com | Hash lookup + decrypt |
| hashcat.net/wiki | Hash mode reference |
| dcode.fr | Cipher identification |
| CyberChef | Decode/encode |

---

## 5. Classical Ciphers

### Caesar Cipher

```python
# Brute force (26 shifts)
def caesar_brute(ciphertext):
    for shift in range(26):
        result = ''
        for c in ciphertext:
            if c.isalpha():
                base = ord('A') if c.isupper() else ord('a')
                result += chr((ord(c) - base - shift) % 26 + base)
            else:
                result += c
        print(f"Shift {shift:2d}: {result}")

caesar_brute("Synt{grfg}")
```

### Vigenere Cipher

```python
# Vigenere decrypt
def vigenere_decrypt(ciphertext, key):
    result = ''
    key_idx = 0
    for c in ciphertext:
        if c.isalpha():
            base = ord('A') if c.isupper() else ord('a')
            shift = ord(key[key_idx % len(key)].upper()) - ord('A')
            result += chr((ord(c) - base - shift) % 26 + base)
            key_idx += 1
        else:
            result += c
    return result

# Kasiski examination (find key length)
def find_key_length(ciphertext, max_len=20):
    # Find repeated sequences
    import re
    repeats = {}
    for length in range(3, 10):
        for i in range(len(ciphertext) - length):
            seq = ciphertext[i:i+length]
            if seq in repeats:
                repeats[seq].append(i)
            else:
                repeats[seq] = [i]
    
    # Calculate GCD of distances
    from math import gcd
    from functools import reduce
    
    distances = []
    for seq, positions in repeats.items():
        if len(positions) > 1:
            for i in range(1, len(positions)):
                distances.append(positions[i] - positions[0])
    
    if distances:
        return reduce(gcd, distances)
    return None
```

### Substitution Cipher

```python
# Frequency analysis
def frequency_analysis(ciphertext):
    freq = {}
    for c in ciphertext:
        if c.isalpha():
            freq[c.upper()] = freq.get(c.upper(), 0) + 1
    
    # English frequency: E, T, A, O, I, N, S, H, R
    english_freq = 'ETAOINSHRDLCUMWFGYPBVKJXQZ'
    
    sorted_chars = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    
    mapping = {}
    for i, (char, _) in enumerate(sorted_chars):
        if i < len(english_freq):
            mapping[char] = english_freq[i]
    
    return mapping
```

---

## 6. Encoding Chains

### Common Chains

```bash
# Base64 → Hex → ASCII
echo "ZmxhZ3t0ZXN0fQ==" | base64 -d | xxd -r -p

# Multiple Base64
echo "WkdWd1oyaGxZWEpr..." | base64 -d | base64 -d

# URL → Base64 → Hex
python3 -c "
import base64, urllib.parse
s = '%66%6c%61%67'
decoded = urllib.parse.unquote(s)
print(base64.b64decode(decoded).hex())
"

# XOR → Base64 → Decode
python3 -c "
import base64
data = base64.b64decode('...')
# XOR with key
result = bytes([b ^ 0x42 for b in data])
print(result)
"
```

### CyberChef Recipes

```
# Input → operations → Output
# Common recipes:

# Recipe 1: Decode chain
From Hex → From Base64 → Gunzip

# Recipe 2: XOR decrypt
From Hex → XOR with Key → From Base64

# Recipe 3: RSA decrypt
From PEM → RSA Decrypt → From Hex

# Recipe 4: Reverse + decode
Reverse → From Base64 → From Hex
```

---

## 7. CTF Crypto Workflow

```
CHALLENGE DITERIMA
│
├─→ FASE 1: IDENTIFIKASI
│   # Baca deskripsi
│   # Cek hint
│   # Identifikasi cipher type
│   # Cek apakah ada encoded string
│
├─→ FASE 2: TRIAGE CEPAT
│   # Coba base64/hex/url decode
│   # Coba ROT13/caesar
│   # Cek factordb.com kalau ada angka besar
│   # Cek CyberChef
│
├─→ FASE 3: ANALISIS
│   # Kalau RSA → factor n
│   # Kalau XOR → cari key (single/plaintext)
│   # Kalau AES → cek mode, cari padding oracle
│   # Kalau classical → frequency analysis
│
├─→ FASE 4: SOLVE
│   # Jalankan attack
│   # Extract flag
│   # Verify format (flag{...})
│
└─→ FASE 5: REPORT
    # Simpan flag
    # Catat cara solve
    # Share writeup
```

---

## 8. Tools Reference

| Tool | Untuk |
|------|-------|
| CyberChef | Universal decode/encode |
| RsaCtfTool | RSA auto-attack |
| Hashcat | Hash cracking |
| John the Ripper | Hash cracking |
| dcode.fr | Cipher identification |
| factordb.com | Integer factorization |
| yafu | Factorization |
| openssl | Key manipulation |
| gmpy2 | Math operations |
| pwntools | CTF scripting |

---

*End skill — gas lanjut, jangan mandek ya tod.*

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Binary crypto implementation | `core/reverse-binary/SKILL.md` — Reverse RE |
| Encrypted malware | `core/malware-analysis/SKILL.md` — Malware analysis |
| TLS/SSL analysis | `core/forensics/SKILL.md` — Forensics |
| Password cracking | `core/pentest-web/SKILL.md` — Brute force |
| Network encryption | `core/mitm-network/SKILL.md` — MITM |
