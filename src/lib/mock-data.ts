import type { SupervisionLevel } from "@/types";

// IDs match the seeded UUIDs in supabase/seed.sql so the fallback works
// even when the /api/materials call hasn't resolved yet.
export const materials = [
  { id: "00000000-0000-0000-0000-000000000001", name: "Cardboard",        icon: "📦", category: "paper"      },
  { id: "00000000-0000-0000-0000-000000000002", name: "Toilet Paper Roll", icon: "🧻", category: "tubes"      },
  { id: "00000000-0000-0000-0000-000000000003", name: "Tape",             icon: "🩹", category: "connectors" },
  { id: "00000000-0000-0000-0000-000000000004", name: "Markers",          icon: "🖊️", category: "art"        },
  { id: "00000000-0000-0000-0000-000000000005", name: "Plastic Cup",      icon: "🥤", category: "containers" },
  { id: "00000000-0000-0000-0000-000000000006", name: "Bottle Caps",      icon: "🪙", category: "containers" },
  { id: "00000000-0000-0000-0000-000000000007", name: "String",           icon: "🧵", category: "connectors" },
  { id: "00000000-0000-0000-0000-000000000008", name: "Egg Carton",       icon: "🥚", category: "containers" },
  { id: "00000000-0000-0000-0000-000000000009", name: "Foil",             icon: "✨", category: "paper"      },
  { id: "00000000-0000-0000-0000-000000000010", name: "Glue",             icon: "🗜️", category: "connectors" },
  { id: "00000000-0000-0000-0000-000000000011", name: "Paper",            icon: "📄", category: "paper"      },
  { id: "00000000-0000-0000-0000-000000000012", name: "Cereal Box",       icon: "🥣", category: "containers" },
  { id: "00000000-0000-0000-0000-000000000013", name: "Rubber Bands",     icon: "🔁", category: "connectors" },
  { id: "00000000-0000-0000-0000-000000000014", name: "Popsicle Sticks",  icon: "🪵", category: "wood"       },
  { id: "00000000-0000-0000-0000-000000000015", name: "Paint",            icon: "🎨", category: "art"        },
];

export const materialCategories = [
  { id: "all",        label: "All"            },
  { id: "paper",      label: "Paper & Foil"   },
  { id: "containers", label: "Containers"     },
  { id: "connectors", label: "Connectors"     },
  { id: "art",        label: "Art Supplies"   },
  { id: "tubes",      label: "Tubes & Rolls"  },
  { id: "wood",       label: "Wood & Sticks"  },
  { id: "fabric",     label: "Fabric & Yarn"  },
  { id: "misc",       label: "Other"          },
];

export type Project = {
  id: string;
  title: string;
  description: string;
  ageRange: string;
  timeEstimate: string;
  cleanupLevel: "Low" | "Medium" | "High";
  supervisionLevel: SupervisionLevel;
  difficulty: "Easy" | "Medium" | "Hard";
  requiredMaterials: string[];
  optionalMaterials: string[];
  substitutions: Record<string, string>;
  steps: BuildStep[];
  matchLabel?: "Great Match" | "Close Match" | "Partial Match";
  emoji: string;
  bgColor: string;
};

export type BuildStep = {
  id: number;
  title: string;
  instruction: string;
  tip?: string;
  safetyNote?: string;
};

