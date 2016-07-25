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

return if $static?

global.$static = (args...) -> while a = do args.shift
  if ( t = typeof a ) is 'string' then global[a] = do args.shift
  else if a::? and a::constructor? and a::constructor.name?
    global[a::constructor.name] = a
  else ( global[k] = v for k,v of a )
  null

###   * CLB CLB     * CLB *     CLB CLB *     CLB CLB CLB   CLB           CLB CLB CLB   CLB CLB *
    CLB           CLB     CLB   CLB     CLB   CLB           CLB               CLB       CLB     CLB
    CLB           CLB     CLB   CLB CLB *     CLB CLB CLB   CLB               CLB       CLB CLB *
    CLB           CLB     CLB   CLB     CLB   CLB           CLB               CLB       CLB     CLB
      * CLB CLB     * CLB *     CLB     CLB   CLB CLB CLB   CLB CLB CLB   CLB CLB CLB   CLB CL###

$os   = require 'os'
$fs   = require 'fs'
$cp   = require 'child_process'
$util = require 'util'
$path = require 'path'

$app  = new ( EventEmitter = require('events').EventEmitter )
$app.setMaxListeners 0

$nullfn = ->
$evented = (obj)-> Object.assign obj, EventEmitter::; EventEmitter.call obj; obj.setMaxListeners(0); return obj
$function = (members,func)-> unless func then func = members else ( func[k] = v for k,v of members ); func
$which = (name)-> w = $cp.spawnSync 'which',[name]; return false if w.status isnt 0; return w.stdout.toString().trim()

$static $app:$app,$os:$os,$fs:$fs,$cp:$cp,$util:$util,$path:$path,$nullfn:$nullfn,$evented:$evented,
  $function:$function,$which:$which

# unless String::bold then do -> # COLORS Module [: what i need in ansi formatting, nothing really :]
colormap = bold:1, inverse:7, \
  black:30, red:31, green:32, yellow:33, blue:34, purple:35, cyan:36, white:37, \
  blackBG:40, redBG:41, greenBG:42, yellowBG:43, blueBG:44, purpleBG:45, cyanBG:46, whiteBG:47, \
  error:'31;1;7', ok:'32;1;7', warn:'33;1;7', bolder:'37;1;7', log:'34;1;7'
COLORS = require('tty').isatty() and not process.env.NO_COLORS
String._color = if COLORS then ( (k)-> -> '\x1b[' + k  + 'm' + @ + '\x1b[0m' ) else -> -> @
Object.defineProperty String::, name, get: String._color k for name, k of colormap

### DGB DBG *     DBG DBG DBG   DBG DBG *     DBG     DBG     * DBG DBG
    DGB     DBG   DBG           DBG     DBG   DBG     DBG   DBG
    DGB     DBG   DBG DBG DBG   DBG DBG *     DBG     DBG   DBG   * DBG
    DGB     DBG   DBG           DBG     DBG   DBG     DBG   DBG     DBG
    DGB DBG *     DBG DBG DBG   DBG DBG *       * DBG DBG     * DB###

$static $debug: $function active:no, hardcore:no, (fn) -> do fn if $debug.active and fn and fn.call
$debug.enable = (debug=no,hardcore=no)->
  @verbose = yes; @debug = debug || hardcore; @hardcore = hardcore
  c._log = log = c.log unless log = ( c = console )._log; start = Date.now();
  c.log = (args...)-> log.apply c, ['['+(Date.now()-start)+']'].concat args
  c.verbose = log; c.debug = ( if @debug then log else $nullfn ); c.hardcore = ( if @hardcore then log else $nullfn )
  c.log '\x1b[43;30mDEBUG MODE\x1b[0m', @debug, @hardcore, c.hardcore
$debug.disable = -> $debug.active = no; c = console; c.log = c._log || c.log; c.hardcore = c.debug = c.verbose = ->
unless -3 is process.argv.indexOf('-D') + process.argv.indexOf('-d') + process.argv.indexOf('-v')
  $debug.enable -1 isnt process.argv.indexOf('-d'), -1 isnt process.argv.indexOf('-D')
else do $debug.disable

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

### REQ REQ *     REQ REQ REQ     * REQ *     REQ     REQ   REQ REQ REQ   REQ REQ *     REQ REQ REQ
    REQ     REQ   REQ           REQ     REQ   REQ     REQ       REQ       REQ     REQ   REQ
    REQ REQ *     REQ REQ REQ   REQ     REQ   REQ     REQ       REQ       REQ REQ *     REQ REQ REQ
    REQ     REQ   REQ           REQ     *     REQ     REQ       REQ       REQ     REQ   REQ
    REQ     REQ   REQ REQ REQ     * REQ REQ     * REQ REQ   REQ REQ REQ   REQ     REQ   REQ REQ ###

