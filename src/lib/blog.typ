// Loads the blog post manifest. Typst has no directory listing, so every
// post must be registered in blog/posts.toml. See that file for the schema.
#let load-posts() = {
  let raw = toml("/blog/posts.toml").posts
  raw.sorted(key: p => p.date).rev()
}

// Renders a blog index: a list of posts, date + title.
// No heading — layout supplies <h1> from the document title.
//
// Links are same-directory relative (e.g. `hello.html`), not absolute
// (`/blog/hello.html`), so the site works when opened over `file://` too.
#let blog-index() = {
  let posts = load-posts()
  for post in posts [
    / #post.date: #link(post.slug + ".html")[#post.title]
    #if "summary" in post [

      #post.summary
    ]
  ]
}

// Minimal RSS 2.0 feed. Bytes-encoded for `#asset`.
// RSS requires absolute URLs, so this is one of the few places where
// site.toml's `url` field is actually consulted.
#let xml-escape(s) = {
  s.replace("&", "&amp;")
   .replace("<", "&lt;")
   .replace(">", "&gt;")
   .replace("\"", "&quot;")
}

#let rfc822(date) = {
  // Expects `date` as ISO "YYYY-MM-DD". Time is midnight UTC.
  let d = datetime(
    year: int(date.slice(0, 4)),
    month: int(date.slice(5, 7)),
    day: int(date.slice(8, 10)),
  )
  d.display("[weekday repr:short], [day] [month repr:short] [year] 00:00:00 +0000")
}

#let build-feed() = {
  let cfg = toml("/site.toml")
  let posts = load-posts()
  let now = datetime.today().display(
    "[weekday repr:short], [day] [month repr:short] [year] 00:00:00 +0000"
  )
  let items = posts.map(p => {
    let url = cfg.url + "/blog/" + p.slug + ".html"
    let desc = if "summary" in p {
      "      <description>" + xml-escape(p.summary) + "</description>\n"
    } else { "" }
    (
      "    <item>\n"
        + "      <title>" + xml-escape(p.title) + "</title>\n"
        + "      <link>" + url + "</link>\n"
        + "      <guid isPermaLink=\"true\">" + url + "</guid>\n"
        + "      <pubDate>" + rfc822(p.date) + "</pubDate>\n"
        + desc
        + "    </item>"
    )
  }).join("\n")

  (
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      + "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n"
      + "  <channel>\n"
      + "    <title>" + xml-escape(cfg.name) + "</title>\n"
      + "    <link>" + cfg.url + "/</link>\n"
      + "    <atom:link href=\"" + cfg.url + "/feed.xml\" rel=\"self\" type=\"application/rss+xml\"/>\n"
      + "    <description>" + xml-escape(cfg.description) + "</description>\n"
      + "    <language>en</language>\n"
      + "    <lastBuildDate>" + now + "</lastBuildDate>\n"
      + items + "\n"
      + "  </channel>\n"
      + "</rss>\n"
  )
}

#let feed-bytes() = bytes(build-feed())
