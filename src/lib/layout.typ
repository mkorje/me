// The nav lives here (not in site.toml) because each entry references a
// Typst label on a document, and labels aren't serialisable to TOML.
#let NAV = (
  (label: <home>,   name: "home"),
  (label: <papers>, name: "papers"),
  (label: <links>,  name: "links"),
  (label: <blog>,   name: "blog"),
)

// Wraps page content in a full <html> document so we can control <head>.
// When we emit our own <html> element, Typst skips its default wrapping —
// so charset/viewport/title have to go in by hand.
//
// `depth` is how many directory levels deep the current page lives (0 for
// site root, 1 for /blog/*, etc.). It's used to build relative paths to
// top-level assets (style.css, feed.xml) so the site works both over an
// HTTP server and when opened directly via file://. Nav links go through
// Typst labels — Typst resolves those to relative paths automatically, so
// they don't care about depth.
//
// Use as:
//   #document("blog/hello.html", title: [...])[
//     #page(depth: 1)[ body... ]
//   ]
#let page(body, depth: 0) = context {
  let cfg = toml("/site.toml")
  let title = document.title
  let description = document.description
  let up = "../" * depth

  let head = {
    html.elem("meta", attrs: (charset: "utf-8"))
    html.elem("meta", attrs: (
      name: "viewport",
      content: "width=device-width, initial-scale=1",
    ))
    if title == none {
      html.elem("title", cfg.name)
    } else {
      html.elem("title", cfg.name + " — " + title.text)
    }
    if description != none {
      html.elem("meta", attrs: (name: "description", content: description))
    }
    html.elem("link", attrs: (rel: "stylesheet", href: up + "style.css"))
    html.elem("link", attrs: (
      rel: "alternate",
      type: "application/rss+xml",
      title: cfg.name + " blog",
      href: up + "feed.xml",
    ))
  }

  let nav = html.elem("nav", {
    NAV.enumerate().map(((i, item)) => {
      let sep = if i > 0 { " · " } else { "" }
      sep + link(item.label, item.name)
    }).sum(default: [])
  })

  let header = html.elem("header", nav)

  let main = html.elem("main", {
    if title != none {
      html.elem("h1", title)
    }
    body
  })

  let footer = html.elem("footer",
    "© " + str(datetime.today().year()) + " " + cfg.name
  )

  html.elem("html", attrs: (lang: "en"), {
    html.elem("head", head)
    html.elem("body", {
      header
      main
      footer
    })
  })
}
