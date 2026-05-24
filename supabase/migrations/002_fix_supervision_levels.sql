-- Paper Binoculars and Foil Moon Rocks are targeted at ages 3-8 but were
-- seeded with supervision_level = 'independent'. The safety check blocks
-- 'independent' projects for children under 11, making these two projects
-- invisible to their entire target age group. Change to 'check_in' which
-- is appropriate for simple crafts with young children.
update projects
set supervision_level = 'check_in'
where slug in ('paper-binoculars', 'foil-moon-rocks');
