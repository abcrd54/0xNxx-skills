---
name: keychain
description: |
  iOS keychain dump, certificate pinning bypass, Frida iOS hooking.
  Kata kunci: ios, keychain, certificate pinning, frida, objection, class-dump, swizzling, jailbreak.
---

# SKILL: iOS Security — Keychain + Pinning + Runtime

> **Trigger:** User minta dump keychain iOS, bypass SSL pinning, atau analisis IPA.

---

## 0. Setup

```bash
# Tools
pip3 install frida-tools objection
brew install libimobiledevice
brew install idb-companion

# Frida server untuk iOS
# Download dari: https://github.com/frida/frida/releases
# Sesuaikan dengan versi iOS & device

# class-dump (untuk dump headers)
brew install class-dump
```

---

## 1. Keychain Dump

### Via Frida (Non-Jailbreak yang diizinkan)

```python
# keychain_dump.js
if (ObjC.available) {
    try {
        var keychain = ObjC.classes.NSUserDefaults;
        var items = [];
        
        // Query all keychain items
        var query = ObjC.classes.NSMutableDictionary.alloc().init();
        query.setObject_forKey_(ObjC.classes.NSecClass.keychainItem(), ObjC.classes.NSecClass());
        
        // Execute keychain query
        var status = Security.SecItemCopyMatching(query, NULL);
        
        if (status == 0) {
            console.log("[+] Keychain items found:");
            // Process results
        } else {
            console.log("[-] No keychain items or error: " + status);
        }
    } catch(e) {
        console.log("[-] Error: " + e.message);
    }
}
```

### Via Objection (Jailbroken)

```bash
# Spawn app
objection -g "com.target.app" explore

# Dump keychain
ios keychain dump

# Dump with specific classes
ios keychain dump --literal

# Dump all
ios keychain dump --all
```

### Keychain Query Patterns

```python
# Common keychain attributes to check
kSecClassGenericPassword   # Internet password
kSecClassInternetPassword  # Internet password
kSecClassCertificate       # Certificate
kSecClassKey               # Cryptographic key
kSecClassIdentity          # Identity

# Common keys to look for
- auth_token
- access_token
- refresh_token
- api_key
- secret
- password
- session_id
- user_id
- certificate
```

---

## 2. Certificate Pinning Bypass

### Method 1: Frida Universal Bypass

```javascript
// ssl_pinning_bypass.js
if (ObjC.available) {
    try {
        // Bypass SSL pinning for NSURLSession
        var resolver = new ApiResolver('objc');
        resolver.enumerateMatches(
            '-[* URLSession:didReceiveChallenge:completionHandler:]',
            {
                onMatch: function(match) {
                    console.log('[+] Found: ' + match.name);
                    Interceptor.attach(match.address, {
                        onEnter: function(args) {
                            var challenge = new ObjC.Object(args[2]);
                            var protectionSpace = challenge.protectionSpace();
                            var authMethod = protectionSpace.authenticationMethod().toString();
                            
                            if (authMethod == 'NSURLAuthenticationMethodServerTrust') {
                                var serverTrust = protectionSpace.serverTrust();
                                var certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
                                
                                var credential = ObjC.classes.NSURLCredential.credentialForTrust_(serverTrust);
                                var handler = new ObjC.Block(args[3]);
                                handler.implementation(0, credential);
                            }
                        }
                    });
                },
                onComplete: function() {}
            }
        );
        
        // Bypass ATS (App Transport Security)
        var ats = ObjC.classes.NSUserDefaults;
        var defaults = ats.standardUserDefaults();
        defaults.setObject_forKey_(true, 'NSAllowsArbitraryLoads');
        
        console.log('[+] SSL Pinning bypass applied');
    } catch(e) {
        console.log('[-] Error: ' + e.message);
    }
}
```

### Method 2: Objection Built-in

```bash
# Start objection
objection -g "com.target.app" explore

# Disable SSL pinning
ios sslpinning disable

# Verify it's disabled
ios sslpinning status
```

### Method 3: Runtime Hook (Specific App)

```javascript
// Hook specific URL session delegate
if (ObjC.available) {
    var className = "AppDelegate"; // Ganti dengan class name app
    
    try {
        var resolver = new ApiResolver('objc');
        resolver.enumerateMatches(
            '-[' + className + ' URLSession:didReceiveChallenge:completionHandler:]',
            {
                onMatch: function(match) {
                    Interceptor.attach(match.address, {
                        onEnter: function(args) {
                            // Accept all challenges
                            var challenge = new ObjC.Object(args[2]);
                            var credential = ObjC.classes.NSURLCredential.credentialForTrust_(
                                challenge.protectionSpace().serverTrust()
                            );
                            var handler = new ObjC.Block(args[3]);
                            handler.implementation(0, credential);
                            console.log('[+] Challenge bypassed');
                        }
                    });
                },
                onComplete: function() {}
            }
        );
    } catch(e) {
        console.log('[-] ' + e.message);
    }
}
```

---

## 3. Method Swizzling

### Basic Swizzle

