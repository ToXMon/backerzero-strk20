#!/usr/bin/env python3
"""Capability-splitting Starknet RPC proxy for the privacy transaction prover.

No single hosted Starknet Sepolia endpoint we found satisfies both prover
requirements at once:

  * the prover re-executes the block, so block headers must carry the RPC v0.8+
    commitment fields (`state_diff_commitment`, `transaction_commitment`, ...).
    Only spec-0.10 endpoints return them (e.g. PublicNode 0.10.2).
  * the prover needs `starknet_getStorageProof` at the *proving block*, which
    must be >= 10 blocks old (blockifier STORED_BLOCK_HASH_BUFFER). PublicNode
    serves storage proofs for the latest block only; Cartridge/Alchemy serve a
    ~16-block window.

This proxy fans each JSON-RPC call out to whichever upstream can serve it. Both
upstreams are the same chain, so a storage proof from one is verifiable against
the header/root from the other.

Usage:
  scripts/rpc-capability-proxy.py [--port 8547] \
      [--header-url URL] [--proof-url URL]
"""
import argparse
import json
import sys
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PROOF_METHODS = {"starknet_getStorageProof"}


def forward(url: str, payload: bytes) -> bytes:
    request = urllib.request.Request(
        url,
        data=payload,
        # Some hosted endpoints reject the default urllib user agent with 403.
        headers={"content-type": "application/json", "user-agent": "curl/8.5.0"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


class Handler(BaseHTTPRequestHandler):
    header_url = ""
    proof_url = ""
    verbose = False
    storage_proof_cache: dict[bytes, bytes] = {}

    def log_message(self, *args):  # noqa: D102 - silence default access log
        pass

    def _cache_key(self, body: bytes) -> bytes:
        return body

    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("content-length", 0))
        body = self.rfile.read(length)
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError:
            parsed = {}
        methods = (
            [entry.get("method") for entry in parsed]
            if isinstance(parsed, list)
            else [parsed.get("method")]
        )
        is_proof = any(method in PROOF_METHODS for method in methods)
        target = self.proof_url if is_proof else self.header_url

        if self.verbose:
            print(f"[proxy] {methods} -> {target}", file=sys.stderr, flush=True)
            for method in methods:
                if method in PROOF_METHODS:
                    print(f"[proxy] storage-proof body: {body.decode()[:2000]}", file=sys.stderr, flush=True)

        # Serve storage-proof responses from cache when we already paid to
        # fetch them while the proving block was still within the upstream window.
        if is_proof and body in Handler.storage_proof_cache:
            result = Handler.storage_proof_cache[body]
            if self.verbose:
                print("[proxy] storage-proof cache HIT", file=sys.stderr, flush=True)
        else:
            try:
                result = forward(target, body)
                if is_proof:
                    Handler.storage_proof_cache[body] = result
            except Exception as error:  # upstream failure -> JSON-RPC error
                result = json.dumps(
                    {
                        "jsonrpc": "2.0",
                        "id": None,
                        "error": {"code": -32603, "message": f"proxy: {error}"},
                    }
                ).encode()

        # If upstream now rejects the proving block as too old, fall back to a
        # previously cached response for the same proof request.
        if is_proof:
            try:
                parsed_result = json.loads(result)
            except json.JSONDecodeError:
                parsed_result = {}
            if (
                isinstance(parsed_result, dict)
                and parsed_result.get("error", {}).get("code") == 42
                and body in Handler.storage_proof_cache
            ):
                if self.verbose:
                    print("[proxy] upstream too-old; using cached storage proof", file=sys.stderr, flush=True)
                result = Handler.storage_proof_cache[body]

        status = 200
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(result)))
        self.end_headers()
        self.wfile.write(result)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8547)
    parser.add_argument(
        "--header-url", default="https://starknet-sepolia-rpc.publicnode.com"
    )
    parser.add_argument(
        "--proof-url", default="https://api.cartridge.gg/x/starknet/sepolia"
    )
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    Handler.header_url = args.header_url
    Handler.proof_url = args.proof_url
    Handler.verbose = args.verbose
    print(
        f"[proxy] :{args.port} headers={args.header_url} proofs={args.proof_url}",
        file=sys.stderr,
        flush=True,
    )
    ThreadingHTTPServer(("0.0.0.0", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
