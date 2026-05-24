-- ============================================================
-- 003_more_projects.sql
-- Seeds 25 additional projects (IDs ...000000009 through ...000000033)
-- ============================================================

-- ============================================================
-- PROJECT INSERTS
-- ============================================================

-- 1. Paper Airplane
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000009',
  'Paper Airplane',
  'paper-airplane',
  'Fold a classic dart-style paper airplane and launch it across the room. A timeless activity that teaches basic aerodynamics through play.',
  5, 12, 5, 'low', 'check_in', 'easy',
  '{"Throw away from people''s faces","Use only indoors or in calm outdoor areas"}',
  '[{"step":1,"instruction":"Start with a sheet of paper held landscape (wide side facing you). Fold it in half lengthways, then unfold so you have a centre crease.","tip":"A crisp centre crease makes everything line up later."},{"step":2,"instruction":"Fold the top-left and top-right corners down to meet the centre crease, forming a triangle at the top."},{"step":3,"instruction":"Fold the two slanted edges in to the centre crease again to make a sharper point."},{"step":4,"instruction":"Fold the whole plane in half along the centre crease so the point faces forward."},{"step":5,"instruction":"Fold each wing down so its edge aligns with the bottom of the fuselage. Repeat on the other side.","tip":"Equal wings mean a straighter flight."},{"step":6,"instruction":"Hold the fuselage near the middle and throw smoothly forward at a slight upward angle. Adjust wing tips up or down to tune the flight."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 2. Handprint Art
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000010',
  'Handprint Art',
  'handprint-art',
  'Press painted hands onto paper to create colourful prints. A wonderful keepsake craft that doubles as a sensory experience for young children.',
  3, 7, 20, 'high', 'adult_assist', 'easy',
  '{"Use only child-safe, non-toxic paint","Keep paint away from eyes and mouth","Have wet wipes or a sink ready for clean-up"}',
  '[{"step":1,"instruction":"Cover the work surface with newspaper or an old plastic bag to protect it."},{"step":2,"instruction":"Pour a small amount of paint onto a flat tray or plate and spread it into a thin, even layer.","tip":"A foam roller works great for an even coat."},{"step":3,"instruction":"Help the child press their palm and fingers firmly into the paint, coating the whole hand."},{"step":4,"instruction":"Guide the child to press their painted hand onto the paper, holding it still for three seconds, then lift straight up.","tip":"Wiggling smears the print — lift straight up."},{"step":5,"instruction":"Repeat with different colours, rinsing hands between colours if desired."},{"step":6,"instruction":"Allow prints to dry fully (about 20 minutes), then use markers to add details like tree branches, animal features, or flower petals."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 3. Cereal Box Car
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000011',
  'Cereal Box Car',
  'cereal-box-car',
  'Transform an empty cereal box into a rolling toy car with bottle-cap wheels. Great for imaginative play and basic engineering thinking.',
  5, 10, 25, 'low', 'check_in', 'easy',
  '{"Adult should help with any sharp cutting","Keep small bottle caps away from children under 3"}',
  '[{"step":1,"instruction":"Seal the open end of the cereal box with tape so you have a solid rectangular box."},{"step":2,"instruction":"Use a marker to draw windows, doors, and a windscreen on the sides and front of the box.","tip":"Draw lightly first in pencil so you can adjust before going over with marker."},{"step":3,"instruction":"Colour in the windows and any other details with markers."},{"step":4,"instruction":"Cut two pieces of string or a thin strip of cardboard, each about the width of the box, to act as axles. Thread or tape each axle across the underside of the box at the front and rear."},{"step":5,"instruction":"Push a bottle cap onto each end of both axles (or glue them flat to the underside as fixed wheels)."},{"step":6,"instruction":"Stand the car upright and give it a gentle push across a smooth surface to test the wheels.","tip":"If wheels wobble, re-tape the axles so they are parallel."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 4. Rubber Band Guitar
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000012',
  'Rubber Band Guitar',
  'rubber-band-guitar',
  'Stretch rubber bands of different thicknesses across an open cereal box to create a real-sounding mini guitar. Explore how tension and thickness change the pitch.',
  6, 12, 15, 'low', 'check_in', 'easy',
  '{"Do not snap rubber bands at people","Check bands for cracks before stretching; discard worn ones"}',
  '[{"step":1,"instruction":"Cut a large oval or round hole in the front face of a cereal box — this is the sound hole. An adult should help with the cutting."},{"step":2,"instruction":"Decorate the box with markers to make it look like a guitar body."},{"step":3,"instruction":"Select 4–6 rubber bands of varying thicknesses."},{"step":4,"instruction":"Stretch each rubber band lengthways over the box so it crosses over the sound hole, spacing them evenly across the width.","tip":"Thicker bands make lower notes; thinner bands make higher notes."},{"step":5,"instruction":"Gently pluck each band over the hole and listen to the different tones."},{"step":6,"instruction":"Try tightening or loosening individual bands to tune your guitar, or press a finger behind a band to change its pitch."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 5. Tin Foil Boat
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000013',
  'Tin Foil Boat',
  'tin-foil-boat',
  'Shape a piece of aluminium foil into a boat and see how many small objects it can carry before sinking. A classic engineering challenge for curious kids.',
  4, 9, 10, 'low', 'check_in', 'easy',
  '{"Use a shallow container of water on a stable surface","Supervise near water at all times"}',
  '[{"step":1,"instruction":"Tear off a sheet of foil roughly 30 cm × 30 cm (about one foot square)."},{"step":2,"instruction":"Place the foil flat on the table and fold up each edge about 2–3 cm to form the sides of the boat.","tip":"Press the corners firmly so there are no gaps where water can sneak in."},{"step":3,"instruction":"Pinch and fold the corners neatly to seal them."},{"step":4,"instruction":"Gently lower your foil boat onto the surface of the water in a bowl or tray."},{"step":5,"instruction":"Slowly add small items (coins, pebbles, bottle caps) one at a time and count how many the boat holds."},{"step":6,"instruction":"When the boat sinks, dry the foil and experiment with a different shape — wider, higher sides — and try again to beat your record."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 6. Popsicle Stick Picture Frame
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000014',
  'Popsicle Stick Picture Frame',
  'popsicle-stick-picture-frame',
  'Glue popsicle sticks together to build a charming photo frame that makes a wonderful personalised gift.',
  6, 12, 30, 'medium', 'check_in', 'easy',
  '{"Allow glue to dry fully before handling","Keep glue away from eyes"}',
  '[{"step":1,"instruction":"Lay four popsicle sticks in a square, overlapping at the corners. This is your frame shape."},{"step":2,"instruction":"Apply a small dot of glue to each overlapping corner and press firmly. Leave to dry for 5 minutes."},{"step":3,"instruction":"Add a second layer of four sticks on top in the opposite orientation and glue again, building up thickness and strength."},{"step":4,"instruction":"Once fully dry, decorate the frame with markers, paint, or by gluing on small scraps — bottle caps, bits of foil — for texture.","tip":"Keep decorations relatively flat so the frame can rest against a surface."},{"step":5,"instruction":"Cut or fold a favourite drawing or photo to fit behind the frame opening."},{"step":6,"instruction":"Glue a folded piece of cardboard to the back as a stand, or tape a loop of string for hanging."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 7. Toilet Roll Owl
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000015',
  'Toilet Roll Owl',
  'toilet-roll-owl',
  'Turn an empty toilet paper tube into an adorable owl with paper wings and big expressive eyes.',
  4, 9, 20, 'low', 'check_in', 'easy',
  '{"Use child-safe glue","Supervise use of scissors"}',
  '[{"step":1,"instruction":"Gently pinch the top of the toilet paper roll and press inward on both sides to form two pointed ear tufts."},{"step":2,"instruction":"Draw or cut two large circles from paper for eyes. Colour in a smaller dark circle in the centre of each for the pupils and glue them onto the front of the roll."},{"step":3,"instruction":"Cut a small diamond shape from paper or foil, fold it in half, and glue it below the eyes as a beak."},{"step":4,"instruction":"Cut two wing shapes from paper — roughly teardrop-shaped — and draw feather lines on them with a marker."},{"step":5,"instruction":"Glue or tape the wings to the sides of the roll."},{"step":6,"instruction":"Draw feather patterns across the body of the roll with a marker, then stand your owl on a shelf and admire it.","tip":"Add feet cut from paper for extra character."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 8. Cardboard Box Playhouse
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000016',
  'Cardboard Box Playhouse',
  'cardboard-box-playhouse',
  'Use a large cardboard box to build a mini playhouse complete with windows and a door. Perfect for imaginative play and a rainy-day project.',
  4, 10, 45, 'medium', 'check_in', 'medium',
  '{"Adult must do all box-cutter or heavy scissor cuts","Do not allow children inside the box while cutting","Ensure the box is stable before play"}',
  '[{"step":1,"instruction":"Stand a large cardboard box upright and make sure the bottom is sealed firmly with tape."},{"step":2,"instruction":"On one side, draw a door shape — a rectangle with a rounded top. An adult cuts three sides so the door swings open."},{"step":3,"instruction":"On the remaining sides, draw and cut out one or two window holes."},{"step":4,"instruction":"Decorate the outside with markers: add brick or stone patterns, window shutters, flower boxes, and a house number."},{"step":5,"instruction":"Decorate the inside with drawn-on shelves, pictures, or a rug outline on the floor."},{"step":6,"instruction":"Reinforce any sagging edges with strips of tape and place the playhouse on a flat surface ready for imaginative adventures.","tip":"For a roof, cut four triangular flaps from a second box and tape them together over the top."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 9. Friendship Bracelet
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000017',
  'Friendship Bracelet',
  'friendship-bracelet',
  'Braid or knot colourful pieces of string into a bracelet to gift to a friend. A calming craft that builds fine motor skills and patience.',
  8, 12, 25, 'low', 'check_in', 'easy',
  '{"Ensure the finished bracelet is not too tight on the wrist"}',
  '[{"step":1,"instruction":"Cut three pieces of string, each about 60 cm long. Choose different colours for a striped effect."},{"step":2,"instruction":"Hold all three strings together and tie a knot at one end, leaving a 5 cm tail. Tape or clip this end to a table so it stays put while you braid."},{"step":3,"instruction":"Spread the three strings out and begin a simple three-strand braid: right strand over the centre, then left strand over the new centre, repeating.","tip":"Keep even tension for a neat braid."},{"step":4,"instruction":"Continue braiding until the bracelet is long enough to wrap around a wrist with a couple of centimetres to spare."},{"step":5,"instruction":"Tie a knot at the end to secure the braid."},{"step":6,"instruction":"Wrap around the recipient''s wrist and tie the two end knots together. Trim any excess string."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 10. Cup Stacking Game
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000018',
  'Cup Stacking Game',
  'cup-stacking-game',
  'Decorate plastic cups and then race to build the tallest tower or fastest pyramid. An active game that sharpens hand-eye coordination.',
  4, 9, 10, 'low', 'check_in', 'easy',
  '{"Use only on stable, flat surfaces to prevent toppling"}',
  '[{"step":1,"instruction":"Gather at least 10 plastic cups."},{"step":2,"instruction":"Use markers to decorate each cup with patterns, faces, or colours — let creativity run wild.","tip":"Permanent markers work best on plastic; let them dry before stacking."},{"step":3,"instruction":"Practise stacking the cups into a simple pyramid: 4 cups on the bottom row, 3 on the next, then 2, then 1 on top."},{"step":4,"instruction":"Time yourself building the pyramid and then collapsing it back into a single stack."},{"step":5,"instruction":"Try different formations: a tall single tower, a star shape, or a staircase."},{"step":6,"instruction":"Challenge a friend or sibling to see who can build the tallest tower without it falling."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 11. Bottle Cap Wind Chime
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000019',
  'Bottle Cap Wind Chime',
  'bottle-cap-wind-chime',
  'Thread painted bottle caps onto string and hang them from a popsicle stick to make a colourful wind chime that chimes in the breeze.',
  6, 12, 20, 'low', 'check_in', 'easy',
  '{"An adult should help punch holes in bottle caps","Avoid sharp edges on bent caps"}',
  '[{"step":1,"instruction":"Collect 6–10 bottle caps and use a hammer and nail (adult only) or a hole punch to make one small hole near the edge of each cap."},{"step":2,"instruction":"Decorate the caps with paint or markers and leave to dry."},{"step":3,"instruction":"Cut 4–6 lengths of string, each between 15 and 25 cm, varying the lengths for visual interest."},{"step":4,"instruction":"Thread 1–3 bottle caps onto each string and knot below each cap so it hangs at the desired position."},{"step":5,"instruction":"Tie the strings at regular intervals along a popsicle stick or short twig."},{"step":6,"instruction":"Tie a final string across both ends of the stick to create a hanger. Hang outside or near a window and listen for the gentle clinking."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 12. Egg Carton Garden
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000020',
  'Egg Carton Garden',
  'egg-carton-garden',
  'Paint the cups of an egg carton in bright colours and fill them with soil or cotton wool to sprout seeds — or simply turn them into flower sculptures.',
  4, 9, 25, 'high', 'check_in', 'easy',
  '{"Use non-toxic paint","Wash hands after handling soil","Keep painted items away from mouth"}',
  '[{"step":1,"instruction":"Cut the lid off the egg carton and set it aside. You will use the bottom half with its 12 individual cups."},{"step":2,"instruction":"Paint the outside of each cup a different colour and let dry completely (about 10 minutes)."},{"step":3,"instruction":"To make flower sculptures: cut petal shapes from paper and glue them around the outside rim of each cup; push a popsicle stick through the bottom for a stem."},{"step":4,"instruction":"Alternatively, fill each cup with a small amount of damp cotton wool or potting soil."},{"step":5,"instruction":"Press 2–3 seeds (cress or sunflower work well) into each cup and lightly cover."},{"step":6,"instruction":"Place on a sunny windowsill and water lightly every day. Watch your garden sprout in just a few days!","tip":"Cress sprouts in as little as 3 days — perfect for impatient young gardeners."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 13. Paper Collage
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000021',
  'Paper Collage',
  'paper-collage',
  'Tear and cut colourful pieces of paper, then glue them together to make a vibrant picture. A wonderful open-ended art activity for toddlers and pre-schoolers.',
  3, 7, 20, 'medium', 'adult_assist', 'easy',
  '{"Use child-safe glue sticks","Supervise tearing to avoid paper cuts","Keep glue away from eyes"}',
  '[{"step":1,"instruction":"Set out a large sheet of paper as the background and arrange a selection of colourful scrap paper, old magazine pages, or tissue paper."},{"step":2,"instruction":"Help the child tear or cut the scrap paper into small pieces — different shapes and sizes add interest."},{"step":3,"instruction":"Apply glue to the back of each piece and press it onto the background paper.","tip":"A glue stick is less messy than liquid glue for young children."},{"step":4,"instruction":"Layer pieces on top of each other, overlapping colours to discover mixing effects."},{"step":5,"instruction":"Add drawn details with markers — faces, outlines, or patterns — once the glue has dried."},{"step":6,"instruction":"Allow the finished collage to dry flat for 10 minutes before displaying."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 14. Periscope
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000022',
  'Periscope',
  'periscope',
  'Build a working periscope from two toilet rolls and pieces of foil to see around corners and over obstacles — just like a submarine!',
  7, 12, 30, 'low', 'check_in', 'medium',
  '{"Adult should help with any cutting","Handle foil edges carefully to avoid small cuts"}',
  '[{"step":1,"instruction":"Tape two toilet paper rolls end to end with a strip of tape to create one long tube."},{"step":2,"instruction":"Cut two squares of foil slightly larger than the diameter of the tube."},{"step":3,"instruction":"Carefully smooth each foil square as flat and wrinkle-free as possible — this is your mirror surface."},{"step":4,"instruction":"Cut a small square viewing hole near the bottom of the tube on one side, and another near the top on the opposite side."},{"step":5,"instruction":"Angle and tape a foil square at 45° inside the tube at each end, facing the corresponding viewing hole so that light from the top hole reflects down to the bottom hole.","tip":"Getting the 45° angle right is the tricky part — check by looking through the bottom hole and adjusting until you see light from above."},{"step":6,"instruction":"Look through the lower hole while holding the tube vertically to see over walls or around the corner of a door."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 15. Cardboard Shield
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000023',
  'Cardboard Shield',
  'cardboard-shield',
  'Cut a shield shape from cardboard, cover it in foil for a metallic finish, and decorate it with a crest design. Perfect for imaginative battles and costume play.',
  5, 12, 25, 'low', 'check_in', 'easy',
  '{"Adult should help with cutting the cardboard","Do not use the shield to hit people or objects"}',
  '[{"step":1,"instruction":"Draw a shield shape on a piece of flat cardboard — a classic kite shape or a rounded-bottom rectangle both work well."},{"step":2,"instruction":"An adult cuts along the outline with scissors or a craft knife."},{"step":3,"instruction":"Cover the front of the shield with foil, wrapping the edges around the back and taping them securely.","tip":"Smooth the foil from the centre outwards to reduce wrinkles and get a shiny finish."},{"step":4,"instruction":"Draw your crest design on paper — a dragon, lightning bolt, or family symbol — cut it out, and glue it to the centre of the shield."},{"step":5,"instruction":"Cut a strip of cardboard about 25 cm long and 4 cm wide. Arch it into a handle shape and tape both ends firmly to the back of the shield."},{"step":6,"instruction":"Allow all glue and tape to set, then slide your arm through the handle and head into battle."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 16. Glue String Art
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000024',
  'Glue String Art',
  'glue-string-art',
  'Dip string in craft glue and arrange it on cardboard to create stunning abstract or geometric designs. When dry, the hardened string holds its shape beautifully.',
  9, 12, 50, 'high', 'check_in', 'advanced',
  '{"Keep liquid glue away from eyes","Work on a covered surface — glue is hard to remove","Wash hands thoroughly after handling glue"}',
  '[{"step":1,"instruction":"Cover your work surface with plastic wrap or a bin bag. Cut several lengths of string between 20 and 50 cm each."},{"step":2,"instruction":"Pour a generous pool of craft glue into a shallow dish."},{"step":3,"instruction":"Submerge a length of string in the glue and run it between two fingers to remove excess, leaving the string fully saturated but not dripping."},{"step":4,"instruction":"Arrange the string on a piece of cardboard in your chosen design — swirls, geometric angles, letters, or an abstract shape. Press gently so it adheres.","tip":"Work quickly; glue-soaked string dries faster than you expect."},{"step":5,"instruction":"Repeat with more strings, layering and crossing them to build up the design."},{"step":6,"instruction":"Leave to dry completely — at least 2 hours, ideally overnight. Once dry, the string will be stiff and hold its form. You can paint over the whole piece or leave the natural string colour."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 17. Paper Hat
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000025',
  'Paper Hat',
  'paper-hat',
  'Fold a classic newspaper-style paper hat that actually fits on your head. A quick and satisfying origami-inspired project for young crafters.',
  4, 10, 10, 'low', 'check_in', 'easy',
  '{"Use paper large enough to fit the child''s head — standard A4 may be too small; use a sheet of newspaper instead"}',
  '[{"step":1,"instruction":"Fold a large sheet of paper in half widthways (the short way) so you have a long rectangle."},{"step":2,"instruction":"Fold it in half again lengthways, then unfold to reveal a centre crease running down the middle."},{"step":3,"instruction":"Fold the top-left and top-right corners down to meet the centre crease, forming a triangle across the top half."},{"step":4,"instruction":"Fold the bottom strip of the front layer up over the base of the triangle, then flip the hat over and repeat on the other side."},{"step":5,"instruction":"Open the hat gently from the bottom by pushing in on the sides, shaping it into a hat you can wear."},{"step":6,"instruction":"Decorate with markers — add a band, stars, or a name badge — then pop it on your head."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 18. Popsicle Stick Raft
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000026',
  'Popsicle Stick Raft',
  'popsicle-stick-raft',
  'Lash or glue popsicle sticks together with string to build a raft and test how much weight it can float. A fun introduction to buoyancy and construction.',
  7, 12, 35, 'medium', 'check_in', 'medium',
  '{"Supervise near water","Use a shallow basin — not a deep bath or outdoor water feature","Allow glue to dry fully before water testing"}',
  '[{"step":1,"instruction":"Lay 8–10 popsicle sticks side by side on a flat surface, touching, to form the deck of the raft."},{"step":2,"instruction":"Spread a line of glue across two popsicle sticks positioned perpendicular to the deck sticks, one near each end. Press the deck sticks onto these crosspieces and hold until the glue grips.","tip":"Clothes pegs or bulldog clips are excellent for holding joints while the glue dries."},{"step":3,"instruction":"Leave to dry for at least 20 minutes (or as instructed on your glue packaging)."},{"step":4,"instruction":"For extra strength, tie short lengths of string around each crosspiece and the deck sticks beside it, knotting tightly."},{"step":5,"instruction":"Make a small sail from paper and a popsicle stick mast. Glue or tape the mast to the centre of the raft."},{"step":6,"instruction":"Lower the raft gently onto water in a bowl or tray. Gradually add small items — coins, pebbles — to measure its load capacity."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 19. Toilet Roll Stamp Printing
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000027',
  'Toilet Roll Stamp Printing',
  'toilet-roll-stamp-printing',
  'Squish toilet paper rolls into different shapes and use them as stamps to print colourful patterns and pictures on paper.',
  3, 7, 15, 'high', 'adult_assist', 'easy',
  '{"Use only non-toxic, washable paint","Keep paint away from eyes and mouth","Protect clothes and surfaces before starting"}',
  '[{"step":1,"instruction":"Cover the table with newspaper and put on an apron or old clothes."},{"step":2,"instruction":"Pour small amounts of different coloured paints onto separate flat plates or trays."},{"step":3,"instruction":"Take a toilet paper roll and, to make a heart shape, pinch the tube at the top to create two bumps and a point at the bottom."},{"step":4,"instruction":"Press the shaped end of the roll into the paint, coating the rim evenly."},{"step":5,"instruction":"Press the painted rim firmly onto paper and lift straight up to reveal the stamp.","tip":"Try other shapes: leave the roll round for circles, or pinch it flat for a rectangle."},{"step":6,"instruction":"Create a picture using multiple stamps — trees, flowers, caterpillars, or fireworks. Allow the paint to dry before touching."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 20. Painted Bottle Cap Magnets
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000028',
  'Painted Bottle Cap Magnets',
  'painted-bottle-cap-magnets',
  'Paint bottle caps with tiny designs and turn them into fridge magnets. A great way to recycle and create personalised gifts.',
  5, 10, 20, 'medium', 'check_in', 'easy',
  '{"Keep small magnets away from children under 3","Ensure paint is fully dry before sticking to the fridge","Use non-toxic paint"}',
  '[{"step":1,"instruction":"Wash and dry the bottle caps thoroughly."},{"step":2,"instruction":"Apply a base coat of paint to the inside of each cap and leave to dry for 5 minutes."},{"step":3,"instruction":"Paint a small design on each cap: a tiny face, a star, a heart, a letter of your name, or a miniature landscape.","tip":"Use the tip of a toothpick to add fine details."},{"step":4,"instruction":"Allow the paint to dry completely."},{"step":5,"instruction":"If desired, apply a thin coat of clear craft glue on top as a sealant and leave to dry again."},{"step":6,"instruction":"Stick a small adhesive magnet to the back of each cap (or use a glue gun with adult help) and press onto the fridge to display your collection."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 21. Rubber Band Ball
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000029',
  'Rubber Band Ball',
  'rubber-band-ball',
  'Wind rubber bands around each other to build a bouncy ball from scratch. Satisfying to make and surprisingly good at bouncing!',
  6, 12, 15, 'low', 'check_in', 'easy',
  '{"Do not snap rubber bands at people","Check bands for cracks before use","Supervise to ensure no one puts bands near their mouth"}',
  '[{"step":1,"instruction":"Start with one rubber band and fold it over itself several times until it forms a small, tight wad — this is your core."},{"step":2,"instruction":"Stretch a second rubber band around the core in one direction, then a third in a different direction to start making it round."},{"step":3,"instruction":"Continue adding rubber bands one at a time, rotating after each one to keep the ball as round as possible.","tip":"Vary the direction of each band — think of wrapping a ball of yarn."},{"step":4,"instruction":"As the ball grows, you will need to use larger bands or double up smaller ones to stretch around the outside."},{"step":5,"instruction":"Keep adding bands until the ball reaches your desired size."},{"step":6,"instruction":"Drop it on a hard floor to test the bounce. The more tightly wound the bands, the higher it will bounce."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 22. Marble Maze
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000030',
  'Marble Maze',
  'marble-maze',
  'Design and build a marble run maze inside a cardboard box using folded card and popsicle stick barriers. Then race your marble to the finish!',
  8, 12, 45, 'low', 'check_in', 'medium',
  '{"Keep marbles away from children under 3","Work on a low, stable surface to prevent falling marbles","Adult should help with heavy-duty cutting"}',
  '[{"step":1,"instruction":"Start with the lid of a large cardboard box or cut the sides of a box down to about 5 cm tall to create a shallow tray."},{"step":2,"instruction":"Plan your maze on paper first — sketch out a path from start to finish with bends, dead ends, and obstacles."},{"step":3,"instruction":"Cut strips of cardboard about 4 cm wide and fold a 1 cm tab along one long edge. Glue or tape the tabs to the floor of the tray to create walls and channels."},{"step":4,"instruction":"Use popsicle sticks as additional barriers, gluing them at angles to redirect the marble.","tip":"Let each wall set for a few minutes before adding the next so nothing shifts."},{"step":5,"instruction":"Mark a clear START and FINISH with a marker. Place a bottle cap at the finish as the target hole if you want."},{"step":6,"instruction":"Test the maze with a marble. If it gets stuck, adjust the walls. Challenge friends to guide the marble from start to finish by tilting the tray."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 23. Paper Puppet
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000031',
  'Paper Puppet',
  'paper-puppet',
  'Draw, colour, and cut out a character from paper, then attach it to a popsicle stick handle to create a puppet for storytelling and imaginative play.',
  3, 8, 15, 'low', 'adult_assist', 'easy',
  '{"Adult should help young children with scissors","Supervise the popsicle stick handle — avoid waving it near faces"}',
  '[{"step":1,"instruction":"Draw a character on a piece of paper — it could be an animal, a fairy, a robot, or a person. Make it big enough to hold comfortably, roughly the size of a hand."},{"step":2,"instruction":"Colour in the character using markers, making it as bright and detailed as you like."},{"step":3,"instruction":"Carefully cut around the outline of the character. An adult should help younger children with the scissors."},{"step":4,"instruction":"Flip the character over and apply a strip of glue or tape down the centre of the back."},{"step":5,"instruction":"Press a popsicle stick onto the glued area so that it sticks out below the character like a handle. Hold it in place for a minute until secure."},{"step":6,"instruction":"Once dry, use your puppet to act out a story. Try making two or three different characters to put on a full puppet show!"}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 24. Cereal Box Piggy Bank
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000032',
  'Cereal Box Piggy Bank',
  'cereal-box-piggy-bank',
  'Transform an empty cereal box into a painted piggy bank complete with a coin slot. A fun way to teach saving while recycling.',
  6, 12, 20, 'medium', 'check_in', 'easy',
  '{"Adult should help cut the coin slot","Keep coins away from children under 3","Allow paint to dry fully before use"}',
  '[{"step":1,"instruction":"Seal all openings of the cereal box firmly with tape so it is a solid block."},{"step":2,"instruction":"On the top of the box, draw a rectangle about 4 cm long and 0.5 cm wide — the coin slot. An adult cuts this out with a craft knife or scissors."},{"step":3,"instruction":"Paint the whole box in a solid colour — pink for a classic pig, or any colour you like. Allow to dry."},{"step":4,"instruction":"Add details with markers or extra paint: eyes, a snout (a circle), ears (cut from cardboard and taped on), and curly tail details."},{"step":5,"instruction":"If you want feet, cut four small rectangles of cardboard, fold a tab on each, and tape them to the underside."},{"step":6,"instruction":"Drop a coin through the slot to test. To retrieve savings, simply open the bottom tape seal carefully.","tip":"Write your saving goal on a sticky note and attach it to the bank for motivation."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 25. Foil Jewellery
INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES (
  '10000000-0000-0000-0000-000000000033',
  'Foil Jewellery',
  'foil-jewellery',
  'Mould and twist pieces of aluminium foil into shiny rings, bracelets, and pendants. No glue required — just foil and imagination.',
  5, 10, 15, 'low', 'check_in', 'easy',
  '{"Fold any sharp foil edges back to avoid scratching skin","Do not wear jewellery in water"}',
  '[{"step":1,"instruction":"Tear off a strip of foil about 30 cm long and 5 cm wide."},{"step":2,"instruction":"Fold the strip in half lengthways, then fold again (and again if needed) until you have a narrow, sturdy band about 1 cm wide."},{"step":3,"instruction":"For a ring: wrap the band around a finger, overlap the ends, and press firmly to join. Slide off and reshape if needed.","tip":"Wrap around a marker barrel to get an even circle before putting it on."},{"step":4,"instruction":"For a bracelet: make a longer band (use two strips joined together) and wrap around the wrist, shaping it into a cuff."},{"step":5,"instruction":"For a pendant: cut a smaller square of foil and mould it around a bottle cap or fold it into a shape (star, heart). Twist a small loop of foil at the top and thread a piece of string through as a necklace cord."},{"step":6,"instruction":"Combine pieces to make a full set. Use a marker to draw patterns on the foil for extra decoration."}]',
  false
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PROJECT MATERIALS
-- ============================================================

-- paper-airplane (Paper main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000011', true,  '1 sheet of A4 or letter-size paper'),
  ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000004', false, 'For decorating')
ON CONFLICT DO NOTHING;

-- handprint-art (Paint + Paper main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000015', true,  '2–3 colours of washable paint'),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000011', true,  '1 large sheet of paper'),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000004', false, 'For adding details after drying')
ON CONFLICT DO NOTHING;

-- cereal-box-car (Cereal Box main, Tape, Bottle Caps, Markers, optional String)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000003', true,  'Several strips'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000006', true,  '4 bottle caps for wheels'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000004', true,  'For decoration'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000007', false, 'For axles')
ON CONFLICT DO NOTHING;

-- rubber-band-guitar (Cereal Box + Rubber Bands main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000013', true,  '4–6 rubber bands of varying thickness'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000004', false, 'For decorating the guitar body')
ON CONFLICT DO NOTHING;

-- tin-foil-boat (Foil main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000009', true, '1 sheet approx 30 cm × 30 cm')
ON CONFLICT DO NOTHING;

-- popsicle-stick-picture-frame (Popsicle Sticks + Glue main, optional Markers, Foil, Bottle Caps)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', true,  '8–10 popsicle sticks'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000010', true,  'Craft glue'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000004', false, 'For decoration'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000015', false, 'For painting the frame')
ON CONFLICT DO NOTHING;

-- toilet-roll-owl (Toilet Paper Roll main, Paper, Markers, optional Glue, Foil)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000002', true,  '1 toilet paper roll'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000011', true,  'Scraps for eyes, beak, and wings'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000004', true,  'For drawing features'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000010', false, 'Craft glue for attaching wings'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000003', false, 'Tape as alternative to glue')
ON CONFLICT DO NOTHING;

-- cardboard-box-playhouse (Cardboard + Tape main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000001', true,  '1 large cardboard box (appliance-sized ideal)'),
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000003', true,  'Strong packing tape'),
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000004', false, 'For decorating inside and outside')
ON CONFLICT DO NOTHING;

-- friendship-bracelet (String main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000007', true, '3 colours of string, each 60 cm long')
ON CONFLICT DO NOTHING;

-- cup-stacking-game (Plastic Cup + Markers main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000005', true,  'At least 10 plastic cups'),
  ('10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000004', true,  'Permanent markers for decoration')
ON CONFLICT DO NOTHING;

-- bottle-cap-wind-chime (Bottle Caps + String main, optional Popsicle Sticks, Paint)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000006', true,  '6–10 bottle caps'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000007', true,  '4–6 lengths of string (15–25 cm each) plus a hanger length'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000014', false, '1 popsicle stick or short twig for the crossbar'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000015', false, 'To decorate the caps')
ON CONFLICT DO NOTHING;

-- egg-carton-garden (Egg Carton + Paint main, optional Popsicle Sticks, Paper)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000008', true,  '1 egg carton (12-egg size)'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000015', true,  'Assorted colours of paint'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000014', false, 'Popsicle stick stems for flower sculptures'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000011', false, 'For cutting petal shapes')
ON CONFLICT DO NOTHING;

-- paper-collage (Paper + Glue + Markers main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000011', true, 'Assorted scraps plus 1 large background sheet'),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000010', true, 'Glue stick or craft glue'),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000004', true, 'For drawn details')
ON CONFLICT DO NOTHING;

-- periscope (Toilet Paper Roll + Tape + Foil main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002', true, '2 toilet paper rolls'),
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000003', true, 'Several strips of tape'),
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000009', true, '2 small squares of foil (mirror surfaces)')
ON CONFLICT DO NOTHING;

-- cardboard-shield (Cardboard + Foil + Tape main, optional Markers, Glue, Paper)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000001', true,  '1 large piece of flat cardboard'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000009', true,  'Enough foil to cover the shield face'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000003', true,  'For securing the foil and handle'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000004', false, 'For crest details'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000010', false, 'To glue on a paper crest'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000011', false, 'For cutting out a crest design')
ON CONFLICT DO NOTHING;

-- glue-string-art (Glue + String + Cardboard main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000010', true,  'Generous amount of craft glue'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000007', true,  'Several lengths of string (various colours optional)'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000001', true,  '1 piece of flat cardboard as the canvas'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000015', false, 'To paint the finished piece')
ON CONFLICT DO NOTHING;

-- paper-hat (Paper main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000011', true,  '1 large sheet (newspaper or A3 recommended)'),
  ('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000004', false, 'For decorating the hat')
ON CONFLICT DO NOTHING;

-- popsicle-stick-raft (Popsicle Sticks + String + Glue main, optional Paper)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000014', true,  '10–12 popsicle sticks'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000007', true,  'Short lengths to lash the crosspieces'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000010', true,  'Craft glue'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000011', false, 'For the sail')
ON CONFLICT DO NOTHING;

-- toilet-roll-stamp-printing (Toilet Paper Roll + Paint + Paper main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000002', true, '2–3 toilet paper rolls'),
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000015', true, 'Several colours of washable paint'),
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000011', true, 'Several sheets of paper')
ON CONFLICT DO NOTHING;

-- painted-bottle-cap-magnets (Bottle Caps + Paint main, optional Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000006', true,  '8–12 bottle caps'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000015', true,  'Assorted colours of paint'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000004', false, 'For fine details'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000010', false, 'Clear craft glue as sealant')
ON CONFLICT DO NOTHING;

-- rubber-band-ball (Rubber Bands main)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000029', '00000000-0000-0000-0000-000000000013', true, 'A large collection of rubber bands in mixed sizes')
ON CONFLICT DO NOTHING;

-- marble-maze (Cardboard + Tape + Popsicle Sticks main, optional Bottle Caps, Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001', true,  '1 large box lid or flat box plus extra cardboard for walls'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000003', true,  'Plenty of tape'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000014', true,  '6–10 popsicle sticks for barriers'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000006', false, '1 bottle cap as a target hole'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000004', false, 'For labelling the maze path')
ON CONFLICT DO NOTHING;

-- paper-puppet (Paper + Popsicle Sticks + Markers main, optional Glue, Tape)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000011', true,  '1–2 sheets of paper'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000014', true,  '1 popsicle stick per puppet'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000004', true,  'Markers for colouring the character'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000010', false, 'Craft glue to attach stick'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000003', false, 'Tape as alternative to glue')
ON CONFLICT DO NOTHING;

-- cereal-box-piggy-bank (Cereal Box + Paint + Tape main, optional Cardboard, Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000015', true,  'Pink or any colour paint'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000003', true,  'To seal the box and attach details'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000001', false, 'Small scraps for ears and feet'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000004', false, 'For drawing on features')
ON CONFLICT DO NOTHING;

-- foil-jewellery (Foil main, optional String, Bottle Caps, Markers)
INSERT INTO project_materials (project_id, material_id, required, quantity_note)
VALUES
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000009', true,  'Several strips and squares of foil'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000007', false, 'For necklace cord'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000006', false, 'As a mould for pendant shapes'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000004', false, 'For drawing patterns on the foil')
ON CONFLICT DO NOTHING;
