-- ============================================================
-- MATERIALS
-- ============================================================
insert into materials (id, name, aliases, category, icon) values
  ('00000000-0000-0000-0000-000000000001', 'Cardboard', '{"cardboard box","corrugated cardboard","box"}', 'paper', '📦'),
  ('00000000-0000-0000-0000-000000000002', 'Toilet Paper Roll', '{"cardboard tube","paper roll","tp roll"}', 'tubes', '🧻'),
  ('00000000-0000-0000-0000-000000000003', 'Tape', '{"scotch tape","masking tape","duct tape","sticky tape"}', 'connectors', '🩹'),
  ('00000000-0000-0000-0000-000000000004', 'Markers', '{"marker","felt tip","crayons","pens"}', 'art', '🖊️'),
  ('00000000-0000-0000-0000-000000000005', 'Plastic Cup', '{"plastic cup","disposable cup","cup"}', 'containers', '🥤'),
  ('00000000-0000-0000-0000-000000000006', 'Bottle Caps', '{"bottle cap","lid","cap"}', 'containers', '🪙'),
  ('00000000-0000-0000-0000-000000000007', 'String', '{"twine","yarn","thread","cord"}', 'connectors', '🧵'),
  ('00000000-0000-0000-0000-000000000008', 'Egg Carton', '{"egg box","egg container","egg tray"}', 'containers', '🥚'),
  ('00000000-0000-0000-0000-000000000009', 'Foil', '{"aluminum foil","tin foil","silver foil"}', 'paper', '✨'),
  ('00000000-0000-0000-0000-000000000010', 'Glue', '{"glue stick","white glue","craft glue","pva glue"}', 'connectors', '🗜️'),
  ('00000000-0000-0000-0000-000000000011', 'Paper', '{"copy paper","printer paper","construction paper","newspaper"}', 'paper', '📄'),
  ('00000000-0000-0000-0000-000000000012', 'Cereal Box', '{"cereal box","food box","cardboard box"}', 'containers', '🥣'),
  ('00000000-0000-0000-0000-000000000013', 'Rubber Bands', '{"elastic band","rubber band","hair tie"}', 'connectors', '🔁'),
  ('00000000-0000-0000-0000-000000000014', 'Popsicle Sticks', '{"craft sticks","ice pop sticks","wooden sticks"}', 'wood', '🪵'),
  ('00000000-0000-0000-0000-000000000015', 'Paint', '{"acrylic paint","watercolor","tempera paint","craft paint"}', 'art', '🎨')
on conflict (id) do nothing;

-- ============================================================
-- PROJECTS
-- ============================================================

-- 1. Cardboard Rocket Ship
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000001',
  'Cardboard Rocket Ship',
  'cardboard-rocket-ship',
  'Build a towering rocket ship from cardboard and toilet paper tubes. Decorate with foil and markers for a space-ready finish.',
  4, 10, 30, 'low', 'check_in', 'easy',
  '{"Use scissors carefully — adult should pre-cut shapes for young children","Avoid sharp edges on cardboard"}',
  '[
    {"step":1,"instruction":"Cut a large triangle from cardboard for the rocket nose cone.","tip":"Make it about as tall as a ruler for good proportions."},
    {"step":2,"instruction":"Stand two toilet paper rolls upright side by side and tape them together to form the rocket body.","tip":"Overlap by about an inch so it stays sturdy."},
    {"step":3,"instruction":"Tape the triangle nose cone to the top of the rocket body."},
    {"step":4,"instruction":"Cut two small fins from leftover cardboard and tape one to each side near the bottom."},
    {"step":5,"instruction":"Wrap a piece of foil around the rocket body and smooth it flat.","tip":"Crinkle it slightly for a metallic texture."},
    {"step":6,"instruction":"Use markers to draw windows, flames, and your astronaut''s name on the rocket.","tip":"A red and orange flame at the bottom looks great!"}
  ]'::jsonb,
  false
);

-- 2. Bottle Cap Robot
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000002',
  'Bottle Cap Robot',
  'bottle-cap-robot',
  'Assemble a quirky little robot from bottle caps and cardboard scraps. Give it a face and a personality!',
  5, 12, 25, 'low', 'check_in', 'easy',
  '{"Let glue dry fully before handling the finished robot","Bottle caps may have sharp edges — inspect before use"}',
  '[
    {"step":1,"instruction":"Cut a small rectangle of cardboard (about the size of your hand) for the robot body."},
    {"step":2,"instruction":"Glue two bottle caps onto the upper body as eyes.","tip":"Use more glue than you think you need — caps are heavy."},
    {"step":3,"instruction":"Glue a row of three caps across the middle as buttons or a chest panel."},
    {"step":4,"instruction":"Cut two thin strips of cardboard for arms and glue them to each side."},
    {"step":5,"instruction":"Use markers to draw a mouth, nose, and any circuit lines or details."},
    {"step":6,"instruction":"Let everything dry for 10 minutes before standing it up or playing with it.","tip":"Prop it against a cup while it dries."}
  ]'::jsonb,
  false
);

