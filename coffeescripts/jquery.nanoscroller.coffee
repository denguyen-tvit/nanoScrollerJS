$ = @jQuery

SCROLLBAR  = 'scrollbar'
SCROLL     = 'scroll'
MOUSEDOWN  = 'mousedown'
MOUSEMOVE  = 'mousemove'
MOUSEWHEEL = 'mousewheel'
MOUSEUP    = 'mouseup'
RESIZE     = 'resize'
DRAG       = 'drag'
UP         = 'up'
PANEDOWN   = 'panedown'
DOMSCROLL  = 'DOMMouseScroll'
DOWN       = 'down'
WHEEL      = 'wheel'

getScrollbarWidth = ->
  outer                = document.createElement 'div'
  outer.style.position = 'absolute'
  outer.style.width    = '100px'
  outer.style.height   = '100px'
  outer.style.overflow = 'scroll'
  document.body.appendChild outer
  noscrollWidth  = outer.offsetWidth
  yesscrollWidth = outer.scrollWidth
  document.body.removeChild outer
  noscrollWidth - yesscrollWidth

class NanoScroll

  constructor: (@el) ->
    @generate()
    @createEvents()
    @addEvents()
    @reset()
    return
  
  createEvents: ->
    ## filesize reasons
    @events =
      down: (e) =>
        @isDrag  = true
        @offsetY = e.clientY - @slider.offset().top
        @pane.addClass 'active'
        $(document).bind MOUSEMOVE, @events.drag
        $(document).bind MOUSEUP, 	@events.up
        false

      drag: (e) =>
        @sliderY = e.clientY - @el.offset().top - @offsetY
        @scroll()
        false

      up: (e) =>
        @isDrag = false
        @pane.removeClass 'active'
        $(document).unbind MOUSEMOVE, @events.drag
        $(document).unbind MOUSEUP, 	@events.up
        false

      resize: (e) =>
        @reset()
        return

      panedown: (e) =>
        @sliderY = e.clientY - @el.offset().top - @sliderH * 0.5
        @scroll()
        @events.down e
        return

      scroll: (e) =>
        content = @content[0]
        return if @isDrag is true
        top = content.scrollTop / (content.scrollHeight - content.clientHeight) * (@paneH - @sliderH)
        @slider.css top: top + 'px'
        return

      wheel: (e) =>
        @sliderY +=  -e.wheelDeltaY || -e.delta
        @scroll()
        return false
    return

  addEvents: ->
    events = @events
    pane = @pane
    $(window).bind RESIZE  , events[RESIZE]
    @slider.bind MOUSEDOWN , events[DOWN]
    pane.bind MOUSEDOWN   , events[PANEDOWN]
    @content.bind SCROLL   , events[SCROLL]

    if window.addEventListener
      pane = pane[0]
      pane.addEventListener MOUSEWHEEL , events[WHEEL]
      pane.addEventListener DOMSCROLL  , events[WHEEL]
    return

  removeEvents: ->
    events = @events
    pane = @pane
    $(window).unbind RESIZE  , events[RESIZE]
    @slider.unbind MOUSEDOWN , events[DOWN]
    pane.unbind MOUSEDOWN    , events[PANEDOWN]
    @content.unbind SCROLL   , events[SCROLL]

    if window.addEventListener
      pane = pane[0]
      pane.removeEventListener MOUSEWHEEL , events[WHEEL]
      pane.removeEventListener DOMSCROLL  , events[WHEEL]
    return
    
  generate: ->
    @el.append '<div class="pane"><div class="slider"></div></div>'
    @content = $ @el.children()[0]
    @slider  = @el.find '.slider'
    @pane    = @el.find '.pane'
    @scrollW = getScrollbarWidth()
    @scrollW = 0 if @scrollbarWidth is 0
    @content.css
      right  : -@scrollW + 'px'

    # scumbag IE7
    if $.browser.msie?
      @pane.hide() if parseInt($.browser.version, 10) < 8
    return

  reset: ->
    if @isDead is true
      @isDead = false
      @pane.show()
      @addEvents()

    @contentH  = @content[0].scrollHeight + @scrollW
    @paneH     = @pane.outerHeight()
    @sliderH   = @paneH / @contentH * @paneH
    @sliderH   = Math.round @sliderH
    @scrollH   = @paneH - @sliderH
    @slider.height 	@sliderH

    if @paneH >= @content[0].scrollHeight
      @pane.hide()
    else
      @pane.show()
    return

  scroll: ->
    @sliderY    = Math.max 0, @sliderY
    @sliderY    = Math.min @scrollH, @sliderY
    scrollValue = @paneH - @contentH + @scrollW
    scrollValue = scrollValue * @sliderY / @scrollH
    # scrollvalue = (paneh - ch + sw) * sy / sw
    @content.scrollTop -scrollValue
    @slider.css top: @sliderY

  scrollBottom: (offsetY) ->
    @reset()
    @content.scrollTop @contentH - @content.height() - offsetY
    return

  scrollTop: (offsetY) ->
    @reset()
    @content.scrollTop offsetY + 0
    return
  
  stop: ->
    @isDead = true
    @removeEvents()
    @pane.hide()
    return

  
$.fn.nanoScroller = (options) ->
  options or= {}
  scrollbar = @data SCROLLBAR
  if scrollbar is undefined
    scrollbar = new NanoScroll this
    @data SCROLLBAR: scrollbar
    return

  return scrollbar.scrollBottom(options.scrollBottom) if options.scrollBottom
  return scrollbar.scrollTop(options.scrollTop)       if options.scrollTop
  return scrollbar.scrollBottom(0)                    if options.scroll is 'bottom'
  return scrollbar.scrollTop(0)                       if options.scroll is 'top'
  return scrollbar.stop()                             if options.stop   is true
  return scrollbar.reset()
