"""Check replay press/release consistency and intended movement evidence."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
issues=[]
frames=0
for route_type in ['','normal/']:
    for i in range(45 if not route_type else 40):
        name=f'chapter_{i//10+1:02}_room_{i%10+1:02}.json'
        path=ROOT/'tests/fixtures'/route_type/name
        if not path.exists():issues.append(f'Missing {route_type}{name}');continue
        held=False
        for tick,frame in enumerate(json.loads(path.read_text())):
            axis,pressed,next_held=frame[:3]
            if len(frame)!=(6 if i>=40 else 3):issues.append(f'Wrong input count: {name}:{tick}')
            if not -1<=axis<=1:issues.append(f'Axis out of range: {name}:{tick}')
            if pressed and (held or not next_held):issues.append(f'Invalid press edge: {route_type}{name}:{tick}')
            if next_held and not held and not pressed:issues.append(f'Missing press edge: {route_type}{name}:{tick}')
            held=next_held;frames+=1
report={'files':85,'frames':frames,'issues':issues,'pass':not issues}
(ROOT/'artifacts/fixture_integrity.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
raise SystemExit(0 if report['pass'] else 1)
