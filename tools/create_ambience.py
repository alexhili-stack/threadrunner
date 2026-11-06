"""Original seamless ambient compositions: no outside recordings or assets."""
from pathlib import Path
import math,struct,wave

ROOT=Path(__file__).resolve().parents[1]
RATE=22050
SECONDS=24
CHORDS=[[(50,57,62,65),(46,53,58,62),(48,55,60,64),(45,52,57,60)],
        [(45,52,57,60),(41,48,53,57),(43,50,55,59),(40,47,52,55)],
        [(48,55,60,64),(43,50,55,59),(45,52,57,60),(46,53,58,62)]]
CHORDS.append([(55,62,67,71),(53,60,65,69),(48,55,60,64),(50,57,62,66)])
for chapter,chords in enumerate(CHORDS,1):
    path=ROOT/f'assets/audio/chapter_{chapter:02d}.wav'
    frames=bytearray()
    for i in range(RATE*SECONDS):
        t=i/RATE;bar=int(t//6);local=t%6
        envelope=math.sin(math.pi*local/6)**1.2
        value=0.0
        for n,note in enumerate(chords[bar]):
            freq=440*2**((note-69)/12)
            value += math.sin(math.tau*freq*t)*.045/(1+n*.3)
            value += math.sin(math.tau*freq*2*t)*.009
        pulse=math.sin(math.pi*(t%1.5)/1.5)**4
        value=(value*envelope + .008*math.sin(math.tau*110*t)*pulse)
        fade=min(1,t/.1,(SECONDS-t)/.1)
        sample=max(-32767,min(32767,int(value*fade*32767)))
        frames.extend(struct.pack('<h',sample))
    with wave.open(str(path),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(frames)
    print(path.name,len(frames),'PCM bytes')
