#let data = yaml("data.yaml")
#let me = data.people.me

// The commit the site is built from, passed in by the Nix build with
// `--input rev=...`. A build from a dirty tree passes `<rev>-dirty`. If it's
// unknown, this is `main`, which GitHub resolves to the latest commit on it.
#let rev = {
  let input = sys.inputs.at("rev", default: "")
  if input == "" {
    (full: "main", short: "main")
  } else {
    let full = input.trim("-dirty", at: end)
    let dirty = full != input
    (full: full, short: full.slice(0, 7) + if dirty { "-dirty" } else { "" })
  }
}

// Titles, abstracts and awards in data.yaml are Typst markup.
#let markup(s) = eval(s, mode: "markup")

// ---- Dates ------------------------------------------------------------------

#let parse-date(s) = if type(s) == datetime { s } else {
  let (y, m, d) = str(s).split("-").map(int)
  datetime(year: y, month: m, day: d)
}

#let fmt-date(d) = d.display("[day padding:none] [month repr:short] [year]")

// "8–12 Dec 2025", "28 Jul – 2 Aug 2025", or "20 Nov 2024".
#let fmt-range(start, end) = {
  let (s, e) = (parse-date(start), parse-date(end))
  if s == e {
    fmt-date(s)
  } else if s.year() != e.year() {
    [#fmt-date(s) – #fmt-date(e)]
  } else if s.month() != e.month() {
    [#s.display("[day padding:none] [month repr:short]") – #fmt-date(e)]
  } else {
    [#s.day()–#fmt-date(e)]
  }
}

// ---- Small pieces -----------------------------------------------------------

#let meta(body) = html.span(class: "meta", body)

#let person(id) = {
  let p = data.people.at(id)
  if "url" in p { link(p.url, p.name) } else { p.name }
}

// "with A, B and C", leaving myself out; `none` for sole-author papers.
#let coauthors(ids) = {
  let others = ids.filter(id => id != "me")
  if others.len() > 0 [with #others.map(person).join(", ", last: " and ")]
}

// The entry's award, or `none`.
#let award(entry) = if "award" in entry {
  html.span(class: "award", markup(entry.award))
}

// A row of small links, e.g. [arXiv] [slides], skipping missing ones; or
// `none` if all are missing.
#let links(..pairs) = {
  let items = pairs.pos().filter(((_, url)) => url != none)
  if items.len() > 0 {
    // Each link is wrapped so that CSS can bracket it without the brackets
    // being part of the link.
    html.span(
      class: "links",
      items.map(((name, url)) => html.span(link(url, name))).join[ ],
    )
  }
}

// The lines of an entry below its title, skipping those that are `none`.
#let lines(..lines) = lines.pos().filter(x => x != none).join(linebreak())

#let event-name(e) = if "url" in e { link(e.url, e.name) } else { e.name }

// A title that opens a dropdown below it, e.g. with an abstract.
#let title-dropdown(title, body) = html.details(class: "title", {
  html.summary(title)
  body
})

// A title on the left with a date on the right. With a body, the title is a
// dropdown that opens below this line; see `.head` in style.css.
#let head(title, date, body: none) = html.div(class: "head", {
  if body != none { title-dropdown(title, body) } else { html.span(title) }
  meta(date)
})

// ---- Sections ---------------------------------------------------------------

#let papers() = {
  let papers = data.papers.sorted(key: p => parse-date(p.arxiv.date)).rev()
  list(..papers.map(p => {
    let arxiv = p.arxiv
    // Unquoted, YAML reads 2510.10010 as the float 2510.1001.
    assert(
      type(arxiv.id) == str,
      message: "quote the arXiv id of \"" + p.title + "\" in data.yaml",
    )
    let date = parse-date(arxiv.date)
    head(markup(p.title), str(date.year()), body: if "abstract" in p {
      html.p(markup(p.abstract))
    })

    // Published papers: the venue, as written. Preprints: when they went on
    // arXiv, and their length.
    let publication = p.at("publication", default: none)
    let status = if publication != none { publication.venue } else [
      preprint (#date.display("[month repr:long] [year]")), #arxiv.pages pages
    ]
    lines(
      coauthors(p.authors),
      status,
      award(p),
      links(
        if publication != none {
          ("doi:" + publication.doi, "https://doi.org/" + publication.doi)
        } else { (none, none) },
        ("arXiv:" + arxiv.id, "https://arxiv.org/abs/" + arxiv.id),
        ("code", p.at("code", default: none)),
      ),
    )
  }))
}

#let talks() = {
  let talks = data.talks.sorted(key: t => parse-date(t.date)).rev()
  list(..talks.map(t => {
    let event = data.events.at(t.event)
    let kind = t.at("kind", default: "contributed")

    head(markup(t.title), fmt-date(parse-date(t.date)), body: if (
      "abstract" in t
    ) { html.p(markup(t.abstract)) })

    // Seminars: the seminar and its host. Conferences and workshops: the
    // event's short name, linking to it under Whereabouts, then the session
    // or the kind of talk.
    let event-line = if event.kind == "seminar" {
      event-name(event)
      if "host" in event [, #event.host]
    } else {
      link(label(t.event), event.at("short", default: event.name))
      if "session" in t [, #event.sessions.at(t.session).name session] else if (
        kind == "poster"
      ) [, poster] else [, #kind talk]
    }
    lines(
      event-line,
      award(t),
      links(
        ("slides", t.at("slides", default: none)),
        ("video", t.at("video", default: none)),
      ),
    )
  }))
}

#let events() = {
  let events = data
    .events
    .pairs()
    .filter(((_, e)) => e.kind != "seminar")
    .sorted(key: ((_, e)) => parse-date(e.start))
    .rev()
  list(..events.map(((id, e)) => {
    let name = {
      // Labelled so that talks can link here.
      [#html.span(event-name(e))#label(id)]
      let role = e.at("role", default: none)
      if role != none [ #html.span(class: "tag", role)]
    }
    head(name, fmt-range(e.start, e.end))
    lines(
      (e.at("host", default: none), e.location)
        .filter(x => x != none)
        .join(", "),
      award(e),
    )
  }))
}

// ---- Page -------------------------------------------------------------------

#asset("favicon.png", read("favicon.png", encoding: none))
#for file in (
  "LatoLatin-Regular.woff2",
  "LatoLatin-Italic.woff2",
  "LatoLatin-Bold.woff2",
  "LatoLatin-BoldItalic.woff2",
  "LeteSansMath.woff2",
) {
  asset("fonts/" + file, read("fonts/" + file, encoding: none))
}

#document("index.html", title: me.name, html.html(lang: "en", {
  html.head({
    html.meta(charset: "utf-8")
    html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
    html.title(me.name)
    html.style(read("styles.css"))
    html.link(rel: "icon", type: "image/png", href: "favicon.png")
  })
  html.body({
    html.header({
      title()
      html.nav(list(
        link("mailto:" + me.email)[email],
        ..me.links.map(l => link(l.url, l.name)),
      ))
    })

    html.main[
      I'm an undergraduate student studying pure mathematics and computing at the University of Melbourne.
      My interests are in number theory, currently isogeny graphs.
      I also contribute to open source software, in particular #link("https://github.com/typst/typst")[Typst].

      = Papers <papers>
      #papers()

      = Talks <talks>
      #talks()

      = Whereabouts <whereabouts>
      #events()
    ]

    html.footer({
      let url = "https://github.com/mkorje/me/commit/" + rev.full
      [Last updated #fmt-date(datetime.today()) (#link(url, rev.short)).]
    })
  })
}))
