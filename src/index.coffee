#!/usr/bin/env coffee
###

  * c) 1998-2016 Sebastian Glaser <anx@ulzq.de>

  This file is part of gearlib.

  gearlib is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  gearlib is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with gearlib.  If not, see <http://www.gnu.org/licenses/>.

###

###   * CLB CLB     * CLB *     CLB CLB *     CLB CLB CLB   CLB           CLB CLB CLB   CLB CLB *
    CLB           CLB     CLB   CLB     CLB   CLB           CLB               CLB       CLB     CLB
    CLB           CLB     CLB   CLB CLB *     CLB CLB CLB   CLB               CLB       CLB CLB *
    CLB           CLB     CLB   CLB     CLB   CLB           CLB               CLB       CLB     CLB
      * CLB CLB     * CLB *     CLB     CLB   CLB CLB CLB   CLB CLB CLB   CLB CLB CLB   CLB CL###

unless String::bold then do -> # COLORS Module [: what i need in ansi formatting, nothing really :]
  colormap = bold:1, inverse:7, black:30, red:31, green:32, yellow:33, blue:34, purple:35, cyan:36, white:37, \
    error:'31;1;7', ok:'32;1;7', warn:'33;1;7', bolder:'37;1;7', log:'34;1;7'
  COLORS = require('tty').isatty() and not process.env.NO_COLORS
  String._color = if COLORS then ( (k)-> -> '\x1b[' + k  + 'm' + @ + '\x1b[0m' ) else -> -> @
  Object.defineProperty String::, name, get: String._color k for name, k of colormap

### process enhancements ###
process.cpus = (
  try $fs.readFileSync('/proc/cpuinfo','utf8').match(/processor/g).length
  catch e then 1 )

### $util enhancements ###
global.$util = require 'util'
$util.print = -> process.stdout.write arguments[0]
$util.debuglog = $util.debuglog || -> ->

### Type enhancements ###
Boolean.default = (val,def)-> if val then val isnt 'false' else def

### Array enhancements ###
Object.defineProperties Array::,
  trim:get:          -> return ( @filter (i)-> i? and i isnt false ) || []
  last:get:          -> @[@length-1]
  first:get:         -> @[0]
  random:get:        -> @[Math.round Math.random()*(@length-1)]
  unique:get:        -> u={}; @filter (i)-> return u[i] = on unless u[i]; no
( (k)-> Array[k] = (a)-> a[k] )( k ) for k in ['trim','last','first','unique','random']

Array::remove       = (v) -> @splice i, 1 if i = @indexOf v; @
Array::pushUnique   = (v) -> @push v if -1 is @indexOf v
Array::commons      = (b) -> @filter (i)-> -1 isnt b.indexOf i
( (k)-> Array[k] = (a,v)-> a[k](v) )( k ) for k in ['remove','pushUnique','commons']

Array.slice         = (a,c) -> Array::slice.call a||[], c
Array.oneSharedItem = (b)-> return true for v in @ when -1 isnt b.indexOf v; false

Array.blindPush = (o,a,e)->
  list = o[a] || o[a] = []
  list.push e if -1 is list.indexOf e

Array.blindSortedPush = (o,a,e,key='date')->
  return o[a] = [e] unless ( list = o[a] ) and list.length > 0
  return            unless -1 is list.indexOf e
  return list.unshift e if list[0][key] > e[key]
  break for item, idx in list when item[key] > e[key]
  list.splice idx, 0, e

Array.blindConcat = (o,a,e)->
  o[a] = ( o[a] || o[a] = [] ).concat e

Array.destructiveRemove = (o,a,e)->
  return unless list = o[a]
  list.remove e
  delete o[a] if list.length is 0

### Object enhancements ###
Object.keyCount = (o)-> Object.keys(o).length

Object.resolve = (o,path)->
  ( path = o; o = global ) unless path?
  return o if not path or path is ''
  return false for k in ( l = path.split '.' ) when not ( o = o[k] )?
  return o

Object.unroll = (obj, handle)->
  cue = [].concat obj; cat = cue.concat.bind cue
  if typeof o is 'object' and not Array.isArray o then cat o else handle o, cat while o = do cue.shift
  null

