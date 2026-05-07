// Thin loaders over the TOML data files in /data. Both the site and the
// CV pull from these, so formatting decisions (e.g. sort order) live in
// one place.

#let profile() = toml("/data/profile.toml")

// Papers sorted newest-first. Entries keep their schema keys as-is; the
// caller decides what to render.
#let papers() = toml("/data/papers.toml").papers.sorted(key: p => p.year).rev()

// Experience / education come back in the order they appear in the TOML
// — TOML arrays preserve insertion order, so the author controls the
// display order by editing the file.
#let experience() = toml("/data/experience.toml").experience
#let education()  = toml("/data/education.toml").education

// Format a start/end date range. Omits end for "present"-style entries.
#let daterange(start, end: none) = if end == none {
  start + " — present"
} else {
  start + " — " + end
}
