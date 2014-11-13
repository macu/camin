Animator = do ->

  rAF = window["requestAnimationFrame"]
  cAF = window["cancelAnimationFrame"]

  # based on polyfill by Erik Möller,
  # with fixes from Paul Irish and Tino Zijdel.
  # https://gist.github.com/1579671
  if !rAF or !cAF then do ->
    for v in ['ms', 'moz', 'webkit', 'o']
      rAF ?= window["#{v}RequestAnimationFrame"]
      cAF ?= window["#{v}CancelAnimationFrame"] or
        window["#{v}CancelRequestAnimationFrame"]
    return

  if !rAF or !cAF then do ->
    # if either is undefined, use manual timeout at ~62fps.
    # keep a queue of callbacks and call them all on timeout,
    # rather than setting a separate timeout for each.
    # this allows multiple independent animations on each frame.
    cbQueue = {}
    currAnim = null
    lastTime = 0
    dAF = (currTime) ->
      # draw: call all queued callbacks for the current frame
      queue = cbQueue
      cbQueue = {}
      currAnim = null
      cb?(currTime) for cb of queue
      return
    rAF = (cb) ->
      # request: add callback to queue for next frame
      cbQueue[cb] = true
      return cb if currAnim
      currTime = Date.now?() or (new Date).getTime()
      waitTime = Math.max(0, 16 - (currTime - lastTime)) # ~62fps
      lastTime = currTime + waitTime
      currAnim = window.setTimeout((-> dAF(lastTime)), waitTime)
      return cb
    cAF = (an) ->
      # cancel: remove callback from queue for next frame
      cbCount = 0
      for cb of cbQueue
        if cb == an then delete cbQueue[cb]
        else if cb then cbCount++
      if cbCount == 0
        window.clearTimeout currAnim
        currAnim = null
      return
    return

  ##################################################
  # EXPORTS

  start: (fn, cb, el) ->
    # start returns a controller for the animation.
    # fn is called on the next animation frame.
    # fn receives the elapsed time since anim start, and the controls.
    # fn should perform drawing, and return true for another frame.
    # call controls.stop() to end the animation and invoke cb.
    # call controls.cancel() to end without invoking cb.
    initTime = null
    currAnim = null
    done = false
    controls = {
      busy: -> !done
      stop: -> if !done then @cancel(); if cb then cb()
      cancel: -> done = true; cAF currAnim
    }
    next = -> currAnim = rAF step, el
    step = (currTime) -> if !done
      initTime ?= currTime
      if fn(currTime - initTime, controls) then next()
      else controls.stop()
    next()
    return controls
