/**
 * Generates the Krusader README banner (house banner convention):
 *   krusader-banner.svg / .png : white 1600x500 - the Breeze-recoloured logo on
 *                                the left, the official lowercase "krusader"
 *                                wordmark + a cheeky claim below.
 *
 * The official Krusader wordmark (krusader.org header) is lowercase "krusader"
 * in DejaVu Sans Bold Oblique - the classic Bitstream-Vera-era Linux face. We
 * replicate it faithfully; the claim uses DejaVu Sans Book. Both fonts are free
 * (Bitstream Vera / DejaVu licence), fetched at runtime from the dejavu-fonts-ttf
 * npm package via jsDelivr, cached in the OS temp dir, and never committed.
 *
 * The text is converted to SVG paths (opentype.js) so the SVG is self-contained.
 * NOTE: DejaVu's GSUB ccmp lookups crash opentype.js's feature engine, so glyph
 * runs are shaped with features disabled (plain Latin text - no loss).
 *
 * The OLD logo-only banner is preserved as krusader-banner-logo.png - support
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
const NAME = "krusader"; // lowercase, exactly like the official wordmark
const CLAIM = "Drag it. Drop it. In the dark.";
const NAME_FILL = "#232629"; // Breeze dark grey - the logo's frame colour
const CLAIM_FILL = "#5a5d5e"; // house claim grey
const W = 1600, H = 500;
const LH = 400; // logo height (the source is square, 200x200 units)
const nameSize = 150, claimSize = 42, gap = 64, lineGap = 22;
// ---------------------------------------------------------------------------

// DejaVu's ccmp GSUB lookups crash opentype.js's feature engine even with
// features disabled (the Bidi pipeline always applies ccmp). For plain Latin
// text we shape glyph-by-glyph instead - charToGlyph + manual pair kerning -
// which bypasses that pipeline entirely with no visual loss.
function shapeRun(font, text, size) {
  const scale = size / font.unitsPerEm;
  const run = [];
  let x = 0;
  let prev = null;
  for (const ch of text) {
    const g = font.charToGlyph(ch);
    if (prev) x += font.getKerningValue(prev, g) * scale;
    run.push({ g, x });
    x += g.advanceWidth * scale;
    prev = g;
  }
  return { run, width: x };
}
function runWidth(font, text, size) {
  return shapeRun(font, text, size).width;
}
function runPathData(font, text, x, y, size) {
  let d = "";
  for (const { g, x: gx } of shapeRun(font, text, size).run) {
    d += g.getPath(x + gx, y, size).toPathData(2);
  }
  return d;
}

async function loadFont(url, cacheName) {
  const path = join(tmpdir(), `krusader-${cacheName}.ttf`);
  if (!existsSync(path)) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`font fetch ${cacheName}: ${res.status}`);
    writeFileSync(path, Buffer.from(await res.arrayBuffer()));
  }
  const buf = readFileSync(path);
  return opentype.parse(buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength));
}
const DEJAVU = "https://cdn.jsdelivr.net/npm/dejavu-fonts-ttf@2.37.3/ttf";
const nameFont = await loadFont(`${DEJAVU}/DejaVuSans-BoldOblique.ttf`, "DejaVuSans-BoldOblique");
const claimFont = await loadFont(`${DEJAVU}/DejaVuSans.ttf`, "DejaVuSans-Book");

const nameW = runWidth(nameFont, NAME, nameSize);
const claimW = runWidth(claimFont, CLAIM, claimSize);
const LW = LH; // square logo
const groupW = LW + gap + Math.max(nameW, claimW);
const startX = (W - groupW) / 2;
const LX = startX, LY = (H - LH) / 2;
const textX = startX + LW + gap;

const em = (f, s) => s / f.unitsPerEm;
const nameAsc = nameFont.ascender * em(nameFont, nameSize);
const nameDesc = -nameFont.descender * em(nameFont, nameSize);
const claimAsc = claimFont.ascender * em(claimFont, claimSize);
const blockH = nameAsc + nameDesc + lineGap + claimAsc;
const nameBaseline = H / 2 - blockH / 2 + nameAsc;
const claimBaseline = nameBaseline + nameDesc + lineGap + claimAsc;

const namePath = runPathData(nameFont, NAME, textX, nameBaseline, nameSize);
const claimPath = runPathData(claimFont, CLAIM, textX, claimBaseline, claimSize);

// Embed the Breeze-recoloured logo verbatim. Its root <svg> has width/height but
// NO viewBox, so the positioned wrapper adds one (same 200x200 unit space) -
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
