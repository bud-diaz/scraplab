SCRAPLAB UI DESIGN LANGUAGE SYSTEM
Version 1.0

Core UX Philosophy
ScrapLab is not a dashboard.
ScrapLab is not a marketplace.
ScrapLab is not content browsing first.
ScrapLab is a guided utility experience.
Primary user mental state:
“My kid is bored. I have 11 minutes. Help.”
That means:
Design for:
speed
confidence
low cognitive load
immediate momentum
tactile clarity
NOT:
exploration-first complexity
nested menus
“discoverability theater”

Product Archetype
Think:
Apple Family app meets LEGO instructions meets modern maker kit
Behavioral references:
Duolingo onboarding clarity
Apple setup simplicity
Headspace calm confidence
Notion modularity (LIGHTLY)
IKEA instruction obviousness

Interaction Personality
The UI should feel:
Calm
Never visually noisy.
Encouraging
No harsh failure states.
Smart
Should feel adaptive.
Tactile
Cards should feel like “pieces.”
Fast
No bloated interactions.
Slightly playful
Just enough warmth.

Visual Layout Language
Overall Layout Style
Card-based modular UI
This fits your whole brand thesis.
Cards = materials
 Cards = projects
 Cards = steps
 Cards = saved builds
Everything should feel assemble-able.

Shape language
Primary:
 rounded rectangles
Not hyper-rounded bubble app.
 Not sharp enterprise corners.
Sweet spot:
 12px–20px radius
Feels:
 modern + friendly + tactile

Depth model
Soft layered depth.
Think:
 paper stacks.
Use:
subtle shadows
layered cards
slight elevation changes
NOT:
 glassmorphism nonsense
NOT:
 hard brutalist blocks

Texture Rules
Texture = seasoning.
Not dinner.
Allowed:
ultra subtle cardboard grain
blueprint grid background accents
faint assembly marks
NOT:
 full textured panels everywhere
The app still needs to feel premium.

Navigation Model
This is NOT sidebar software.
This is mobile-first utility.
Even on desktop.
Navigation style:
Top nav + contextual flows
Desktop:
 horizontal nav
Mobile:
 bottom nav

Iconography
Style:
 clean outlined icons
Think:
 Lucide-style
But slightly customized later if desired.
Allowed motif inspiration:
ruler
tape
scissors
cube
spark
wrench
clipboard
build steps
Avoid:
 toy-like chunky cartoon icons

Motion Design
Motion should feel:
assembled, not flashy
Examples:
cards slide into place
progress fills like build completion
material confirmations gently snap in
Avoid:
bouncing chaos
excessive easing gimmicks
TikTok app energy

Core Component Language
Buttons
Primary CTA:
 Builder Blue fill
Rounded
 Confident
 Chunky enough to tap
Examples:
 “Find Builds”
 “Start Build”
 “Try Another”

Secondary:
 outline / cream / brown text

Danger:
 orange only for action energy
 NOT destructive actions

Inputs
Inputs should feel lightweight.
Examples:
 search bar
 material selector
 age picker
Style:
 rounded
 clean
 minimal borders
 soft shadow optional

Cards
Cards are EVERYTHING.
Card types:
Material card
Small
 icon + label + selected state
Example:
 [📦 Cardboard]

Project card
Hero image
 title
 metadata chips
Example:
 15 min
 Low mess
 Ages 4–7

Step card
Instruction focus
 one action at a time

Saved project card
lighter metadata

Progress System
Progress should feel satisfying.
Use:
 step indicators
 completion bars
 checkpoints
Tone:
 encouraging
 not gamified chaos

Information Hierarchy
ALWAYS:
Action first.
 Decision second.
 Details third.
Example:
GOOD:
 Rocket Ship
 15 min
 Low mess
 Adult assist
 [Start]
BAD:
 massive paragraph first

Content Density
Low-to-medium density.
This is a family utility.
Not Airtable.
Whitespace matters.

UI Metaphors
Subtle recurring metaphors:
assembly instructions
fold guides
blueprint notation
material labels
project tags
These create cohesion.

Screen Tone by Context
Home
optimistic / welcoming
Material input
efficient / focused
Recommendations
exciting / confidence-building
Build mode
calm / instructional
Saved
organized / library-like
Account
minimal boring utility
(as God intended)

Design Anti-Patterns
ABSOLUTELY avoid:
❌ Pinterest masonry layout
 ❌ Etsy scrapbook UI
 ❌ STEM camp website vibes
 ❌ enterprise dashboard tables
 ❌ teacher worksheet aesthetic
 ❌ neon kid chaos
 ❌ too many colors per screen
 ❌ mascot overuse