Object.collect = (obj,handle)->
  res = []; cue = [].concat obj; push = cue.push.bind cue; push = cue.push.bind cue
  res = res.concat handle cue.shift(), push while cue.length > 0
  return res

Object.trim = (map)->
  for key,val of map
    delete map[key] if Array.isArray(val)  and val.length is 0
    delete map[key] if typeof val is 'object' and Object.keys(val).length is 0
  map

### $pipe tools ###
global.$pipe = catchErrors: (p)->
  p.on 'error', $nullfn
  p.stdin.on  'error', $nullfn if p.stdin
  p.stdout.on 'error', $nullfn if p.stdout
  p.stderr.on 'error', $nullfn if p.stderr

### $cp enhancements ###
global.$cp   = require 'child_process'

$cp.sane = (i)-> [i.stderr,i.stdout,i.stdin].map( (i)-> i.setEncoding 'utf8'); i

$cp.readlines = (cmd,args...,callback)->
  console.debug '$cp.readlines', cmd, args
  c = $cp.sane $cp.spawn cmd,args
  $carrier.carry c.stdout, callback
  $carrier.carry c.stderr, (line)-> callback line, 'error'
  c

$cp.script = (cmd,callback=->)->
  console.debug '$cp.script', cmd
  c = $cp.sane if cmd.stdout then cmd else $cp.spawn "sh", ["-c",cmd]
  c.buf = []
  $carrier.carry c.stdout, push = (line)-> c.buf.push line
  $carrier.carry c.stderr, push
  c.on 'close', (e)-> callback(e, c.buf.join().trim())
  c

$cp.console = (args...)->
  if process.env.DISPLAY
       return $cp.spawn 'xterm', ['-e'].concat args
  else return $cp.spawn args.shift(), args, stdio:'inherit'

$cp.ssh = (args...)->
  return $cp.console.apply null, ['ssh','-tXA'].concat args

$cp.ssh.cli = (args...)->
  return $cp.spawn('ssh', [`process.env.DISPLAY?'-XA':'-t'`].concat(args), stdio:'inherit')

$cp.ssh.pipe = (args...)->
  return $cp.spawn('ssh', ['-T'].concat(args), stdio:'pipe')

$cp.expect = (cmd)-> new Expect cmd

class Expect
  expect: null
  constructor: (@cmd,@onopen) ->
    @expect = []
    $sudo [ 'sh','-c',@cmd], @run
  run: (@proc,done) =>
    setImmediate done
    $cp.sane @proc
    $carrier.carry @proc.stdout, @data
    $carrier.carry @proc.stderr, @data
    @proc.on 'close', => @onend @ if @onend
    @onopen @ if @onopen
  on:     (match,cb=->) => @expect.push [match,cb]; @
  end:         (@onend) => @
  open:       (@onopen) => @
  data:          (line) => for rec in @expect when ( match = line.match rec[0] )
    rec[1] line, match
    break

### $async functions / inpired by npm:async ###
global.$async = {}

$async.series = (list,done=$nullfn)->
  setImmediate next = (error,args...)->
    return done.call ctx, error, args      if error
    return fn.apply  ctx, [next].concat args if fn = list.shift()
    return done.call ctx
  ctx = list:list, done:done

$async.parallel = (list,done=$nullfn)->
  return done null, [] if list.length is null
  result = new Array list.length; error = new Array list.length; count=0;
  finish = -> done ( if error.length is 0 then null else error ), result
  cb = (i,fn)-> fn (e,a...)-> error[i] = e; result[i] = a; if ++count is list.length then do finish
  cb idx, fn for fn, idx in list
  null

$async.accumulate = (worker)-> queue = []; return ->
  args = new Array arguments.length; args[i] = v for v,i in arguments; queue.push args
  return if worker.hot; worker.hot = yes; setImmediate -> worker queue; queue = []; worker.hot = no

$async.blocking = (worker)->
  q = ( (task)-> tip cue.push task ); cue = []; hot = no
  tip = -> return if hot; return hot = no unless task = cue.shift(); hot = yes; worker task, -> tip hot = no
  return q

$async.oneImmediate = (callback)-> ->
  return if callback.hot; callback.hot = yes
  setImmediate -> do callback; callback.hot = no

