const PptxGenJS = require("pptxgenjs");
const { buildIcons } = require("./icons");

// ---------- Palette ----------
const INK = "0D0D14";        // deep background
const PANEL = "191922";      // card surface
const PANEL2 = "212130";     // raised surface
const LINE = "2E2E3D";       // hairline border
const RED = "FF3B47";        // accent — REC / energy
const RED_DK = "D42130";
const GOLD = "FFC93C";       // secondary accent — spotlight
const WHITE = "FFFFFF";
const MUTED = "A2A2B5";
const DIM = "6C6C80";

const HEAD = "Arial";
const BODY = "Calibri";

const W = 13.333, H = 7.5;
const ML = 0.7, MR = 0.7;
const CW = W - ML - MR; // 11.933

const ICON_SPEC = {
  star:      ["FaStar", GOLD],
  video:     ["FaVideo", GOLD],
  laugh:     ["FaLaughSquint", GOLD],
  masks:     ["FaTheaterMasks", GOLD],
  clock:     ["FaClock", RED],
  calendar:  ["FaCalendarAlt", RED],
  film:      ["FaFilm", RED],
  layers:    ["FaLayerGroup", RED],
  youtube:   ["FaYoutube", RED],
  users:     ["FaUsers", GOLD],
  eye:       ["FaEye", GOLD],
  chart:     ["FaChartLine", GOLD],
  seedling:  ["FaSeedling", GOLD],
  mars:      ["FaMars", GOLD],
  venus:     ["FaVenus", RED],
  globe:     ["FaGlobeEurope", GOLD],
  box:       ["FaBoxOpen", GOLD],
  copyright: ["FaCopyright", GOLD],
  mic:       ["FaMicrophoneAlt", GOLD],
  couch:     ["FaCouch", GOLD],
  gift:      ["FaGift", GOLD],
  instagram: ["FaInstagram", WHITE],
  facebook:  ["FaFacebookF", WHITE],
  telegram:  ["FaTelegramPlane", WHITE],
  yt2:       ["FaYoutube", WHITE],
  tiktok:    ["FaTiktok", WHITE],
  desktop:   ["FaDesktop", WHITE],
  ad:        ["FaAd", WHITE],
  phone:     ["FaPhoneAlt", GOLD],
  handshake: ["FaHandshake", GOLD],
  camera:    ["FaCamera", WHITE],
  bolt:      ["FaBolt", GOLD],
  play:      ["FaPlay", WHITE],
};

