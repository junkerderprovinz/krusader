/**
 * Renders the README banner that points Krusader users at CannonCommander, in the
 * style of the KnightLoader banner in the JDownloader repos: 1920x640, the logo and
 * the name large so the app is known at a glance, the two panels on the right.
 * Logo and screenshot come from the CannonCommander repo.
 *
 * Needs playwright-core installed globally and Chrome.
 * Run: node .github/assets/gen-cannoncommander-ad.mjs
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const { chromium } = require(`${execSync("npm root -g").toString().trim()}/playwright-core`);

const here = dirname(fileURLToPath(import.meta.url));

async function cached(file, url) {
  const path = join(tmpdir(), `cannoncommander-ad-${file}`);
  if (!existsSync(path)) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`${file}: fetch ${res.status}`);
    writeFileSync(path, Buffer.from(await res.arrayBuffer()));
  }
  return readFileSync(path);
}

const dataUrl = (buf, type) => `data:${type};base64,${buf.toString("base64")}`;
const fonts = "https://github.com/google/fonts/raw/main/ofl";
const cc = "https://raw.githubusercontent.com/junkerderprovinz/cannoncommander/main/.github/assets";
const bree = dataUrl(await cached("BreeSerif-Regular.ttf", `${fonts}/breeserif/BreeSerif-Regular.ttf`), "font/ttf");
const lato = dataUrl(await cached("Lato-Regular.ttf", `${fonts}/lato/Lato-Regular.ttf`), "font/ttf");
const latoBold = dataUrl(await cached("Lato-Bold.ttf", `${fonts}/lato/Lato-Bold.ttf`), "font/ttf");
const mark = dataUrl(await cached("logo.svg", `${cc}/logo.svg`), "image/svg+xml");
// The raw capture rather than the README picture: it is the bare interface at twice the
// pixels, so it stays sharp at this size and the window around it can match the store pictures.
const shot = dataUrl(await cached("panels.png", `${cc}/screenshots/captures/panels.png`), "image/png");
// Drawn rather than typed, since Bree Serif has no check mark.
const tick = dataUrl(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 12.5l5 5L20 6.5" fill="none" stroke="#FCC419" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`), "image/svg+xml");

// The capture is 1440x700 in twice the pixels.
const winWidth = 720;
const viewHeight = Math.round((winWidth * 700) / 1440);
const barHeight = 40;

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face { font-family: "Bree Serif"; src: url(${bree}); }
@font-face { font-family: Lato; src: url(${lato}); font-weight: 400; }
@font-face { font-family: Lato; src: url(${latoBold}); font-weight: 700; }
* { box-sizing: border-box; margin: 0; }
body { position: relative; width: 1920px; height: 640px; overflow: hidden; font-family: Lato, sans-serif; background: #0c0c0b; }
.wall { position: absolute; inset: 0; background: radial-gradient(55% 60% at 62% 35%, #26231d, #0f0e0c 72%); }
.relief { position: absolute; width: 34%; left: 52%; top: -26%; transform: rotate(-10deg); opacity: .32;
  filter: grayscale(1) brightness(.36) contrast(1.2) drop-shadow(-2px -2px 0 rgba(255,255,255,.16)) drop-shadow(12px 18px 26px rgba(0,0,0,.85)); }
.vignette { position: absolute; inset: 0; box-shadow: inset 0 0 200px rgba(0,0,0,.6); }
.crest { position: absolute; left: 64px; top: 150px; width: 340px; height: 340px; filter: drop-shadow(0 20px 40px rgba(0,0,0,.6)); }
.copy { position: absolute; left: 450px; top: 0; bottom: 0; width: 650px; display: flex; flex-direction: column; justify-content: center; align-items: flex-start; gap: 22px; }
.label { padding: 8px 18px; border-radius: 8px; background: #FCC419; color: #141414; font: 700 22px/1 Lato, sans-serif; letter-spacing: .12em; text-transform: uppercase; }
.name { font: 400 118px/1 "Bree Serif", serif; color: #f4f4f4; white-space: nowrap; }
.what { margin-top: -12px; font: 400 28px/1.1 Lato, sans-serif; color: #c9bfa9; white-space: nowrap; }
.what em { font-style: normal; font-weight: 700; color: #FCC419; }
.points { list-style: none; padding: 0; display: flex; flex-direction: column; gap: 8px; font: 400 38px/1.1 "Bree Serif", serif; color: #f4f4f4; white-space: nowrap; }
.points li { display: flex; align-items: center; gap: 16px; }
.points li::before { content: ""; flex: none; width: 30px; height: 30px; background: url("${tick}") center / contain no-repeat; }
.points em { font-style: normal; color: #FCC419; }
.go { margin-top: 10px; padding: 20px 38px; border-radius: 18px; background: #FCC419; color: #141414; font: 700 32px/1 Lato, sans-serif;
  box-shadow: 0 0 0 6px rgba(252,196,25,.18), 0 18px 40px rgba(0,0,0,.5); }
.window { position: absolute; right: 48px; top: 50%; width: ${winWidth}px; overflow: hidden; border-radius: 14px; background: #1c1c1c;
  transform: translateY(-50%) perspective(1800px) rotateY(-9deg); box-shadow: 0 30px 60px rgba(0,0,0,.75), 0 0 0 1px rgba(255,255,255,.06); }
.bar { height: ${barHeight}px; display: flex; align-items: center; padding: 0 14px; background: #242424; }
.address { flex: 1; height: 24px; border-radius: 12px; background: #2b2b2b; color: #b5b5b5; font: 400 13px/24px Lato, sans-serif; padding: 0 14px; }
.window img { display: block; width: ${winWidth}px; height: ${viewHeight}px; }
</style></head><body>
<div class="wall"></div><img class="relief" src="${mark}"><div class="vignette"></div>
<img class="crest" src="${mark}" alt="">
<div class="window"><div class="bar"><div class="address">nas.local:8480</div></div><img src="${shot}"></div>
<div class="copy">
  <span class="label">Krusader has a cousin</span>
  <div class="name">CannonCommander</div>
  <div class="what">A <em>smarter</em> two-pane file manager for your server</div>
  <ul class="points">
    <li><span>Knows cache, array and <em>sleeping disks</em></span></li>
    <li><span>Copies run in the background, with undo</span></li>
    <li><span>A real web app, not a streamed desktop</span></li>
  </ul>
  <span class="go">Why don't you try? &rarr;</span>
</div>
</body></html>`;

// Rendered at twice the size and scaled down, which keeps the type crisp.
const browser = await chromium.launch({ channel: "chrome" });
const big = await browser.newPage({ viewport: { width: 1920, height: 640 }, deviceScaleFactor: 2 });
await big.setContent(html);
await big.evaluate(() => document.fonts.ready);
// The name is longer than KnightLoader's and the lines below it run long, so each shrinks until it fits beside the window.
await big.evaluate(() => {
  for (const el of document.querySelectorAll(".name, .what, .points")) {
    const room = el.parentElement.clientWidth;
    const size = parseFloat(getComputedStyle(el).fontSize);
    if (el.scrollWidth > room) el.style.fontSize = `${Math.floor((size * room) / el.scrollWidth)}px`;
  }
});
const png = await big.screenshot();
const small = await browser.newPage({ viewport: { width: 1920, height: 640 } });
await small.setContent(`<body style="margin:0"><img src="${dataUrl(png, "image/png")}" style="display:block;width:1920px;height:640px">`);
await small.locator("img").evaluate((img) => img.decode());
await small.screenshot({ path: join(here, "cannoncommander-ad.png") });
await browser.close();
console.log("cannoncommander-ad.png written");