$async.blockingImmediate = (callback)-> trigger = ->
  return callback.waiting = yes if callback.hot; callback.hot = yes; callback.waiting = no
  setImmediate -> callback -> callback.hot = no; do trigger if callback.waiting

$async.limit = (token,timeout,callback)->
  unless callback
    callback = timeout
    timeout  = 0
  clearTimeout t if ( t = $limit[token] )
  $limit[token] = setTimeout callback, 0

$async.cue = (worker)->
  q = (task...)-> tip cue.push task
  q.cue = cue = []; running = no
  tip = -> unless running
    return running = no unless task = cue.shift()
    running = yes; worker task, -> tip running = no
  return q

$async.debug = (e,c,o=5000)-> late = no; return (d) ->
  console.hardcore '+>>', e
  t = setTimeout ( -> late =  yes; console.error 'late:', e ), o
  c ->
    if late then console.debug 'resolved', e else console.hardcore '<<-', e
    clearTimeout t
    d null

$async.deadline = (deadline,worker)->
  running = no; timer = null; cue = []
  reset = -> return running = no if cue.length is 0; setImmediate guard
  guard = -> running = yes; worker cue.slice(), reset; cue = []
  return trigger = ->
    cue.push arguments
    return if running
    timer && clearTimeout timer
    timer = setTimeout guard, deadline
    null

$async.pushup = (opts)->
  { worker, threshold, deadline } = opts
  timer = running = again = null; cue = []
  reset = -> setImmediate guard if again; running = again = no
  guard = -> running = yes; worker cue.slice(), reset; cue = []
  return ->
    cue.push arguments
    return again = true if running
    if cue.length < threshold
      clearTimeout timer
      timer = setTimeout guard, deadline
    else clearTimeout timer; setImmediate guard

$async.throttle = (interval,key,callback)->
  unless ( k = $async.throttle[key] )
    k = $async.throttle[key] = interval:interval,key:key,callback:callback,last:0,timer:null
  return if k.timer
  if ( t = Date.now() ) > ( next = k.last + k.interval )
    delta = 0
  else delta = next - t
  k.timer = setTimeout ( ->
    k.last = t
    k.timer = null
    do callback
  ), delta

$async.defer = (fn) -> return o = $function
  task: {}
  waiting: []
  final: fn || $nullfn
  count: 0
  engage: ->
    if o.count is 0 and o.final
      f = o.final
      delete o.final
      f null
  after: (name,deps,fnc)->
    done = o name
    for d in deps when not o.task[d] or o.task[d].done
      f = -> fnc done
      f.__name = name
      f.deps = deps
      o.waiting.push f
      return null
    fnc done
    null
  (task) -> # part
    ++o.count
    o.task[id = task||o.count] = 'pending'
    # console.hardcore 'defer-task:', id
    return -> # join
      # console.hardcore 'finish-task:', id
      o.task[id].done = true
      for fnc in o.waiting
        continue if fnc.done
        continue for d in fnc.deps when not o.task[d] or o.task[d].done
        fnc.done = true
        fnc null
      if --o.count is 0 and o.final
        f = o.final
        delete o.final
        f null
      null

### $sudo helper ###
unless process.env.SUDO_ASKPASS
  process.env.SUDO_ASKPASS = w if w = $which 'ssh-askpass'

global.$sudo = $async.cue (task,done)->
  [ args, opts, callback ] = task
  unless typeof opts is 'object'
    callback = opts
    opts = {}
  do done unless ( args = args || [] ).length > 0
  args.unshift '-A' if process.env.DISPLAY
  sudo = $cp.spawn 'sudo', args, opts
  console.log '\x1b[32mSUDO\x1b[0m', args.join ' '
  if callback then callback sudo, done
  else sudo.on 'close', done

$sudo.read = (cmd,callback)-> $sudo ['sh','-c',cmd], (proc,done)->
  $cp.sane proc
  proc.stdout.once 'data', -> done null
  $carrier.carry proc.stdout, callback

$sudo.script = (cmd,callback)-> $sudo ['sh','-c',cmd], (sudo,done)->
  do done; $cp.sane sudo; out = []; err = []
  $carrier.carry sudo.stdout, out.push.bind out
  $carrier.carry sudo.stderr, err.push.bind out
  sudo.on 'close', (status)-> callback status, out.join('\n'), err.join('\n')
