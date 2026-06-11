/**
 * Generates the Krusader README banner (house banner convention):
 *   krusader-banner.svg / .png : white 1600x500 — the Breeze-recoloured logo on
 *                                the left, "Krusader" in Fira Sans SemiBold +
 *                                a cheeky claim below in Fira Sans Regular.
 *
 * The text is converted to SVG paths (opentype.js) so the SVG is self-contained.
 * Fira Sans (OFL) is fetched at runtime via the Google-Fonts CSS API — a legacy
 * User-Agent makes it return STATIC per-weight TTF URLs (opentype.js cannot
 * apply variable-font gvar deltas) — and cached in the OS temp dir, never
 * committed to the repo.
 *
 * The OLD logo-only banner is preserved as krusader-banner-logo.png — support
 * threads use that one; do not delete it. (build_logo.py regenerates it.)
 *
 * Deps: `npm i -g @resvg/resvg-js opentype.js`. Run: node .github/assets/gen-banner.mjs
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const gRoot = execSync("npm root -g").toString().trim();
const { Resvg } = require(`${gRoot}/@resvg/resvg-js`);
const opentype = require(`${gRoot}/opentype.js`);

const __dir = dirname(fileURLToPath(import.meta.url));

// ---- content + styling -----------------------------------------------------
const NAME = "Krusader";
const CLAIM = "Two panes. Zero mercy for messy files.";
const NAME_FILL = "#232629"; // Breeze dark grey — the logo's frame colour
const CLAIM_FILL = "#5a5d5e"; // house claim grey
const W = 1600, H = 500;
const LH = 400; // logo height (the source is square, 200x200 units)
const nameSize = 150, claimSize = 42, gap = 64, lineGap = 22;
// ---------------------------------------------------------------------------

async function loadFont(spec, cacheName) {
  const path = join(tmpdir(), `krusader-${cacheName}.ttf`);
  if (!existsSync(path)) {
    const cssRes = await fetch(`https://fonts.googleapis.com/css2?family=${spec}`, {
      headers: { "User-Agent": "curl/8" }, // legacy UA → static TTF, no subsets
    });
    if (!cssRes.ok) throw new Error(`font css ${spec}: ${cssRes.status}`);
    const m = (await cssRes.text()).match(/url\((https:[^)]+\.ttf)\)/);
    if (!m) throw new Error(`no ttf url in css for ${spec}`);
    const ttf = await fetch(m[1]);
    if (!ttf.ok) throw new Error(`font ttf ${spec}: ${ttf.status}`);
    writeFileSync(path, Buffer.from(await ttf.arrayBuffer()));
  }
  const buf = readFileSync(path);
  return opentype.parse(buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength));
}
const firaSemi = await loadFont("Fira+Sans:wght@600", "FiraSans-600");
const firaReg = await loadFont("Fira+Sans:wght@400", "FiraSans-400");

const nameW = firaSemi.getAdvanceWidth(NAME, nameSize, { kerning: true });
const claimW = firaReg.getAdvanceWidth(CLAIM, claimSize, { kerning: true });
const LW = LH; // square logo
const groupW = LW + gap + Math.max(nameW, claimW);
const startX = (W - groupW) / 2;
const LX = startX, LY = (H - LH) / 2;
const textX = startX + LW + gap;

const em = (f, s) => s / f.unitsPerEm;
const nameAsc = firaSemi.ascender * em(firaSemi, nameSize);
const nameDesc = -firaSemi.descender * em(firaSemi, nameSize);
const claimAsc = firaReg.ascender * em(firaReg, claimSize);
const blockH = nameAsc + nameDesc + lineGap + claimAsc;
const nameBaseline = H / 2 - blockH / 2 + nameAsc;
const claimBaseline = nameBaseline + nameDesc + lineGap + claimAsc;

const namePath = firaSemi
  .getPath(NAME, textX, nameBaseline, nameSize, { kerning: true })
  .toPathData(2);
const claimPath = firaReg
  .getPath(CLAIM, textX, claimBaseline, claimSize, { kerning: true })
  .toPathData(2);

// Embed the Breeze-recoloured logo verbatim. Its root <svg> has width/height but
// NO viewBox, so the positioned wrapper adds one (same 200x200 unit space) —
// attribute-only change, the artwork inside is untouched.
let logo = readFileSync(join(__dir, "krusader-logo-breeze.svg"), "utf8")
  .replace(/<\?xml[^>]*\?>\s*/, "");
logo = logo.replace(
  /<svg[\s\S]*?>/,
  `<svg x="${LX.toFixed(1)}" y="${LY.toFixed(1)}" width="${LW}" height="${LH}" viewBox="0 0 200.00003 199.99998" xmlns="http://www.w3.org/2000/svg">`,
);

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="Krusader">
  <rect width="${W}" height="${H}" fill="#ffffff"/>
  ${logo}
  <path d="${namePath}" fill="${NAME_FILL}"/>
  <path d="${claimPath}" fill="${CLAIM_FILL}"/>
</svg>
`;
writeFileSync(join(__dir, "krusader-banner.svg"), svg);

const png = new Resvg(svg, { fitTo: { mode: "width", value: W }, background: "white" }).render().asPng();
writeFileSync(join(__dir, "krusader-banner.png"), png);
console.log(`wrote krusader-banner.svg + .png (name ${Math.round(nameW)}px, claim ${Math.round(claimW)}px, group ${Math.round(groupW)}px)`);