async function main() {
  const I = await buildIcons(ICON_SPEC);
  const pres = new PptxGenJS();
  pres.layout = "LAYOUT_WIDE";
  pres.author = "Mergan Production";
  pres.company = "Mergan Production";
  pres.title = "Shunaqasi ham bo'p turadi — Kommersiya taklifi";

  const RR = pres.ShapeType.roundRect;
  const OVAL = pres.ShapeType.ellipse;
  const RECT = pres.ShapeType.rect;

  // ---------- helpers ----------
  const newSlide = (bgColor = INK) => {
    const s = pres.addSlide();
    s.background = { color: bgColor };
    return s;
  };

  const card = (s, x, y, w, h, opts = {}) =>
    s.addShape(RR, {
      x, y, w, h,
      rectRadius: opts.radius || 0.1,
      fill: { color: opts.fill || PANEL },
      line: { color: opts.line || LINE, width: opts.lineWidth || 0.75 },
    });

  const badge = (s, x, y, d, iconData, opts = {}) => {
    s.addShape(OVAL, {
      x, y, w: d, h: d,
      fill: { color: opts.fill || PANEL2 },
      line: { color: opts.line || LINE, width: 0.75 },
    });
    const pad = d * 0.28;
    s.addImage({ data: iconData, x: x + pad, y: y + pad, w: d - pad * 2, h: d - pad * 2 });
  };

  const header = (s, kicker, title, titleW) => {
    s.addText(kicker, {
      x: ML, y: 0.42, w: 9, h: 0.3, margin: 0,
      fontFace: HEAD, fontSize: 11, bold: true, color: GOLD, charSpacing: 2.5,
    });
    s.addText(title, {
      x: ML, y: 0.74, w: titleW || CW, h: 1.05, margin: 0, valign: "top",
      fontFace: HEAD, fontSize: 32, bold: true, color: WHITE, lineSpacing: 40,
    });
  };

  const footer = (s, num) => {
    s.addText("MERGAN PRODUCTION", {
      x: ML, y: 6.86, w: 4, h: 0.3, margin: 0,
      fontFace: HEAD, fontSize: 9, bold: true, color: DIM, charSpacing: 1.5,
    });
    s.addText(String(num).padStart(2, "0"), {
      x: W - MR - 1.2, y: 6.86, w: 1.2, h: 0.3, margin: 0, align: "right",
      fontFace: HEAD, fontSize: 9, bold: true, color: DIM, charSpacing: 1.5,
    });
  };

  const p = (s, text, o) =>
    s.addText(text, { margin: 0, fontFace: BODY, color: MUTED, lineSpacing: 22, ...o });

  // =====================================================================
  // 1 — TITLE
  // =====================================================================
  {
    const s = newSlide();

    // full-bleed poster on the right
    s.addImage({
      path: "assets/poster.jpg",
      x: 7.95, y: 0, w: 5.383, h: 7.5,
      sizing: { type: "cover", w: 5.383, h: 7.5 },
    });

    s.addText("MERGAN PRODUCTION", {
      x: ML, y: 1.05, w: 6.6, h: 0.3, margin: 0,
      fontFace: HEAD, fontSize: 12, bold: true, color: GOLD, charSpacing: 3,
    });
    s.addText("SHUNAQASI HAM\nBO\u2018P TURADI", {
      x: ML, y: 1.52, w: 6.9, h: 2.1, margin: 0, valign: "top",
      fontFace: HEAD, fontSize: 44, bold: true, color: WHITE, lineSpacing: 50,
    });
    p(s, "Komedik yashirin kamera ko\u2018rsatuvi \u2014 O\u2018zbekistonning mashhur shaxslari ishtirokida.", {
      x: ML, y: 3.5, w: 6.5, h: 0.9, fontSize: 15, color: MUTED, lineSpacing: 26,
    });

    const teaser = [
      ["62 400+", "YouTube obunachi"],
      ["48", "original son \u2014 yiliga"],
      ["3,6 mln+", "eng yuqori ko\u2018rish"],
    ];
    teaser.forEach(([v, l], i) => {
      const x = ML + i * 2.3;
      s.addText(v, {
        x, y: 4.6, w: 2.15, h: 0.45, margin: 0,
        fontFace: HEAD, fontSize: 22, bold: true, color: WHITE,
      });
      p(s, l, { x, y: 5.05, w: 2.15, h: 0.5, fontSize: 11.5, lineSpacing: 15 });
    });

    card(s, ML, 5.85, 4.85, 0.95, { fill: PANEL, radius: 0.12 });
    badge(s, ML + 0.25, 6.08, 0.5, I.handshake, { fill: INK });
    s.addText("KOMMERSIYA TAKLIFI", {
      x: ML + 0.95, y: 6.05, w: 3.7, h: 0.28, margin: 0,
      fontFace: HEAD, fontSize: 11, bold: true, color: GOLD, charSpacing: 2,
    });
    p(s, "Homiylik va hamkorlik dasturi", {
      x: ML + 0.95, y: 6.35, w: 3.7, h: 0.3, fontSize: 13, color: MUTED, lineSpacing: 16,
    });

    s.addNotes(
      "0:00\u20130:10 | Kirish. Kamera 1 (umumiy plan).\n" +
      "Jalol: Assalomu alaykum! Sarvar: Assalomu alaykum!\n" +
      "Jalol: Biz sizlarga Mergan Production\u2019ning yangi loyihasi \u2014 \u00abShunaqasi ham bo\u2018p turadi\u00bb komedik yashirin kamera shousini taqdim etamiz.\n" +
      "Montaj: loyiha logotipi, dynamic intro, studio kadrlari, Mergan Production logotipi."
    );
  }

  // =====================================================================
  // 2 — LOYIHA HAQIDA
  // =====================================================================
  {
    const s = newSlide();
    header(s, "01 · LOYIHA HAQIDA", "Yulduzlar ustidan komedik prank", 9.5);
    p(s, "Ushbu loyiha O‘zbekistonning mashhur estrada xonandalari, aktyorlari, blogerlari va taniqli shaxslariga uyushtiriladigan komedik yashirin kamera ko‘rsatuvidir.", {
      x: ML, y: 1.95, w: 5.2, h: 1.6, fontSize: 15, lineSpacing: 26,
    });
    card(s, ML, 4.7, 5.2, 1.5, { fill: PANEL });
    badge(s, ML + 0.35, 5.05, 0.7, I.bolt, { fill: INK });
    s.addText("Kutilmagan vaziyat — samimiy reaksiya", {
      x: ML + 1.25, y: 4.98, w: 3.6, h: 0.5, margin: 0, valign: "top",
      fontFace: HEAD, fontSize: 14, bold: true, color: WHITE, lineSpacing: 19,
    });
    p(s, "Kontentning asosiy kuchi — o‘ynalmagan emotsiya.", {
      x: ML + 1.25, y: 5.55, w: 3.6, h: 0.4, fontSize: 12, lineSpacing: 16,
    });

    const feats = [
      [I.star, "Mashhur mehmonlar", "Xonandalar, aktyorlar va blogerlar."],
      [I.video, "Yashirin kamera", "Mehmon uchun kutilmagan vaziyat."],
      [I.laugh, "Kulgili reaksiyalar", "Tabiiy, o‘ynalmagan emotsiyalar."],
      [I.masks, "Prank jarayoni", "Puxta senariy va professional prodakshn."],
    ];
    const cw = 2.99, ch = 2.0;
    feats.forEach(([ic, t, d], i) => {
      const x = 6.35 + (i % 2) * (cw + 0.3);
      const y = 1.95 + Math.floor(i / 2) * (ch + 0.25);
      card(s, x, y, cw, ch);
      badge(s, x + 0.3, y + 0.28, 0.68, ic, { fill: INK });
      s.addText(t, {
        x: x + 0.3, y: y + 1.05, w: cw - 0.6, h: 0.3, margin: 0,
        fontFace: HEAD, fontSize: 14, bold: true, color: WHITE,
      });
      p(s, d, { x: x + 0.3, y: y + 1.36, w: cw - 0.6, h: 0.55, fontSize: 11.5, lineSpacing: 15 });
    });
    footer(s, 2);
    s.addNotes(
      "0:10–0:25 | Loyiha haqida. Kamera 2.\n" +
      "Sarvar: Ushbu loyiha O‘zbekistonning mashhur estrada xonandalari, aktyorlari, blogerlari va taniqli shaxslariga uyushtiriladigan komedik yashirin kamera ko‘rsatuvidir.\n" +
      "Montaj: mashhur mehmonlar, yashirin kamera, kulgili reaksiyalar, prank jarayonlari."
    );
  }

  // =====================================================================
  // 3 — FORMAT
  // =====================================================================
  {
    const s = newSlide();
    header(s, "02 · FORMAT", "Har hafta — yangi son", 8);
    p(s, "Har bir original son 15–20 daqiqa davom etadi va har hafta shanba kuni Mergan Production YouTube kanalida e’lon qilinadi.", {
      x: ML, y: 1.55, w: 8.6, h: 0.75, fontSize: 15, lineSpacing: 24,
    });

    const items = [
      [I.clock, "15–20", "daqiqa davomiylik"],
      [I.calendar, "Shanba", "har haftalik chiqish kuni"],
      [I.film, "4", "original son — oyiga"],
      [I.layers, "48", "original son — yiliga"],
    ];
    const cw = (CW - 3 * 0.3) / 4, ch = 2.6;
    items.forEach(([ic, v, l], i) => {
      const x = ML + i * (cw + 0.3);
      const y = 2.7;
      card(s, x, y, cw, ch);
      badge(s, x + 0.32, y + 0.32, 0.72, ic, { fill: INK });
      s.addText(v, {
        x: x + 0.32, y: y + 1.2, w: cw - 0.64, h: 0.6, margin: 0,
        fontFace: HEAD, fontSize: 32, bold: true, color: WHITE,
      });
      p(s, l, { x: x + 0.32, y: y + 1.85, w: cw - 0.64, h: 0.6, fontSize: 12, lineSpacing: 16 });
    });

    card(s, ML, 5.65, CW, 0.85, { fill: PANEL2 });
    s.addText("Barqaror chiqish grafigi — hamkor brend butun yil davomida efirda ko‘rinadi.", {
      x: ML + 0.35, y: 5.87, w: CW - 0.7, h: 0.4, margin: 0,
      fontFace: BODY, fontSize: 14, color: WHITE,
    });
    footer(s, 3);
    s.addNotes(
      "0:25–0:40 | Format. Kamera 1.\n" +
      "Jalol: Har bir original son 15–20 daqiqa davom etadi va har hafta shanba kuni YouTube kanalimizda e’lon qilinadi.\n" +
      "Grafika: 15–20 daqiqa · Har hafta — Shanba · Oyiga 4 ta original son · Yiliga 48 ta original son."
    );
  }

  // =====================================================================
  // 4 — YOUTUBE KANALI
  // =====================================================================
  {
    const s = newSlide();
    header(s, "03 · YOUTUBE KANALI", "62 mingdan ortiq obunachi", 8);

    card(s, ML, 1.95, 5.55, 4.5, { fill: PANEL });
    badge(s, ML + 0.45, 2.35, 0.85, I.youtube, { fill: INK });
    s.addText("62 400+", {
      x: ML + 0.45, y: 3.4, w: 4.6, h: 1.0, margin: 0,
      fontFace: HEAD, fontSize: 58, bold: true, color: WHITE,
    });
    s.addText("OBUNACHI", {
      x: ML + 0.45, y: 4.45, w: 4.6, h: 0.32, margin: 0,
      fontFace: HEAD, fontSize: 13, bold: true, color: GOLD, charSpacing: 2.5,
    });
    p(s, "Mergan Production rasmiy YouTube kanali", {
      x: ML + 0.45, y: 4.85, w: 4.6, h: 0.4, fontSize: 13, lineSpacing: 18,
    });
    s.addShape(RECT, { x: ML + 0.45, y: 5.45, w: 4.65, h: 0.01, fill: { color: LINE }, line: { color: LINE, width: 0.5 } });
    p(s, "Obunachilar bazasi har bir yangi son bilan kengayib bormoqda.", {
      x: ML + 0.45, y: 5.62, w: 4.65, h: 0.6, fontSize: 12.5, color: DIM, lineSpacing: 17,
    });

    p(s, "Bugungi kunda Mergan Production YouTube kanalida 62 mingdan ortiq obunachi mavjud va kanalimizdagi kontent millionlab tomoshabinlarga yetib bormoqda.", {
      x: 6.6, y: 1.95, w: 6.03, h: 1.3, fontSize: 15, lineSpacing: 26,
    });

    const side = [
      [I.users, "Millionlab tomoshabin", "Kontent kanal doirasidan tashqariga chiqib, keng auditoriyaga yetib boradi."],
      [I.seedling, "Organik o‘sish", "Auditoriya sun’iy usullarsiz, kontent sifati hisobiga shakllangan."],
    ];
    side.forEach(([ic, t, d], i) => {
      const y = 3.5 + i * 1.55;
      card(s, 6.6, y, 6.03, 1.35);
      badge(s, 6.9, y + 0.32, 0.7, ic, { fill: INK });
      s.addText(t, {
        x: 7.8, y: y + 0.26, w: 4.6, h: 0.32, margin: 0,
        fontFace: HEAD, fontSize: 15, bold: true, color: WHITE,
      });
      p(s, d, { x: 7.8, y: y + 0.62, w: 4.6, h: 0.6, fontSize: 12, lineSpacing: 16 });
    });
    footer(s, 4);
    s.addNotes(
      "0:40–0:55 | YouTube kanali. Kamera 2.\n" +
      "Sarvar: Bugungi kunda Mergan Production YouTube kanalida 62 mingdan ortiq obunachi mavjud va kanalimizdagi kontent millionlab tomoshabinlarga yetib bormoqda.\n" +
      "Grafika: 62 400+ obunachi · YouTube Subscriber Counter."
    );
  }

  // =====================================================================
  // 5 — KO'RSATKICHLAR
  // =====================================================================
  {
    const s = newSlide();
    header(s, "04 · KO‘RSATKICHLAR", "Millionlab ko‘rishlar", 8);
    p(s, "Kanalimizdagi videolar millionlab ko‘rishlarga erishgan — auditoriyamiz faol hamda organik tarzda shakllangan.", {
      x: ML, y: 1.55, w: 8.6, h: 0.75, fontSize: 15, lineSpacing: 24,
    });

    const stats = [
      [I.eye, "3,6 mln+", "Eng yuqori ko‘rish", "Bitta videoning rekord natijasi"],
      [I.chart, "1 mln+", "Millionlik videolar", "Muntazam takrorlanadigan daraja"],
      [I.users, "200 ming+", "Barqaror ko‘rish", "Har bir yangi son uchun asos"],
    ];
    const cw = (CW - 2 * 0.3) / 3, ch = 3.4;
    stats.forEach(([ic, v, t, d], i) => {
      const x = ML + i * (cw + 0.3);
      const y = 2.7;
      card(s, x, y, cw, ch);
      badge(s, x + 0.38, y + 0.42, 0.8, ic, { fill: INK });
      s.addText(v, {
        x: x + 0.38, y: y + 1.55, w: cw - 0.76, h: 0.75, margin: 0,
        fontFace: HEAD, fontSize: 38, bold: true, color: WHITE,
      });
      s.addText(t, {
        x: x + 0.38, y: y + 2.35, w: cw - 0.76, h: 0.32, margin: 0,
        fontFace: HEAD, fontSize: 13.5, bold: true, color: GOLD,
      });
      p(s, d, { x: x + 0.38, y: y + 2.72, w: cw - 0.76, h: 0.45, fontSize: 12, lineSpacing: 16 });
    });
    footer(s, 5);
    s.addNotes(
      "0:55–1:15 | Statistika. Kamera 1.\n" +
      "Jalol: Kanalimizdagi videolar millionlab ko‘rishlarga erishgan va auditoriyamiz faol hamda organik tarzda shakllangan.\n" +
      "Grafika: 3,6 mln+ · 1 mln+ · 200 ming+."
    );
  }

  // =====================================================================
  // 6 — AUDITORIYA
  // =====================================================================
  {
    const s = newSlide();
    header(s, "05 · AUDITORIYA", "Kim tomosha qiladi?", 8);

    // gender card
    card(s, ML, 1.85, 5.0, 4.65, { fill: PANEL });
    s.addText("Jins bo‘yicha", {
      x: ML + 0.4, y: 2.15, w: 4.2, h: 0.32, margin: 0,
      fontFace: HEAD, fontSize: 14, bold: true, color: WHITE,
    });

    const g = [
      [I.mars, "Erkaklar", "83%", GOLD, 2.7],
      [I.venus, "Ayollar", "16%", RED, 4.15],
    ];
    g.forEach(([ic, name, val, col, y]) => {
      badge(s, ML + 0.4, y, 0.7, ic, { fill: INK });
      s.addText(name, {
        x: ML + 1.25, y: y + 0.06, w: 2.0, h: 0.32, margin: 0,
        fontFace: HEAD, fontSize: 15, bold: true, color: WHITE,
      });
      s.addText(val, {
        x: ML + 2.3, y: y - 0.04, w: 2.3, h: 0.5, margin: 0, align: "right",
        fontFace: HEAD, fontSize: 26, bold: true, color: col,
      });
      const track = 4.2;
      s.addShape(RR, { x: ML + 0.4, y: y + 0.82, w: track, h: 0.16, rectRadius: 0.08, fill: { color: PANEL2 }, line: { color: PANEL2, width: 0.5 } });
      s.addShape(RR, { x: ML + 0.4, y: y + 0.82, w: track * (parseInt(val) / 100), h: 0.16, rectRadius: 0.08, fill: { color: col }, line: { color: col, width: 0.5 } });
    });
    p(s, "Qolgan 1% — jinsi aniqlanmagan tomoshabinlar.", {
      x: ML + 0.4, y: 5.72, w: 4.2, h: 0.32, fontSize: 11, color: DIM, lineSpacing: 14,
    });

    // age chart card
    card(s, 6.1, 1.85, 6.53, 4.65, { fill: PANEL });
    s.addText("Yosh bo‘yicha taqsimot", {
      x: 6.5, y: 2.15, w: 5.7, h: 0.32, margin: 0,
      fontFace: HEAD, fontSize: 14, bold: true, color: WHITE,
    });
    s.addChart(
      pres.ChartType.bar,
      [{ name: "Ulush", labels: ["18–24", "25–34", "35–44"], values: [14, 31, 27] }],
      {
        x: 6.35, y: 2.6, w: 6.03, h: 3.15,
        barDir: "col", barGapWidthPct: 90,
        chartColors: [GOLD, GOLD, GOLD],
        chartArea: { fill: { color: PANEL } },
        plotArea: { fill: { color: PANEL } },
        showLegend: false,
        showTitle: false,
        showValue: true,
        dataLabelPosition: "outEnd",
        dataLabelColor: WHITE,
        dataLabelFontFace: HEAD,
        dataLabelFontSize: 13,
        dataLabelFontBold: true,
        dataLabelFormatCode: '0"%"',
        catAxisLabelColor: MUTED,
        catAxisLabelFontFace: BODY,
        catAxisLabelFontSize: 13,
        catAxisLineShow: false,
        catGridLine: { style: "none" },
        valAxisHidden: true,
        valGridLine: { style: "none" },
        valAxisMaxVal: 40,
      }
    );
    p(s, "Asosiy auditoriya — 25–44 yosh: to‘lovga qodir, faol iste’molchi qatlam.", {
      x: 6.5, y: 5.72, w: 5.8, h: 0.32, fontSize: 11.5, color: DIM, lineSpacing: 14,
    });
    footer(s, 6);
    s.addNotes(
      "0:55–1:15 | Statistika (davomi).\n" +
      "Auditoriya: erkaklar — 83%, ayollar — 16%.\n" +
      "Yosh: 18–24 — 14%, 25–34 — 31%, 35–44 — 27%."
    );
  }

  // =====================================================================
  // 7 — GEOGRAFIYA
  // =====================================================================
  {
    const s = newSlide();
    header(s, "06 · GEOGRAFIYA", "Auditoriya qayerdan tomosha qiladi?", 9.5);

    card(s, ML, 1.95, 6.1, 4.4, { fill: PANEL });
    s.addChart(
      pres.ChartType.doughnut,
      [{ name: "Davlatlar", labels: ["O‘zbekiston", "Rossiya", "Qirg‘iziston", "Boshqa davlatlar"], values: [72, 17, 2, 9] }],
      {
        x: ML + 0.25, y: 2.2, w: 5.6, h: 3.9,
        holeSize: 62,
        chartColors: [GOLD, RED, "5B8DEF", "8C8CA6"],
        chartArea: { fill: { color: PANEL } },
        plotArea: { fill: { color: PANEL } },
        showLegend: false,
        showTitle: false,
        showValue: true,
        dataLabelPosition: "bestFit",
        dataLabelColor: INK,
        dataLabelFontFace: HEAD,
        dataLabelFontSize: 12,
        dataLabelFontBold: true,
        dataLabelFormatCode: '0"%"',
      }
    );

    const geo = [
      ["O‘zbekiston", "72%", GOLD],
      ["Rossiya", "17%", RED],
      ["Qirg‘iziston", "2%", "5B8DEF"],
      ["Boshqa davlatlar", "9%", "8C8CA6"],
    ];
    card(s, 7.15, 1.95, 5.48, 4.4, { fill: PANEL });
    badge(s, 7.5, 2.3, 0.72, I.globe, { fill: INK });
    s.addText("Asosiy bozor — O‘zbekiston", {
      x: 8.4, y: 2.45, w: 3.9, h: 0.4, margin: 0,
      fontFace: HEAD, fontSize: 15, bold: true, color: WHITE,
    });
    geo.forEach(([name, val, col], i) => {
      const y = 3.45 + i * 0.68;
      s.addShape(OVAL, { x: 7.5, y: y + 0.1, w: 0.16, h: 0.16, fill: { color: col }, line: { color: col, width: 0.5 } });
      p(s, name, { x: 7.85, y, w: 3.0, h: 0.36, fontSize: 14, color: WHITE, lineSpacing: 18 });
      s.addText(val, {
        x: 10.6, y: y - 0.02, w: 1.7, h: 0.36, margin: 0, align: "right",
        fontFace: HEAD, fontSize: 16, bold: true, color: col === "8C8CA6" ? MUTED : col,
      });
      if (i < 3) s.addShape(RECT, { x: 7.5, y: y + 0.5, w: 4.8, h: 0.01, fill: { color: LINE }, line: { color: LINE, width: 0.5 } });
    });
    footer(s, 7);
    s.addNotes(
      "0:55–1:15 | Statistika (davomi).\n" +
      "Davlatlar: O‘zbekiston — 72%, Rossiya — 17%, Qirg‘iziston — 2%. Qolgan ulush — boshqa davlatlar."
    );
  }

  // =====================================================================
  // 8 — HAMKORLIK IMKONIYATLARI
  // =====================================================================
  {
    const s = newSlide();
    header(s, "07 · HAMKORLIK IMKONIYATLARI", "Brendingiz voqea ichida", 9.5);
    p(s, "Loyiha davomida homiy yoki hamkor brendi voqealar rivoji, studiya suhbati hamda sovg‘a topshirish jarayonida tabiiy tarzda namoyish etiladi.", {
      x: ML, y: 1.55, w: 9.4, h: 0.75, fontSize: 15, lineSpacing: 24,
    });

    const opts = [
      [I.box, "Product Placement", "Mahsulot voqea rivojining tabiiy qismiga aylanadi."],
      [I.copyright, "Logotip", "Brend logotipi video davomida va grafikada ko‘rinadi."],
      [I.mic, "Boshlovchi tavsiyasi", "Jalol va Sarvar tomonidan jonli, ishonchli tavsiya."],
      [I.couch, "Studio integratsiyasi", "Studiya suhbatida brend haqida alohida blok."],
      [I.gift, "Sovg‘a topshirish", "Mehmonlarga brend sovg‘alari efir davomida topshiriladi."],
    ];
    const cw = (CW - 2 * 0.3) / 3, ch = 1.95;
    opts.forEach(([ic, t, d], i) => {
      const x = ML + (i % 3) * (cw + 0.3);
      const y = 2.45 + Math.floor(i / 3) * (ch + 0.25);
      card(s, x, y, cw, ch);
      badge(s, x + 0.32, y + 0.26, 0.66, ic, { fill: INK });
      s.addText(t, {
        x: x + 0.32, y: y + 1.0, w: cw - 0.64, h: 0.3, margin: 0,
        fontFace: HEAD, fontSize: 15, bold: true, color: WHITE,
      });
      p(s, d, { x: x + 0.32, y: y + 1.32, w: cw - 0.64, h: 0.5, fontSize: 12, lineSpacing: 16 });
    });

    // accent 6th cell
    const x6 = ML + 2 * (cw + 0.3), y6 = 2.45 + (ch + 0.25);
    s.addShape(RR, { x: x6, y: y6, w: cw, h: ch, rectRadius: 0.1, fill: { color: RED }, line: { color: RED, width: 0.75 } });
    s.addText("Har bir son —\nyangi imkoniyat", {
      x: x6 + 0.32, y: y6 + 0.34, w: cw - 0.64, h: 0.85, margin: 0, valign: "top",
      fontFace: HEAD, fontSize: 19, bold: true, color: WHITE, lineSpacing: 26,
    });
    s.addText("Formatlar birgalikda ham qo‘llaniladi", {
      x: x6 + 0.32, y: y6 + 1.32, w: cw - 0.64, h: 0.4, margin: 0,
      fontFace: BODY, fontSize: 12, color: "FFE0E2", lineSpacing: 16,
    });
    footer(s, 8);
    s.addNotes(
      "1:15–1:35 | Hamkorlik imkoniyatlari. Kamera 2.\n" +
      "Sarvar: Loyiha davomida homiy yoki hamkor brendi voqealar rivoji, studiya suhbati hamda sovg‘a topshirish jarayonida tabiiy tarzda namoyish etiladi.\n" +
      "Grafika: Product Placement · Logo · Boshlovchi tavsiyasi · Studio integratsiyasi · Sovg‘a topshirish."
    );
  }

  // =====================================================================
  // 9 — QO'SHIMCHA QIYMAT
  // =====================================================================
  {
    const s = newSlide();
    header(s, "08 · QO‘SHIMCHA QIYMAT", "Kontentdan foydalanish huquqi", 9.5);
    p(s, "Homiy yoki hamkor mashhur mehmon bilan tayyorlangan foto va video materiallardan o‘zining reklama kampaniyalari hamda ijtimoiy tarmoqlarida foydalanish huquqiga ega bo‘ladi.", {
      x: ML, y: 1.95, w: 5.1, h: 1.75, fontSize: 15, lineSpacing: 26,
    });
    card(s, ML, 4.75, 5.1, 1.75, { fill: PANEL });
    badge(s, ML + 0.32, 5.08, 0.7, I.star, { fill: INK });
    s.addText("Yulduz bilan kontent — qo‘shimcha to‘lovsiz", {
      x: ML + 1.22, y: 5.08, w: 3.55, h: 0.7, margin: 0, valign: "top",
      fontFace: HEAD, fontSize: 14, bold: true, color: WHITE, lineSpacing: 20,
    });
    p(s, "Bir marta suratga olingan material — o‘nlab reklama nuqtasida ishlaydi.", {
      x: ML + 0.32, y: 5.85, w: 4.45, h: 0.5, fontSize: 12, lineSpacing: 16,
    });

    card(s, 6.2, 1.95, 6.43, 4.55, { fill: PANEL });
    s.addText("FOYDALANISH KANALLARI", {
      x: 6.55, y: 2.25, w: 5.7, h: 0.3, margin: 0,
      fontFace: HEAD, fontSize: 11, bold: true, color: GOLD, charSpacing: 2,
    });
    const chips = [
      [I.instagram, "Instagram"], [I.facebook, "Facebook"], [I.telegram, "Telegram"],
      [I.yt2, "YouTube"], [I.tiktok, "TikTok"], [I.desktop, "LED ekran"],
      [I.ad, "Billboard"],
    ];
    const chw = 1.78, chh = 0.95, gap = 0.2;
    chips.forEach(([ic, name], i) => {
      const x = 6.55 + (i % 3) * (chw + gap);
      const y = 2.75 + Math.floor(i / 3) * (chh + gap);
      s.addShape(RR, { x, y, w: chw, h: chh, rectRadius: 0.09, fill: { color: PANEL2 }, line: { color: LINE, width: 0.75 } });
      s.addImage({ data: ic, x: x + 0.2, y: y + 0.28, w: 0.4, h: 0.4 });
      p(s, name, { x: x + 0.68, y: y + 0.3, w: chw - 0.8, h: 0.36, fontSize: 11.5, color: WHITE, lineSpacing: 15 });
    });
    p(s, "Materiallar hamkorga tayyor holda taqdim etiladi.", {
      x: 6.55, y: 6.02, w: 5.7, h: 0.35, fontSize: 11.5, color: DIM, lineSpacing: 15,
    });
    footer(s, 9);
    s.addNotes(
      "1:35–1:50 | Qo‘shimcha qiymat. Kamera 1.\n" +
      "Jalol: Homiy yoki hamkor mashhur mehmon bilan tayyorlangan foto va video materiallardan o‘zining reklama kampaniyalari va ijtimoiy tarmoqlarida foydalanish huquqiga ega bo‘ladi.\n" +
      "Grafika: Instagram · Facebook · Telegram · YouTube · TikTok · LED ekranlar · Billboard."
    );
  }

  // =====================================================================
  // 10 — NIMA UCHUN BIZ
  // =====================================================================
  {
    const s = newSlide();
    header(s, "09 · NIMA UCHUN AYNAN SHU LOYIHA", "Uchta asosiy sabab", 9.5);
    const reasons = [
      ["01", "Faol va organik auditoriya", "62 400+ obunachi va millionlab ko‘rishlar sun’iy usullarsiz, kontent sifati hisobiga to‘plangan."],
      ["02", "Tabiiy integratsiya", "Brend reklama bloki emas, voqea rivojining qismi sifatida namoyon bo‘ladi — tomoshabin uni o‘tkazib yubormaydi."],
      ["03", "Barqaror chiqish grafigi", "Yiliga 48 ta original son — brend uchun uzluksiz va oldindan rejalashtiriladigan efir."],
    ];
    reasons.forEach(([n, t, d], i) => {
      const y = 1.95 + i * 1.6;
      card(s, ML, y, CW, 1.4);
      s.addText(n, {
        x: ML + 0.35, y: y + 0.34, w: 1.0, h: 0.7, margin: 0,
        fontFace: HEAD, fontSize: 30, bold: true, color: GOLD,
      });
      s.addText(t, {
        x: ML + 1.5, y: y + 0.3, w: 4.0, h: 0.7, margin: 0,
        fontFace: HEAD, fontSize: 17, bold: true, color: WHITE, lineSpacing: 22,
      });
      p(s, d, { x: ML + 5.7, y: y + 0.32, w: 5.5, h: 0.8, fontSize: 12.5, lineSpacing: 17 });
    });
    footer(s, 10);
    s.addNotes("Xulosaviy blok — homiy uchun asosiy argumentlar. Senariyning 1:50 dan oldingi qismida grafik tarzda ishlatilishi mumkin.");
  }

  // =====================================================================
  // 11 — CTA (accent)
  // =====================================================================
  {
    const s = newSlide(INK);
    s.addImage({
      path: "assets/banner.jpg",
      x: 0, y: 0, w: W, h: H,
      sizing: { type: "cover", w: W, h: H },
    });
    s.addShape(RECT, { x: 0, y: 0, w: W, h: H, fill: { color: INK, transparency: 16 }, line: { color: INK, width: 0.5 } });

    s.addText("TAKLIF", {
      x: 1.4, y: 1.75, w: 10.5, h: 0.32, margin: 0, align: "center",
      fontFace: HEAD, fontSize: 12, bold: true, color: GOLD, charSpacing: 3.5,
    });
    s.addText("Brendingizni millionlab tomoshabinlarga\nzamonaviy va tabiiy formatda taniting", {
      x: 1.4, y: 2.35, w: 10.5, h: 1.7, margin: 0, align: "center",
      fontFace: HEAD, fontSize: 34, bold: true, color: WHITE, lineSpacing: 44,
    });
    s.addText("Sizni «Shunaqasi ham bo‘p turadi» loyihasining rasmiy hamkori bo‘lishga taklif qilamiz.", {
      x: 1.0, y: 4.25, w: 11.33, h: 0.5, margin: 0, align: "center",
      fontFace: BODY, fontSize: 17, color: "F0F0F5",
    });
    s.addShape(RR, { x: 4.97, y: 5.15, w: 3.4, h: 0.8, rectRadius: 0.12, fill: { color: RED }, line: { color: RED, width: 0.75 } });
    s.addText("HAMKOR BO‘LISH", {
      x: 4.97, y: 5.34, w: 3.4, h: 0.42, margin: 0, align: "center",
      fontFace: HEAD, fontSize: 13, bold: true, color: WHITE, charSpacing: 2,
    });
    s.addNotes(
      "1:50–2:05 | Yakun. Kamera 1 + Kamera 2.\n" +
      "Sarvar: Agar siz ham brendingizni millionlab tomoshabinlarga zamonaviy va tabiiy formatda tanitishni istasangiz...\n" +
      "Jalol: Sizni «Shunaqasi ham bo‘p turadi» loyihasining rasmiy hamkori bo‘lishga taklif qilamiz."
    );
  }

  // =====================================================================
  // 12 — KONTAKT
  // =====================================================================
  {
    const s = newSlide();
    s.addShape(OVAL, { x: 8.9, y: -1.2, w: 6.2, h: 6.2, fill: { color: INK }, line: { color: "1E1E2A", width: 1 } });

    s.addImage({
      path: "assets/logo.jpg",
      x: ML, y: 1.5, w: 3.45, h: 3.45,
      sizing: { type: "cover", w: 3.45, h: 3.45 },
    });
    s.addText("MERGAN PRODUCTION", {
      x: ML, y: 5.2, w: 5.6, h: 0.32, margin: 0,
      fontFace: HEAD, fontSize: 12, bold: true, color: GOLD, charSpacing: 3,
    });
    p(s, "Hamkorlik shartlari va narxlar bo‘yicha to‘liq ma’lumot uchun biz bilan bog‘laning.", {
      x: ML, y: 5.6, w: 5.6, h: 0.85, fontSize: 14, lineSpacing: 22,
    });

    const contacts = [
      [I.phone, "Telefon", "+998 __ ___ __ __"],
      [I.telegram, "Telegram", "@ ____________"],
      [I.instagram, "Instagram", "@ ____________"],
      [I.youtube, "YouTube", "Mergan Production"],
    ];
    card(s, 7.05, 1.5, 5.58, 4.5, { fill: PANEL });
    contacts.forEach(([ic, label, val], i) => {
      const y = 1.9 + i * 1.05;
      badge(s, 7.4, y + 0.12, 0.66, ic, { fill: INK });
      s.addText(label, {
        x: 8.25, y: y + 0.08, w: 4.0, h: 0.28, margin: 0,
        fontFace: HEAD, fontSize: 10.5, bold: true, color: GOLD, charSpacing: 1.5,
      });
      p(s, val, { x: 8.25, y: y + 0.4, w: 4.0, h: 0.35, fontSize: 14, color: val.includes("_") ? MUTED : WHITE, lineSpacing: 18 });
      if (i < 3) s.addShape(RECT, { x: 7.4, y: y + 0.9, w: 4.88, h: 0.01, fill: { color: LINE }, line: { color: LINE, width: 0.5 } });
    });
    s.addText("MERGAN PRODUCTION", {
      x: ML, y: 6.86, w: 5, h: 0.3, margin: 0,
      fontFace: HEAD, fontSize: 9, bold: true, color: DIM, charSpacing: 1.5,
    });
    s.addNotes(
      "2:05–2:15 | Kontakt. Qora fon.\n" +
      "MERGAN PRODUCTION · SHUNAQASI HAM BO‘P TURADI\n" +
      "Telefon / Telegram / Instagram / YouTube — yakuniy logotip animatsiyasi.\n" +
      "ESLATMA: telefon raqami va akkaunt manzillarini yakuniy ma’lumot bilan almashtiring."
    );
  }

  await pres.writeFile({ fileName: "Shunaqasi_ham_bop_turadi_Kommersiya_taklifi.pptx" });
  console.log("OK");
}

main().catch((e) => { console.error(e); process.exit(1); });
