"""Author the reviewed v1.1 rooms. Source scenes remain the runtime geometry."""
from pathlib import Path
import argparse
import re

ROOT=Path(__file__).resolve().parents[1]
PILOTS=[0,3,7,12,29]

def vec(v,kind='Vector2'):return kind+'('+', '.join(str(x) for x in v)+')'
def arr(values,kind):return 'Array['+kind+'](['+', '.join(vec(v,kind) for v in values)+'])'

# Per-room composition: bottom obstacles, middle obstacles, top obstacles,
# floor gaps, timing gates, moving machinery, ceiling precision, wall ascent.
# Coordinates are authored in the logical 640x360 single-screen playfield.
SPECS=[
 ([],[],[],[],[],[],False,False,'Follow the signal arrows. Jump up at each end of the room.'),
 ([],[],[],[(272,48)],[],[],False,False,'Leave the edge late. Find the next safe landing.'),
 ([(224,24)],[],[],[],[],[],True,False,'A short tap clears the spikes. The teeth above punish a held jump.'),
 ([(200,32)],[(336,20)],[],[(304,48)],[],[],False,False,'Read the landing, change direction, and climb to the exit.'),
 ([],[],[],[(320,48)],[],[],False,False,'Settle on each landing. The next move can wait.'),
 ([(208,32)],[],[],[],[],[],False,True,'Press toward the tall wall to slide. Jump away, then steer back.'),
 ([(240,40)],[],[],[(352,32)],[],[],False,True,'Use wall contact to climb. You cannot reach the exit from the floor.'),
 ([(208,40),(368,32)],[],[],[],[],[],False,True,'Climb the shaft, push away from the wall, and bring the signal back.'),
 ([(240,32)],[(304,32)],[(400,24)],[],[],[],False,False,'The gold detour is optional. Secure it by finishing this attempt.'),
 ([(208,32)],[(352,32)],[(256,32)],[(288,40)],[],[],True,False,'Departure test: short jump, high jump, turn and climb.'),
 ([],[],[],[],[],[(304,284,24,3.8)],False,False,'Watch the machine cross your route. Move when the space is clear.'),
 ([(240,32)],[],[],[],[],[(368,276,32,4.2)],False,False,'The striped pads are safe places to watch a cycle.'),
 ([],[],[],[],[(320,264,12,64),(352,184,12,64)],[],False,False,'Empty brackets are open. Crosshatched beams are lethal.'),
 ([],[(320,32)],[],[(288,32)],[],[(272,280,28,4.4)],False,False,'Let the moving teeth pass before leaving the observation pad.'),
 ([(208,32)],[],[],[],[(400,264,12,64)],[],False,False,'Watch the gate bar. Commit only when the opening is long enough.'),
 ([],[],[],[],[],[],False,False,'A quiet relay. Keep your rhythm through the turns.'),
 ([],[(288,32)],[],[],[],[(352,280,24,3.6),(288,200,24,4.6)],False,False,'The machines repeat their paths. Your landings give you time to read them.'),
 ([],[],[],[],[(272,264,12,64)],[],False,True,'Wait before the gate, then use the wall to recover your rhythm.'),
 ([(240,32)],[],[(352,24)],[],[],[(336,280,28,4.2),(336,120,28,4.8)],False,False,'Two crossings, two decisions. Look before each jump.'),
 ([],[(304,32)],[],[(320,40)],[(400,264,12,64)],[(272,200,24,4.8)],False,False,'Clockwork test: watch, cross, change direction, repeat.'),
 ([(208,40)],[(352,32)],[(304,32)],[(288,48)],[],[],False,False,'The resting places are smaller. The movement is unchanged.'),
 ([(240,32)],[(288,40)],[(400,32)],[(336,40)],[],[],True,False,'Short jumps under teeth; full jumps at the turn. Choose deliberately.'),
 ([(240,32)],[],[],[],[],[],False,True,'Go up the wall and come back across the upper platforms.'),
 ([],[(352,32)],[(288,32)],[],[(320,264,12,64)],[(400,200,24,4.4)],False,False,'Carry the rhythm from the first crossing into the return route.'),
 ([],[],[],[(288,32)],[],[],False,False,'A breath before the final relay. Make each landing deliberate.'),
 ([(208,32)],[(336,32)],[(400,32)],[(288,40)],[(304,104,12,64)],[],True,False,'A careful tap below. A committed crossing above.'),
 ([],[(304,32)],[],[],[(400,264,12,64),(320,104,12,64)],[(272,200,20,4.8)],False,False,'Do not chase a closing gate. The next opening will come.'),
 ([(208,32)],[],[(256,24)],[(336,32)],[],[(304,112,24,4.6)],False,True,'Recover on the wall. Keep the fragment through the last crossing.'),
 ([],[(352,32)],[(288,32)],[(288,48)],[(400,264,12,64)],[(304,200,20,4.8)],False,False,'The daylight is close. Read every landing before you leave.'),
 ([(208,32)],[(304,32)],[(400,24)],[(288,40)],[(432,264,12,64),(304,104,12,64)],[(224,112,40,4.8)],True,False,'Final transmission: short jumps, safe waits, clean turns, one last delivery.')
]

