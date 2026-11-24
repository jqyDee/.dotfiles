#let defaultStyling(body, heading_pagebreak: true) = {
  show math.equation: set text(weight: 400)

  set page(margin: 1in, numbering: "1", number-align: center)
  set text(font: "New Computer Modern")
  show raw: set text(font: "New Computer Modern Mono")
  show heading: set block(above: 1.4em, below: 1em)

  show heading.where(level: 1): it => {
    let pg = counter(page).at(it.location()).first()

    if heading_pagebreak and pg > 1 {
      pagebreak(weak: true)
    }

    it
  }

  set heading(numbering: none)

  set par(leading: 0.75em, spacing: 1.50em, first-line-indent: 0em, justify: true)

  set enum(indent: 2em, numbering: "(a)", spacing: 1.3em)
  set list(indent: 2em, spacing: 1.3em)

  show raw.where(block: false): box.with(
    fill: luma(225),
    inset: (x: 2pt, y: 2pt),
    // outset: (x: 2pt, y: 2pt),
    radius: 3pt,
    stroke: (0.5pt + luma(190)),
    baseline: 17%
  )

  show raw.where(block: true): it => {
    // Extract the language, defaulting to none if not specified
    let lang = if it.has("lang") { it.lang } else { none }
    
    box(
      width: 100%,
      fill: luma(225),
      // Switch from 'outset' to 'inset' so the padding is inside the box.
      // This ensures the label sits nicely inside the gray background.
      inset: 4pt,
      radius: 3pt,
      stroke: (0.5pt + luma(190)),
      {
        // Place the language label at the Top Right
        if lang != none {
          place(
            top + right, 
            box(
              fill: luma(125),
              inset: 3pt, 
              radius: 3pt,
              stroke: (0.5pt + luma(190)),
              text(fill: luma(255), size: 8pt, weight: "bold", lang)
            )
          )
        }
        
        // Display the actual code
        it
      }
    )
  }
  set table(stroke: 0.5pt)
  set table.vline(stroke: 0.5pt)
  set table.hline(stroke: 0.5pt)

  body
}

#let generic(
  date: none,
  title: none,
  subtitle: none,
  title_extra: none,
  heading_pagebreak: true,
  body
) = {
  let author = "Matti Fischbach"
  let email = "matti.fischbach@web.de"
  let title = title + " " + title_extra

  set document(author: author, title: title)

  show: defaultStyling.with(
    heading_pagebreak: heading_pagebreak
  )

  // Title row.
  align(center)[
    #block(text(weight: 500, 1.55em, title))
    #block(text(weight: 500, 1em, subtitle))
    #v(1em, weak: true)
    #date
  ]

  // Author information.
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: 1fr,
      gutter: 1em,
      align(center)[
        #author \
        #email
      ]
    ),
  )

  body
}

#let badge(content) = {
  box(
    fill: luma(250),
    inset: 3pt, 
    radius: 3pt,
    stroke: (0.5pt + luma(190)),
    smallcaps(text(content, weight: "bold"))
  )
}

#let question(title: none, body) = {
  let header = []
  if title != none {
    header = [#title]
  }

  block(
    fill: luma(255),
    stroke: (0.5pt + luma(180)),
    inset: 6pt,
    radius: 4pt,
    width: 100%,
    {
      grid(
        column-gutter: 2%,
        columns: (80%, 18%),
        align: (left, right),
        [
          #text(header, weight: 700)
        ],
        [
          #badge("Question")
        ]
      )
      v(0.25em) // Spacing between header and body
      line(length: 100%, stroke: (0.5pt + luma(180)))
      body
    }
  )
  v(0.5em)
}

// 2. ANSWER: Text with floating badge in top-right
#let answer(title: none, body) = {
  let header = []
  if title != none {
    header = [#title]
  }

  block(
    stroke: (left: 0.5pt + luma(180)), // Thick left border
    inset: (left: 1em), // text padding away from border
    width: 100%,
    {
      grid(
        column-gutter: 2%,
        columns: (80%, 18%),
        align: (left, right),
        [
          #text(header, weight: 700)
        ],
        [
          #badge("Answer")
        ]
      )
      v(0.25em) // Spacing between header and body
      body
    }
  )
  v(0.5em)
}

// 3. PROOF: Text with floating badge + QED at bottom
#let proof(title: none, body) = {
  let header = []
  if title != none {
    header = [#title]
  }

  block(
    stroke: (left: 0.5pt + luma(180)), // Thick left border
    inset: (left: 1em), // text padding away from border
    width: 100%,
    {
      grid(
        column-gutter: 2%,
        columns: (80%, 18%),
        align: (left, right),
        [
          #text(weight: "bold", header)
        ],
        [
          #badge("Proof")
        ]
      )
      v(0.25em) // Spacing between header and body
      body

      // QED Symbol (flushed right)
      h(1fr) 
      $square$ 
    }
  )
  v(0.5em)
}

#let _fc = counter("fitch")

// `label` is an optional name shown before the formula (e.g. for referencing
// lines by name). Pass any content, e.g. ln($phi$, [...], label: [A]).
#let ln(formula, just, num: auto, label: none) = ((type: "line", formula: formula, just: just, num: num, label: label),)
#let subproof(..body) = ((type: "subproof", children: body.pos().flatten()),)

