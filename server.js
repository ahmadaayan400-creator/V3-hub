const express = require("express");
const path = require("path");
 
const app = express();
const PORT = process.env.PORT || 3000;

const SCRIPT_URL =
"https://raw.githubusercontent.com/ahmadaayan400-creator/V3-hub/refs/heads/main/DATABASE_GUI-4.lua";

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.get("/health", (req, res) => {
    res.json({status:"online"});
});

app.get("/load", async (req, res) => {
    try {
        const response = await fetch(SCRIPT_URL);

        if (!response.ok) {
            return res.status(502).send("Script source unavailable");
        }

        const lua = await response.text();

        res.set("Cache-Control", "no-store");
        res.type("text/plain").send(lua);

    } catch (error) {
        res.status(500).send("Protector server error");
    }
});

app.listen(PORT, "0.0.0.0", () => {
    console.log("ALPHA EMPIRE PROTECTOR ONLINE");
});
