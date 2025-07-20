export const HELP = {
  name: {
    title: "Domain-Name",
    desc:  [
      "Dies ist die Domain, unter der diese Ökosystem-/Satelliten-Seite erreicht werden soll. Hier einfach nur eine Domain einzutragen reicht allerdings nicht aus. Bevor diese Satelliten-Seite benutzt werden kann, muss die Domain ggf. erst noch registriert werden. Auf jeden Fall sind Änderungen an der Serverkonfiguration notwendig, die nur der Support durchführen kann.",
      "Die Default-Domain stellt einen Spezialfall dar: hier kann der Name (aus offensichtlichen Gründen) nicht bearbeitet werden.",
    ],
  },
  brand_name: {
    title: "Branding",
    desc:  [
      "An verschiedenen Stellen auf der Webseite kann kein ordentlicher Seitentitel generiert werden. In solchen Fällen wird auf diesen Wert zurückgegriffen.",
      "Beispiele hierfür sind das Anlegen von «App-Shortcuts» oder auch die Ökosystem-Verlinkung.",
    ],
  },
  theme: {
    title: "Farb-Schema",
    desc:  [
      "Das äussere Erscheinungsbild der Webseite wird im Wesentlichen durch diese Einstellung beinflusst. Derzeit stehen ein paar wenige Farben zur Verfügung. Der Support kann bei Bedarf aber weitere Schemata erstellen.",
    ],
  },
  partials: {
    title: "Inhalte",
    desc:  [
      "Die Startseite ist in Abschnitte unterteilt. Welche Inhalte angezeigt werden, wird durch den Schalter auf der linken Seite bestimmt, die Reihenfolge kann durch die Schaltflächen mit den Pfeilen beeinflusst werden",
    ],
  },
  slides: {
    title: "Slider-Bilder",
    desc:  [
      "Dies sind die Bilder, die auf der Startseite rolliert werden. Um die Ladezeit kurz zu halten, werden beim Laden bis zu drei Bilder zufällig ausgewählt, die tatsächlich angezeigt werden.",
      "Mit dem Schalter auf der linken Seite kann bestimmt werden, welche Bilder (und welche nicht) angezeigt werden sollen.",
    ],
  },
  content: {
    html:  true,
    title: "SEO-Text",
    desc:  [
      "Dieser Text erscheint auf der Homepage.",
      "Zur Formatierung können sowohl HTML als Markdown verwendet werden. Markdown ist eine einfache, Text-basierte Auszeichnungssprache. Beispiele:",
      "&bull; Eine Leerzeile (zwei mal <code>Enter</code>) erzeugt einen Absatz.",
      "&bull; Mit der Raute am Anfang einer Zeile wird die Zeile zu einer Überschift; <code>#</code> ergibt eine Überschrift erster Ordnung, <code>######</code> ergibt eine Überschrift sechster Ordnung.",
      "&bull; Aus <code>*text*</code> wird <em>text</em> (kursiv).",
      "&bull; Aus <code>**text**</code> wird <strong>text</strong> (fett).",
      "&bull; Links werden mit <code>[text](url)</code> eingefügt, z.B. <code class='nowrap'>[Yahoo!](https://google.com)</code> ergibt <a href='https://google.com' target='_blank'>Yahoo!</a>",
      "Einige HTML-Elemente (u.a. <code>&lt;script&gt;</code>, <code>&lt;iframe&gt;</code>) werden aus Sicherheitsgründen herausgefiltert.",
      "Die konkrete Markdown-Implementierung ist <em>kramdown</em>, und es stehen weitere Formatierungsmöglichkeiten zur Verfügung. Die vollständige Dokumentation kann <a href='https://kramdown.gettalong.org/quickref.html' target='_blank'>hier nachgeschlagen</a> werden.",
    ],
  },
  pages: {
    title: "Unterseiten",
    desc:  [
      "Diese Unterseiten sind global im System angelegt und können für diese Domain verfügbar gemacht werden.",
      "Einige Unterseiten sind allerdings bestimmten Domains vorbehalten und sollten nicht anderweitig wiederverwendet werden.",
    ],
  },
}

export const PARTIAL_INFO = {
  buttons_villas_specials: {
    title: "Button/Link-Zeile",
    desc:  "Links zu allen Villen und den Last-Minute-Angeboten",
  },
  goto_intervillas: {
    title: "Hinweis-Banner",
    desc:  "Seite stellt nicht das Gesamtangebot dar, Link zu intervillas-florida.com",
  },
  last_minute: {
    title: "Angebote",
    desc:  "bis zu drei Teaser-Villen aus dem Pool der Last-Minute-Angebote",
  },
  page_heading: {
    title: "Überschrift",
    desc:  "Zeile mit Seiten-Überschrift",
  },
  promo_video: {
    title: "Promo-Video",
    desc:  "Eingebettetes YouTube-Video",
  },
  seo_block: {
    title: "SEO-Text-Block",
    desc:  "Block mit Text für Ökosystem-/Satellitenseiten",
  },
  testimonials: {
    title: "Kundenbewertungen",
    desc:  "Slider mit zwei zufälligen Kundenbewertungen",
  },
  usp: {
    title: "Unique-Selling-Points",
    desc:  "Text-Schnippsel zu Kunden, Villen, Administration und Betreuung",
  },
}

export const DETAIL_BITS = {
  name:             { label: "Domain-Name", help: true, split: [3, 6] },
  tracking_code:    { label: "Tracking-Code", split: [3, 6] },
  brand_name:       { label: "Branding", help: true, split: [3, 6] },
  theme:            { label: "Farb-Schema", help: true, split: [3, 6] },
  multilingual:     { label: false, split: [3, 6] },
  interlink:        { label: false, split: [3, 6] },
  partials:         { label: "Inhalte", help: true, split: [3, 6] },
  slides:           { label: "Slider-Bilder", help: true },
  content:          { label: "SEO-Text", help: true },
  pages:            { label: "Unterseiten", help: true },
  villas:           { label: "Villen" },
  boats:            { label: "Boote" },
  meta_description: { label: "Meta-Beschreibung" },
  html_title:       { label: "HTML-Titel" },
  page_heading:     { label: "Überschrift" },
}
