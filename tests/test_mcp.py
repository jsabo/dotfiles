import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / '.config/bash/mcp_call.py'
SERVER = '''import json,os,sys,time
from pathlib import Path
Path(os.environ['STARTED']).write_text(str(os.getpid()))
mode=os.environ.get('MODE','success')
if mode=='exit':
 print('transport failed',file=sys.stderr);sys.exit(7)
request=json.loads(sys.stdin.readline())
assert request['method']=='initialize'
if mode=='timeout': time.sleep(10)
if mode=='malformed': print('invalid JSON',flush=True);time.sleep(10)
if mode=='init_error':
 print(json.dumps({'jsonrpc':'2.0','id':1,'error':{'code':-1,'message':'denied'}}),flush=True);time.sleep(10)
print(json.dumps({'jsonrpc':'2.0','id':1,'result':{'protocolVersion':'2025-03-26'}}),flush=True)
assert json.loads(sys.stdin.readline())['method']=='notifications/initialized'
request=json.loads(sys.stdin.readline())
assert request['method']=='tools/call'
print(json.dumps({'jsonrpc':'2.0','method':'notifications/progress'}),flush=True)
print(json.dumps({'jsonrpc':'2.0','id':99,'method':'ping'}),flush=True)
assert json.loads(sys.stdin.readline())['result']=={}
result={'content':[{'type':'text','text':request['params']['name']}], 'arguments':request['params']['arguments']}
if mode=='tool_error': result['isError']=True
print(json.dumps({'jsonrpc':'2.0','id':2,'result':result}),flush=True)
time.sleep(10)
'''


class MCP(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        server = self.root / 'tsh'
        server.write_text('#!'+sys.executable+'\n'+SERVER)
        server.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root), STARTED=str(self.root/'started'), MCP_CALL_WAIT='2')

    def run_client(self, mode='success', arguments='{}'):
        return subprocess.run([sys.executable,str(CLIENT),'app','tool "quoted"',arguments],
                              env=dict(self.env, MODE=mode), text=True, capture_output=True, timeout=5)

    def test_handshake_and_structured_response(self):
        start = time.monotonic()
        result = self.run_client(arguments='{"sql":"select 1"}')
        self.assertEqual(result.returncode,0,result.stderr)
        data=json.loads(result.stdout)
        self.assertEqual(data['arguments'],{'sql':'select 1'})
        self.assertEqual(data['content'][0]['text'],'tool "quoted"')
        self.assertLess(time.monotonic()-start,3)
        with self.assertRaises(ProcessLookupError):
            os.kill(int((self.root/'started').read_text()),0)

    def test_invalid_arguments_fail_before_connect(self):
        for arguments in ['{broken','[]','null']:
            result=self.run_client(arguments=arguments)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse((self.root/'started').exists())

    def test_timeouts_errors_and_early_eof(self):
        for mode in ['timeout','exit','malformed','init_error','tool_error']:
            with self.subTest(mode=mode):
                result=self.run_client(mode)
                self.assertNotEqual(result.returncode,0)
                if mode=='exit': self.assertIn('transport failed',result.stderr)
                if mode=='timeout': self.assertIn('timed out',result.stderr)
                if mode=='tool_error': self.assertTrue(json.loads(result.stdout)['isError'])

    def test_timeout_setting_is_validated(self):
        for value in ['0','-1','nan','inf','nope']:
            self.env['MCP_CALL_WAIT']=value
            result=self.run_client()
            self.assertNotEqual(result.returncode,0)
            self.assertFalse((self.root/'started').exists())
