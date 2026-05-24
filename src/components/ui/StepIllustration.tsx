import type { ReactNode } from "react";

type StepAction =
  | "cut" | "roll" | "fold" | "tape" | "glue"
  | "decorate" | "thread" | "tie" | "launch" | "default";

function getStepAction(title: string): StepAction {
  const t = title.toLowerCase();
  if (/cut|snip|scissor/.test(t)) return "cut";
  if (/roll/.test(t)) return "roll";
  if (/fold/.test(t)) return "fold";
  if (/tape|secure|attach/.test(t)) return "tape";
  if (/glue/.test(t)) return "glue";
  if (/decor|color|paint|draw|backdrop/.test(t)) return "decorate";
  if (/poke|thread|hole|antenn/.test(t)) return "thread";
  if (/tie|knot/.test(t)) return "tie";
  if (/launch|test|try|stand/.test(t)) return "launch";
  return "default";
}

function ScissorsSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-wiggle w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Handle 1 */}
      <circle cx="18" cy="22" r="11" fill="#F8F3EA" stroke="#8B6B52" strokeWidth="2.5" />
      <circle cx="18" cy="22" r="4"  fill="#8B6B52" />
      {/* Handle 2 */}
      <circle cx="18" cy="58" r="11" fill="#F8F3EA" stroke="#8B6B52" strokeWidth="2.5" />
      <circle cx="18" cy="58" r="4"  fill="#8B6B52" />
      {/* Blades */}
      <path d="M27 24 L68 40" stroke="#4A301E" strokeWidth="2.5" strokeLinecap="round" />
      <path d="M27 56 L68 40" stroke="#4A301E" strokeWidth="2.5" strokeLinecap="round" />
      {/* Pivot */}
      <circle cx="47" cy="40" r="3.5" fill="#C8A97E" stroke="#8B6B52" strokeWidth="1.5" />
    </svg>
  );
}

function RollSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-bounce-soft w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Cylinder body */}
      <rect x="14" y="28" width="42" height="24" fill="#C8A97E" />
      {/* Top ellipse */}
      <ellipse cx="35" cy="28" rx="21" ry="7" fill="#E8D4B0" stroke="#8B6B52" strokeWidth="2" />
      {/* Bottom ellipse */}
      <ellipse cx="35" cy="52" rx="21" ry="7" fill="#A07840" stroke="#8B6B52" strokeWidth="2" />
      {/* Curved arrow */}
      <path d="M63 33 Q72 40 63 47" stroke="#2D9CDB" strokeWidth="2.5" strokeLinecap="round" fill="none" />
      <path d="M63 47 L59 44 M63 47 L67 44" stroke="#2D9CDB" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function FoldSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-pulse-soft w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Paper base */}
      <rect x="10" y="24" width="44" height="34" rx="3" fill="#E8D4B0" stroke="#8B6B52" strokeWidth="2" />
      {/* Folded flap */}
      <path d="M54 24 L54 45 L10 24 Z" fill="#C8A97E" stroke="#8B6B52" strokeWidth="2" strokeLinejoin="round" />
      {/* Fold crease line */}
      <path d="M10 24 L54 45" stroke="#8B6B52" strokeWidth="1.5" strokeDasharray="3 2" />
      {/* Arrow showing fold direction */}
      <path d="M62 36 Q70 30 65 22" stroke="#2D9CDB" strokeWidth="2" strokeLinecap="round" fill="none" />
      <path d="M65 22 L61 25 M65 22 L68 26" stroke="#2D9CDB" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function TapeSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-pulse-soft w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Tape roll outer */}
      <circle cx="30" cy="40" r="22" fill="#E8D4B0" stroke="#8B6B52" strokeWidth="2.5" />
      {/* Inner hole */}
      <circle cx="30" cy="40" r="9"  fill="#F8F3EA" stroke="#8B6B52" strokeWidth="2" />
      {/* Strip coming off */}
      <path d="M50 30 L70 22 L72 28 L52 37 Z" fill="#C8A97E" stroke="#8B6B52" strokeWidth="1.5" />
      {/* Serrated cut mark */}
      <path d="M70 22 L72 25 M71 23 L73 26" stroke="#8B6B52" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function GlueSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-float w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Bottle body */}
      <rect x="26" y="30" width="24" height="30" rx="5" fill="#F28C28" stroke="#D97818" strokeWidth="2" />
      {/* Neck */}
      <rect x="32" y="18" width="12" height="14" rx="3" fill="#F5A052" stroke="#D97818" strokeWidth="2" />
      {/* Cap */}
      <rect x="30" y="13" width="16" height="7" rx="2" fill="#8B6B52" />
      {/* Label stripe */}
      <rect x="30" y="39" width="16" height="8" rx="2" fill="#F5A052" opacity="0.6" />
      {/* Drip */}
      <ellipse cx="40" cy="67" rx="4" ry="5" fill="#E8D4B0" opacity="0.9" />
      <line x1="40" y1="60" x2="40" y2="63" stroke="#E8D4B0" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

function DecorateSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-float w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Marker 1 — blue, tilted left */}
      <g transform="rotate(-18 20 42)">
        <rect x="15" y="18" width="10" height="34" rx="3" fill="#2D9CDB" />
        <rect x="15" y="50" width="10" height="6"  rx="1" fill="#1E87C4" />
        <rect x="15" y="14" width="10" height="6"  rx="2" fill="#4BAEE3" />
      </g>
      {/* Marker 2 — orange, straight */}
      <rect x="34" y="14" width="10" height="34" rx="3" fill="#F28C28" />
      <rect x="34" y="46" width="10" height="6"  rx="1" fill="#D97818" />
      <rect x="34" y="10" width="10" height="6"  rx="2" fill="#F5A052" />
      {/* Marker 3 — walnut, tilted right */}
      <g transform="rotate(18 60 42)">
        <rect x="54" y="18" width="10" height="34" rx="3" fill="#8B6B52" />
        <rect x="54" y="50" width="10" height="6"  rx="1" fill="#4A301E" />
        <rect x="54" y="14" width="10" height="6"  rx="2" fill="#C8A97E" />
      </g>
      {/* Color dots */}
      <circle cx="18" cy="70" r="3" fill="#2D9CDB" />
      <circle cx="39" cy="72" r="3" fill="#F28C28" />
      <circle cx="60" cy="70" r="3" fill="#8B6B52" />
    </svg>
  );
}

function ThreadSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-pulse-soft w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Material */}
      <rect x="8" y="34" width="58" height="12" rx="4" fill="#E8D4B0" stroke="#8B6B52" strokeWidth="2" />
      {/* Needle body */}
      <rect x="36" y="8"  width="6"  height="40" rx="2" fill="#8B6B52" />
      {/* Needle eye */}
      <ellipse cx="39" cy="15" rx="2" ry="3" fill="#F8F3EA" />
      {/* Needle tip */}
      <path d="M37 48 L39 56 L41 48" fill="#4A301E" />
      {/* Thread */}
      <path d="M39 15 Q18 8 12 22" stroke="#F28C28" strokeWidth="2" strokeLinecap="round" fill="none" strokeDasharray="4 2" />
    </svg>
  );
}

function TieSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-bounce-soft w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* String ends coming in */}
      <path d="M8  28 Q22 38 18 48" stroke="#F28C28" strokeWidth="3" strokeLinecap="round" fill="none" />
      <path d="M72 28 Q58 38 62 48" stroke="#F28C28" strokeWidth="3" strokeLinecap="round" fill="none" />
      {/* Left bow loop */}
      <path d="M18 48 Q10 64 28 60 Q34 56 40 54" stroke="#8B6B52" strokeWidth="3" strokeLinecap="round" fill="none" />
      {/* Right bow loop */}
      <path d="M62 48 Q70 64 52 60 Q46 56 40 54" stroke="#8B6B52" strokeWidth="3" strokeLinecap="round" fill="none" />
      {/* Center knot */}
      <circle cx="40" cy="51" r="5.5" fill="#C8A97E" stroke="#8B6B52" strokeWidth="2" />
      {/* Tails */}
      <path d="M36 55 Q28 66 20 68" stroke="#8B6B52" strokeWidth="3" strokeLinecap="round" fill="none" />
      <path d="M44 55 Q52 66 60 68" stroke="#8B6B52" strokeWidth="3" strokeLinecap="round" fill="none" />
    </svg>
  );
}

function LaunchSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-launch w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Rocket body */}
      <path d="M40 8 Q53 20 53 46 L40 52 L27 46 Q27 20 40 8Z" fill="#2D9CDB" stroke="#1E87C4" strokeWidth="2" />
      {/* Body highlight */}
      <path d="M40 8 Q47 20 47 36 L40 40 L33 36 Q33 20 40 8Z" fill="#4BAEE3" />
      {/* Porthole */}
      <circle cx="40" cy="32" r="5" fill="#F8F3EA" stroke="#1E87C4" strokeWidth="1.5" />
      {/* Left fin */}
      <path d="M27 44 L16 56 L27 52 Z" fill="#F28C28" />
      {/* Right fin */}
      <path d="M53 44 L64 56 L53 52 Z" fill="#F28C28" />
      {/* Flame outer */}
      <path d="M33 52 Q36 64 40 60 Q44 64 47 52" fill="#F28C28" />
      {/* Flame inner */}
      <path d="M36 52 Q38 60 40 57 Q42 60 44 52" fill="#F5A052" />
    </svg>
  );
}

function DefaultSVG() {
  return (
    <svg viewBox="0 0 80 80" className="animate-float w-14 h-14" fill="none" xmlns="http://www.w3.org/2000/svg">
      {/* Star */}
      <path
        d="M40 12 L44 30 L62 30 L48 40 L53 58 L40 48 L27 58 L32 40 L18 30 L36 30 Z"
        fill="#C8A97E" stroke="#8B6B52" strokeWidth="1.5" strokeLinejoin="round"
      />
      {/* Sparkles */}
      <circle cx="15" cy="16" r="3" fill="#F28C28" />
      <path d="M64 18 L66 22 M66 18 L64 22" stroke="#2D9CDB" strokeWidth="2" strokeLinecap="round" />
      <circle cx="65" cy="60" r="2.5" fill="#C8A97E" />
      <path d="M12 58 L14 62 M14 58 L12 62" stroke="#F28C28" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

const svgMap: Record<StepAction, ReactNode> = {
  cut:      <ScissorsSVG />,
  roll:     <RollSVG />,
  fold:     <FoldSVG />,
  tape:     <TapeSVG />,
  glue:     <GlueSVG />,
  decorate: <DecorateSVG />,
  thread:   <ThreadSVG />,
  tie:      <TieSVG />,
  launch:   <LaunchSVG />,
  default:  <DefaultSVG />,
};

export function StepIllustration({ title }: { title: string }) {
  const action = getStepAction(title);
  return (
    <div className="flex justify-center pt-1 pb-3">
      <div className="w-24 h-24 bg-kraft-500/10 rounded-3xl flex items-center justify-center">
        {svgMap[action]}
      </div>
    </div>
  );
}
