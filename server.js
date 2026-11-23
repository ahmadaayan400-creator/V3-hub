/*
  AAYAN PROTECTION SERVER
  ------------------------------------------------------------
  Deploy this on Render.com (or any free Node host). It:

  1. Serves a branded loader page at "/" (public/index.html) with one
     fixed "Copy Script" button - no key system, just like a normal
     script-hub loader.
  2. Only hands out the REAL script (protected_script.lua) from "/load"
     when the request looks like it came from a Roblox executor, not a
     normal browser. Anyone who just pastes the loadstring URL into a
     browser tab gets a troll response instead of your code.
  3. Logs every request (IP + User-Agent) to the console so you can see
     in the Render dashboard who's hitting the endpoint.

  Nothing here can stop a 100% determined person with their own proxy,
  but it kills casual "open link in browser -> copy raw code" leeching,
  which is how most leaks like the V3 one actually happen.
*/

const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

// ---- config ----
const MAX_REQ_PER_MIN = 20; // simple per-IP rate limit on /load

// ---- in-memory state (fine for a single free-tier instance) ----
const hits = new Map(); // ip -> [timestamps]

function cleanup() {
  const now = Date.now();
  for (const [ip, arr] of hits) {
    const recent = arr.filter((t) => now - t < 60000);
    if (recent.length) hits.set(ip, recent);
    else hits.delete(ip);
  }
}
setInterval(cleanup, 60000);

function getIp(req) {
  return (req.headers["x-forwarded-for"] || req.socket.remoteAddress || "unknown").split(",")[0].trim();
}

function looksLikeExecutor(req) {
  const ua = (req.headers["user-agent"] || "").toLowerCase();
  // Most Roblox executors either send no User-Agent, a Roblox-style one,
  // or an http-library default (not a real desktop/mobile browser UA).
  const browserSignals = ["mozilla", "chrome", "safari", "firefox", "edg/"];
  const robloxSignals = ["roblox", "winhttp", "requests", "okhttp", "python", "lua", "wininet"];
  if (robloxSignals.some((s) => ua.includes(s))) return true;
  if (!ua) return true; // many executors send an empty UA
  if (browserSignals.some((s) => ua.includes(s))) return false;
  return true; // unknown client -> default to allow, log it instead
}

function rateLimited(ip) {
  const now = Date.now();
  const arr = hits.get(ip) || [];
  const recent = arr.filter((t) => now - t < 60000);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > MAX_REQ_PER_MIN;
}

app.use(express.static(path.join(__dirname, "public")));

// ---- serve the real script, gated by a basic executor check ----
app.get("/load", async (req, res) => {
  const ip = getIp(req);
  const ua = req.headers["user-agent"] || "(none)";
  console.log(`[LOAD HIT] ip=${ip} ua="${ua}"`);

  if (rateLimited(ip)) {
    return res.status(429).send("-- too many requests, slow down");
  }

  if (!looksLikeExecutor(req)) {
    // browser (or anything that doesn't look like an executor) just gets
    // sent back to the loader website - no code, no error text, nothing
    // to copy-paste.
    return res.redirect(302, "/");
  }

  // Option A (recommended): set SOURCE_URL in Render's environment variables
  // to your EXISTING raw script link (e.g. a GitHub raw .lua URL). This
  // server fetches it fresh each time and forwards it - you never have to
  // paste code into this repo, and updating your GitHub file updates the
  // live script automatically.
  const sourceUrl = process.env.SOURCE_URL;
  if (sourceUrl) {
    try {
      const upstream = await fetch(sourceUrl);
      const code = await upstream.text();
      res.set("Content-Type", "text/plain");
      return res.send(code);
    } catch (e) {
      console.log("[SOURCE_URL FETCH FAILED]", e.message);
      return res.status(502).send("-- could not reach the source script, try again");
    }
  }

  // Option B: no SOURCE_URL set -> fall back to the local protected_script.lua
  // file in this repo (paste your real script into that file directly).
  const scriptPath = path.join(__dirname, "protected_script.lua");
  if (!fs.existsSync(scriptPath)) {
    return res.status(500).send("-- script not configured on server yet");
  }
  res.set("Content-Type", "text/plain");
  res.send(fs.readFileSync(scriptPath, "utf8"));
});

app.listen(PORT, () => console.log(`AAYAN protection server running on :${PORT}`));
 
