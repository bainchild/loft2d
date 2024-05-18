--[[

	File and TCP logging with capped disk & memory usage.
	Written by Cosmin Apreutesei. Public domain.

	logging.log(severity, module, event, fmt, ...)
	logging.note(module, event, fmt, ...)
	logging.dbg(module, event, fmt, ...)
	logging.warnif(module, event, condition, fmt, ...)
	logging.logerror(module, event, fmt, ...)

	logging.args(...) -> ...
	logging.printargs(...) -> ...

	logging.env <- 'dev' | 'prod', etc.
	logging.deploy <- app deployment name
	logging.filter <- {severity->true}
	logging.censor <- f(severity, module, event, msg)

	logging:tofile(logfile, max_disk_size)
	logging:toserver(host, port, queue_size, timeout)

]]

local unpack = (unpack or table.unpack)
local pp = (function()
	--Recursive pretty printer with optional indentation and cycle detection.
	--Written by Cosmin Apreutesei. Public Domain.
	local type, tostring = type, tostring
	local string_format, string_dump = string.format, string.dump
	local math_huge, floor = math.huge, math.floor

	--pretty printing for non-structured types -----------------------------------

	local escapes = { --don't add unpopular escapes here
		['\\'] = '\\\\',
		['\t'] = '\\t',
		['\n'] = '\\n',
		['\r'] = '\\r',
	}

	local function escape_byte_long(c1, c2)
		return string_format('\\%03d%s', c1:byte(), c2)
	end
	local function escape_byte_short(c)
		return string_format('\\%d', c:byte())
	end
	local function quote_string(s, quote)
		s = s:gsub('[\\\t\n\r]', escapes)
		s = s:gsub(quote, '\\%1')
		s = s:gsub('([^\32-\126])([0-9])', escape_byte_long)
		s = s:gsub('[^\32-\126]', escape_byte_short)
		return s
	end

	local function format_string(s, quote)
		return string_format('%s%s%s', quote, quote_string(s, quote), quote)
	end

	local function write_string(s, write, quote)
		write(quote); write(quote_string(s, quote)); write(quote)
	end

	local keywords = {}
	for i,k in ipairs{
		'and',       'break',     'do',        'else',      'elseif',    'end',
		'false',     'for',       'function',  'goto',      'if',        'in',
		'local',     'nil',       'not',       'or',        'repeat',    'return',
		'then',      'true',      'until',     'while',
	} do
		keywords[k] = true
	end

	local function is_stringable(v)
		if type(v) == 'table' then
			return getmetatable(v) and getmetatable(v).__tostring and true or false
		else
			return type(v) == 'string'
		end
	end

	local function is_identifier(v)
		if is_stringable(v) then
			v = tostring(v)
			return not keywords[v] and v:find('^[a-zA-Z_][a-zA-Z_0-9]*$') ~= nil
		else
			return false
		end
	end

	local hasinf = math_huge == math_huge - 1
	local function format_number(v)
		if v ~= v then
			return '0/0' --NaN
		elseif hasinf and v == math_huge then
			return '1/0' --writing 'math.huge' would not make it portable, just wrong
		elseif hasinf and v == -math_huge then
			return '-1/0'
		elseif v == floor(v) and v >= -2^31 and v <= 2^31-1 then
			return string_format('%d', v) --printing with %d is faster
		else
			return string_format('%0.17g', v)
		end
	end

	local function write_number(v, write)
		write(format_number(v))
	end

	local function is_dumpable(f)
		return type(f) == 'function' and debug.getinfo(f, 'Su').what ~= 'C'
	end

	local function format_function(f)
		return string_format('loadstring(%s)', format_string(string_dump(f, true)))
	end

	local function write_function(f, write, quote)
		write'loadstring('; write_string(string_dump(f, true), write, quote); write')'
	end

	local ffi, int64, uint64
	local function is_int64(v)
		if type(v) ~= 'cdata' then return false end
		if not int64 then
			ffi = require'ffi'
			int64 = ffi.typeof'int64_t'
			uint64 = ffi.typeof'uint64_t'
		end
		return ffi.istype(v, int64) or ffi.istype(v, uint64)
	end

	local function format_int64(v)
		return tostring(v)
	end

	local function write_int64(v, write)
		write(format_int64(v))
	end

	local function format_value(v, quote)
		quote = quote or "'"
		if v == nil or type(v) == 'boolean' then
			return tostring(v)
		elseif type(v) == 'number' then
			return format_number(v)
		elseif is_stringable(v) then
			return format_string(tostring(v), quote)
		elseif is_dumpable(v) then
			return format_function(v)
		elseif is_int64(v) then
			return format_int64(v)
		else
			assert(false)
		end
	end

	local function is_serializable(v)
		return type(v) == 'nil' or type(v) == 'boolean' or type(v) == 'number'
			or is_stringable(v) or is_dumpable(v) or is_int64(v)
	end

	local function write_value(v, write, quote)
		quote = quote or "'"
		if v == nil or type(v) == 'boolean' then
			write(tostring(v))
		elseif type(v) == 'number' then
			write_number(v, write)
		elseif is_stringable(v) then
			write_string(tostring(v), write, quote)
		elseif is_dumpable(v) then
			write_function(v, write, quote)
		elseif is_int64(v) then
			write_int64(v, write)
		else
			assert(false)
		end
	end

	--pretty-printing for tables -------------------------------------------------

	local to_string --fw. decl.

	local cache = setmetatable({}, {__mode = 'kv'})
	local function cached_to_string(v, parents)
		local s = cache[v]
		if not s then
			s = to_string(v, nil, parents, nil, nil, nil, true)
			cache[v] = s
		end
		return s
	end

	local function virttype(v)
		return is_stringable(v) and 'string' or type(v)
	end

	local type_order = {boolean = 1, number = 2, string = 3, table = 4}
	local function cmp_func(t, parents)
		local function cmp(a, b)
			local ta, tb = virttype(a), virttype(b)
			if ta == tb then
				if ta == 'boolean' then
					return (a and 1 or 0) < (b and 1 or 0)
				elseif ta == 'string' then
					return tostring(a) < tostring(b)
				elseif ta == 'number' then
					return a < b
				elseif a == nil then --can happen when comparing values
					return false
				else
					local sa = cached_to_string(a, parents)
					local sb = cached_to_string(b, parents)
					if sa == sb then --keys look the same serialized, compare values
						return cmp(t[a], t[b])
					else
						return sa < sb
					end
				end
			else
				return type_order[ta] < type_order[tb]
			end
		end
		return cmp
	end

	local function sortedpairs(t, parents)
		local keys = {}
		for k in pairs(t) do
			keys[#keys+1] = k
		end
		table.sort(keys, cmp_func(t, parents))
		local i = 0
		return function()
			i = i + 1
			return keys[i], t[keys[i]]
		end
	end

	local function is_array_index_key(k, maxn)
		return
			maxn > 0
			and type(k) == 'number'
			and k == floor(k)
			and k >= 1
			and k <= maxn
	end

	local function pretty(v, write, depth, wwrapper, indent,
		parents, quote, line_term, onerror, sort_keys, filter)

		if not filter(v) then return end

		if is_serializable(v) then

			write_value(v, write, quote)

		elseif getmetatable(v) and getmetatable(v).__pwrite then

			wwrapper = wwrapper or function(v)
				pretty(v, write, -1, wwrapper, nil,
					parents, quote, line_term, onerror, sort_keys, filter)
			end
			getmetatable(v).__pwrite(v, write, wwrapper)

		elseif type(v) == 'table' then

			if indent == nil then indent = '\t' end

			parents = parents or {}
			if parents[v] then
				write(onerror and onerror('cycle', v, depth) or 'nil --[[cycle]]')
				return
			end
			parents[v] = true

			write'{'

			local first = true
			local t = v

			local maxn = 0
			for k,v in ipairs(t) do
				maxn = maxn + 1
				if filter(v, k, t) then
					if first then
						first = false
					else
						write','
					end
					if indent then
						write(line_term)
						write(indent:rep(depth))
					end
					pretty(v, write, depth + 1, wwrapper, indent,
						parents, quote, line_term, onerror, sort_keys, filter)
				end
			end

			local pairs = sort_keys ~= false and sortedpairs or pairs
			for k,v in pairs(t, parents) do
				if not is_array_index_key(k, maxn) and filter(v, k, t) then
					if first then
						first = false
					else
						write','
					end
					if indent then
						write(line_term)
						write(indent:rep(depth))
					end
					if is_stringable(k) then
						k = tostring(k)
					end
					if is_identifier(k) then
						write(k); write'='
					else
						write'['
						pretty(k, write, depth + 1, wwrapper, indent,
							parents, quote, line_term, onerror, sort_keys, filter)
						write']='
					end
					pretty(v, write, depth + 1, wwrapper, indent,
						parents, quote, line_term, onerror, sort_keys, filter)
				end
			end

			if indent then
				write(line_term)
				write(indent:rep(depth-1))
			end

			write'}'

			parents[v] = nil

		else
			write(onerror and onerror('unserializable', v, depth) or
				string_format('nil --[[unserializable %s]]', type(v)))
		end
	end

	local function nofilter(v) return true end

	local function args(opt, ...)
		local
			indent, parents, quote, line_term, onerror,
			sort_keys, filter
		if type(opt) == 'table' then
			indent, parents, quote, line_term, onerror,
			sort_keys, filter =
				opt.indent, opt.parents, opt.quote, opt.line_term, opt.onerror,
				opt.sort_keys, opt.filter
		else
			indent, parents, quote, line_term, onerror,
			sort_keys, filter = opt, ...
		end
		line_term = line_term or '\n'
		filter = filter or nofilter
		return
			indent, parents, quote, line_term, onerror,
			sort_keys, filter
	end

	local function to_sink(write, v, ...)
		return pretty(v, write, 1, nil, args(...))
	end

	function to_string(v, ...) --fw. declared
		local buf = {}
		pretty(v, function(s) buf[#buf+1] = s end, 1, nil, args(...))
		return table.concat(buf)
	end

	local function to_openfile(f, v, ...)
		pretty(v, function(s) assert(f:write(s)) end, 1, nil, args(...))
	end

	local function to_file(_, _, ...)
		-- local glue = require'glue'
		-- return glue.writefile(file, coroutine.wrap(function(...)
		-- 	coroutine.yield'return '
		-- 	to_sink(coroutine.yield, v, ...)
		-- end, ...))
	end

	local function to_stdout(v, ...)
		return to_openfile(io.stdout, v, ...)
	end

	local pp_skip = {
		__index = 1,
		__newindex = 1,
		__mode = 1,
	}
	local function filter(v, k, t) --don't show methods and inherited objects.
		if type(v) == 'function' then return end --skip methods.
		if getmetatable(t) == t and pp_skip[k] then return end --skip inherits.
		return true
	end
	local function pp(...)
		local n = select('#',...)
		for i = 1, n do
			local v = select(i,...)
			if is_stringable(v) then
				io.stdout:write(tostring(v))
			else
				to_openfile(io.stdout, v, nil, nil, nil, nil, nil, nil, filter)
			end
			if i < n then io.stdout:write'\t' end
		end
		io.stdout:write'\n'
		io.stdout:flush()
		return ...
	end

	return setmetatable({

		--these can be exposed too if needed:
		--
		--is_identifier = is_identifier,
		--is_dumpable = is_dumpable,
		--is_serializable = is_serializable,
		--is_stringable = is_stringable,
		--
		--format_value = format_value,
		--write_value = write_value,

		write = to_sink,
		format = to_string,
		stream = to_openfile,
		save = to_file,
		load = function(file)
			local f, err = loadfile(file)
			if not f then return nil, err end
			local ok, v = pcall(f)
			if not ok then return nil, v end
			return v
		end,
		pp = pp, --old API

	}, {__call = function(self, ...)
		return self.pp(...)
	end})

end)()
local pp_format = pp.format
local function glue_starts(s, p)
	return s:sub(1, #p) == p
end
local function glue_lines(s, opt, i)
	local term = opt == '*L'
	local patt = term and '()([^\r\n]*()\r?\n?())' or '()([^\r\n]*)()\r?\n?()'
	i = i or 1
	local ended
	return function()
		if ended then return end
		local i0, s, i1, i2 = s:match(patt, i)
		ended = i1 == i2
		i = i2
		return s, i0, i1, i2
	end
end
local function glue_outdent(s, newindent)
	newindent = newindent or ''
	local indent
	local t = {}
	for s in glue_lines(s) do
		local indent1 = s:match'^([\t ]*)[^%s]'
		if not indent then
			indent = indent1
		elseif indent1 then
			if indent ~= indent1 then
				if #indent1 > #indent then --more indented
					if not glue_starts(indent1, indent) then
						indent = ''
						break
					end
				elseif #indent > #indent1 then --less indented
					if not glue_starts(indent, indent1) then
						indent = ''
						break
					end
					indent = indent1
				else --same length, diff contents.
					indent = ''
					break
				end
			end
		end
		t[#t+1] = s
	end
	if indent == '' and newindent == '' then
		return s
	end
	for i=1,#t do
		t[i] = newindent .. t[i]:sub(#indent + 1)
	end
	return table.concat(t, '\n'), indent
end

local time = os.time
local _ = string.format

local logging = {
	quiet = false,
	verbose = true,
	debug = false,
	flush = false, --too slow (but you can tail)
	censor = {},
	max_disk_size = 16 * 1024^2,
	queue_size = 10000,
	timeout = 5,
}

function logging:tofile(logfile, max_size)

	-- local fs = require'fs'

	local logfile0 = logfile:gsub('(%.[^%.]+)$', '0%1')
	if logfile0 == logfile then logfile0 = logfile..'0' end

	local f, size

	local function check(event, ret, err)
		if ret then return ret end
		self.log('', 'log', event, '%s', err)
		if f then f:close(); f = nil end
	end

	local function open()
		if f then return true end
		f = check('open', io.open(logfile, 'a')); if not f then return end
		size = check('size', (function()
			local c = f:seek("cur")
			local si = #f:read("*a")
			f:seek("set",c)
			return si
		end)()); if not f then return end
		return true
	end

	max_size = max_size or self.max_disk_size

	local function rotate(len)
		if max_size and size + len > max_size / 2 then
			f:close(); f = nil
			if not open() then return end
		end
		return true
	end

	function self:logtofile(s)
		if not open() then return end
		if not rotate(#s + 1) then return end
		size = size + #s + 1
		if not check('write', f:write(s)) then return end
		if self.flush and not check('flush', f:flush()) then return end
	end

	return self
end

function logging:toserver(_,_,_,_)
	error("disabled")
end

function logging:toserver_stop() end

logging.filter = {}

local null = {}
local names = setmetatable({}, {__mode = 'k'}) --{[obj]->name}

function logging.name(obj, name)
	names[(rawequal(obj,nil) and null or obj)] = name
end

logging.name(coroutine.running(), 'TM')

local function debug_type(v)
	return type(v) == 'table' and v.type or type(v)
end

local prefixes = {
	thread = 'T',
	['function'] = 'f',
	cdata = 'c',
}

local function debug_prefix(v)
	return type(v) == 'table' and v.debug_prefix
		or prefixes[debug_type(v)] or debug_type(v)
end

local ids_db = {} --{type->{last_id=,[obj]->id}}

local function debug_id(v)
	local type = debug_type(v)
	local ids = ids_db[type]
	if not ids then
		ids = setmetatable({}, {__mode = 'k'})
		ids_db[type] = ids
	end
	local id = ids[v]
	if not id then
		id = (ids.last_id or 0) + 1
		ids.last_id = id
		ids[v] = id
	end
	return debug_prefix(v)..id
end

local pp_skip = {
	__index = 1,
	__newindex = 1,
	__mode = 1,
}
local function pp_filter(v, k, t)
	if type(v) == 'function' then return end --skip methods.
	if getmetatable(t) == t and pp_skip[k] then return end --skip inherits.
	return true
end
local pp_opt = {filter = pp_filter}
local pp_opt_compact = {filter = pp_filter, indent = false}
local function pp_compact(v)
	local s = pp_format(v, pp_opt)
	return #s < 50 and pp_format(v, pp_opt_compact) or s
end

local function debug_arg(for_printing, v)
	if v == nil then
		return 'nil'
	elseif type(v) == 'boolean' then
		return v and 'Y' or 'N'
	elseif type(v) == 'number' then
		return _('%.17g', v)
	else --string, table, function, thread, cdata
		v = type(v) == 'string' and v
			or names[v]
			or (type(v) == 'table' and not v.type and not v.debug_prefix and pp_compact(v))
			or (getmetatable(v) and getmetatable(v).__tostring
				and not (type(v) == 'table' and v.type and v.debug_prefix)
				and tostring(v))
			or debug_id(v)
		if not for_printing then
			if v:find('\n', 1, true) then --multiline, make room for it.
				v = v:gsub('\r\n', '\n')
				v = glue_outdent(v)
				v = '\n\n'..v..'\n'
			end
			--avoid messing up the terminal when tailing logs.
			v = v:gsub('[%z\1-\8\11-\31\128-\255]', '.')
		end
		return v
	end
end

local function logging_args_func(for_printing)
	return function(...)
		if select('#', ...) == 1 then
			return debug_arg(for_printing, (...))
		end
		local args, n = {...}, select('#',...)
		for i=1,n do
			args[i] = debug_arg(for_printing, args[i])
		end
		return unpack(args, 1, n)
	end
end
logging.args      = logging_args_func(false)
logging.printargs = logging_args_func(true)

local function log(self, severity, module, event, fmt, ...)
	if self.filter[severity] then return end
	local env = logging.env and logging.env:upper():sub(1, 1) or 'D'
	local time = time()
	local date = os.date('%Y-%m-%d %H:%M:%S', time)
	local msg = fmt and _(fmt, self.args(...))
	if next(self.censor) then
		for _,censor in pairs(self.censor) do
			msg = censor(msg, self, severity, module, event)
		end
	end
	if msg and msg:find('\n', 1, true) then --multiline
		local arg1_multiline = msg:find'^\n\n'
		msg = glue_outdent(msg, '\t')
		if not arg1_multiline then
			msg = '\n\n'..msg..'\n'
		end
	end
	local entry = _('%s %s %-6s %-6s %-8s %-4s %s\n',
		env, date, severity, module or '', (event or ''):sub(1, 8),
		debug_arg(false, (coroutine.running() or null)), msg or '')
	if severity ~= '' then --debug messages are transient
		if self.logtofile then
			self:logtofile(entry)
		end
		if self.logtoserver then
			self:logtoserver{
				deploy = logging.deploy, env = logging.env, time = time,
				severity = severity, module = module, event = event,
				message = msg,
			}
		end
	end
	if
		not self.quiet
		and (severity ~= '' or self.debug)
		and (severity ~= 'note' or (self.verbose == true or self.verbose == module))
	then
		io.stderr:write(entry)
		io.stderr:flush()
	end
end
local function note (self, ...) log(self, 'note', ...) end
local function dbg  (self, ...) log(self, '', ...) end

local function warnif(self, module, event, cond, ...)
	if not cond then return end
	log(self, 'WARN', module, event, ...)
end

local function logerror(self, module, event, ...)
	log(self, 'ERROR', module, event, ...)
end

function logging:clone(module)
	local new = logging.new(module)
	new.quiet = self.quiet
	new.verbose = self.verbose
	new.debug = self.debug
	new.flush = self.flush
	new.censor = self.censor
	new.max_disk_size = self.max_disk_size
	new.queue_size = self.queue_size
	new.timeout = self.timeout
	return new
end

local function init(self,mdl)
	-- probably a good way to do this
	-- don't want to stack functions cause stack traces
	if mdl then
		self.log      = function(...) return log      (self, mdl, ...) end
		self.note     = function(...) return note     (self, mdl, ...) end
		self.dbg      = function(...) return dbg      (self, mdl, ...) end
		self.warnif   = function(...) return warnif   (self, mdl, ...) end
		self.logerror = function(...) return logerror (self, mdl, ...) end
	else
		self.log      = function(...) return log      (self, ...) end
		self.note     = function(...) return note     (self, ...) end
		self.dbg      = function(...) return dbg      (self, ...) end
		self.warnif   = function(...) return warnif   (self, ...) end
		self.logerror = function(...) return logerror (self, ...) end
	end
	return self
end

init(logging)

logging.__index = logging

function logging.new(module)
	return init(setmetatable({}, logging),module)
end
return logging