def authored(index):
    bottom,middle,top,gaps,gates,movers,ceiling,wall=SPECS[index][:8]
    middle=[(x,min(w,20)) for x,w in middle]
    if movers:movers=[(224,200,32,movers[0][3])]
    platforms=[(0,64,16,280),(624,64,16,280)]
    floor=[];start=16
    for x,w in gaps:
        floor.append((start,328,x-start,16));start=x+w
    floor.append((start,328,624-start,16));platforms+=floor
    spikes=[(x,316,w,12) for x,w in bottom]
    spikes += [(x,236,w,12) for x,w in middle]
    spikes += [(x,156,w,12) for x,w in top]
    ceiling_spikes=[(176,264,112,8)] if ceiling else []
    # Each obstacle gets a read point, an airborne crossing, then a landing.
    route=[(88,317)]
    for x,w in sorted(bottom+gaps):
        if x-32 > route[-1][0]:route.append((x-32,317))
        route += [(x+w*.5,282),(x+w+32,317)]
    if wall:
        platforms += [(528,152,16,176),(480,152,16,96),(16,152,48,16),(128,152,288,16),(16,248,464,16)]
        route += [(512,317),(514,257),(514,199),(514,143),(456,123),(384,141),(152,141),(96,237),(464,237)]
        # The upper return is compulsory; the fragment requires a small hop.
        fragment=(224,102);exit_pos=(464,228)
    else:
        platforms += [(16,248,480,16),(544,288,64,16),(32,208,64,16),(144,168,96,16),(272,168,96,16),(400,168,224,16)]
        route += [(512,317),(576,277),(464,237)]
        for x,w in sorted(middle,reverse=True):
            route += [(x+w+32,237),(x+w*.5,202),(x-32,237)]
        route += [(128,237),(64,197),(176,157)]
        upper=[]
        for marker in [216,312,440]:
            if not any(x-40 <= marker <= x+w+40 for x,w in top):upper.append((marker,157))
        for x,w in sorted(top):
            before=x-32;after=x+w+32
            if 240<before<272:before=228
            if 368<before<400:before=356
            if 240<after<272:after=284
            if 368<after<400:after=412
            upper += [(before,157),(x+w*.5,122),(after,157)]
        route += sorted(upper)
        route += [(580,157)]
        fragment=(480,114);exit_pos=(600,148)
    # Approach pads before gates are on the actual authored path.
    return dict(platforms=platforms,spikes=spikes,ceiling_spikes=ceiling_spikes,route=route,
                fragment=fragment,exit=exit_pos,movers=movers,gates=gates,wall=wall,ceiling=ceiling)

def write_room(index):
    d=authored(index);chapter=index//10+1;number=index%10+1
    vents=[(176,212,32,36)] if index in [20,23,25,28,29] else []
    text=f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/gameplay/level_root.gd" id="1"]
