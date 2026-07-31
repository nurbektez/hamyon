const React = require("react");
const { renderToStaticMarkup } = require("react-dom/server");
const sharp = require("sharp");
const Fa = require("react-icons/fa");
const Fa6 = require("react-icons/fa6");

async function makeIcon(name, hex) {
  const El = Fa[name] || Fa6[name];
  if (!El) throw new Error("Icon not found: " + name);
  const svg = renderToStaticMarkup(
    React.createElement(El, { color: "#" + hex, size: 512 })
  );
  const buf = await sharp(Buffer.from(svg), { density: 384 })
    .resize(512, 512, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

async function buildIcons(spec) {
  const out = {};
  for (const [key, [name, hex]] of Object.entries(spec)) {
    out[key] = await makeIcon(name, hex);
  }
  return out;
}

module.exports = { makeIcon, buildIcons };
