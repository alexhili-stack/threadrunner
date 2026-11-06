"""Author fixed thread terminals and five teaching missions. No runtime generation."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def array(kind, values):
    return f"Array[{kind}]([" + ", ".join(f"{kind}({', '.join(str(x) for x in v)})" for v in values) + "])"


for index in range(40):
    path = ROOT / f"scenes/levels/chapter_{index//10+1:02}/room_{index%10+1:02}.tscn"
    text = path.read_text()
    text = re.sub(r"\n(thread_anchors|stitch_pairs) = [^\n]*", "", text)
    geometry = [tuple(map(float, v.split(","))) for v in re.findall(r"Rect2\(([^)]+)\)", re.search(r"platforms = ([^\n]+)", text)[1])]
    floors = [r for r in geometry if r[3] <= 24 and r[2] >= 32]
    pairs = []
    for y in sorted(set(r[1] for r in floors), reverse=True):
        row = sorted([r for r in floors if r[1] == y])
        for left, right in zip(row, row[1:]):
            end = left[0]+left[2]
            if 24 <= right[0]-end <= 260:
                pairs.append((int(end-8), int(y), int(right[0]+8), int(y)))
    # Every original room has at least one optional bridge or relay terminal.
    if not pairs:
        floor = max(floors, key=lambda r:r[2])
        pairs = [(int(floor[0]+40), int(floor[1]), int(floor[0]+112), int(floor[1]))]
    anchors = []
    for floor in sorted(floors, key=lambda r:(-r[1],r[0])):
        if floor[2] < 96: continue
        x, y = floor[0]+floor[2]*0.5, max(84, floor[1]-54)
        if not any(rx-8 <= x <= rx+rw+8 and ry-8 <= y <= ry+rh+8 for rx,ry,rw,rh in geometry):
            if all((x-ax)**2+(y-ay)**2 > 60**2 for ax,ay in anchors):
                anchors.append((int(x),int(y)))
    if not anchors: anchors=[(220,286)]
    text += "\nthread_anchors = " + array("Vector2", anchors[:8])
    text += "\nstitch_pairs = " + array("Vector4", pairs[:3]) + "\n"
    path.write_text(text)

lessons = [
    dict(name="A stitch across",goal="stitch",spawn=(40,289),exit=(600,280),fragment=(330,280),
         platforms=[(16,300,180,16),(440,300,184,16)],spikes=[(196,344,244,16)],pairs=[(180,300,456,300)],anchors=[],
         route=[(160,289),(600,289)],purpose="E beside a square terminal weaves a bridge. Cross the gap."),
    dict(name="Swing the signal",goal="grapple",spawn=(40,289),exit=(600,280),fragment=(500,280),
         platforms=[(16,300,216,16),(440,300,184,16)],spikes=[(232,344,208,16)],pairs=[],anchors=[(320,100)],
         route=[(200,289),(350,280),(500,289),(600,289)],purpose="F grabs a round anchor. Steer to swing. Jump releases you upward."),
    dict(name="A living circuit",goal="relay",spawn=(40,317),exit=(600,308),fragment=(470,308),
         platforms=[(16,328,608,16)],spikes=[],pairs=[(116,328,188,328)],anchors=[(300,220)],gates=[(320,218,12,110)],
         route=[(116,317),(600,317)],purpose="Stitch the square terminals to power the relay and hold the gate open."),
    dict(name="Follow it home",goal="rewind",spawn=(40,317),exit=(100,308),fragment=(540,308),checkpoint=(548,310),
         platforms=[(16,328,608,16)],spikes=[],pairs=[],anchors=[(320,230)],
         route=[(548,317),(100,317)],purpose="Reach the white relay at the far end. Hold Shift to rewind along your thread."),
    dict(name="The unbroken thread",goal="all",spawn=(40,289),exit=(1220,280),fragment=(1150,280),checkpoint=(700,284),size=(1280,360),
         platforms=[(16,300,180,16),(444,300,316,16),(1008,300,256,16)],spikes=[(196,344,248,16),(760,344,248,16)],
         pairs=[(180,300,456,300)],anchors=[(880,95)],gates=[(1120,190,12,110)],
         route=[(160,289),(700,289),(620,289),(750,289),(930,250),(1220,289)],
         purpose="Weave the bridge. Reach the relay and rewind. Swing across. Deliver the signal."),
]
folder=ROOT/'scenes/levels/chapter_05';folder.mkdir(exist_ok=True)
for n,lesson in enumerate(lessons,1):
    ident=f'chapter_05_room_{n:02}'
    scene='[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/gameplay/level_root.gd" id="1"]\n[node name="CurrentLevel" type="Node2D"]\nscript = ExtResource("1")\n'
    scene+=f'level_id = "{ident}"\n'
    for key,field in [('spawn','spawn'),('exit_position','exit'),('fragment_position','fragment'),('world_size','size'),('thread_checkpoint','checkpoint')]:
        if field in lesson: scene+=f'{key} = Vector2({", ".join(map(str,lesson[field]))})\n'
    for key,kind,field in [('platforms','Rect2','platforms'),('spikes','Rect2','spikes'),('gates','Rect2','gates'),('route','Vector2','route'),('thread_anchors','Vector2','anchors'),('stitch_pairs','Vector4','pairs')]:
        scene+=f'{key} = {array(kind,lesson.get(field,[]))}\n'
    scene+=f'purpose = "{lesson["purpose"]}"\nchapter = 5\nrequired_skill = "thread_{lesson["goal"]}"\nthread_goal = "{lesson["goal"]}"\n'
    if lesson.get('gates'): scene+='gate_period = 5.0\ngate_open_time = 0.75\n'
    (folder/f'room_{n:02}.tscn').write_text(scene)
    nxt=f'chapter_05_room_{n+1:02}' if n<5 else ''
    (ROOT/f'data/campaign/{ident}.tres').write_text(f'''[gd_resource type="Resource" script_class="LevelDefinition" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/resources/level_definition.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/levels/chapter_05/room_{n:02}.tscn" id="2"]
[resource]
script = ExtResource("1")
stable_id = "{ident}"
display_name = "{lesson['name']}"
chapter = 5
scene = ExtResource("2")
next_level_id = "{nxt}"
target_seconds = 20.0
has_fragment = true
''')
p=ROOT/'data/campaign/chapter_04_room_10.tres'
p.write_text(p.read_text().replace('next_level_id = ""','next_level_id = "chapter_05_room_01"'))
print('Authored thread anchors in 40 rooms and 5 Threadwork lessons')