export const projects: Project[] = [
  {
    id: "cardboard-rocket",
    title: "Cardboard Rocket Ship",
    description: "Build a standing rocket ship with a nose cone, fins, and a porthole window. Great for imaginative play.",
    ageRange: "4–8",
    timeEstimate: "20 min",
    cleanupLevel: "Low",
    supervisionLevel: "check_in",
    difficulty: "Easy",
    requiredMaterials: ["cardboard", "tape", "markers"],
    optionalMaterials: ["foil", "toilet-roll"],
    substitutions: {
      "foil": "Shiny wrapping paper works great",
      "markers": "Crayons or paint work too",
    },
    emoji: "🚀",
    bgColor: "bg-builder-500",
    steps: [
      {
        id: 1,
        title: "Cut the Body",
        instruction: "Cut a large piece of cardboard into a rectangle — about 30cm tall and 20cm wide. This is your rocket body.",
        tip: "The taller the rectangle, the taller your rocket!",
      },
      {
        id: 2,
        title: "Roll Into a Tube",
        instruction: "Roll the cardboard into a tube shape and secure with tape along the seam. Make sure it holds its shape.",
        tip: "Overlap the edges a bit before taping for a stronger tube.",
      },
      {
        id: 3,
        title: "Make the Nose Cone",
        instruction: "Cut a half-circle from cardboard. Roll it into a cone shape and tape it closed. Tape the cone to the top of your tube.",
        safetyNote: "Ask an adult for help with scissors.",
      },
      {
        id: 4,
        title: "Add Rocket Fins",
        instruction: "Cut 3 triangle shapes from cardboard for the fins. Tape one fin to the bottom of the rocket, spacing them evenly around the tube.",
        tip: "Wider fins at the base help the rocket stand up on its own.",
      },
      {
        id: 5,
        title: "Cut the Porthole",
        instruction: "Draw a circle on the side of the rocket for a window. If you have foil, glue or tape a small piece behind it to make it shiny.",
        tip: "Draw the circle first with a marker before cutting.",
      },
      {
        id: 6,
        title: "Decorate",
        instruction: "Use markers to add flames at the bottom, write the rocket's name on the side, and decorate however you like!",
        tip: "Red and orange markers make great rocket flames.",
      },
      {
        id: 7,
        title: "Launch!",
        instruction: "Stand your rocket up and admire your work. Make rocket sounds optional but highly recommended.",
      },
    ],
  },
  {
    id: "bottle-cap-robot",
    title: "Bottle Cap Robot",
    description: "Assemble a fun flat robot face or standing figure using bottle caps as eyes, buttons, and body parts.",
    ageRange: "5–10",
    timeEstimate: "25 min",
    cleanupLevel: "Low",
    supervisionLevel: "check_in",
    difficulty: "Medium",
    requiredMaterials: ["bottle-caps", "cardboard", "glue", "markers"],
    optionalMaterials: ["foil", "tape", "toilet-roll"],
    substitutions: {
      "bottle-caps": "Buttons or coins work great",
      "glue": "Double-sided tape works if you don't have glue",
    },
    emoji: "🤖",
    bgColor: "bg-walnut-700",
    steps: [
      {
        id: 1,
        title: "Make the Body Base",
        instruction: "Cut a rectangle from cardboard for the robot's body — about 15cm tall and 12cm wide.",
      },
      {
        id: 2,
        title: "Cut the Head",
        instruction: "Cut a smaller square for the robot's head. It should be about the same width as the body.",
      },
      {
        id: 3,
        title: "Arrange Bottle Caps",
        instruction: "Before gluing, arrange bottle caps on the body to plan your design. Use 2 caps for eyes, some for buttons on the body.",
        tip: "Try different arrangements before committing to glue.",
      },
      {
        id: 4,
        title: "Glue It Together",
        instruction: "Glue the head to the top of the body. Then glue each bottle cap in place. Let dry for a few minutes.",
        safetyNote: "Adult supervision recommended for strong glue.",
      },
      {
        id: 5,
        title: "Add Robot Details",
        instruction: "Use markers to draw a mouth, antenna lines, arm joints, and any robot details you like.",
        tip: "Silver markers give an amazing robot look if you have them.",
      },
      {
        id: 6,
        title: "Add Arms and Legs",
        instruction: "Cut strips of cardboard for arms and legs. Fold them accordion-style so they look jointed, then tape to the sides and bottom.",
      },
    ],
  },
  {
    id: "egg-carton-creature",
    title: "Egg Carton Creature",
    description: "Transform an egg carton into a wacky creature with googly eyes, pipe cleaner legs, and painted details.",
    ageRange: "3–7",
    timeEstimate: "15 min",
    cleanupLevel: "Medium",
    supervisionLevel: "independent",
    difficulty: "Easy",
    requiredMaterials: ["egg-carton", "markers", "glue"],
    optionalMaterials: ["string", "foil", "tape"],
    substitutions: {
      "string": "Pipe cleaners or strips of paper work as legs",
    },
    emoji: "🐛",
    bgColor: "bg-kraft-500",
    steps: [
      {
        id: 1,
        title: "Prep the Egg Carton",
        instruction: "Cut the egg carton lid off. You can use the bottom tray as your creature's body.",
        safetyNote: "Ask an adult to help with cutting.",
      },
      {
        id: 2,
        title: "Decide Your Creature",
        instruction: "Is it a caterpillar? A monster? An alien bug? Pick your creature type before you start decorating.",
        tip: "Caterpillars are easiest — just paint each cup a different color!",
      },
      {
        id: 3,
        title: "Add the Eyes",
        instruction: "Draw two big eyes on one end of the carton using markers. You can also cut small circles from paper and glue them on.",
      },
      {
        id: 4,
        title: "Add Legs",
        instruction: "Cut string or strips of paper into 6–8 equal pieces. Poke small holes along the sides and thread the legs through, knotting to keep them in place.",
      },
      {
        id: 5,
        title: "Decorate",
        instruction: "Color each bump of the egg carton, add spots, stripes, or patterns with markers.",
        tip: "Alternating colors look amazing on caterpillar creatures.",
      },
      {
        id: 6,
        title: "Add Antennae",
        instruction: "Poke two small holes in the front end and thread string or a strip of paper through each. Tie a small knot at the end to stop them falling through.",
      },
    ],
  },
  {
    id: "cup-string-phone",
    title: "Cup-and-String Phone",
    description: "The classic! Make a real working telephone from two cups and some string that transmits your voice.",
    ageRange: "4–9",
    timeEstimate: "10 min",
    cleanupLevel: "Low",
    supervisionLevel: "check_in",
    difficulty: "Easy",
    requiredMaterials: ["plastic-cup", "string"],
    optionalMaterials: ["markers"],
    substitutions: {
      "plastic-cup": "Paper cups work even better for sound",
      "string": "Thin wire or fishing line carries sound further",
    },
    emoji: "📞",
    bgColor: "bg-orange-500",
    steps: [
      {
        id: 1,
        title: "Prep Your Cups",
        instruction: "Take two plastic cups. Make sure they're clean and dry.",
        tip: "Paper cups actually transmit sound better than plastic!",
      },
      {
        id: 2,
        title: "Poke the Holes",
        instruction: "Carefully poke a small hole in the center of the bottom of each cup.",
        safetyNote: "Use a pencil tip or ask an adult to use a sharp object.",
      },
      {
        id: 3,
        title: "Thread the String",
        instruction: "Cut a piece of string at least 3 meters long. Thread one end through the bottom of each cup from the outside in.",
      },
      {
        id: 4,
        title: "Tie Knots",
        instruction: "Tie a knot inside each cup so the string can't pull back through. The knot should be bigger than the hole.",
      },
      {
        id: 5,
        title: "Decorate",
        instruction: "Decorate your cups with markers — make them look like old phones, walkie talkies, or just go wild with color.",
      },
      {
        id: 6,
        title: "Test It!",
        instruction: "Hold one cup and have a friend hold the other. Walk apart until the string is tight (but not pulling). Speak into one cup while the other person listens. Can you hear each other?",
        tip: "The string MUST be pulled tight for it to work. Slack string = no sound.",
      },
    ],
  },
  {
    id: "cereal-box-puppet-theater",
    title: "Cereal Box Puppet Theater",
    description: "Turn a cereal box into a mini puppet theater stage with curtains, a backdrop, and room for finger puppet shows.",
    ageRange: "5–10",
    timeEstimate: "30 min",
    cleanupLevel: "Medium",
    supervisionLevel: "check_in",
    difficulty: "Medium",
    requiredMaterials: ["cardboard", "markers", "tape", "string"],
    optionalMaterials: ["foil", "glue"],
    substitutions: {
      "string": "Ribbon or strips of fabric work as curtains",
      "foil": "Use stickers or bright paper for decoration",
    },
    emoji: "🎭",
    bgColor: "bg-walnut-600",
    steps: [
      {
        id: 1,
        title: "Prep the Box",
        instruction: "Take a large cereal box and cut out a big rectangle from the front panel — this is your stage opening. Leave a border of about 3cm on all sides.",
        safetyNote: "Adult help needed for cutting.",
      },
      {
        id: 2,
        title: "Cut the Stage Floor",
        instruction: "At the bottom of the opening, fold a small flap inward to create a stage floor where your puppets can stand.",
      },
      {
        id: 3,
        title: "Make the Curtains",
        instruction: "Cut two pieces of string or ribbon long enough to hang across the top of the opening. Cut fabric scraps or colored paper into curtain shapes and glue or tape them to hang from the string.",
        tip: "Red curtains look the most theatrical!",
      },
      {
        id: 4,
        title: "Create a Backdrop",
        instruction: "Draw or paint a backdrop scene on a piece of paper that fits inside the back of the box. Tape it in place inside the theater.",
      },
      {
        id: 5,
        title: "Decorate the Frame",
        instruction: "Decorate the outside of the box to look like a fancy theater — add stars, columns, a theater name, lights.",
        tip: "Foil strips along the edges look like stage lights!",
      },
      {
        id: 6,
        title: "Make Your Puppets",
        instruction: "Draw characters on small pieces of cardboard, cut them out, and tape a popsicle stick or pencil to the back as a handle. You're ready for your first show!",
      },
    ],
  },
];
