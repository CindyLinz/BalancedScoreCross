esc-html = (str) ->
  str
    .replace(/&/g, '&amps;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

update-view = !->
  labels =
    for label in document.query-selector-all '#config tr:first-of-type input'
      label.value
  divs = document.query-selector-all '#view div'
  for div,i in divs
    div.innerHTML = esc-html labels[i]

  pivots =
    for input in document.query-selector-all '#config input[type=number]'
      +input.value

  colors =
    for input in document.query-selector-all('#config .jscolor')
      \# + input.value
  colors.reverse!

  scores =
    for input in document.query-selector-all '#view input'
      +input.value

  canvas = document.query-selector \canvas

  draw-canvas canvas, pivots, colors, scores

draw-canvas = (canvas, pivots, colors, scores) !->
  ctx = canvas.get-context \2d

  padding =
    left: 0
    top: 20
    right: 0
    bottom: 20

  for i from 0 til 5
    m = ctx.measure-text pivots[4*i + 1]
    padding.left >?= m.width
    m = ctx.measure-text pivots[4*i + 2]
    padding.right >?= m.width
  padding.left += 10
  padding.right += 10

  w = h = 400

  scores-pos = []
  :next-pos for i from 0 til 4
    if scores[i] >= pivots[i]
      scores-pos[i] = 0
      continue next-pos
    for j from 1 til 5
      if scores[i] >= pivots[4*j + i]
        scores-pos[i] = (j - 1 + (scores[i] - pivots[4*j - 4 + i]) / (pivots[4*j + i] - pivots[4*j - 4 + i])) / 4
        continue next-pos
    scores-pos[i] = 1

  canvas.width = w + padding.left + padding.right
  canvas.height = h + padding.top + padding.bottom
  ctx.font = \16px
  ctx.text-align = \center
  ctx.text-baseline = \middle

  ctx.fill-style = \#000
  for i from 0 til 5
    ctx.fill-text pivots[4*i], padding.left + w/4 * i, padding.top/2
    ctx.fill-text pivots[4*i+1], padding.left/2, padding.top + h/4 * i
    ctx.fill-text pivots[4*i+2], padding.left + w + padding.right/2, padding.top + h/4 * i
    ctx.fill-text pivots[4*i+3], padding.left + w/4 * i, padding.top + h + padding.bottom/2

  for color,i in colors
    ctx.fill-style = color
    ctx.fill-rect padding.left, padding.top, w/4 * (4 - i), h/4 * (4 - i)

  ctx.stroke-style = \#000
  ctx.line-width = 1

  ctx.move-to padding.left + scores-pos[0] * w, padding.top
  ctx.line-to padding.left + scores-pos[3] * w, padding.top + h
  ctx.stroke!

  ctx.move-to padding.left, padding.top + scores-pos[1] * h
  ctx.line-to padding.left + w, padding.top + scores-pos[2] * h
  ctx.stroke!

document.query-selector(\#bulk_file).onchange = (ev) !->
  if @files.0?
    reader = new FileReader
    reader.read-as-array-buffer that
    reader.onload = (rev) !->
      try
        archive = new JSZip rev.target.result
        shared-strings =
          for t in new DOM-parser!parse-from-string(archive.file('xl/sharedStrings.xml').asText!, 'text/xml').query-selector-all(\t)
            t.innerHTML
        sheet = new DOM-parser!parse-from-string archive.file('xl/worksheets/sheet1.xml').asText!, 'text/xml'
      catch e
        alert "檔案有問題 #e"
        return
      #console.warn shared-strings

      bulk-board = document.query-selector(\#bulk_board)
        ..innerHTML = ''

      pivots =
        for input in document.query-selector-all '#config input[type=number]'
          +input.value

      colors =
        for input in document.query-selector-all('#config .jscolor')
          \# + input.value
      colors.reverse!

      labels =
        for label in document.query-selector-all '#config tr:first-of-type input'
          label.value

      for row in sheet.query-selector-all \row
        cols =
          for c in row.query-selector-all \c
            type = c.get-attribute(\t)
            value = c.query-selector(\v).innerHTML
            if type == \s
              value = shared-strings[value.|.0]
            value
        console.warn cols

        if cols.length < 5
          continue

        row-board = document.create-element \div
          ..innerHTML = """
            <hr style=page-break-before:always>
            <h3 align=center>#{esc-html cols.0}</h3>
            <table align=center>
                <tr align=center>
                    <td><td><div></div><td>
                <tr align=center>
                    <td><div></div>
                    <td><canvas width=400 height=400>
                        </canvas>
                    <td><div></div>
                <tr align=center>
                    <td><td><div></div><td>
            </table>
          """
          bulk-board.append-child ..

        scores =
          for c in cols[1 to 4]
            +c

        divs = row-board.query-selector-all 'div'
        for div,i in divs
          div.innerHTML = esc-html "#{labels[i]}：#{+cols[i+1]}"

        canvas = row-board.query-selector \canvas

        draw-canvas canvas, pivots, colors, scores

prepare-input = !->
  document.body.onchange = (ev) !->
    #clear-empty-input-tr!
    #add-new-input-tr!
    update-view!
  input-tbody = document.query-selector '#config tbody'

  clear-empty-input-tr = !->
    first-tr = input-tbody.query-selector \tr:first-of-type
    last-tr = input-tbody.query-selector \tr:last-of-type
    if first-tr != last-tr
      is-empty = yes
      for input in last-tr.query-selector-all \input
        if !input.class-list.contains(\jscolor) && input.value == /\d/
          is-empty = no
          break
      if is-empty
        input-tbody.remove-child last-tr
        clear-empty-input-tr!

  add-new-input-tr = !->
    new-input-tr = document.create-element \tr
      ..innerHTML = '<td><input>' * 4 + '<td><input class=jscolor>'
    picker = new jscolor new-input-tr.query-selector 'td:last-of-type input'
    picker.fromHSV Math.random()*360, 20, 100
    input-tbody.append-child new-input-tr

  #clear-empty-input-tr!
  #add-new-input-tr!
  update-view!

prepare-input!
