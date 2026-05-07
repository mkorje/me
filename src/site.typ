// Entry point. Emits every HTML page and every asset in the site.
//
// Build: `typst compile --format bundle site.typ build`
// Watch: `typst watch --format bundle site.typ build`
// (The dev shell exports TYPST_FEATURES=bundle,html so you don't need
// to pass `--features` manually.)

#import "/lib/layout.typ": page
#import "/lib/blog.typ": blog-index, feed-bytes

// Nothing is imported from /site.toml here — it's loaded on demand by
// layout.typ and blog.typ. Keeping config access local to the files that
// actually need it avoids pulling everything through this entry file.

// --- static pages -----------------------------------------------------

#document("index.html", title: [home])[
  #page[
    #include "/pages/index.typ"
  ]
] <home>

#document("papers.html", title: [papers])[
  #page[
    #include "/pages/papers.typ"
  ]
] <papers>

#document("links.html", title: [links])[
  #page[
    #include "/pages/links.typ"
  ]
] <links>

// --- blog -------------------------------------------------------------

// `depth: 1` tells the layout that this page lives one level below the
// site root, so stylesheet/feed hrefs are rewritten as `../style.css`
// instead of `style.css`. Lets the site work over file:// too.
#document("blog/index.html", title: [blog])[
  #page(depth: 1)[
    #blog-index()
  ]
] <blog>

#let posts = toml("/blog/posts.toml").posts
#for post in posts {
  document(
    "blog/" + post.slug + ".html",
    title: [#post.title],
  )[
    #page(depth: 1)[
      #include "/blog/posts/" + post.file
    ]
  ]
}

// --- CV ---------------------------------------------------------------

// The bundle exporter emits a PDF for any #document whose path ends in
// .pdf, so the same `typst compile` produces cv.pdf alongside the HTML
// pages. The CV pulls from /data/*.toml, shared with pages/papers.typ.
#document("cv.pdf", title: [CV])[
  #include "/cv/cv.typ"
]

// --- assets -----------------------------------------------------------

#asset("style.css", read("/assets/style.css", encoding: none))
#asset("feed.xml", feed-bytes())