-- 3. Egg Carton Creature
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000003',
  'Egg Carton Creature',
  'egg-carton-creature',
  'Turn an egg carton into a bumpy, colorful creature — could be a caterpillar, a monster, or something totally new!',
  3, 8, 20, 'medium', 'adult_assist', 'easy',
  '{"Keep paint off clothing — use an old shirt or apron","Wash hands after painting","Adult should cut the egg carton if scissors are needed"}',
  '[
    {"step":1,"instruction":"Cut the egg carton lengthwise into a strip of 6 cups — this is your creature body.","safety_note":"Adult should do this step with scissors."},
    {"step":2,"instruction":"Paint the whole strip your favourite creature colour.","tip":"Two coats gives a brighter result. Let each coat dry before adding the next."},
    {"step":3,"instruction":"While the body dries, cut two small antennae or horns from leftover cardboard."},
    {"step":4,"instruction":"Glue the antennae to the first cup (the head)."},
    {"step":5,"instruction":"Draw or paint eyes, a mouth, and spots when the base coat is dry."},
    {"step":6,"instruction":"Name your creature and show it off!","tip":"You can make a whole family using a full egg carton."}
  ]'::jsonb,
  false
);

-- 4. Cup-and-String Phone
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000004',
  'Cup-and-String Phone',
  'cup-and-string-phone',
  'Make a real working telephone with two cups and a piece of string. Talk to a friend across the room!',
  4, 10, 10, 'low', 'check_in', 'easy',
  '{"An adult should make the hole in the cup bottom to avoid injury","Keep the string taut during use — do not wrap around fingers or neck"}',
  '[
    {"step":1,"instruction":"Ask a grown-up to poke a small hole in the bottom of each plastic cup using a pencil or pin.","safety_note":"Adult step — sharp point required."},
    {"step":2,"instruction":"Thread one end of a long piece of string through the hole in the first cup, going from the outside in."},
    {"step":3,"instruction":"Tie a big knot at the end inside the cup so it cannot pull back through."},
    {"step":4,"instruction":"Thread the other end of the string through the second cup the same way and tie a knot."},
    {"step":5,"instruction":"Hold one cup each with a friend and walk apart until the string is tight."},
    {"step":6,"instruction":"One person talks into the cup while the other holds their cup to their ear.","tip":"The string must be straight and tight — it carries the sound vibrations!"}
  ]'::jsonb,
  false
);

-- 5. Cereal Box Puppet Theater
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000005',
  'Cereal Box Puppet Theater',
  'cereal-box-puppet-theater',
  'Transform a cereal box into a mini stage. Put on a show with paper puppets behind the curtain!',
  5, 12, 45, 'low', 'check_in', 'medium',
  '{"Adult should cut the stage opening with a craft knife or strong scissors","Watch fingers when cutting"}',
  '[
    {"step":1,"instruction":"Lay the cereal box flat with the large face up. Cut a rectangle out of the center — leave a 1-inch border all around.","safety_note":"Adult should make this cut.","tip":"This rectangle is your stage opening."},
    {"step":2,"instruction":"Decorate the frame around the opening with markers — draw curtains, stars, the theater name."},
    {"step":3,"instruction":"Cut two small rectangles of paper or fabric scraps to be curtains and tape them to the inside top corners."},
    {"step":4,"instruction":"Cut paper puppets — characters, animals, trees — and tape each to a popsicle stick or strip of cardboard."},
    {"step":5,"instruction":"Prop the theater box upright. Hold puppets up through the bottom opening so they appear in the stage window."},
    {"step":6,"instruction":"Write a short play and perform it for family!","tip":"You can make ticket stubs from paper scraps for extra fun."}
  ]'::jsonb,
  false
);

-- 6. Paper Binoculars
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000006',
  'Paper Binoculars',
  'paper-binoculars',
  'Make pretend binoculars from two toilet paper rolls. Perfect for backyard bird-watching adventures.',
  3, 8, 15, 'low', 'independent', 'easy',
  '{"Do not look at the sun through any tubes or lenses"}',
  '[
    {"step":1,"instruction":"Place two toilet paper rolls side by side so the openings line up."},
    {"step":2,"instruction":"Wrap tape around the middle where they touch to hold them together.","tip":"Go around at least three times for a sturdy grip."},
    {"step":3,"instruction":"Decorate the outside with markers — camouflage, bright colours, or a space design."},
    {"step":4,"instruction":"Punch a small hole on the outer side of each tube near one end."},
    {"step":5,"instruction":"Thread a piece of string through both holes and tie knots to make a neck strap."},
    {"step":6,"instruction":"Head outside and look for birds, bugs, or neighbours!","tip":"The closer you hold them to your eyes, the better it feels."}
  ]'::jsonb,
  false
);

