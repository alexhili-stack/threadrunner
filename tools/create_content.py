"""Author original room scenes, procedural audio, and concise local workflows."""
from pathlib import Path
import json
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]

def write(name, text):
    path = ROOT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def room(index, platforms, spikes, route, fragment, purpose, movers=(), gates=(), spawn=(40,317), exit=(600,308)):
    chapter, number = index // 10 + 1, index % 10 + 1
    platforms = [(0,56,16,288),(624,56,16,288)] + platforms
    def arr(values, kind):
        return '[' + ', '.join(f'{kind}(' + ', '.join(str(v) for v in item) + ')' for item in values) + ']'
    text = f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/gameplay/level_root.gd" id="1"]
[node name="CurrentLevel" type="Node2D"]
script = ExtResource("1")
level_id = "chapter_{chapter:02d}_room_{number:02d}"
spawn = Vector2{spawn}
exit_position = Vector2{exit}
fragment_position = Vector2{fragment}
platforms = Array[Rect2]({arr(platforms, 'Rect2')})
spikes = Array[Rect2]({arr(spikes, 'Rect2')})
movers = Array[Vector4]({arr(movers, 'Vector4')})
gates = Array[Rect2]({arr(gates, 'Rect2')})
route = Array[Vector2]({arr(route, 'Vector2')})
purpose = "{purpose}"
'''
    write(f'scenes/levels/chapter_{chapter:02d}/room_{number:02d}.tscn', text)

FLOOR = [(16,328,608,16)]

# Each entry is authored geometry, not a procedural runtime level generator.
ROOMS = [
 (FLOOR+[(152,280,80,16),(352,264,80,16)], [], [(188,269),(390,253),(600,317)], (390,235), 'Hold jump to go higher. Release to cut your ascent.'),
 ([(16,328,160,16),(256,328,368,16)], [], [(150,317),(256,270),(600,317)], (218,255), 'Read the landing before you leave the edge.'),
 (FLOOR+[(180,264,144,16)], [(184,316,96,12)], [(150,317),(233,253),(358,275),(600,317)], (247,230), 'A short tap keeps your jump low.'),
 (FLOOR+[(136,280,64,16),(296,232,80,16),(472,280,64,16)], [], [(168,269),(332,221),(504,269),(600,317)], (332,202), 'Take the high route. Every platform is a safe place to stop.'),
 ([(16,328,176,16),(272,280,80,16),(432,328,192,16)], [(432,316,56,12)], [(172,317),(308,269),(520,277),(600,317)], (308,244), 'Land, settle, then choose your next jump.'),
 (FLOOR+[(192,168,16,160),(208,168,160,16)], [], [(166,317),(176,247),(178,183),(245,157),(405,228),(600,317)], (290,148), 'Press toward a wall to slow your fall. Jump pushes you away.'),
 (FLOOR+[(208,200,24,128),(232,200,120,16)], [], [(178,317),(193,238),(205,175),(285,189),(412,252),(600,317)], (286,165), 'Jump from the wall, then steer back toward the ledge.'),
 (FLOOR+[(176,168,16,160),(272,120,16,208),(288,120,112,16)], [], [(150,317),(160,238),(225,211),(257,150),(322,109),(458,212),(600,317)], (353,98), 'Alternate walls. One jump button, no extra abilities.'),
 (FLOOR+[(144,280,64,16),(320,232,64,16),(496,280,64,16)], [(240,316,64,12),(400,316,64,12)], [(176,269),(352,221),(528,269),(600,317)], (352,197), 'The fragment only stays yours when you finish the room.'),
 ([(16,328,144,16),(240,280,80,16),(400,232,80,16),(552,280,72,16)], [(240,316,80,12)], [(138,317),(276,269),(436,221),(588,269)], (436,199), 'Departure test: connect the moves you already know.', (), (), (40,317),(600,260)),
 (FLOOR, [], [(130,317),(218,260),(336,317),(418,260),(600,317)], (419,247), 'The saw follows a fixed path. Watch one cycle before crossing.', ((240,230,82,3.6),)),
 (FLOOR+[(160,280,80,16),(368,264,80,16)], [], [(197,269),(300,245),(405,253),(600,317)], (405,229), 'The platforms are observation points.', ((300,210,98,3.2),)),
 (FLOOR, [], [(200,317),(300,317),(420,317),(600,317)], (350,277), 'Gates are safe when open. Solid crosshatching means danger.', (), ((320,224,12,104),)),
 (FLOOR+[(184,272,80,16),(400,248,80,16)], [(280,316,64,12)], [(220,261),(322,236),(438,237),(600,317)], (438,211), 'Give moving parts room to pass.', ((327,170,116,4.0),)),
 (FLOOR+[(160,280,80,16),(352,248,96,16)], [], [(198,269),(290,245),(396,237),(600,317)], (396,215), 'The cycle bar tells you when the window will close.', (), ((290,190,12,138),)),
 (FLOOR+[(240,280,128,16)], [], [(292,269),(600,317)], (306,245), 'A quiet room. Breathe, then move.'),
 (FLOOR+[(144,280,64,16),(320,248,80,16),(496,280,64,16)], [], [(176,269),(359,237),(528,269),(600,317)], (359,212), 'Find a rhythm. The machines restart with you.', ((257,190,122,3.4),(451,180,128,4.4))),
 (FLOOR+[(192,184,16,144),(208,184,144,16)], [], [(160,317),(177,245),(178,195),(270,173),(430,252),(600,317)], (290,153), 'Use a wall slide to wait for an opening.', (), ((390,224,12,104),)),
 (FLOOR+[(160,280,80,16),(368,248,96,16)], [(270,316,64,12)], [(198,269),(310,235),(416,237),(600,317)], (416,214), 'Two paths cross. Yours is the one you control.', ((290,176,112,3.8),(510,186,120,4.2))),
 (FLOOR+[(152,280,64,16),(328,232,80,16),(504,280,64,16)], [(240,316,64,12)], [(184,269),(368,221),(536,269),(600,317)], (368,198), 'Clockwork test: wait, jump, commit.', ((270,184,112,4.4),), ((462,224,12,104),)),
 ([(16,328,144,16),(240,280,64,16),(384,232,64,16),(528,280,96,16)], [], [(140,317),(272,269),(416,221),(576,269),(600,269)], (416,198), 'Fewer places to rest. The same familiar movement.', (), (), (40,317),(600,260)),
 (FLOOR+[(144,280,48,16),(288,232,48,16),(432,184,64,16)], [(208,316,64,12),(352,316,64,12)], [(168,269),(312,221),(464,173),(600,245)], (464,151), 'Centre each landing before the next takeoff.'),
 (FLOOR+[(160,200,16,128),(176,200,112,16),(384,152,112,16)], [], [(132,317),(145,244),(147,187),(232,189),(355,175),(432,141),(600,245)], (432,120), 'The straight line is not always the route.'),
 (FLOOR+[(144,280,64,16),(304,232,64,16),(464,280,64,16)], [], [(176,269),(336,221),(496,269),(600,317)], (336,198), 'Pass the signal across the room.', ((245,184,112,3.2),(414,168,128,3.8))),
 (FLOOR+[(192,280,80,16),(400,280,80,16)], [], [(232,269),(440,269),(600,317)], (440,245), 'A breath before the final sequence.'),
 (FLOOR+[(144,280,48,16),(288,232,64,16),(464,184,64,16)], [(208,316,64,12),(376,316,64,12)], [(168,269),(320,221),(496,173),(600,245)], (496,151), 'Place your jumps. You have done each part before.', (), ((411,224,12,104),)),
 (FLOOR+[(176,264,80,16),(368,216,80,16)], [], [(215,253),(312,225),(408,205),(600,278)], (408,182), 'A closing window is an invitation to wait.', ((298,152,128,4.4),), ((500,216,12,112),)),
 (FLOOR+[(192,168,16,160),(208,168,144,16),(464,216,80,16)], [(368,316,64,12)], [(160,317),(177,243),(178,183),(280,157),(410,192),(504,205),(600,285)], (290,138), 'Recover on the wall. Keep the fragment through the exit.', ((408,220,88,4.6),)),
 ([(16,328,144,16),(240,280,64,16),(384,232,64,16),(544,280,80,16)], [], [(140,317),(272,269),(416,221),(588,269)], (416,199), 'The daylight is close. Make the landings count.', ((340,200,108,4.2),), (), (40,317),(600,260)),
 (FLOOR+[(144,280,64,16),(304,232,64,16),(464,184,80,16)], [(224,316,64,12),(384,316,64,12)], [(176,269),(336,221),(504,173),(600,245)], (504,150), 'Final transmission. Nothing new. Everything you have learned.', ((252,184,110,4.4),), ((420,224,12,104),))
]

for index, values in enumerate(ROOMS):
    room(index, *values)

# Laboratory and visual test use the actual runtime level class.
lab = (ROOT/'scenes/levels/chapter_01/room_08.tscn').read_text()
write('scenes/levels/prototype/movement_lab.tscn', lab.replace('chapter_01_room_08', 'movement_lab'))
write('scenes/levels/prototype/visual_test.tscn', (ROOT/'scenes/levels/chapter_02/room_10.tscn').read_text().replace('chapter_02_room_10', 'visual_test'))

specs = {
 'architecture': ('scene, service, resource and save-boundary changes', 'docs/architecture.md', 'Keep player, visuals, attempts, saves and catalog responsibilities separate. Preserve stable IDs and save compatibility. Run tools/qa.py after dependency or service changes.'),
 'movement': ('controller, collision, jump timing or MovementConfig changes', 'docs/movement_spec.md', 'Use tests/movement/test_player.gd against the actual CharacterBody2D. Reproduce the failure before editing. Keep one tuning Resource; never change physics per room. Run movement plus lifecycle and route regressions.'),
 'level-design': ('room geometry, hazards or campaign-order changes', 'docs/level_design_rules.md', 'Set one teaching goal. Author geometry in the room scene. Keep safe spawn and readable hazards. Run real-controller exit and fragment routes three times. Do not teleport, suppress hazards or grant collectibles in fixtures. Record evidence in docs/campaign_review.md.'),
 'qa': ('gameplay regressions and milestone verification', 'docs/acceptance_tests.md', 'Run tools/qa.py; preserve logs and discovered test counts in artifacts. Report executed PASS/FAIL and unavailable NOT RUN separately. Never weaken valid assertions to get green. Stop after three materially different failed repair approaches and record the blocker.'),
 'art-direction': ('figure, HUD, menus, effects and audio feedback changes', 'docs/art_direction.md', 'Keep the white courier, teal scarf, crosshatched lethal gates, spike triangles and diamond fragments distinct. Preserve collisions and retry latency. Inspect actual captures. Record asset rights in docs/asset_provenance.md; distinguish listening from event tests.'),
 'release': ('local exports, manifests and store-material preparation', 'docs/release_checklist.md', 'Run the canonical QA wrapper. Export and launch separately; record target, engine, hash and actual evidence. Keep tests and private paths out of the export. Prepare local materials only; publishing, uploads, payments and account actions are outside this workflow.')
}
for suffix,(trigger,reference,body) in specs.items():
    name='threadrunner-'+suffix
    write(f'.agents/skills/{name}/SKILL.md', f'---\nname: {name}\ndescription: Handle Threadrunner {trigger}.\n---\n\nRead AGENTS.md and [{reference}](../../../{reference}) before editing.\n\n{body}\n')

random.seed(7)
for event,(start,end,duration) in {
 'jump':(420,840,.09),'wall_jump':(540,1060,.11),'land':(150,65,.05),
 'death':(220,45,.13),'fragment':(880,1760,.18),'clear':(523,1046,.32),
 'menu':(650,780,.035),'respawn':(330,660,.06)
}.items():
    path=ROOT/f'assets/audio/{event}.wav';path.parent.mkdir(parents=True,exist_ok=True)
    samples=[]
    for i in range(int(22050*duration)):
        t=i/22050;u=t/duration
        phase=math.tau*(start*t+(end-start)*t*t/(2*duration))
        envelope=math.sin(math.pi*u)**1.5
        tone=math.sin(phase)*.22 + math.sin(phase*2)*.045
        if event in ('land','death'): tone += random.uniform(-.06,.06)
        samples.append(struct.pack('<h',int(tone*envelope*32767)))
    with wave.open(str(path),'wb') as out:
        out.setparams((1,2,22050,0,'NONE','not compressed'));out.writeframes(b''.join(samples))
print('Authored 30 room scenes, 2 labs, 6 local skills and 8 original sounds.')
