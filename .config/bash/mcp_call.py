#!/usr/bin/env python3
"""One newline-delimited MCP stdio tool call via tsh, with a bounded lifetime."""
import json
import os
import selectors
import signal
import subprocess
import sys
import time

PROTOCOL = "2025-03-26"


def call(app, tool, arguments, timeout):
    process = subprocess.Popen(
        ["tsh", "mcp", "connect", app], stdin=subprocess.PIPE,
        stdout=subprocess.PIPE, start_new_session=True,
    )
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    pending = b""
    deadline = time.monotonic() + timeout

    def send(message):
        process.stdin.write((json.dumps(message) + "\n").encode())
        process.stdin.flush()

    def response(request_id):
        nonlocal pending
        while True:
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                if not line.strip():
                    continue
                message = json.loads(line)
                if not isinstance(message, dict):
                    raise ValueError("MCP response must be a JSON object")
                if "method" in message:
                    if "id" in message:
                        reply = {"jsonrpc": "2.0", "id": message["id"]}
                        if message["method"] == "ping":
                            reply["result"] = {}
                        else:
                            reply["error"] = {"code": -32601, "message": "Method not supported"}
                        send(reply)
                    continue
                if message.get("id") == request_id:
                    if "error" in message:
                        raise ValueError("MCP error: " + json.dumps(message["error"]))
                    if "result" not in message:
                        raise ValueError("MCP response has no result")
                    return message["result"]
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not selector.select(remaining):
                raise TimeoutError("MCP response timed out")
            chunk = os.read(process.stdout.fileno(), 65536)
            if not chunk:
                raise ValueError("MCP connection closed before the response completed")
            pending += chunk
            if len(pending) > 8 * 1024 * 1024:
                raise ValueError("MCP response exceeds 8 MiB")

    try:
        send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
            "protocolVersion": PROTOCOL, "capabilities": {},
            "clientInfo": {"name": "dotfiles", "version": "1"},
        }})
        initialized = response(1)
        if not isinstance(initialized, dict) or initialized.get("protocolVersion") != PROTOCOL:
            raise ValueError("Server selected an unsupported MCP protocol version")
        send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        send({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {
            "name": tool, "arguments": arguments,
        }})
        result = response(2)
        if not isinstance(result, dict):
            raise ValueError("Tool result must be a JSON object")
        print(json.dumps(result, indent=2))
        return 1 if isinstance(result, dict) and result.get("isError") else 0
    finally:
        selector.close()
        try:
            process.stdin.close()
        except OSError:
            pass
        # tsh may leave a transport child; stop the entire private process group.
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        process.stdout.close()


def main():
    if not 3 <= len(sys.argv) <= 4:
        print("usage: mcp_call <app> <tool> [json-args]", file=sys.stderr)
        return 2
    try:
        arguments = json.loads(sys.argv[3]) if len(sys.argv) == 4 else {}
        if not isinstance(arguments, dict):
            raise ValueError("Tool arguments must be a JSON object")
        timeout = float(os.environ.get("MCP_CALL_WAIT", "30"))
        if not 0 < timeout < float("inf"):
            raise ValueError("MCP_CALL_WAIT must be a positive finite timeout")
        return call(sys.argv[1], sys.argv[2], arguments, timeout)
    except (OSError, ValueError, TimeoutError) as error:
        print(f"mcp_call: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
