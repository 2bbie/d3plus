fetchValue   = require "../../../../core/fetch/value.coffee"
stringStrip  = require "../../../../string/strip.js"
uniqueValues = require "../../../../util/uniques.coffee"

module.exports = (vars, data) ->

  data     = vars.data.viz unless data
  discrete = vars[vars.axes.discrete]
  opposite = vars[vars.axes.opposite]
  timeAxis = discrete.value is vars.time.value
  if timeAxis
    ticks = vars.data.time.ticks
    if vars.time.solo.value.length
      serialized = vars.time.solo.value.map(Number)
      ticks = ticks.filter (f) -> serialized.indexOf(+f) >= 0
    else if vars.time.mute.value.length
      serialized = vars.time.mute.value.map(Number)
      ticks = ticks.filter (f) -> serialized.indexOf(+f) < 0
  else if discrete.ticks.values
    ticks = discrete.ticks.values
  else
    ticks = uniqueValues data, discrete.value, fetchValue, vars

  d3.nest()
    .key (d) ->
      return_id = "nesting"
      for id in vars.id.nesting.slice 0, vars.depth.value+1
        val = fetchValue vars, d, id
        val = val.join("_") if val instanceof Array
        return_id += "_"+stringStrip val
      return_id
    .rollup (leaves) ->

      availables = uniqueValues leaves, discrete.value, fetchValue, vars
      timeVar    = availables.length and availables[0].constructor is Date
      availables = availables.map(Number) if timeVar

      if discrete.zerofill.value

        if discrete.scale.value is "log"
          if opposite.scale.viz.domain().every((d) -> d < 0)
            filler = -1
          else
            filler = 1
        else
          filler = 0

        for tick, i in ticks

          tester = if timeAxis then +tick else tick

          if availables.indexOf(tester) < 0

            obj                 = {d3plus: {}}
            for key in vars.id.nesting
              obj[key] = leaves[0][key] if key of leaves[0]
            obj[discrete.value] = tick
            obj[opposite.value] = 0
            obj[opposite.value] = filler

            leaves.splice i, 0, obj

      if typeof leaves[0][discrete.value] is "string"
        leaves
      else
        leaves.sort (a, b) ->
          ad = fetchValue vars, a, discrete.value
          bd = fetchValue vars, b, discrete.value
          xsort = ad - bd
          return xsort if xsort
          ao = fetchValue vars, a, opposite.value
          bo = fetchValue vars, b, opposite.value
          ao - bo

    .entries data
