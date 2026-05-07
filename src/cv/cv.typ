// Paged (PDF) CV. Pulls shared data from /data so the paper list stays
// in sync with the website. Styling is intentionally minimal — plug in
// your own template later.

#import "/lib/data.typ": profile, papers, experience, education, daterange

#let p = profile()

#set page(paper: "a4", margin: 2cm)
#set text(size: 10pt)
#set par(justify: true)

#align(center)[
  #text(size: 18pt, weight: "bold", p.name)

  #p.email · #link(p.website)[#p.website] · #link(p.github)[github]

  #if "tagline" in p [ #emph(p.tagline) ]
]

= Education
#for e in education() [
  *#e.degree*, #e.org #h(1fr) #daterange(e.start, end: e.at("end", default: none)) \
  #if "thesis" in e [ Thesis: #emph(e.thesis) ]
  #if "supervisor" in e [ · Supervisor: #e.supervisor ]
]

= Experience
#for x in experience() [
  *#x.role*, #x.org #h(1fr) #daterange(x.start, end: x.at("end", default: none)) \
  #if "location" in x [ #x.location \ ]
  #if "bullets" in x [
    #list(..x.bullets)
  ]
]

= Publications
#for q in papers() [
  - #emph(q.title), #q.authors, #q.year.#if "venue" in q [ #q.venue.]
]