UI Archetype Summary
If ScrapLab were a place:
Not:
 craft store
Not:
 daycare classroom
Not:
 corporate SaaS office
It’s:
a beautifully organized family maker workshop.


SCRAPLAB NAV ARCHITECTURE + PRODUCT SITEMAP
Version 1.0
Product Model
ScrapLab has 4 functional zones:
Create → core product utility
Library → saved/history/discovery
Challenges → engagement loop
Account / Household → personalization
Simple enough for parents.
 Expandable enough for ecosystem.

GLOBAL PRIMARY NAV
Mobile Bottom Nav (Primary)
Home
 Create
 Library
 Challenges
 Profile
5 is the sweet spot.
Do NOT exceed 5.
Nobody with a bored child wants to decode 8 tabs.

Desktop Top Nav
Left:
 ScrapLab logo
Center:
 Home
 Create
 Library
 Challenges
Right:
 Search
 Notifications (future)
 Profile avatar

PRIMARY PAGE ARCHITECTURE
1. HOME
Priority: MVP
Purpose:
 launchpad + confidence engine
This is NOT a dashboard.
This is:
 “what should I do right now?”

Home Sections
Hero Action Card
Primary CTA.
Examples:
“Let’s make something.”
 [Find a Build]
or
“What materials do you have?”

Quick Input Options
Fast actions.
Cards:
📸 Scan Materials (Premium MVP-ready gated)
 🖐 Manual Material Picker (MVP)
 🎲 Surprise Me (future-lite)

Resume Build
If active session exists.
“Continue Rocket Ship”

Saved For Later Preview
Mini carousel

Quick Challenge Banner
Promotional engagement surface
“Weekend Build Challenge”
Future-ready.

Recently Built
Emotional retention loop

Home should feel alive but not crowded.

2. CREATE
Priority: MVP CORE
This is the product.
The money room.

Create Flow Architecture
This is likely a guided multi-step flow.
Subpages:

2A. Input Method Selection
MVP
Choose:
Scan Materials
Manual Selection
Household Staples
Quick Build / Fewer Items

2B. Material Scanner
MVP (premium gated)
Camera / upload
AI detects:
cardboard
cups
markers
 etc.
User confirms.

2C. Manual Material Picker
MVP
Searchable categorized selector.
Categories:
cardboard/paper
containers
connectors
art supplies
recyclables
misc household
Grid cards.
Fast tap interaction.

2D. Household Inventory
V1.5+
Persistent saved materials.
“Stuff we usually have.”

2E. Recommendation Results
MVP
Critical screen.
Cards showing:
project image
 title
 time
 mess
 age fit
 supervision
 match confidence
Actions:
 Save
 View
 Start
Filters:
 time
 mess
 difficulty
 age
 materials used

2F. Project Detail
MVP
Full project breakdown.
Includes:
 hero image
 materials list
 substitutions
 time
 cleanup
 safety
 difficulty
 steps preview
CTA:
 Start Build

2G. Guided Build Mode
MVP
Instruction-first interface.
One step at a time.
Features:
 next
 back
 mark complete
 pause
 exit
Future:
 voice mode

2H. Completion Screen
MVP
Celebrate completion.
Options:
 Save completed
 Try another
 Share (future)
 Rate difficulty

3. LIBRARY
Priority: MVP-lite
Purpose:
 retention

Library Tabs
Saved Projects
MVP
Projects bookmarked for later.

Build History
MVP
Recently completed builds.

Recommended For You
Future
Personalized suggestions.

Seasonal Collections
Future
Holiday / themed packs.

Library = calm organized workshop shelf.
NOT infinite content feed.

4. CHALLENGES
Priority: Dream shell / MVP teaser
Purpose:
 engagement + conversion

Challenge Sections
Weekly Challenge
Future

Mystery Build
Future premium
“Here are 3 weird materials. Make it work.”

Minimal Materials Mode
V1.5 / maybe MVP-lite
Strong feature.

Weekend Mega Builds
Future

Seasonal Events
Future

Kid Chooses Chaos
Future ecosystem tie-in
(yes, this is a content-to-product bridge)

Challenge section becomes major retention lever later.

5. PROFILE / HOUSEHOLD
Priority: MVP
Utility zone.
Keep boring.
Beautifully boring.

Sections
Child Profiles
MVP-lite
age
 name optional

