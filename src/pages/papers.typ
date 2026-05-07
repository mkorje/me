#import "/lib/data.typ": papers

#for p in papers() [
  - #emph(p.title), #p.authors, #p.year.#{
    let xs = ()
    if "url"    in p { xs.push(link(p.url)[preprint]) }
    if "code"   in p { xs.push(link(p.code)[code]) }
    if "slides" in p { xs.push(link(p.slides)[slides]) }
    if xs.len() > 0 [ #xs.join([ · ])]
  }
]
