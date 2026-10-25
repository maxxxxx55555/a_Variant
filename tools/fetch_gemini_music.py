"""Fetch actual Lyria RealTime PCM captures without playing audio or exposing credentials.

Build-time dependency: websockets. API credentials come only from the process environment.
Usage: python tools/fetch_gemini_music.py --output <absolute folder outside this repository>
"""
import argparse,asyncio,base64,hashlib,json,os,time,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
async def fetch(entry,output):
    from websockets.asyncio.client import connect
    key=os.environ.get('GEMINI_API_KEY') or os.environ.get('GOOGLE_API_KEY')
    if not key:raise RuntimeError('Set GEMINI_API_KEY or GOOGLE_API_KEY in the environment')
    name=entry['mood'];record=output/(name+'.json')
    if record.exists():raise RuntimeError('Capture metadata already exists; use another output folder')
    metadata=dict(entry,model='lyria-realtime-exp',date=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),documentation='https://ai.google.dev/api/live_music')
    try:
        endpoint='wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateMusic'
        async with connect(endpoint,additional_headers={'x-goog-api-key':key},open_timeout=30,max_size=None,ping_interval=None) as connection:
            await connection.send(json.dumps({'setup':{'model':'models/lyria-realtime-exp'}}))
            response=json.loads(await asyncio.wait_for(connection.recv(),45))
            if 'setupComplete' not in response:raise RuntimeError('Music setup rejected')
            await connection.send(json.dumps({'clientContent':{'weightedPrompts':[{'text':entry['prompt'],'weight':1.0}]}}))
            await connection.send(json.dumps({'musicGenerationConfig':{'bpm':entry['bpm'],'density':entry['density'],'brightness':0.35}}))
            await connection.send(json.dumps({'playbackControl':'PLAY'}))
            raw=bytearray();needed=entry['capture_seconds']*48000*4
            while len(raw)<needed:
                message=json.loads(await asyncio.wait_for(connection.recv(),150))
                if 'filteredPrompt' in message:raise RuntimeError('Prompt was filtered; no successful capture is claimed')
                if 'error' in message:raise RuntimeError('Music service rejected generation')
                for chunk in message.get('serverContent',{}).get('audioChunks',[]):raw.extend(base64.b64decode(chunk['data']))
            path=output/(name+'-source.wav')
            with wave.open(str(path),'wb') as f:
                f.setnchannels(2);f.setsampwidth(2);f.setframerate(48000);f.writeframes(bytes(raw[:needed]))
            metadata.update(status='generated',source_filename=path.name,source_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    except Exception as error:
        metadata.update(status='failed',error_type=type(error).__name__,message=str(error).replace(key,'[REDACTED]')[:1000])
    record.write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(name,metadata['status'])
    if metadata['status']!='generated':raise RuntimeError('Generation failed; inspect the scrubbed capture record')
async def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,required=True);parser.add_argument('--mood')
    args=parser.parse_args();output=args.output.resolve()
    if output.is_relative_to(ROOT):parser.error('Original captures must be outside the shipping repository')
    output.mkdir(parents=True,exist_ok=True)
    prompts=json.loads((ROOT/'assets/audio/generation-prompts.json').read_text(encoding='utf-8'))
    for entry in prompts:
        if args.mood and args.mood!=entry['mood']:continue
        await fetch(entry,output)
if __name__=='__main__':asyncio.run(main())