Household Staples
MVP-lite / V1.5
saved common materials

Subscription / Upgrade
MVP

Preferences
MVP
mess tolerance maybe later
 time preference
 age defaults

Safety Preferences
Future

Notifications
Future

Billing
MVP

Help / Support
MVP

SECONDARY / HIDDEN ROUTES
Not nav items.

Authentication
MVP
/login
 /signup
 /forgot-password

Paywall / Upgrade
MVP
/subscription

Onboarding
MVP
Very important.

onboarding flow:
Welcome
 Child age
 Common materials?
 Premium teaser
 done

Empty States
MVP
Huge UX differentiator.
Examples:
 No matches
 No saved builds
 No history

Error States
MVP
Friendly tone.

Settings
MVP

Admin / Content Management
Internal only
Project database management.
Codex needs this if you’re serious.

CONTENT TAXONOMY
Projects tagged by:
age
 difficulty
 mess
 time
 supervision
 theme
 materials
 season
 indoor/outdoor
 energy level
 solo/family
This matters early.

MVP BUILD PRIORITY LIST
PHASE 1 TRUE MVP
Must build:
✅ Home
 ✅ Manual material picker
 ✅ recommendation engine
 ✅ project detail
 ✅ guided build mode
 ✅ saved projects
 ✅ build history
 ✅ auth
 ✅ subscription gating
 ✅ onboarding

PHASE 1.5
Add:
🔶 scanner
 🔶 household inventory
 🔶 minimal materials mode
 🔶 child profiles

PHASE 2
Add:
🔷 challenges
 🔷 personalization
 🔷 recommendations memory
 🔷 seasonal content
 🔷 notifications

PHASE 3 ECOSYSTEM
Add:
⚫ community
 ⚫ creator tie-ins
 ⚫ user submissions
 ⚫ classroom mode
 ⚫ printable packs

PROTOTYPE SCREEN COUNT ESTIMATE
Dream-state realistic:
Home
 Input method
 Scanner
 Manual picker
 Inventory
 Results
 Project detail
 Build mode
 Completion
 Library
 Saved
 History
 Challenges hub
 Challenge detail
 Profile
 Subscription
 Onboarding x3–5
 Auth x2
 Empty states x3
Roughly:
22–30 screens
Which is healthy.
Not insane.

MY UI RECOMMENDATION
Prototype in this order:
design system primitives
nav shell
home
create flow
project detail
guided build
library
profile
upgrade/paywall
challenge shells

SCRAPLAB COMPONENT INVENTORY
Design System / Prototype Build Kit
 Version 1.0
This is your UI LEGO bucket.
Build these once.
 Reuse forever.
 Codex will thank you.
 Future-you will thank you.
 Your sanity will file fewer complaints.

FOUNDATIONS
1. Color Tokens
Core Brand
kraft-500      #C8A97E
walnut-700     #6B4F3A
builder-500    #2D9CDB
orange-500     #F28C28
cream-50       #F8F3EA
charcoal-900   #2B2B2B

Functional Colors
Success:
green-500
Warning:
orange-500
Danger:
red-500
Info:
builder-500
Muted:
warm-gray palette

2. Typography Tokens
Display
Big moments.
Use:
 Outfit Bold
Examples:
 page headers
 hero actions
Sizes:
48
40
32
28

Heading
Use:
 Outfit SemiBold
Sizes:
24
20
18
16

Body
Use:
 Inter
Sizes:
16
14
13

Metadata
Use:
 Inter Medium
Examples:
 chips
 project metadata
 timestamps

3. Spacing Scale
LOCK THIS OR CHAOS WINS.
4
8
12
16
20
24
32
40
48
64
Everything snaps here.
No random 17px crimes.

4. Radius Scale
small: 10
medium: 16
large: 20
xl: 28
pill: 999

5. Shadow System
Soft paper-stack vibe.
Small:
 inputs/cards
Medium:
 modals
Large:
 hero emphasis
No crypto-dashboard shadows.

NAVIGATION COMPONENTS
Top Nav
Desktop only.
Contains:
logo
nav links
profile
upgrade CTA
Behavior:
 sticky

Bottom Nav
Mobile only.
Items:
Home
Create
Library
Challenges
Profile
Icon + label

Breadcrumb
Desktop utility.
Example:
 Create > Recommendations > Rocket Ship

Floating Action CTA (optional)
Mobile shortcut:
 “Create”
Potentially useful later.

BUTTON SYSTEM
Primary Button
Builder Blue fill
Use:
 main CTAs
