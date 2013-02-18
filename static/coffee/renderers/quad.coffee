
properties = require('./properties')
glyph_properties = properties.glyph_properties
line_properties = properties.line_properties
fill_properties = properties.fill_properties

glyph = require('./glyph')
Glyph = glyph.Glyph
GlyphView = glyph.GlyphView


class QuadView extends GlyphView

  initialize: (options) ->
    glyphspec = @mget('glyphspec')
    @glyph_props = new glyph_properties(
      @,
      glyphspec,
      ['right', 'left', 'bottom', 'top'],
      [
        new fill_properties(@, glyphspec),
        new line_properties(@, glyphspec)
      ]
    )

    @do_fill   = @glyph_props.fill_properties.do_fill
    @do_stroke = @glyph_props.line_properties.do_stroke
    super(options)

  _render: (data) ->
    ctx = @plot_view.ctx
    glyph_props = @glyph_props

    ctx.save()

    left = (glyph_props.select('left', obj) for obj in data)
    top  = (glyph_props.select('top', obj) for obj in data)
    [@sx0, @sy0] = @map_to_screen(left, glyph_props.left.units, top, glyph_props.top.units)

    right  = (glyph_props.select('right', obj) for obj in data)
    bottom = (glyph_props.select('bottom', obj) for obj in data)
    [@sx1, @sy1] = @map_to_screen(right, glyph_props.right.units, bottom, glyph_props.bottom.units)

    if @glyph_props.fast_path
      @_fast_path(ctx, glyph_props)
    else
      @_full_path(ctx, glyph_props, data)

    ctx.restore()

  _fast_path: (ctx, glyph_props) ->
    if @do_fill
      glyph_props.fill_properties.set(ctx, glyph)
      ctx.beginPath()
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i])
          continue
        ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])
      ctx.fill()

    if @do_stroke
      glyph_props.line_properties.set(ctx, glyph)
      ctx.beginPath()
      for i in [0..@sx0.length-1]
        if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i])
          continue
        ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])
      ctx.stroke()

  _full_path: (ctx, glyph_props, data) ->
    for i in [0..@sx0.length-1]
      if isNaN(@sx0[i] + @sy0[i] + @sx1[i] + @sy1[i])
        continue

      ctx.beginPath()
      ctx.rect(@sx0[i], @sy0[i], @sx1[i]-@sx0[i], @sy1[i]-@sy0[i])

      if @do_fill
        glyph_props.fill_properties.set(ctx, data[i])
        ctx.fill()

      if @do_stroke
        glyph_props.line_properties.set(ctx, data[i])
        ctx.stroke()


class Quad extends Glyph
  default_view: QuadView
  type: 'GlyphRenderer'


Quad::display_defaults = _.clone(Quad::display_defaults)
_.extend(Quad::display_defaults, {

  fill: 'gray'
  fill_alpha: 1.0

  line_color: 'red'
  line_width: 1
  line_alpha: 1.0
  line_join: 'miter'
  line_cap: 'butt'
  line_dash: []

})

class Quads extends Backbone.Collection
  model: Quad

exports.quads = new Quads
exports.Quad = Quad
exports.QuadView = QuadView