$static $require: (callback) ->
  ( Error.prepareStackTrace = (err, stack) -> stack ); ( try err = new Error ); ( file = do -> while err.stack.length then return f if __filename isnt f = err.stack.shift().getFileName() ); ( delete Error.prepareStackTrace )
  mod = $require.Module.byName[name = $require.modName(file)]
  mod.deps = callback
  do mod.checkDeps

$require.modName = (file) ->
  f = file.replace(/\.js$/,'').replace($path.cache+'/','')
  if $path.basename(f) is $path.basename($path.dirname f) then f = $path.dirname f else f

$require.compile = (source) =>
  dest = source.replace($path.modules,$path.cache).replace(/coffee$/,'js')
  return dest if $fs.existsSync(dest) and Date.parse($fs.statSync(source).mtime) is Date.parse($fs.statSync(dest).mtime)
  $fs.mkdirSync(dir) unless $fs.existsSync dir = $path.dirname(dest)
  $fs.writeFileSync dest, '#!/usr/bin/env node\n' + $coffee.compile $fs.readFileSync source, 'utf8'
  $fs.touch.sync dest, ref: source
  console.debug '\x1b[32m$compiled\x1b[0m', $require.modName dest
  dest

$require.scan = (base) -> Object.collect base, (dir,cue)->
  $fs.readdirSync(dir).map( (i)-> $path.join dir, i ).filter (i) ->
    return false if i is __filename or i.match 'node_modules'
    cue i        if $fs.statSync(i).isDirectory()
    i.match /\.(js|coffee)$/

$require.all = (callback) ->
  $require.scan($path.modules).map($require.compile).map (file)->
    return if file.match /\/gear\.js$/
    new $require.Module file
  $async.series [ $require.apt.commit, $require.npm.commit ], ->
    setImmediate retryRound = ->
      console.hardcore 'WAITING_FOR', Object.keys($require.Module.waiting).join ' '
      do mod.reload for name, mod of $require.Module.waiting
      return setImmediate retryRound unless 0 is Object.keys($require.Module.waiting).length
      $app.emit 'init', defer = $async.defer callback
      do defer.engage



$require.Module = class GEARModule
  @waiting: {}
  @byPath: {}
  @byName: {}
  constructor: (@path)->
    $require.Module.byPath[@path] = $require.Module.byName[@name = $require.modName @path] = @
    require @path
    if ( @deps and @loaded ) or ( not @deps? )
      console.hardcore '\x1b[33mmodule\x1b[0m', @name, @loaded, @deps?
      return @loaded = true
    @loaded = false
  reload: ->
    return unless @checkDeps()
    delete require.cache[@path]
    require @path
  checkDeps: ->
    done = yes; mods = $require.Module.byName
    if @deps then @deps.call {
    defer: => unless @resolve
      done = no
      @defer = $nullfn; console.hardcore '<defer>', @name
      @resolve = =>
        delete @resolve; @loaded = true; console.hardcore '<resolved>', @name
    apt:    (args) => done = done && $require.apt args
    npm: (args...) => done = done && $require.npm.apply null, args
    mod: (args...) => for mod in args
      done = done && mods[mod]? && mods[mod].loaded
    }, @
    if done then delete $require.Module.waiting[@name]
    else $require.Module.waiting[@name] = @
    return if done and @resolve then true else if done then @loaded = true else @loaded = false



$require.npm = $function queue: {}, list: {}, source: {}, (list...) ->
  n = $require.npm; wait = false
  for k in list
    if k.match ' '
      [ k, url ] = k.split ' '
      n.source[k] = url
    n.list[k] = true
    n.queue[k] = n.list[k] = wait = true unless $fs.existsSync $path.join $path.node_modules, k
  not true is wait

$require.npm.now = (list,callback) ->
  return do callback if $require.npm.apply null, list
  $require.npm.commit callback

$require.npm.commit = (callback)->
  queue = ( n = $require.npm ).queue; n.queue = {}
  install = Object.keys(queue).map (i)->
    console.log i, n.source
    n.source[i] || i
  return do callback if install.length is 0
  console.log ' INSTALL ', install
  session = $cp.spawn 'npm', ['install'].concat(install), stdio:'inherit'
  session.on 'close', -> do callback



$require.apt = $function queue: {}, missing: {}, (list) ->
  wait = false
  for k,v of list
    continue if $fs.existsSync(k) or $which(k) or $require.apt.missing[k]
    wait = true ; $require.apt.queue[k] = v
  not true is wait

$require.apt.commit = (callback=->)->
  queue = $require.apt.queue; $require.apt.queue = {}
  return do callback if ( install = ( v for k,v of queue ) ).length is 0
  session = $sudo ['apt-get','install','--no-install-recommends','--no-install-suggests','-y'].concat(install), stdio:'inherit', (p,done)-> do done; p.on 'close', ->
    for app, pkg of queue when not $which app
      console.error 'ERROR:', app, 'is missing and cannot be installed'
      # process.exit(0)
      $require.apt.missing[app] = true
    do callback
