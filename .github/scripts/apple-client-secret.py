# Makes the client secret Supabase sends to Apple for web sign-in: a JWT
# signed with the Sign in with Apple key. Apple caps its life at six months,
# and the weekly run remakes it, so it never gets near expiring.
import base64
import json
import os
import subprocess
import tempfile
import time

TEAM_ID = "6TATRT9BZQ"
KEY_ID = "2HM3T7GKDB"
SERVICES_ID = "com.joclegg.puzzles.signin"
SIX_MONTHS = 15777000


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def der_integer(der, offset):
    length = der[offset + 1]
    value = der[offset + 2 : offset + 2 + length]
    return value.lstrip(b"\0").rjust(32, b"\0"), offset + 2 + length


now = int(time.time())
header = b64(json.dumps({"alg": "ES256", "kid": KEY_ID}).encode())
claims = {"iss": TEAM_ID, "iat": now, "exp": now + SIX_MONTHS, "aud": "https://appleid.apple.com", "sub": SERVICES_ID}
signed = header + b"." + b64(json.dumps(claims).encode())
with tempfile.NamedTemporaryFile("wb", suffix=".p8") as key:
    key.write(base64.b64decode(os.environ["APPLE_SIGN_IN_KEY"]))
    key.flush()
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key.name], input=signed, capture_output=True, check=True).stdout
r, offset = der_integer(der, 3 if der[1] & 0x80 else 2)
s, _ = der_integer(der, offset)
print((signed + b"." + b64(r + s)).decode())