[node name="CurrentLevel" type="Node2D"]
script = ExtResource("1")
level_id = "chapter_{chapter:02d}_room_{number:02d}"
spawn = Vector2(40, 317)
exit_position = {vec(d['exit'])}
fragment_position = {vec(d['fragment'])}
platforms = {arr(d['platforms'],'Rect2')}
spikes = {arr(d['spikes'],'Rect2')}
ceiling_spikes = {arr(d['ceiling_spikes'],'Rect2')}
vents = {arr(vents,'Rect2')}
movers = {arr(d['movers'],'Vector4')}
gates = {arr(d['gates'],'Rect2')}
gate_period = 3.2
gate_open_time = 1.8
route = {arr(d['route'],'Vector2')}
purpose = "{SPECS[index][-1]+(' Amber vents warn before hot air fires.' if vents else '')}"
chapter = {chapter}
required_skill = "{'wall' if d['wall'] else 'variable_jump' if d['ceiling'] else 'timing' if d['gates'] or d['movers'] else 'jump'}"
route_markers = {arr([(160,309),(464,229),(208,149)] if not d['wall'] else [(160,309),(496,237),(352,133)],'Vector2')}
'''
    (ROOT/f'scenes/levels/chapter_{chapter:02d}/room_{number:02d}.tscn').write_text(text)

def write_large(index):
    number=index-29
    platforms=[(0,64,16,280),(1264,64,16,280),(16,328,352,16),(408,328,296,16),(744,328,520,16),
               (16,248,1120,16),(1184,288,64,16),(32,208,64,16),
               (144,168,128,16),(304,168,160,16),(496,168,160,16),(688,168,160,16),(880,168,384,16)]
    bottom=[(240,24),(560,24),(864,24 if number<6 else 32)]
    middle=[(912,20),(640,20),(304,20)] if number%3!=0 else [(800,20),(432,20)]
    top=[(1008,20)] if number>4 else []
    route=[(88,317)]
    for x,w in sorted(bottom+[(368,40),(704,40)]):
        if x-32>route[-1][0]:route.append((x-32,317))
        route.extend([(x+w*.5,282),(x+w+32,317)])
    route += [(1152,317),(1216,277),(1104,237)]
    for x,w in sorted(middle,reverse=True):route += [(x+w+32,237),(x+w*.5,202),(x-32,237)]
    route += [(128,237),(64,197),(176,157)]
    for x in [224,384,576,768,944]:route.append((x,157))
    for x,w in top:route += [(x-32,157),(x+w*.5,122),(x+w+32,157)]
    route += [(1200,157)]
    gates=[(960,264,12,64),(1040,184,12,64)] if number%2 else [(480,264,12,64),(784,104,12,64)]
    movers=[(1048,280,32,4.6+number*.13)]
    if number>3:movers.append((416,112,40,5.2+number*.1))
    spikes=[(x,316,w,12) for x,w in bottom]+[(x,236,w,12) for x,w in middle]+[(x,156,w,12) for x,w in top]
    text=f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/gameplay/level_root.gd" id="1"]
[node name="CurrentLevel" type="Node2D"]
script = ExtResource("1")
level_id = "chapter_04_room_{number:02d}"
spawn = Vector2(40,317)
exit_position = Vector2(1240,148)
fragment_position = Vector2(1104,114)
world_size = Vector2(1280,360)
chapter = 4
platforms = {arr(platforms,'Rect2')}
spikes = {arr(spikes,'Rect2')}
ceiling_spikes = {arr([(176,264,144,8)] if number%2 else [],'Rect2')}
vents = {arr([(528,212,32,36)] if number%2 else [(176,212,32,36)],'Rect2')}
movers = {arr(movers,'Vector4')}
gates = {arr(gates,'Rect2')}
gate_period = 3.6
gate_open_time = 2.1
route = {arr(route,'Vector2')}
purpose = "Afterlight: read the next section, use safe pads, and keep the signal through the full relay."
required_skill = "timing"
route_markers = {arr([(200,309),(600,309),(1000,309),(1000,229),(600,229),(200,229),(200,149),(600,149),(1000,149)],'Vector2')}
'''
    (ROOT/'scenes/levels/chapter_04').mkdir(exist_ok=True)
    (ROOT/f'scenes/levels/chapter_04/room_{number:02d}.tscn').write_text(text)
    names=['Beyond the doors','Long transmission','Night shift','The conduit','Two crossings','Extended range','Fault tolerance','Last frequency','Open horizon','Daybreak']
    next_id=f'chapter_04_room_{number+1:02d}' if number<10 else ''
    definition=f'''[gd_resource type="Resource" script_class="LevelDefinition" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/resources/level_definition.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/levels/chapter_04/room_{number:02d}.tscn" id="2"]
[resource]
script = ExtResource("1")
stable_id = "chapter_04_room_{number:02d}"
display_name = "{names[number-1]}"
chapter = 4
scene = ExtResource("2")
next_level_id = "{next_id}"
target_seconds = 25.0
has_fragment = true
'''
    (ROOT/f'data/campaign/chapter_04_room_{number:02d}.tres').write_text(definition)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--all',action='store_true');a=p.parse_args()
    chosen=range(40) if a.all else PILOTS
    for i in chosen:
        if i<30:write_room(i)
        else:write_large(i)
    if a.all:
        p=ROOT/'data/campaign/chapter_03_room_10.tres'
        p.write_text(p.read_text().replace('next_level_id = ""','next_level_id = "chapter_04_room_01"'))
    print('Authored rooms:',', '.join(str(i+1) for i in chosen))