-- 7. Foil Moon Rocks
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000007',
  'Foil Moon Rocks',
  'foil-moon-rocks',
  'Scrunch and shape aluminium foil into a collection of lumpy, shiny moon rocks. Simple, tactile, and endlessly fun.',
  3, 8, 10, 'low', 'independent', 'easy',
  '{"Foil edges can be sharp — smooth any points with your fingers","Small pieces: supervise toddlers closely"}',
  '[
    {"step":1,"instruction":"Tear off a sheet of foil about as big as a piece of paper."},
    {"step":2,"instruction":"Scrunch the foil loosely into a ball — squeeze it until it holds its shape.","tip":"The lumpier and craggier, the more it looks like a real rock."},
    {"step":3,"instruction":"Gently press dents, craters, and ridges into the surface with your fingers."},
    {"step":4,"instruction":"Make more rocks of different sizes — a collection of five looks great."},
    {"step":5,"instruction":"Arrange your moon rocks on a dark piece of paper or a tray for a moon-surface display.","tip":"Add a small paper flag or a Lego astronaut for the full effect."}
  ]'::jsonb,
  false
);

-- 8. Tape-and-Cardboard Marble Ramp
insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000008',
  'Tape-and-Cardboard Marble Ramp',
  'marble-ramp',
  'Engineer a zigzag marble run using cardboard strips, tape, and a box for catching. Watch physics in action!',
  6, 12, 45, 'medium', 'check_in', 'medium',
  '{"Marbles are a choking hazard — not for children under 3","Keep marbles off the floor where people walk","Supervise closely for young builders"}',
  '[
    {"step":1,"instruction":"Cut four long strips of cardboard (about 30 cm × 5 cm each) for your ramp sections."},
    {"step":2,"instruction":"Fold each strip lengthwise along the middle to form a shallow V-channel — this guides the marble.","tip":"A 90-degree fold works best."},
    {"step":3,"instruction":"Tape the first ramp to the inside of a large open box at a gentle angle, starting near the top."},
    {"step":4,"instruction":"Tape the second ramp below and going the opposite direction, slightly lower — creating a zigzag."},
    {"step":5,"instruction":"Add the remaining ramps continuing the zigzag pattern. Place a small cup or container at the bottom to catch the marble."},
    {"step":6,"instruction":"Test by dropping a marble at the top. Adjust the angles with extra tape if the marble gets stuck.","tip":"Steeper angles = faster marble. Flatter = slower and more dramatic drops."},
    {"step":7,"instruction":"Time how fast the marble travels and experiment with different angles!","tip":"Use rubber bands stretched across the path to slow the marble down for extra challenge."}
  ]'::jsonb,
  false
);

-- ============================================================
-- PROJECT MATERIALS
-- ============================================================

-- Cardboard Rocket Ship
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true,  'One large flat piece'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', true,  '2 rolls'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', true,  'A roll of tape'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000009', false, 'One sheet');

-- Bottle Cap Robot
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000006', true,  'At least 5 caps'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', true,  'Small scraps'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000010', true,  null),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000011', false, 'Small scraps');

-- Egg Carton Creature
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000008', true,  '1 carton'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000015', true,  'Any colour'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', false, null),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000007', false, 'For antennae');

-- Cup-and-String Phone
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000005', true,  '2 cups'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', true,  'At least 3 metres');

-- Cereal Box Puppet Theater
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000012', true,  '1 large box'),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000004', true,  null),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000003', true,  null),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000011', false, 'For puppet bodies'),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000014', false, 'For puppet handles');

-- Paper Binoculars
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000002', true,  '2 rolls'),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', true,  null),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000007', false, 'For neck strap');

-- Foil Moon Rocks
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000009', true,  'Several sheets');

-- Marble Ramp
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', true,  'Several strips'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000003', true,  'Plenty'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000014', false, 'For ramp supports'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000013', false, 'For marble obstacles');

-- ============================================================
-- MATERIAL SUBSTITUTIONS
-- ============================================================
insert into material_substitutions (source_material_id, replacement_material_id, substitution_notes) values
  -- Cardboard ↔ Cereal Box
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'Flatten a cereal box for thinner but usable cardboard'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'Use corrugated cardboard as a sturdier alternative'),
  -- Tape ↔ Glue
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', 'Glue works for flat surfaces; allow extra drying time'),
  ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000003', 'Tape can hold most joins while glue dries'),
  -- Markers ↔ Paint
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000015', 'Paint gives more colour coverage; needs drying time'),
  ('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000004', 'Markers are faster and less messy than paint'),
  -- Toilet paper roll ↔ Paper (rolled)
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000011', 'Roll and tape a sheet of paper into a tube'),
  -- String ↔ Rubber bands (tied together)
  ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000013', 'Loop rubber bands together to form a short string')
on conflict (source_material_id, replacement_material_id) do nothing;
