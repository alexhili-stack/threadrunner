# Movement

Canonical values: scripts/resources/movement_config.gd and data/movement/default.tres. 240 px/s run, 2400 ground acceleration, 3000 ground deceleration, 1500 air acceleration, -430 jump, 1400 gravity, 700 fall cap, 90 wall slide, (250,-410) wall jump, 100 ms coyote, 120 ms buffer, 80 ms steering lock. Release cuts upward velocity to 45%. No room modifies these values.

Physics is 60 Hz. A fresh jump stores a positive buffer; positive coyote time permits a ground jump. Timers decrement before the eligibility test, so exact zero is outside the window. Tolerance is one physics tick plus 1 px for contact placement. A reset invalidates cached CharacterBody contact for one move_and_slide step; held keyboard jump requires a release before another jump. Synthetic fixture inputs use the same physics function.

Tests in tests/movement/test_player.gd drive the actual scene and real floor, ceiling and wall collisions. Unit setups may place a player at an initial state; campaign fixtures never teleport. Cross-platform determinism and human game feel are not established by these tests.

Version 1.1 retains these exact physics values. Replay fixtures now validate physically consistent press/hold/release edges; variable-jump rooms require an early release in the tested route. Ground-input, controller-feel and wall-steering changes await human playtest evidence rather than speculative tuning.

Version 1.2 adds globally shared thread parameters in data/movement/default.tres: 240px grapple reach, 42px stitch reach, 700 swing steering acceleration, 380 input steering speed cap, -300 upward release, six seconds of rewind history and three samples per rewind tick. Normal movement values above remain unchanged. Swing and rewind use CharacterBody2D collision movement. tests/movement/test_thread.gd exercises rope bounds, release, occlusion, rewind collisions, live hazards, pause and reset.