// Flatten to rows, recording which subproof levels start/end at each row
#let _flatten(items, depth) = {
  let result = ()
  for item in items {
    if item.at("type") == "line" {
      result.push((formula: item.formula, just: item.just, num: item.num, label: item.label, depth: depth,
                   starts: (), ends: ()))
    } else {
      let inner = _flatten(item.children, depth + 1)
      let n = inner.len()
      if n > 0 {
        let first = inner.first()
        let last  = inner.last()
        if n == 1 {
          result.push((formula: first.formula, just: first.just, num: first.num, label: first.label, depth: first.depth,
                       starts: first.starts + (depth + 1,),
                       ends:   first.ends   + (depth + 1,)))
        } else {
          result.push((formula: first.formula, just: first.just, num: first.num, label: first.label, depth: first.depth,
                       starts: first.starts + (depth + 1,), ends: first.ends))
          for j in range(1, n - 1) { result.push(inner.at(j)) }
          result.push((formula: last.formula, just: last.just, num: last.num, label: last.label, depth: last.depth,
                       starts: last.starts, ends: last.ends + (depth + 1,)))
        }
      }
    }
  }
  result
}

#let _s(cond) = if cond { 0.7pt } else { none }

#let fitch(..body, inset-y: 6pt) = {
  _fc.update(0)
  let rows  = _flatten(body.pos().flatten(), 0)
  let max-d = rows.fold(0, (m, r) => calc.max(m, r.depth))
  let bar-w = 8pt

  let cells = ()
  for (i, row) in rows.enumerate() {
    let d      = row.depth
    let starts = row.starts
    let ends   = row.ends

    if i > 0 {
      let prev = rows.at(i - 1)
      let needs-spacer = prev.depth == d and prev.ends.contains(d) and starts.contains(d)

      if needs-spacer {
        for l in range(1, max-d + 1) {
          let active = prev.depth >= l and d >= l and not prev.ends.contains(l) and not starts.contains(l)
          cells.push(table.cell(
            inset: 0pt, 
            stroke: (left: _s(active), right: none, top: none, bottom: none), 
            []
          ))
        }

        let gap = box(height: 4pt)
        cells.push(table.cell(stroke: none, inset: 0pt, gap))
        cells.push(table.cell(stroke: none, inset: 0pt, gap))
        cells.push(table.cell(stroke: none, inset: 0pt, gap))
        cells.push(table.cell(stroke: none, inset: 0pt, gap))

        for l in range(max-d, 0, step: -1) {
          let active = prev.depth >= l and d >= l and not prev.ends.contains(l) and not starts.contains(l)
          cells.push(table.cell(
            inset: 0pt, 
            stroke: (left: none, right: _s(active), top: none, bottom: none), 
            []
          ))
        }
      }
    }

    // Top/bottom strokes for formula+just: only when the innermost box starts/ends here
    let f-top = _s(starts.contains(d) and d > 0)
    let f-bot = _s(ends.contains(d)   and d > 0)

    // One narrow bar column per nesting level
    for l in range(1, max-d + 1) {
      let a = d >= l
      cells.push(table.cell(
        inset: 0pt,
        stroke: (
          left:   _s(a),
          right:  none,
          top:    if a { _s(a and starts.contains(l)) } else { f-top },
          bottom: if a { _s(a and ends.contains(l)) } else { f-bot },
        ),
        []
      ))
    }

    // Line number
    let line-content = if row.num != auto {
      row.num
    } else {
      [#_fc.step()#context _fc.display().]
    }
    
    cells.push(table.cell(
      stroke: (left: none, right: none, top: f-top, bottom: f-bot),
      inset: (left: 0pt, right: 5pt, top: 4pt, bottom: 4pt),
      line-content
    ))

    // Label column (optional, sits between line number and formula)
    cells.push(table.cell(
      stroke: (left: none, right: none, top: f-top, bottom: f-bot),
      inset: (left: 5pt, right: 5pt, top: 4pt, bottom: 4pt),
      if row.label != none { text(row.label, style: "italic") } else { [] }
    ))

    // Formula
    cells.push(table.cell(
      stroke: (left: none, right: none, top: f-top, bottom: f-bot),
      inset: (left: 35pt, right: 35pt, top: 4pt, bottom: 4pt),
      row.formula
    ))

    // Justification — carries the right border of the box
    cells.push(table.cell(
      stroke: (left: none, right: none, top: f-top, bottom: f-bot),
      row.just
    ))
    // Right bar columns (innermost → outermost, so level max-d first)
      for l in range(max-d, 0, step: -1) {
        let active = d >= l
        cells.push(table.cell(
          inset: 0pt,
          stroke: (
            left:   none,
            right:  _s(active),
            top:    if active { _s(starts.contains(l)) } else { f-top },
            bottom: if active { _s(ends.contains(l)) } else { f-bot },
          ),
          []
        ))
      }
  }

  // Update the columns definition:
  let cols = (range(max-d).map(_ => bar-w)
    + (auto, 0pt, 1fr, auto)
    + range(max-d).map(_ => bar-w))

    align(center,
      table(
        columns: cols,
        align: left,
        stroke: none,
        column-gutter: 0pt,
        row-gutter: 0pt,
        inset: (x: 5pt, y: inset-y),
        ..cells
    ))
}

