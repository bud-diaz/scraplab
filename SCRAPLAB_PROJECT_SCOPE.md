# PROJECT SCOPE
## Project Name 
ScrapLab

---

# Product Vision

ScrapLab is a kid-friendly creativity assistant that helps parents, caregivers, and educators turn everyday household materials into fun, age-appropriate build projects.

Users upload a photo of available materials or manually select items they have, and the platform suggests safe, achievable projects with step-by-step instructions.

The goal is to reduce parental decision fatigue, encourage creative play, and transform “junk” into structured imagination.

---

# Problem Statement

Children naturally collect random objects for imagined future projects.

Parents often:
- do not know what to make
- do not want to buy expensive craft kits
- lack time to search through Pinterest-style content
- need safe, fast, age-appropriate ideas
- want creative enrichment without clutter escalation

Existing craft discovery platforms are content-heavy and search-driven.

This product is inventory-first.

---

# Core Product Principles

## 1. Inventory First
The system begins with available materials, not predefined craft tutorials.

Example:
Input:
- cardboard tube
- tape
- plastic cup
- markers

Output:
- rocket ship
- binoculars
- mini puppet
- marble launcher

---

## 2. Safety by Design
All projects must be age-filtered and safety-aware.

Constraints:
- no dangerous chemicals
- no open flame
- no sharp tools for younger age groups
- choking hazard awareness
- supervision indicators

---

## 3. Fast Parent UX
Low-friction interaction:
- photo upload
- tap-to-select materials
- optional voice input

No lengthy forms.

---

## 4. Kid Delight
Suggestions should feel fun, imaginative, and achievable.

Include:
- playful naming
- visual inspiration
- challenge prompts
- accomplishment feedback

---

# Target Audience

## Primary
Parents of children ages 3–10

Segments:
- busy parents
- budget-conscious families
- apartment families
- rainy-day activity seekers
- parents encouraging screen-light creativity

---

## Secondary
Educators:
- teachers
- daycare providers
- homeschool families
- after-school programs

---
# Product MVP

ScrapLab MVP will be organized around product systems rather than isolated features.

The goal is to create a cohesive, parent-friendly experience that feels intelligent, flexible, and genuinely useful under real-world conditions.

---

## 1. Material Input System

Primary entry point into the product.

Users can identify available materials through multiple methods.

### Manual Material Picker
Users can:
- browse a categorized material library
- search for specific materials
- select available household items manually

Examples:
- cardboard
- toilet paper roll
- cereal box
- tape
- cups
- string
- bottle caps
- egg carton
- foil
- glue
- markers

---

### Photo Material Recognition
Users can:
- upload a photo of available materials
- have the system detect recognizable objects
- confirm detected materials before recommendation generation

Purpose:
Reduce input friction and create “magic moment” usability.

Because computer vision may be imperfect, user confirmation is required.

Example:
Detected:
☑ cardboard
☑ tape
☑ plastic cup
☐ banana (incorrect detection)

Users can:
- remove incorrect detections
- add missing materials manually

---

## 2. Adaptive Material Engine

Core intelligence layer.

Purpose:
Make ScrapLab useful even when available materials are incomplete, unusual, or imperfect.

This system prevents recommendation dead ends and improves flexibility.

Capabilities include:

### Material Confidence Confirmation
Validate detected materials before generating recommendations.

---

### Material Substitution Support
If a recommended project requires unavailable materials, the system can suggest alternatives.

Examples:
- googly eyes → drawn eyes
- bottle caps → buttons
- cardboard tube → folded paper

Initial MVP implementation may use curated substitutions rather than dynamic AI generation.

---

### Fallback Recommendation Logic
If no exact project matches exist, ScrapLab should provide:
- close matches
- simplified alternatives
- low-material builds
- creative challenge prompts

Goal:
No dead-end user experiences.

---

### Build With Fewer Items Mode
Optional recommendation mode for highly constrained households.

Examples:
- “Show builds requiring fewer materials”
- “Minimal supply ideas”

May launch in lightweight MVP form.

---

### Household Inventory Intelligence
The system can remember commonly available materials over time.

Examples:
“Save these as household staples?”

This improves future recommendation relevance.

This functionality also overlaps with user profile memory systems.

---

## 3. Project Recommendation Engine

Core matching engine.

Purpose:
Translate available materials into useful project suggestions.

Recommendations should be:
- age-appropriate
- safe
- achievable
- ranked by compatibility

Project metadata includes:
- required materials
- optional materials
- substitutions
- age range
- difficulty
- supervision level
- estimated time
- cleanup level
- tags

