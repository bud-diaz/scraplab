-- Migration 006: Expand materials pool for activity compatibility
-- Adds aliases to existing materials and inserts 5 new materials
-- that appear in activities.materials_required but had no match.

-- Part A: Update aliases on existing materials so activity material
-- strings (lowercase, plural, variant names) resolve to the right row.

UPDATE materials SET aliases = array_cat(aliases, ARRAY[
  'cardboard', 'cardboard box', 'large cardboard box',
  'cardboard strips', 'cardboard scraps', 'cardboard base',
  'cardboard backing', 'cardboard box lid'
]) WHERE name = 'Cardboard';

UPDATE materials SET aliases = array_cat(aliases, ARRAY[
  'paper', 'paper scraps', 'junk mail'
]) WHERE name = 'Paper';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['tape'])
  WHERE name = 'Tape';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['markers'])
  WHERE name = 'Markers';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['foil'])
  WHERE name = 'Foil';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['glue'])
  WHERE name = 'Glue';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['string'])
  WHERE name = 'String';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['rubber bands'])
  WHERE name = 'Rubber Bands';

UPDATE materials SET aliases = array_cat(aliases, ARRAY['egg cartons'])
  WHERE name = 'Egg Carton';

UPDATE materials SET aliases = array_cat(aliases, ARRAY[
  'cereal box', 'boxes', 'shoebox', 'small box'
]) WHERE name = 'Cereal Box';

UPDATE materials SET aliases = array_cat(aliases, ARRAY[
  'bottle caps', 'flat tokens'
]) WHERE name = 'Bottle Caps';

UPDATE materials SET aliases = array_cat(aliases, ARRAY[
  'paper tubes', 'tubes', 'cardboard tubes'
]) WHERE name = 'Toilet Paper Roll';

-- Part B: Insert 5 new materials covering required fields not
-- represented by any existing row.

INSERT INTO materials (id, name, aliases, category, icon) VALUES
  (
    gen_random_uuid(),
    'Fabric Scraps',
    ARRAY['fabric scraps', 'fabric', 'soft scrap materials'],
    'fabric',
    '🧶'
  ),
  (
    gen_random_uuid(),
    'Pencil',
    ARRAY['pencil', 'pencils'],
    'art',
    '✏️'
  ),
  (
    gen_random_uuid(),
    'Straws',
    ARRAY['straws', 'straws or sticks'],
    'containers',
    '🥤'
  ),
  (
    gen_random_uuid(),
    'Envelopes',
    ARRAY['envelopes', 'envelope'],
    'paper',
    '✉️'
  ),
  (
    gen_random_uuid(),
    'Small Ball',
    ARRAY['small ball', 'small lightweight ball'],
    'misc',
    '🎾'
  );