Examples:
Find Builds
Start Build
Continue
Upgrade

Secondary Button
Outline / cream background
Examples:
Save
Back
Browse

Tertiary Button
Text only
Examples:
Skip
Not now

Icon Button
Square rounded
Examples:
 back
 close
 bookmark
 share

Destructive Button
Rare.
Red only.

FORM COMPONENTS
Search Input
Used for:
 materials
 projects
Features:
 icon
 clear button
 smart suggestions

Text Input
Auth
 profile
 settings

Select Dropdown
Age
 filters
 difficulty

Segmented Control
Excellent component.
Use for:
 Time filters:
 [ Quick ] [ Medium ] [ Weekend ]
Mess:
 [ Low ] [ Medium ] [ Chaos ]

Checkbox
Material selection

Toggle Switch
Settings
 preferences

Slider
Potential:
 age
 time range

Multi-Select Chip Picker
VERY important.
For materials.
Example:
[ Cardboard x ]
 [ Tape x ]
 [ Cups x ]

CARD SYSTEM
This is your product’s backbone.

Hero Action Card
Large CTA card.
Home screen.
Contains:
 headline
 subcopy
 primary CTA
 illustration

Material Card
Small modular card.
Contains:
 icon
 name
 selected state
States:
 default
 selected
 disabled

Project Recommendation Card
Critical.
Contains:
hero image
 title
 metadata chips
 compatibility indicator
 save button
Example:
ROCKET SHIP
 15 min
 Low mess
 Adult assist
 92% match
CTA:
 View Build

Project Detail Card
Expanded info surface.

Step Card
Build mode.
Contains:
 instruction
 image
 tips
 warnings
One focus per screen.

Saved Project Card
Library.

Challenge Card
Future engagement.

Upgrade Card
Premium upsell.

Status Card
No results
 scanner error
 empty state

CHIP SYSTEM
Highly reusable.

Metadata Chip
Examples:
 15 min
 Low mess
 Age 4–7

Filter Chip
Toggle state
Example:
 Indoor
 Quick
 Independent

Premium Chip
Tiny lock indicator

Match Confidence Badge
Potentially very useful.
Example:
 “Great Match”
 “Close Match”
Avoid exposing fake precision if engine isn’t real.

MODAL SYSTEM
Confirmation Modal
Examples:
 Leave build?
 Delete saved?

Upgrade Modal
Critical.
Soft paywall moment.

Scanner Confirmation Modal
Detected:
 ☑ Cardboard
 ☑ Tape
 ☐ Banana

Error Modal
Friendly.

DRAWERS / SHEETS
Mobile-friendly.
Use for:
 filters
 material categories
 quick actions
Bottom sheets > full page when possible.

EMPTY STATES
Big UX differentiator.
Build intentionally.

No Saved Projects
“Your workshop shelf is empty.”
CTA:
 Find a build

No Build History
“Nothing built yet.”
CTA:
 Let’s fix that

No Recommendations
Critical.
Instead of:
 “No results.”
Say:
 “Not enough for a rocket… but definitely enough for something cool.”
Then:
 fallback suggestions

LOADING STATES
Must exist.

Skeleton Cards
Recommendation loading

Step Loading
Project prep

Scanner Processing
Fun opportunity.
“Checking your materials…”

FEEDBACK SYSTEM
Toasts
Examples:
 Saved
 Removed
 Completed

Inline Feedback
Validation

Progress Indicators
Stepper
 bars
 completion ring

CONTENT-SPECIFIC COMPONENTS
Material Scanner Preview
Photo preview
 detected labels
 edit list

Recommendation Filter Rail
time
 mess
 difficulty
 age
 supervision

Build Progress Tracker
Step 2 of 7

Materials Checklist
Before build starts

Substitution Suggestions
“Don’t have bottle caps?
 Try buttons.”

Completion Celebration Panel
Reward without chaos.

SUBSCRIPTION COMPONENTS
Upgrade Banner
Contextual

Premium Feature Lock Card
Examples:
 scanner
 challenge modes

Pricing Comparison Card
Free vs Plus

ACCOUNT COMPONENTS
Child Profile Card

Household Staples Manager

Preferences Panel

Billing Card

HELP COMPONENTS
FAQ accordion
Support contact
Feedback form

INTERNAL CMS COMPONENTS
(for codex planning)
Project editor
 material manager
 substitution manager
 challenge manager
Not prototype priority unless mocked lightly.