Matching priority:
1. exact matches
2. close matches
3. simplified alternatives
4. creative fallback options

---

## 4. Project Reality Indicators

Parent decision-support layer.

Purpose:
Help caregivers quickly assess effort, mess, and supervision requirements before committing.

Each project should clearly display:

### Time Reality
Examples:
- 5 minute quick win
- 15–20 minutes
- 30+ minutes
- weekend build

---

### Cleanup Estimate
Examples:
- low mess
- medium cleanup
- high cleanup

---

### Supervision Level
Examples:
- independent
- check-in occasionally
- adult assist needed
- full supervision

These indicators should be highly visible and not buried in small print.

---

## 5. Guided Build Experience

Execution layer.

Purpose:
Support users during the actual build process.

Features include:

### Step-by-Step Progress Mode
Users can:
- move forward through instructions
- go backward
- mark progress
- complete builds

---

### Save For Later
Users can bookmark projects for future use.

Initial MVP states:
- saved
- completed

Future expansion:
- custom project boards
- “want to try”

---

### Build History
Users can revisit previous builds.

Examples:
- recently completed projects
- saved favorites
- family activity history

---

## 6. Account / Household Memory Layer

Persistent personalization layer.

Purpose:
Make ScrapLab smarter over time.

Capabilities:
- child profiles
- age preferences
- saved projects
- completed history
- household staple materials
- recommendation memory

Inventory memory partially overlaps with Adaptive Material Engine functionality.

---

## 7. Freemium Access Layer

Business model enforcement layer.

Free users receive a useful but limited experience.

Examples:
- limited daily recommendations
- manual material picker
- limited project access
- one child profile

Premium users unlock:
- unlimited recommendations
- photo material recognition
- advanced challenge modes
- expanded family features
- full personalization systems

---

## HouseholdInventory
- id
- user_id
- material_id
- confidence_score
- source (manual / detected / saved)
- staple_flag

---

## MaterialSubstitution
- id
- source_material_id
- replacement_material_id
- substitution_notes

---

## ProjectRealityMetadata
- project_id
- time_estimate
- cleanup_level
- supervision_level

---


# Recommendation Engine Architecture

## Hybrid Strategy

### Deterministic Rules Engine
Primary logic.

Projects stored in structured database.

Each project includes:
- required materials
- optional materials
- age range
- difficulty
- estimated time
- supervision level
- tags

Matching engine ranks compatible projects.

Benefits:
- predictable
- safe
- inexpensive
- explainable

---

### AI Assistance Layer
Secondary enhancement only.

Allowed AI tasks:
- project naming
- alternate variations
- encouragement copy
- visual descriptions
- creativity expansions

Disallowed:
fully unconstrained craft generation for young children

Reason:
unsafe hallucinations

---

# Safety Model

Hard restrictions:
- fire
- knives
- electrical work
- toxic substances
- chemical reactions
- unsupervised hazardous builds

Safety labels:
- toddler safe
- supervised
- adult assistance required

---

# Suggested Tech Stack

Frontend:
- Next.js
- React
- TailwindCSS
- shadcn/ui

Backend:
- Node.js
- Next API routes

Database:
- Supabase Postgres

Storage:
- Supabase Storage

Auth:
- Clerk or Supabase Auth

AI:
- OpenAI Vision API

Image Processing:
- OpenAI vision OR local classification model later

State:
- Zustand

Analytics:
- PostHog

Deployment:
- Vercel

Payment:
- Stripe

---

# Core Data Models

## User
- id
- email
- created_at

---

## ChildProfile
- id
- user_id
- age_group
- name (optional)

---

## Material
- id
- name
- aliases
- category
- icon

---

## Project
- id
- title
- description
- age_min
- age_max
- time_minutes
- difficulty
- supervision_level
- instructions
- image_url

---

## ProjectMaterial
- project_id
- material_id
- required
- optional

---

## SavedProject
- user_id
- project_id

---

## BuildHistory
- user_id
- project_id
- built_at
- completion_status

---

# UX Requirements

Must feel:
- playful
- premium
- parent-trustworthy
- low-friction
- kid-safe

Avoid:
Pinterest clutter
cheap craft blog aesthetic
overly childish enterprise-looking UI

Preferred inspiration:
- Duolingo simplicity
- Apple family app polish
- Headspace friendliness

---

# Business Model

## Monetization Strategy

ScrapLab will launch using a freemium business model.

Core philosophy:
Deliver meaningful utility for free while reserving premium convenience, advanced features, and expanded experiences for paid users.