```javascript
if (ObjC.available) {
    var className = "TargetClass";
    var methodName = "targetMethod";
    
    try {
        var targetClass = ObjC.classes[className];
        var targetMethod = targetClass[methodName];
        var originalImpl = targetMethod.implementation;
        
        Interceptor.attach(targetMethod.implementation, {
            onEnter: function(args) {
                console.log('[+] ' + methodName + ' called');
                // Log arguments
                for (var i = 0; i < 4; i++) {
                    var arg = new ObjC.Object(args[i]);
                    console.log('  arg[' + i + ']: ' + arg.toString());
                }
            },
            onLeave: function(retval) {
                console.log('[+] ' + methodName + ' returned: ' + retval);
                // Modify return value
                // retval.replace(ObjC.classes.NSString.stringWithString_('modified'));
            }
        });
    } catch(e) {
        console.log('[-] Error: ' + e.message);
    }
}
```

### Swizzle Authentication Methods

```javascript
// Bypass jailbreak detection
if (ObjC.available) {
    var targetClass = ObjC.classes.UIApplication;
    var original = targetClass['- canOpenURL:'];
    
    Interceptor.attach(original.implementation, {
        onEnter: function(args) {
            var url = new ObjC.Object(args[2]);
            console.log('[+] canOpenURL: ' + url.toString());
        },
        onLeave: function(retval) {
            retval.replace(1); // Always return true
            console.log('[+] canOpenURL bypassed');
        }
    });
}
```

---

## 4. Runtime Analysis

### Class Dump

```bash
# Dump all classes
class-dump Target.app > classes.txt

# Dump specific framework
class-dump Framework.framework > framework_classes.txt

# Search for interesting methods
grep -i "password\|token\|key\|secret\|auth" classes.txt
```

### Frida Script — Runtime Monitoring

```javascript
// monitor_app.js
if (ObjC.available) {
    console.log('[*] Monitoring app runtime...');
    
    // Monitor network calls
    var resolver = new ApiResolver('objc');
    resolver.enumerateMatches(
        '-[* NSURLSession dataTaskWithRequest:*]',
        {
            onMatch: function(match) {
                Interceptor.attach(match.address, {
                    onEnter: function(args) {
                        var request = new ObjC.Object(args[2]);
                        console.log('[NET] ' + request.HTTPMethod() + ' ' + request.URL().toString());
                    }
                });
            },
            onComplete: function() {}
        }
    );
    
    // Monitor file operations
    resolver.enumerateMatches(
        '-[* NSFileManager fileExistsAtPath:*]',
        {
            onMatch: function(match) {
                Interceptor.attach(match.address, {
                    onEnter: function(args) {
                        var path = new ObjC.Object(args[2]);
                        console.log('[FILE] ' + path.toString());
                    }
                });
            },
            onComplete: function() {}
        }
    );
    
    // Monitor user defaults
    resolver.enumerateMatches(
        '-[* NSUserDefaults setObject:forKey:*]',
        {
            onMatch: function(match) {
                Interceptor.attach(match.address, {
                    onEnter: function(args) {
                        var value = new ObjC.Object(args[2]);
                        var key = new ObjC.Object(args[3]);
                        console.log('[UD] ' + key.toString() + ' = ' + value.toString());
                    }
                });
            },
            onComplete: function() {}
        }
    );
}
```

---

## 5. IPA Analysis

### Extract IPA

```bash
# Unzip IPA
unzip Target.ipa -d Target_extracted/

# Find interesting files
find Target_extracted/ -name "*.plist"
find Target_extracted/ -name "*.json"
find Target_extracted/ -name "*.db"
find Target_extracted/ -name "*.sqlite"

# Check Info.plist
plutil -p Target_extracted/Payload/Target.app/Info.plist

# Check entitlements
cat Target_extracted/Payload/Target.app/embedded.mobileprovision | security cms -D -i - > entitlements.plist
```

### Static Analysis

```bash
# Check binary
file Target_extracted/Payload/Target.app/Target
otool -L Target_extracted/Payload/Target.app/Target  # Linked libraries

# Check for hardcoded secrets
strings Target_extracted/Payload/Target.app/Target | grep -iE "api_key|token|secret|password"

# Check URL schemes
grep -A 1 "CFBundleURLSchemes" Target_extracted/Payload/Target.app/Info.plist
```

---

## 6. Workflow

```
IPA DITERIMA
│
├─→ FASE 1: TRIAGE
│   unzip Target.ipa -d extracted/
│   file extracted/Payload/Target.app/Target
│   strings Target | grep -iE "api|key|token|secret"
│
├─→ FASE 2: STATIC ANALYSIS
│   class-dump Target.app > classes.txt
│   grep -i "keychain\|auth\|token\|login" classes.txt
│   check Info.plist for URL schemes
│
├─→ FASE 3: RUNTIME ANALYSIS (Frida)
│   frida -U -f Target.app -l bypass.js
│   # Monitor network, keychain, user defaults
│
├─→ FASE 4: SSL PINNING BYPASS
│   objection -g Target.app explore
│   ios sslpinning disable
│   # Test HTTPS endpoints
│
├─→ FASE 5: KEYCHAIN DUMP
│   ios keychain dump
│   # Search for tokens, credentials
│
└─→ FASE 6: REPORT
    # List all findings
    # Include evidence (screenshots, logs)
```

---

## 7. Common Issues

| Issue | Fix |
|-------|-----|
| Frida server won't start | Check iOS version compatibility |
| Objection can't attach | Ensure app is debuggable or use `-f` flag |
| Keychain dump empty | App might use Data Protection API |
| SSL pinning still active | Try different bypass method |
| App crashes on hook | Use `--runtime` flag with objection |

---

*End skill — gas lanjut, jangan mandek ya tod.*