COMPONENT PRIORITY
BUILD FIRST
absolute essentials:
✅ buttons
 ✅ nav
 ✅ material cards
 ✅ recommendation cards
 ✅ chips
 ✅ forms
 ✅ build step card
 ✅ empty states
 ✅ upgrade modal

BUILD SECOND
🔶 filters
 🔶 drawers
 🔶 scanner preview
 🔶 profile cards

BUILD LATER
🔷 challenges
 🔷 CMS
 🔷 personalization extras

PROTOTYPE BUILD ORDER
Actual recommended order:
design tokens
nav
buttons
cards
chips
forms
home
create flow
recommendation flow
build mode
library
profile
paywall
challenge shell



ScrapLab Page Wireframes
1. Home
Purpose: quick launchpad.
Layout:
[Top Nav / Logo]

[Hero Action Card]
"What can we build today?"
Subtext: "Pick materials. Get a safe project fast."
[Find a Build]

[Quick Actions]
[Manual Pick] [Scan Materials 🔒] [Surprise Me]

[Continue Build]
Only if active build exists.

[Saved For Later Preview]

[Recent Builds Preview]
MVP: yes
 Notes: Home should not feel like a dashboard. It’s the “help me now” screen.

2. Create / Input Method
[Header]
"Start with what you have"

[Input Cards]
[Choose Materials Manually]
[Scan a Photo 🔒]
[Use Household Staples]
[Build With Fewer Items]

[Small reassurance copy]
"No perfect supplies needed."
MVP:
manual picker
scan locked/paywalled placeholder
fewer items can be shell only

3. Manual Material Picker
[Search Bar]
"Search materials"

[Selected Materials Tray]
[cardboard x] [tape x] [markers x]

[Category Tabs]
Paper/Cardboard | Containers | Connectors | Art Supplies | Recyclables

[Material Grid]
[Cardboard] [Toilet Roll] [Tape] [Cups]

[Sticky Bottom CTA]
"Find Builds"
MVP: yes
 This screen needs to be fast as hell.

4. Scanner Confirmation
[Photo Preview]

[Detected Materials]
☑ Cardboard
☑ Tape
☐ Plastic Cup
☐ Banana lol

[Add Missing Material]

[CTA]
"Confirm Materials"
MVP: premium shell
 Backend can fake this at first.

5. Recommendation Results
[Header]
"Here’s what you can build"

[Filter Chips]
Quick | Low Mess | Ages 3–5 | Independent

[Result Cards]
[Project Image]
Rocket Ship
15 min | Low mess | Adult assist
Great Match
[View] [Save]

[Fallback Section]
"Almost enough for..."
MVP: yes
 This is one of the most important screens.

6. Project Detail
[Hero Image / Illustration]

[Title]
Cardboard Rocket Ship

[Reality Chips]
15 min | Low mess | Ages 4–7 | Adult assist

[Materials Checklist]
Required
Optional
Substitutions

[Safety Notes]

[Steps Preview]

[Sticky CTA]
Start Build
MVP: yes

7. Guided Build Mode
[Progress]
Step 2 of 7

[Step Card]
Big instruction
Image/diagram
Tip
Safety note if needed

[Controls]
Back | Next

[Secondary]
Pause Build
MVP: yes
 One instruction at a time. No wall of text. Parents are already fighting for their life.

8. Completion Screen
[Celebration Panel]
"Built it. Nice."

[Options]
Mark Complete
Save Project
Build Something Else

[Optional]
Rate difficulty
MVP: yes

9. Library
[Tabs]
Saved | History | Collections

[Saved Project Cards]

[Empty State]
"Your workshop shelf is empty."
[Find a Build]
MVP: saved + history
 Collections can be shell.

10. Challenges
[Hero]
"ScrapLab Challenges"

[Challenge Cards]
Mystery Build 🔒
Weekend Build
Build With Fewer Items
Kid Chooses Chaos

[Coming Soon Banner]
MVP: shell only
 This is dream-state polish, not core build yet.

11. Profile / Household
[Profile Header]

[Child Profiles]
Name / Age

[Household Staples]
Common materials

[Subscription]
Free / Plus

[Preferences]
Mess tolerance
Time preference

[Settings]
MVP: basic account + subscription
 Household staples can be v1.5.

12. Upgrade / Paywall
[Headline]
"Unlock faster creativity"

[Free vs Plus Comparison]

Free:
Manual picker
3 daily recommendations
Basic saves

Plus:
Unlimited builds
Photo scanning
More profiles
Challenge modes

[CTA]
Upgrade to ScrapLab Plus
MVP: yes