This model supports:
- low-friction adoption
- strong organic sharing
- family-friendly accessibility
- creator-driven audience conversion
- long-term upsell opportunities

Freemium aligns with ScrapLab’s product behavior, where repeat usage naturally creates upgrade pressure without requiring aggressive sales tactics.

---

## Free Tier (Core Experience)

The free tier should be genuinely useful, not crippleware.

Purpose:
- maximize adoption
- encourage habit formation
- support organic sharing
- validate product-market fit

Included features:

### Project Discovery
- limited daily project recommendations
- access to core curated project library
- age-based filtering

Suggested launch limit:
3 project recommendations per day

---

### Manual Material Input
Users can:
- browse available material inventory
- manually select household materials
- receive matching project ideas

---

### Basic Build Experience
Users can:
- view instructions
- complete projects
- explore challenge prompts (limited rotation)

---

### Limited User Features
Examples:
- one child profile
- limited saved favorites
- limited recent build history

---

## Premium Tier (ScrapLab Plus / Naming TBD)

Premium unlocks convenience, depth, and enhanced creativity tools.

Purpose:
Convert engaged users who repeatedly find value in the platform.

Included features:

### Unlimited Creativity Access
- unlimited project recommendations
- unlimited browsing
- full curated project library access

---

### AI-Powered Material Recognition
Premium users can:
- upload photos of available materials
- automatically identify objects
- receive instant project matches

This becomes a major premium differentiator.

---

### Enhanced User Features
- unlimited saved favorites
- full build history
- multiple child profiles
- family household mode

---

### Premium Challenge Modes
Examples:
- mystery build mode
- themed challenge packs
- weekend mega builds
- seasonal challenge events

---

### Content / Media Perks (Future)
Potential premium benefits:
- exclusive printable packs
- bonus build templates
- subscriber-only challenge content
- companion activity bundles

---

## Pricing Philosophy

Pricing should remain parent-friendly and impulse-accessible.

Initial target pricing:
$5.99–$11.99/month (to be validated)

Possible launch strategy:
Founding member pricing for early adopters.

Example:
"$3.99/month forever for first 500 users"

Purpose:
- reward early adoption
- create urgency
- improve conversion during launch

---

## Future Revenue Expansion

Freemium software is the initial revenue layer, not the only one.

Future monetization opportunities:

### Media Revenue
- YouTube monetization
- sponsorships
- affiliate partnerships

---

### Digital Product Revenue
- printable activity packs
- seasonal challenge bundles
- classroom worksheets
- homeschool lesson packs

---

### Educational Revenue
- educator subscriptions
- classroom licenses
- institutional access

---

### Physical Product Revenue
- ScrapLab challenge cards
- themed creativity decks
- branded build kits
- family maker boxes

---

## Conversion Strategy

Primary conversion triggers should feel natural and value-driven.

Expected upgrade moments:
- daily recommendation limit reached
- desire to use photo recognition
- multiple children needing profiles
- repeated family engagement
- access to premium challenge content

Conversion messaging should emphasize convenience and expanded creativity rather than restriction.

---

## Anti-Abuse Philosophy

ScrapLab will not rely on free trial abuse-prone subscription tactics.

Instead:
- useful permanent free tier
- premium feature differentiation
- sustainable long-term retention

This reduces friction while minimizing operational complexity around repeated trial abuse.

---

## Long-Term Monetization Thesis

ScrapLab is not intended to rely solely on subscription software revenue.

The long-term business model is a layered ecosystem:

1. Freemium software
2. Audience monetization
3. Digital educational products
4. Institutional licensing
5. Physical branded products

The software serves as the utility engine.
The media ecosystem serves as the acquisition engine.
The broader brand ecosystem creates monetization resilience.

---

# Success Metrics

MVP success indicators:
- suggestion completion rate
- saved project rate
- repeat weekly usage
- project completion confirmation
- average session duration
- parent retention

---

# Explicit Non-Goals (MVP)

Not building:
- social network
- marketplace
- AR assembly
- educator analytics
- custom unrestricted AI generation
- ecommerce craft supply store

---

# Launch Goal

Ship a delightful MVP that reliably transforms household clutter into kid-friendly creativity in under 60 seconds.

—

# V1.5 Scope

- voice material input
- mystery challenge mode
- random creativity prompts
- printable instructions
- seasonal challenge packs
- “build with fewer materials” mode

---

# V2 Scope

- classroom mode
- multiple child profiles
- family accounts
- shared household inventory
- upload finished creation gallery
- AI remix mode
- AR guided assembly
- subscription content packs
- educator dashboards

---

