(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.ae.P === region.an.P)
	{
		return 'on line ' + region.ae.P;
	}
	return 'on lines ' + region.ae.P + ' through ' + region.an.P;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.a1,
		impl.bg,
		impl.bb,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS


function _VirtualDom_noScript(tag)
{
	return tag == 'script' ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return /^(on|formAction$)/i.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,'')) ? '' : value;
}

function _VirtualDom_noJavaScriptUri_UNUSED(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,''))
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value) ? '' : value;
}

function _VirtualDom_noJavaScriptOrHtmlUri_UNUSED(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value)
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		u: func(record.u),
		af: record.af,
		ab: record.ab
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.u;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.af;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.ab) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.a1,
		impl.bg,
		impl.bb,
		function(sendToApp, initialModel) {
			var view = impl.bh;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.a1,
		impl.bg,
		impl.bb,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.ac && impl.ac(sendToApp)
			var view = impl.bh;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.aT);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.be) && (_VirtualDom_doc.title = title = doc.be);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.a3;
	var onUrlRequest = impl.a4;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		ac: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.aC === next.aC
							&& curr.ar === next.ar
							&& curr.az.a === next.az.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		a1: function(flags)
		{
			return A3(impl.a1, flags, _Browser_getUrl(), key);
		},
		bh: impl.bh,
		bg: impl.bg,
		bb: impl.bb
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { a_: 'hidden', aV: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { a_: 'mozHidden', aV: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { a_: 'msHidden', aV: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { a_: 'webkitHidden', aV: 'webkitvisibilitychange' }
		: { a_: 'hidden', aV: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		aG: _Browser_getScene(),
		aN: {
			ag: _Browser_window.pageXOffset,
			ah: _Browser_window.pageYOffset,
			aO: _Browser_doc.documentElement.clientWidth,
			aq: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		aO: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		aq: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			aG: {
				aO: node.scrollWidth,
				aq: node.scrollHeight
			},
			aN: {
				ag: node.scrollLeft,
				ah: node.scrollTop,
				aO: node.clientWidth,
				aq: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			aG: _Browser_getScene(),
			aN: {
				ag: x,
				ah: y,
				aO: _Browser_doc.documentElement.clientWidth,
				aq: _Browser_doc.documentElement.clientHeight
			},
			aY: {
				ag: x + rect.left,
				ah: y + rect.top,
				aO: rect.width,
				aq: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.b) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.c),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.c);
		} else {
			var treeLen = builder.b * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.d) : builder.d;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.b);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.c) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.c);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{d: nodeList, b: (len / $elm$core$Array$branchFactor) | 0, c: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {ap: fragment, ar: host, ax: path, az: port_, aC: protocol, aD: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$GameModel$Error = function (a) {
	return {$: 0, a: a};
};
var $author$project$GameModel$Title = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Main$Flags = F2(
	function (scores, seed) {
		return {D: scores, g: seed};
	});
var $author$project$Game$ScoreRow = F4(
	function (score, run, totalScore, active) {
		return {aQ: active, a7: run, a8: score, bf: totalScore};
	});
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $author$project$Game$Score = $elm$core$Basics$identity;
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$Ports$decodeScore = A2($elm$json$Json$Decode$map, $elm$core$Basics$identity, $elm$json$Json$Decode$int);
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$map4 = _Json_map4;
var $author$project$Ports$decodeScoreRow = A5(
	$elm$json$Json$Decode$map4,
	$author$project$Game$ScoreRow,
	A2($elm$json$Json$Decode$field, 'score', $author$project$Ports$decodeScore),
	A2($elm$json$Json$Decode$field, 'run', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'totalScore', $author$project$Ports$decodeScore),
	A2($elm$json$Json$Decode$field, 'active', $elm$json$Json$Decode$bool));
var $elm$json$Json$Decode$list = _Json_decodeList;
var $author$project$Ports$decodeScoreRows = $elm$json$Json$Decode$list($author$project$Ports$decodeScoreRow);
var $author$project$Main$decodeFlags = A3(
	$elm$json$Json$Decode$map2,
	$author$project$Main$Flags,
	A2($elm$json$Json$Decode$field, 'scores', $author$project$Ports$decodeScoreRows),
	A2($elm$json$Json$Decode$field, 'seed', $elm$json$Json$Decode$int));
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $elm$random$Random$Seed = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$random$Random$next = function (_v0) {
	var state0 = _v0.a;
	var incr = _v0.b;
	return A2($elm$random$Random$Seed, ((state0 * 1664525) + incr) >>> 0, incr);
};
var $elm$random$Random$initialSeed = function (x) {
	var _v0 = $elm$random$Random$next(
		A2($elm$random$Random$Seed, 0, 1013904223));
	var state1 = _v0.a;
	var incr = _v0.b;
	var state2 = (state1 + x) >>> 0;
	return $elm$random$Random$next(
		A2($elm$random$Random$Seed, state2, incr));
};
var $elm$core$Elm$JsArray$map = _JsArray_map;
var $elm$core$Array$map = F2(
	function (func, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = function (node) {
			if (!node.$) {
				var subTree = node.a;
				return $elm$core$Array$SubTree(
					A2($elm$core$Elm$JsArray$map, helper, subTree));
			} else {
				var values = node.a;
				return $elm$core$Array$Leaf(
					A2($elm$core$Elm$JsArray$map, func, values));
			}
		};
		return A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			A2($elm$core$Elm$JsArray$map, helper, tree),
			A2($elm$core$Elm$JsArray$map, func, tail));
	});
var $elm$core$Elm$JsArray$foldl = _JsArray_foldl;
var $elm$core$Array$foldl = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldl, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldl, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldl,
			func,
			A3($elm$core$Elm$JsArray$foldl, helper, baseCase, tree),
			tail);
	});
var $elm$json$Json$Encode$array = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$Array$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $author$project$Ports$platform = _Platform_outgoingPort(
	'platform',
	$elm$json$Json$Encode$array($elm$core$Basics$identity));
var $author$project$Ports$perform = function (records) {
	return $author$project$Ports$platform(
		A2(
			$elm$core$Array$map,
			function (cr) {
				var v = cr;
				return v;
			},
			records));
};
var $author$project$Game$H = $elm$core$Basics$identity;
var $author$project$Game$numTiles = 9;
var $author$project$Game$tileSize = 64;
var $author$project$Game$pixelHeight = $author$project$Game$tileSize * $author$project$Game$numTiles;
var $author$project$Game$W = $elm$core$Basics$identity;
var $author$project$Game$uiWidth = 4;
var $author$project$Game$pixelUIWidth = $author$project$Game$tileSize * $author$project$Game$uiWidth;
var $author$project$Game$pixelWidth = $author$project$Game$tileSize * ($author$project$Game$numTiles + $author$project$Game$uiWidth);
var $elm$core$Array$repeat = F2(
	function (n, e) {
		return A2(
			$elm$core$Array$initialize,
			n,
			function (_v0) {
				return e;
			});
	});
var $author$project$Ports$CommandRecord = $elm$core$Basics$identity;
var $elm$json$Json$Encode$float = _Json_wrap;
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Ports$setCanvasDimensions = function (dimensions) {
	var w = dimensions.a;
	var h = dimensions.b;
	var uiWidth = dimensions.c;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'kind',
				$elm$json$Json$Encode$string('setCanvasDimensions')),
				_Utils_Tuple2(
				'w',
				$elm$json$Json$Encode$float(w)),
				_Utils_Tuple2(
				'h',
				$elm$json$Json$Encode$float(h)),
				_Utils_Tuple2(
				'uiW',
				$elm$json$Json$Encode$float(uiWidth))
			]));
};
var $author$project$Main$init = function (flags) {
	return _Utils_Tuple2(
		function () {
			var _v0 = A2($elm$json$Json$Decode$decodeValue, $author$project$Main$decodeFlags, flags);
			if (!_v0.$) {
				var seed = _v0.a.g;
				var scores = _v0.a.D;
				return {
					t: A2(
						$author$project$GameModel$Title,
						$elm$core$Maybe$Nothing,
						$elm$random$Random$initialSeed(seed)),
					D: scores
				};
			} else {
				var error = _v0.a;
				return {
					t: $author$project$GameModel$Error(
						'Error decoding flags: ' + $elm$json$Json$Decode$errorToString(error)),
					D: _List_Nil
				};
			}
		}(),
		$author$project$Ports$perform(
			A2(
				$elm$core$Array$repeat,
				1,
				$author$project$Ports$setCanvasDimensions(
					_Utils_Tuple3($author$project$Game$pixelWidth, $author$project$Game$pixelHeight, $author$project$Game$pixelUIWidth)))));
};
var $author$project$Main$ScoreRows = function (a) {
	return {$: 2, a: a};
};
var $author$project$Main$Tick = {$: 0};
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$browser$Browser$AnimationManager$Time = function (a) {
	return {$: 0, a: a};
};
var $elm$browser$Browser$AnimationManager$State = F3(
	function (subs, request, oldTime) {
		return {aa: oldTime, aF: request, aK: subs};
	});
var $elm$browser$Browser$AnimationManager$init = $elm$core$Task$succeed(
	A3($elm$browser$Browser$AnimationManager$State, _List_Nil, $elm$core$Maybe$Nothing, 0));
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$browser$Browser$AnimationManager$now = _Browser_now(0);
var $elm$browser$Browser$AnimationManager$rAF = _Browser_rAF(0);
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$browser$Browser$AnimationManager$onEffects = F3(
	function (router, subs, _v0) {
		var request = _v0.aF;
		var oldTime = _v0.aa;
		var _v1 = _Utils_Tuple2(request, subs);
		if (_v1.a.$ === 1) {
			if (!_v1.b.b) {
				var _v2 = _v1.a;
				return $elm$browser$Browser$AnimationManager$init;
			} else {
				var _v4 = _v1.a;
				return A2(
					$elm$core$Task$andThen,
					function (pid) {
						return A2(
							$elm$core$Task$andThen,
							function (time) {
								return $elm$core$Task$succeed(
									A3(
										$elm$browser$Browser$AnimationManager$State,
										subs,
										$elm$core$Maybe$Just(pid),
										time));
							},
							$elm$browser$Browser$AnimationManager$now);
					},
					$elm$core$Process$spawn(
						A2(
							$elm$core$Task$andThen,
							$elm$core$Platform$sendToSelf(router),
							$elm$browser$Browser$AnimationManager$rAF)));
			}
		} else {
			if (!_v1.b.b) {
				var pid = _v1.a.a;
				return A2(
					$elm$core$Task$andThen,
					function (_v3) {
						return $elm$browser$Browser$AnimationManager$init;
					},
					$elm$core$Process$kill(pid));
			} else {
				return $elm$core$Task$succeed(
					A3($elm$browser$Browser$AnimationManager$State, subs, request, oldTime));
			}
		}
	});
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$browser$Browser$AnimationManager$onSelfMsg = F3(
	function (router, newTime, _v0) {
		var subs = _v0.aK;
		var oldTime = _v0.aa;
		var send = function (sub) {
			if (!sub.$) {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(
						$elm$time$Time$millisToPosix(newTime)));
			} else {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(newTime - oldTime));
			}
		};
		return A2(
			$elm$core$Task$andThen,
			function (pid) {
				return A2(
					$elm$core$Task$andThen,
					function (_v1) {
						return $elm$core$Task$succeed(
							A3(
								$elm$browser$Browser$AnimationManager$State,
								subs,
								$elm$core$Maybe$Just(pid),
								newTime));
					},
					$elm$core$Task$sequence(
						A2($elm$core$List$map, send, subs)));
			},
			$elm$core$Process$spawn(
				A2(
					$elm$core$Task$andThen,
					$elm$core$Platform$sendToSelf(router),
					$elm$browser$Browser$AnimationManager$rAF)));
	});
var $elm$browser$Browser$AnimationManager$Delta = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$browser$Browser$AnimationManager$subMap = F2(
	function (func, sub) {
		if (!sub.$) {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Time(
				A2($elm$core$Basics$composeL, func, tagger));
		} else {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Delta(
				A2($elm$core$Basics$composeL, func, tagger));
		}
	});
_Platform_effectManagers['Browser.AnimationManager'] = _Platform_createManager($elm$browser$Browser$AnimationManager$init, $elm$browser$Browser$AnimationManager$onEffects, $elm$browser$Browser$AnimationManager$onSelfMsg, 0, $elm$browser$Browser$AnimationManager$subMap);
var $elm$browser$Browser$AnimationManager$subscription = _Platform_leaf('Browser.AnimationManager');
var $elm$browser$Browser$AnimationManager$onAnimationFrame = function (tagger) {
	return $elm$browser$Browser$AnimationManager$subscription(
		$elm$browser$Browser$AnimationManager$Time(tagger));
};
var $elm$browser$Browser$Events$onAnimationFrame = $elm$browser$Browser$AnimationManager$onAnimationFrame;
var $elm$browser$Browser$Events$Document = 0;
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {ay: pids, aK: subs};
	});
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (!node) {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === -2) {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {ao: event, at: key};
	});
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (!node) {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.ay,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.at;
		var event = _v0.ao;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.aK);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onKeyDown = A2($elm$browser$Browser$Events$on, 0, 'keydown');
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Ports$scores = _Platform_incomingPort('scores', $elm$json$Json$Decode$value);
var $author$project$Ports$scoreList = function (toMsg) {
	return $author$project$Ports$scores(
		A2(
			$elm$core$Basics$composeR,
			$elm$json$Json$Decode$decodeValue($author$project$Ports$decodeScoreRows),
			toMsg));
};
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Main$CastSpell = function (a) {
	return {$: 5, a: a};
};
var $author$project$Main$Down = {$: 2};
var $author$project$GameModel$Eight = 7;
var $author$project$GameModel$Five = 4;
var $author$project$GameModel$Four = 3;
var $author$project$Main$Input = function (a) {
	return {$: 1, a: a};
};
var $author$project$Main$Left = {$: 3};
var $author$project$GameModel$Nine = 8;
var $author$project$GameModel$One = 0;
var $author$project$Main$Other = {$: 0};
var $author$project$Main$Right = {$: 4};
var $author$project$GameModel$Seven = 6;
var $author$project$GameModel$Six = 5;
var $author$project$GameModel$Three = 2;
var $author$project$GameModel$Two = 1;
var $author$project$Main$Up = {$: 1};
var $author$project$Main$toInput = function (s) {
	return $author$project$Main$Input(
		function () {
			switch (s) {
				case 'ArrowUp':
					return $author$project$Main$Up;
				case 'w':
					return $author$project$Main$Up;
				case 'ArrowDown':
					return $author$project$Main$Down;
				case 's':
					return $author$project$Main$Down;
				case 'ArrowLeft':
					return $author$project$Main$Left;
				case 'a':
					return $author$project$Main$Left;
				case 'ArrowRight':
					return $author$project$Main$Right;
				case 'd':
					return $author$project$Main$Right;
				case '1':
					return $author$project$Main$CastSpell(0);
				case '2':
					return $author$project$Main$CastSpell(1);
				case '3':
					return $author$project$Main$CastSpell(2);
				case '4':
					return $author$project$Main$CastSpell(3);
				case '5':
					return $author$project$Main$CastSpell(4);
				case '6':
					return $author$project$Main$CastSpell(5);
				case '7':
					return $author$project$Main$CastSpell(6);
				case '8':
					return $author$project$Main$CastSpell(7);
				case '9':
					return $author$project$Main$CastSpell(8);
				default:
					return $author$project$Main$Other;
			}
		}());
};
var $author$project$Main$subscriptions = function (_v0) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$elm$browser$Browser$Events$onAnimationFrame(
				function (_v1) {
					return $author$project$Main$Tick;
				}),
				$elm$browser$Browser$Events$onKeyDown(
				A2(
					$elm$json$Json$Decode$map,
					$author$project$Main$toInput,
					A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string))),
				$author$project$Ports$scoreList($author$project$Main$ScoreRows)
			]));
};
var $elm$core$Elm$JsArray$appendN = _JsArray_appendN;
var $elm$core$Elm$JsArray$slice = _JsArray_slice;
var $elm$core$Array$appendHelpBuilder = F2(
	function (tail, builder) {
		var tailLen = $elm$core$Elm$JsArray$length(tail);
		var notAppended = ($elm$core$Array$branchFactor - $elm$core$Elm$JsArray$length(builder.c)) - tailLen;
		var appended = A3($elm$core$Elm$JsArray$appendN, $elm$core$Array$branchFactor, builder.c, tail);
		return (notAppended < 0) ? {
			d: A2(
				$elm$core$List$cons,
				$elm$core$Array$Leaf(appended),
				builder.d),
			b: builder.b + 1,
			c: A3($elm$core$Elm$JsArray$slice, notAppended, tailLen, tail)
		} : ((!notAppended) ? {
			d: A2(
				$elm$core$List$cons,
				$elm$core$Array$Leaf(appended),
				builder.d),
			b: builder.b + 1,
			c: $elm$core$Elm$JsArray$empty
		} : {d: builder.d, b: builder.b, c: appended});
	});
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Array$bitMask = 4294967295 >>> (32 - $elm$core$Array$shiftStep);
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$Elm$JsArray$push = _JsArray_push;
var $elm$core$Elm$JsArray$singleton = _JsArray_singleton;
var $elm$core$Elm$JsArray$unsafeGet = _JsArray_unsafeGet;
var $elm$core$Elm$JsArray$unsafeSet = _JsArray_unsafeSet;
var $elm$core$Array$insertTailInTree = F4(
	function (shift, index, tail, tree) {
		var pos = $elm$core$Array$bitMask & (index >>> shift);
		if (_Utils_cmp(
			pos,
			$elm$core$Elm$JsArray$length(tree)) > -1) {
			if (shift === 5) {
				return A2(
					$elm$core$Elm$JsArray$push,
					$elm$core$Array$Leaf(tail),
					tree);
			} else {
				var newSub = $elm$core$Array$SubTree(
					A4($elm$core$Array$insertTailInTree, shift - $elm$core$Array$shiftStep, index, tail, $elm$core$Elm$JsArray$empty));
				return A2($elm$core$Elm$JsArray$push, newSub, tree);
			}
		} else {
			var value = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (!value.$) {
				var subTree = value.a;
				var newSub = $elm$core$Array$SubTree(
					A4($elm$core$Array$insertTailInTree, shift - $elm$core$Array$shiftStep, index, tail, subTree));
				return A3($elm$core$Elm$JsArray$unsafeSet, pos, newSub, tree);
			} else {
				var newSub = $elm$core$Array$SubTree(
					A4(
						$elm$core$Array$insertTailInTree,
						shift - $elm$core$Array$shiftStep,
						index,
						tail,
						$elm$core$Elm$JsArray$singleton(value)));
				return A3($elm$core$Elm$JsArray$unsafeSet, pos, newSub, tree);
			}
		}
	});
var $elm$core$Bitwise$shiftLeftBy = _Bitwise_shiftLeftBy;
var $elm$core$Array$unsafeReplaceTail = F2(
	function (newTail, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		var originalTailLen = $elm$core$Elm$JsArray$length(tail);
		var newTailLen = $elm$core$Elm$JsArray$length(newTail);
		var newArrayLen = len + (newTailLen - originalTailLen);
		if (_Utils_eq(newTailLen, $elm$core$Array$branchFactor)) {
			var overflow = _Utils_cmp(newArrayLen >>> $elm$core$Array$shiftStep, 1 << startShift) > 0;
			if (overflow) {
				var newShift = startShift + $elm$core$Array$shiftStep;
				var newTree = A4(
					$elm$core$Array$insertTailInTree,
					newShift,
					len,
					newTail,
					$elm$core$Elm$JsArray$singleton(
						$elm$core$Array$SubTree(tree)));
				return A4($elm$core$Array$Array_elm_builtin, newArrayLen, newShift, newTree, $elm$core$Elm$JsArray$empty);
			} else {
				return A4(
					$elm$core$Array$Array_elm_builtin,
					newArrayLen,
					startShift,
					A4($elm$core$Array$insertTailInTree, startShift, len, newTail, tree),
					$elm$core$Elm$JsArray$empty);
			}
		} else {
			return A4($elm$core$Array$Array_elm_builtin, newArrayLen, startShift, tree, newTail);
		}
	});
var $elm$core$Array$appendHelpTree = F2(
	function (toAppend, array) {
		var len = array.a;
		var tree = array.c;
		var tail = array.d;
		var itemsToAppend = $elm$core$Elm$JsArray$length(toAppend);
		var notAppended = ($elm$core$Array$branchFactor - $elm$core$Elm$JsArray$length(tail)) - itemsToAppend;
		var appended = A3($elm$core$Elm$JsArray$appendN, $elm$core$Array$branchFactor, tail, toAppend);
		var newArray = A2($elm$core$Array$unsafeReplaceTail, appended, array);
		if (notAppended < 0) {
			var nextTail = A3($elm$core$Elm$JsArray$slice, notAppended, itemsToAppend, toAppend);
			return A2($elm$core$Array$unsafeReplaceTail, nextTail, newArray);
		} else {
			return newArray;
		}
	});
var $elm$core$Array$builderFromArray = function (_v0) {
	var len = _v0.a;
	var tree = _v0.c;
	var tail = _v0.d;
	var helper = F2(
		function (node, acc) {
			if (!node.$) {
				var subTree = node.a;
				return A3($elm$core$Elm$JsArray$foldl, helper, acc, subTree);
			} else {
				return A2($elm$core$List$cons, node, acc);
			}
		});
	return {
		d: A3($elm$core$Elm$JsArray$foldl, helper, _List_Nil, tree),
		b: (len / $elm$core$Array$branchFactor) | 0,
		c: tail
	};
};
var $elm$core$Array$append = F2(
	function (a, _v0) {
		var aTail = a.d;
		var bLen = _v0.a;
		var bTree = _v0.c;
		var bTail = _v0.d;
		if (_Utils_cmp(bLen, $elm$core$Array$branchFactor * 4) < 1) {
			var foldHelper = F2(
				function (node, array) {
					if (!node.$) {
						var tree = node.a;
						return A3($elm$core$Elm$JsArray$foldl, foldHelper, array, tree);
					} else {
						var leaf = node.a;
						return A2($elm$core$Array$appendHelpTree, leaf, array);
					}
				});
			return A2(
				$elm$core$Array$appendHelpTree,
				bTail,
				A3($elm$core$Elm$JsArray$foldl, foldHelper, a, bTree));
		} else {
			var foldHelper = F2(
				function (node, builder) {
					if (!node.$) {
						var tree = node.a;
						return A3($elm$core$Elm$JsArray$foldl, foldHelper, builder, tree);
					} else {
						var leaf = node.a;
						return A2($elm$core$Array$appendHelpBuilder, leaf, builder);
					}
				});
			return A2(
				$elm$core$Array$builderToArray,
				true,
				A2(
					$elm$core$Array$appendHelpBuilder,
					bTail,
					A3(
						$elm$core$Elm$JsArray$foldl,
						foldHelper,
						$elm$core$Array$builderFromArray(a),
						bTree)));
		}
	});
var $author$project$GameModel$Dead = function (a) {
	return {$: 3, a: a};
};
var $author$project$GameModel$Running = function (a) {
	return {$: 2, a: a};
};
var $author$project$Ports$drawOverlay = $elm$json$Json$Encode$object(
	_List_fromArray(
		[
			_Utils_Tuple2(
			'kind',
			$elm$json$Json$Encode$string('drawOverlay'))
		]));
var $author$project$Ports$Violet = 1;
var $author$project$Game$Y = $elm$core$Basics$identity;
var $author$project$Game$SpriteIndex = $elm$core$Basics$identity;
var $author$project$Game$X = $elm$core$Basics$identity;
var $elm$json$Json$Encode$int = _Json_wrap;
var $author$project$Ports$drawSpriteAlpha = F4(
	function (alpha, shake, _v0, spriteIndex) {
		var x = _v0.ag;
		var y = _v0.ah;
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'kind',
					$elm$json$Json$Encode$string('drawSprite')),
					_Utils_Tuple2(
					'alpha',
					$elm$json$Json$Encode$float(alpha)),
					_Utils_Tuple2(
					'sprite',
					function () {
						var sprite = spriteIndex;
						return $elm$json$Json$Encode$int(sprite);
					}()),
					_Utils_Tuple2(
					'x',
					function () {
						var _v2 = _Utils_Tuple2(x, shake.ag);
						var bareX = _v2.a;
						var sX = _v2.b;
						return $elm$json$Json$Encode$float((bareX * $author$project$Game$tileSize) + sX);
					}()),
					_Utils_Tuple2(
					'y',
					function () {
						var _v3 = _Utils_Tuple2(y, shake.ah);
						var bareY = _v3.a;
						var sY = _v3.b;
						return $elm$json$Json$Encode$float((bareY * $author$project$Game$tileSize) + sY);
					}()),
					_Utils_Tuple2(
					'tileSize',
					$elm$json$Json$Encode$float($author$project$Game$tileSize))
				]));
	});
var $author$project$Ports$drawSprite = $author$project$Ports$drawSpriteAlpha(1.0);
var $elm$core$Basics$modBy = _Basics_modBy;
var $elm$core$Array$push = F2(
	function (a, array) {
		var tail = array.d;
		return A2(
			$elm$core$Array$unsafeReplaceTail,
			A2($elm$core$Elm$JsArray$push, a, tail),
			array);
	});
var $author$project$Monster$drawHP = F5(
	function (skake, monster, hp, i, commands) {
		if (_Utils_cmp(i, hp) > -1) {
			return commands;
		} else {
			var _v0 = _Utils_Tuple2(monster.ag, monster.ah);
			var x = _v0.a;
			var y = _v0.b;
			var hpY = y - ($elm$core$Basics$floor(i / 3) * (5 / 16));
			var hpX = x + (A2(
				$elm$core$Basics$modBy,
				3,
				$elm$core$Basics$floor(i)) * (5 / 16));
			var hpCommand = A3(
				$author$project$Ports$drawSprite,
				skake,
				{ag: hpX, ah: hpY},
				9);
			return A5(
				$author$project$Monster$drawHP,
				skake,
				monster,
				hp,
				i + 1,
				A2($elm$core$Array$push, hpCommand, commands));
		}
	});
var $author$project$Monster$getLocated = function (_v0) {
	var offsetX = _v0.U;
	var offsetY = _v0.V;
	var xPos = _v0.L;
	var yPos = _v0.M;
	var _v1 = _Utils_Tuple2(
		_Utils_Tuple2(offsetX, offsetY),
		_Utils_Tuple2(xPos, yPos));
	var _v2 = _v1.a;
	var ox = _v2.a;
	var oy = _v2.b;
	var _v3 = _v1.b;
	var xP = _v3.a;
	var yP = _v3.b;
	return {ag: ox + xP, ah: oy + yP};
};
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $author$project$Monster$signum = function (x) {
	return (x > 0) ? 1.0 : ((x < 0) ? (-1.0) : 0.0);
};
var $author$project$Monster$draw = F2(
	function (shake, _v0) {
		var monster = _v0.a;
		var cmdsIn = _v0.b;
		var located = $author$project$Monster$getLocated(monster);
		return _Utils_Tuple2(
			_Utils_update(
				monster,
				{
					U: function () {
						var _v1 = monster.U;
						var x = _v1;
						return x - ((1.0 / 8.0) * $author$project$Monster$signum(x));
					}(),
					V: function () {
						var _v2 = monster.V;
						var y = _v2;
						return y - ((1.0 / 8.0) * $author$project$Monster$signum(y));
					}()
				}),
			function () {
				if (monster.bd > 0) {
					return A2(
						$elm$core$Array$push,
						A3($author$project$Ports$drawSprite, shake, located, 10),
						cmdsIn);
				} else {
					var commands = A2(
						$elm$core$Array$push,
						A3($author$project$Ports$drawSprite, shake, located, monster.ad),
						cmdsIn);
					var _v3 = monster.a$;
					var hp = _v3;
					return A5($author$project$Monster$drawHP, shake, located, hp, 0, commands);
				}
			}());
	});
var $author$project$Tiles$filterOutNothings = A2(
	$elm$core$Array$foldl,
	F2(
		function (maybe, acc) {
			if (!maybe.$) {
				var x = maybe.a;
				return A2($elm$core$Array$push, x, acc);
			} else {
				return acc;
			}
		}),
	$elm$core$Array$empty);
var $author$project$Tiles$foldMonsters = F3(
	function (folder, acc, tiles) {
		var ts = tiles;
		return A3(
			$elm$core$Array$foldl,
			folder,
			acc,
			$author$project$Tiles$filterOutNothings(
				A2(
					$elm$core$Array$map,
					function ($) {
						return $.e;
					},
					ts)));
	});
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Array$getHelp = F3(
	function (shift, index, tree) {
		getHelp:
		while (true) {
			var pos = $elm$core$Array$bitMask & (index >>> shift);
			var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (!_v0.$) {
				var subTree = _v0.a;
				var $temp$shift = shift - $elm$core$Array$shiftStep,
					$temp$index = index,
					$temp$tree = subTree;
				shift = $temp$shift;
				index = $temp$index;
				tree = $temp$tree;
				continue getHelp;
			} else {
				var values = _v0.a;
				return A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, values);
			}
		}
	});
var $elm$core$Array$tailIndex = function (len) {
	return (len >>> 5) << 5;
};
var $elm$core$Array$get = F2(
	function (index, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? $elm$core$Maybe$Nothing : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? $elm$core$Maybe$Just(
			A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, tail)) : $elm$core$Maybe$Just(
			A3($elm$core$Array$getHelp, startShift, index, tree)));
	});
var $author$project$Tiles$inBounds = function (xy) {
	var _v0 = _Utils_Tuple2(xy.L, xy.M);
	var x = _v0.a;
	var y = _v0.b;
	return (x > 0) && ((y > 0) && ((_Utils_cmp(x, $author$project$Game$numTiles - 1) < 0) && (_Utils_cmp(y, $author$project$Game$numTiles - 1) < 0)));
};
var $author$project$Tiles$toIndex = function (xy) {
	return $author$project$Tiles$inBounds(xy) ? $elm$core$Maybe$Just(
		function () {
			var _v0 = _Utils_Tuple2(xy.L, xy.M);
			var x = _v0.a;
			var y = _v0.b;
			return (y * $author$project$Game$numTiles) + x;
		}()) : $elm$core$Maybe$Nothing;
};
var $author$project$Tile$Wall = 1;
var $author$project$Tile$withKind = F2(
	function (kind, _v0) {
		var xPos = _v0.L;
		var yPos = _v0.M;
		return {O: $elm$core$Maybe$Nothing, I: kind, e: $elm$core$Maybe$Nothing, aM: false, L: xPos, M: yPos};
	});
var $author$project$Tile$wall = $author$project$Tile$withKind(1);
var $author$project$Tiles$get = F2(
	function (tiles, xy) {
		var ts = tiles;
		var m = A2(
			$elm$core$Maybe$andThen,
			function (i) {
				return A2($elm$core$Array$get, i, ts);
			},
			$author$project$Tiles$toIndex(xy));
		if (!m.$) {
			var t = m.a;
			return t;
		} else {
			return $author$project$Tile$wall(xy);
		}
	});
var $author$project$Tiles$Tiles = $elm$core$Basics$identity;
var $elm$core$Array$setHelp = F4(
	function (shift, index, value, tree) {
		var pos = $elm$core$Array$bitMask & (index >>> shift);
		var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
		if (!_v0.$) {
			var subTree = _v0.a;
			var newSub = A4($elm$core$Array$setHelp, shift - $elm$core$Array$shiftStep, index, value, subTree);
			return A3(
				$elm$core$Elm$JsArray$unsafeSet,
				pos,
				$elm$core$Array$SubTree(newSub),
				tree);
		} else {
			var values = _v0.a;
			var newLeaf = A3($elm$core$Elm$JsArray$unsafeSet, $elm$core$Array$bitMask & index, value, values);
			return A3(
				$elm$core$Elm$JsArray$unsafeSet,
				pos,
				$elm$core$Array$Leaf(newLeaf),
				tree);
		}
	});
var $elm$core$Array$set = F3(
	function (index, value, array) {
		var len = array.a;
		var startShift = array.b;
		var tree = array.c;
		var tail = array.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? array : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			tree,
			A3($elm$core$Elm$JsArray$unsafeSet, $elm$core$Array$bitMask & index, value, tail)) : A4(
			$elm$core$Array$Array_elm_builtin,
			len,
			startShift,
			A4($elm$core$Array$setHelp, startShift, index, value, tree),
			tail));
	});
var $author$project$Tiles$set = F2(
	function (tile, tiles) {
		var ts = tiles;
		var _v1 = $author$project$Tiles$toIndex(tile);
		if (!_v1.$) {
			var i = _v1.a;
			return A3($elm$core$Array$set, i, tile, ts);
		} else {
			return ts;
		}
	});
var $author$project$Tiles$transform = F3(
	function (transformer, positioned, tiles) {
		return A2(
			$author$project$Tiles$set,
			transformer(
				A2($author$project$Tiles$get, tiles, positioned)),
			tiles);
	});
var $author$project$Main$drawMonsters = F2(
	function (shake, _v0) {
		var tiles = _v0.a;
		var cmds = _v0.b;
		return A3(
			$author$project$Tiles$foldMonsters,
			F2(
				function (monster, _v1) {
					var ts = _v1.a;
					var oldCmds = _v1.b;
					var _v2 = A2(
						$author$project$Monster$draw,
						shake,
						_Utils_Tuple2(monster, oldCmds));
					var newMonster = _v2.a;
					var newCmds = _v2.b;
					return _Utils_Tuple2(
						A3(
							$author$project$Tiles$transform,
							function (tile) {
								return _Utils_update(
									tile,
									{
										e: $elm$core$Maybe$Just(newMonster)
									});
							},
							newMonster,
							ts),
						newCmds);
				}),
			_Utils_Tuple2(tiles, cmds),
			tiles);
	});
var $author$project$Tile$Effect = F2(
	function (index, counter) {
		return {ak: counter, as: index};
	});
var $author$project$Tile$getLocated = function (_v0) {
	var xPos = _v0.L;
	var yPos = _v0.M;
	var _v1 = _Utils_Tuple2(xPos, yPos);
	var xP = _v1.a;
	var yP = _v1.b;
	return {ag: xP, ah: yP};
};
var $author$project$Tile$maxEffectCount = 30;
var $author$project$Tile$sprite = function (kind) {
	switch (kind) {
		case 0:
			return 2;
		case 1:
			return 3;
		default:
			return 11;
	}
};
var $author$project$Tile$draw = F2(
	function (shake, _v0) {
		var tile = _v0.a;
		var commandsIn = _v0.b;
		var located = $author$project$Tile$getLocated(tile);
		var drawTreasure = function (cmds) {
			return tile.aM ? A2(
				$elm$core$Array$push,
				A3($author$project$Ports$drawSprite, shake, located, 12),
				cmds) : cmds;
		};
		var commands = drawTreasure(
			A2(
				$elm$core$Array$push,
				A3(
					$author$project$Ports$drawSprite,
					shake,
					located,
					$author$project$Tile$sprite(tile.I)),
				commandsIn));
		var _v1 = tile.O;
		if (!_v1.$) {
			var index = _v1.a.as;
			var counter = _v1.a.ak;
			if (counter <= 0) {
				return _Utils_Tuple2(
					_Utils_update(
						tile,
						{O: $elm$core$Maybe$Nothing}),
					commands);
			} else {
				var alpha = counter / $author$project$Tile$maxEffectCount;
				return _Utils_Tuple2(
					_Utils_update(
						tile,
						{
							O: $elm$core$Maybe$Just(
								A2($author$project$Tile$Effect, index, counter - 1))
						}),
					A2(
						$elm$core$Array$push,
						A4($author$project$Ports$drawSpriteAlpha, alpha, shake, located, index),
						commands));
			}
		} else {
			return _Utils_Tuple2(tile, commands);
		}
	});
var $author$project$Game$XPos = $elm$core$Basics$identity;
var $author$project$Game$YPos = $elm$core$Basics$identity;
var $author$project$Tiles$allLocations = A3(
	$elm$core$List$foldr,
	F2(
		function (y, yAcc) {
			return A3(
				$elm$core$List$foldr,
				F2(
					function (x, xAcc) {
						return A2(
							$elm$core$List$cons,
							{L: x, M: y},
							xAcc);
					}),
				yAcc,
				A2($elm$core$List$range, 0, $author$project$Game$numTiles - 1));
		}),
	_List_Nil,
	A2($elm$core$List$range, 0, $author$project$Game$numTiles - 1));
var $author$project$Tiles$foldXY = F2(
	function (folder, initial) {
		return A3($elm$core$List$foldl, folder, initial, $author$project$Tiles$allLocations);
	});
var $author$project$Main$drawTiles = function (shake) {
	return $author$project$Tiles$foldXY(
		F2(
			function (xy, _v0) {
				var tiles = _v0.a;
				var oldCmds = _v0.b;
				var tile = A2($author$project$Tiles$get, tiles, xy);
				var _v1 = A2(
					$author$project$Tile$draw,
					shake,
					_Utils_Tuple2(tile, oldCmds));
				var newTile = _v1.a;
				var newCmds = _v1.b;
				return _Utils_Tuple2(
					A3(
						$author$project$Tiles$transform,
						function (_v2) {
							return newTile;
						},
						newTile,
						tiles),
					newCmds);
			}));
};
var $author$project$Game$levelNumToString = function (levelNum) {
	var l = levelNum;
	return $elm$core$String$fromInt(l);
};
var $author$project$Ports$noCmds = $elm$core$Array$empty;
var $author$project$Ports$Aqua = 2;
var $elm$json$Json$Encode$bool = _Json_wrap;
var $author$project$Ports$drawText = function (_v0) {
	var text = _v0.F;
	var size = _v0.E;
	var centered = _v0.x;
	var y = _v0.ah;
	var colour = _v0.y;
	var textY = y;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'kind',
				$elm$json$Json$Encode$string('drawText')),
				_Utils_Tuple2(
				'text',
				$elm$json$Json$Encode$string(text)),
				_Utils_Tuple2(
				'size',
				$elm$json$Json$Encode$int(size)),
				_Utils_Tuple2(
				'centered',
				$elm$json$Json$Encode$bool(centered)),
				_Utils_Tuple2(
				'textY',
				$elm$json$Json$Encode$float(textY)),
				_Utils_Tuple2(
				'colour',
				$elm$json$Json$Encode$string(
					function () {
						switch (colour) {
							case 0:
								return 'white';
							case 1:
								return 'violet';
							default:
								return 'aqua';
						}
					}()))
			]));
};
var $author$project$Main$pushText = function (textSpec) {
	return $elm$core$Array$push(
		$author$project$Ports$drawText(textSpec));
};
var $author$project$GameModel$spellNameToString = function (name) {
	switch (name) {
		case 0:
			return 'WOOP';
		case 1:
			return 'QUAKE';
		case 2:
			return 'MAELSTROM';
		case 3:
			return 'MULLIGAN';
		case 4:
			return 'AURA';
		case 5:
			return 'DASH';
		case 6:
			return 'DIG';
		case 7:
			return 'KINGMAKER';
		case 8:
			return 'ALCHEMY';
		case 9:
			return 'POWER';
		case 10:
			return 'BUBBLE';
		case 11:
			return 'BRAVERY';
		case 12:
			return 'BOLT';
		case 13:
			return 'CROSS';
		default:
			return 'EX';
	}
};
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $author$project$GameModel$getPair = F2(
	function (key, spells) {
		return _Utils_Tuple2(
			key,
			A2($elm$core$Dict$get, key, spells));
	});
var $author$project$GameModel$spellNamesWithOneBasedIndex = function (book) {
	var spells = book;
	return _List_fromArray(
		[
			A2($author$project$GameModel$getPair, 1, spells),
			A2($author$project$GameModel$getPair, 2, spells),
			A2($author$project$GameModel$getPair, 3, spells),
			A2($author$project$GameModel$getPair, 4, spells),
			A2($author$project$GameModel$getPair, 5, spells),
			A2($author$project$GameModel$getPair, 6, spells),
			A2($author$project$GameModel$getPair, 7, spells),
			A2($author$project$GameModel$getPair, 8, spells),
			A2($author$project$GameModel$getPair, 9, spells)
		]);
};
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $author$project$Main$pushSpellText = F2(
	function (_v0, cmds) {
		var numSpells = _v0.A;
		var spells = _v0.n;
		var step = function (_v2) {
			var i = _v2.a;
			var maybeSpellName = _v2.b;
			var spellNameString = function () {
				if (!maybeSpellName.$) {
					var name = maybeSpellName.a;
					return $author$project$GameModel$spellNameToString(name);
				} else {
					return '';
				}
			}();
			return $author$project$Main$pushText(
				{
					x: false,
					y: 2,
					E: 20,
					F: $elm$core$String$fromInt(i) + (') ' + spellNameString),
					ah: 110 + ((i - 1) * 40)
				});
		};
		return A3(
			$elm$core$List$foldl,
			step,
			cmds,
			A2(
				$elm$core$List$take,
				numSpells,
				$author$project$GameModel$spellNamesWithOneBasedIndex(spells)));
	});
var $author$project$Main$scoreToString = function (score) {
	var s = score;
	return $elm$core$String$fromInt(s);
};
var $elm$core$Basics$cos = _Basics_cos;
var $elm$random$Random$Generator = $elm$core$Basics$identity;
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $elm$core$Bitwise$xor = _Bitwise_xor;
var $elm$random$Random$peel = function (_v0) {
	var state = _v0.a;
	var word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
	return ((word >>> 22) ^ word) >>> 0;
};
var $elm$random$Random$float = F2(
	function (a, b) {
		return function (seed0) {
			var seed1 = $elm$random$Random$next(seed0);
			var range = $elm$core$Basics$abs(b - a);
			var n1 = $elm$random$Random$peel(seed1);
			var n0 = $elm$random$Random$peel(seed0);
			var lo = (134217727 & n1) * 1.0;
			var hi = (67108863 & n0) * 1.0;
			var val = ((hi * 134217728.0) + lo) / 9007199254740992.0;
			var scaled = (val * range) + a;
			return _Utils_Tuple2(
				scaled,
				$elm$random$Random$next(seed1));
		};
	});
var $elm$random$Random$map = F2(
	function (func, _v0) {
		var genA = _v0;
		return function (seed0) {
			var _v1 = genA(seed0);
			var a = _v1.a;
			var seed1 = _v1.b;
			return _Utils_Tuple2(
				func(a),
				seed1);
		};
	});
var $elm$core$Basics$pi = _Basics_pi;
var $elm$core$Basics$round = _Basics_round;
var $elm$core$Basics$sin = _Basics_sin;
var $author$project$Game$screenShake = function (_v0) {
	var amount = _v0.X;
	var x = _v0.ag;
	var y = _v0.ah;
	var _v1 = _Utils_Tuple2(x, y);
	var bareX = _v1.a;
	var bareY = _v1.b;
	return A2(
		$elm$random$Random$map,
		function (shakeAngle) {
			var newAmount = (amount > 0) ? (amount - 1) : 0;
			return {
				X: newAmount,
				ag: $elm$core$Basics$round(
					$elm$core$Basics$cos(shakeAngle) * newAmount),
				ah: $elm$core$Basics$round(
					$elm$core$Basics$sin(shakeAngle) * newAmount)
			};
		},
		A2($elm$random$Random$float, 0, 2 * $elm$core$Basics$pi));
};
var $elm$random$Random$step = F2(
	function (_v0, seed) {
		var generator = _v0;
		return generator(seed);
	});
var $author$project$Main$drawState = function (stateIn) {
	var _v0 = A2(
		$elm$random$Random$step,
		$author$project$Game$screenShake(stateIn.W),
		stateIn.g);
	var shake = _v0.a;
	var seed = _v0.b;
	var state = _Utils_update(
		stateIn,
		{g: seed, W: shake});
	var prev = A2(
		$author$project$Main$pushSpellText,
		state,
		A2(
			$author$project$Main$pushText,
			{
				x: false,
				y: 1,
				E: 30,
				F: 'Score: ' + $author$project$Main$scoreToString(state.a8),
				ah: 70
			},
			A2(
				$author$project$Main$pushText,
				{
					x: false,
					y: 1,
					E: 30,
					F: 'Level: ' + $author$project$Game$levelNumToString(state.Z),
					ah: 40
				},
				$author$project$Ports$noCmds)));
	var _v1 = A2(
		$author$project$Main$drawMonsters,
		state.W,
		A2(
			$author$project$Main$drawTiles,
			state.W,
			_Utils_Tuple2(state.a, prev)));
	var newTiles = _v1.a;
	var cmds = _v1.b;
	return _Utils_Tuple2(
		_Utils_update(
			state,
			{a: newTiles}),
		cmds);
};
var $author$project$Ports$White = 0;
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$String$append = _String_append;
var $elm$core$Bitwise$shiftRightBy = _Bitwise_shiftRightBy;
var $elm$core$String$repeatHelp = F3(
	function (n, chunk, result) {
		return (n <= 0) ? result : A3(
			$elm$core$String$repeatHelp,
			n >> 1,
			_Utils_ap(chunk, chunk),
			(!(n & 1)) ? result : _Utils_ap(result, chunk));
	});
var $elm$core$String$repeat = F2(
	function (n, chunk) {
		return A3($elm$core$String$repeatHelp, n, chunk, '');
	});
var $author$project$Main$rightPad = A2(
	$elm$core$List$foldl,
	F2(
		function (text, finalText) {
			return A2(
				$elm$core$String$append,
				finalText,
				A2(
					$elm$core$String$append,
					text,
					A2(
						$elm$core$String$repeat,
						10 - $elm$core$String$length(text),
						' ')));
		}),
	'');
var $elm$core$List$sortWith = _List_sortWith;
var $author$project$Main$drawScores = F2(
	function (scoresIn, commandsIn) {
		var lastIndex = $elm$core$List$length(scoresIn) - 1;
		var _v0 = _Utils_Tuple2(
			A2($elm$core$List$take, lastIndex, scoresIn),
			A2($elm$core$List$drop, lastIndex, scoresIn));
		if (_v0.b.b && (!_v0.b.b.b)) {
			var scores = _v0.a;
			var _v1 = _v0.b;
			var newestScore = _v1.a;
			var scoresTop = function () {
				var _v7 = $author$project$Game$pixelHeight;
				var h = _v7;
				return h / 2;
			}();
			var commands = A2(
				$author$project$Main$pushText,
				{
					x: true,
					y: 0,
					E: 18,
					F: $author$project$Main$rightPad(
						_List_fromArray(
							['RUN', 'SCORE', 'TOTAL'])),
					ah: scoresTop
				},
				commandsIn);
			var _v2 = A3(
				$elm$core$List$foldl,
				F2(
					function (_v5, _v6) {
						var run = _v5.a7;
						var score = _v5.a8;
						var totalScore = _v5.bf;
						var i = _v6.a;
						var cmds = _v6.b;
						return _Utils_Tuple2(
							i + 1,
							A2(
								$author$project$Main$pushText,
								{
									x: true,
									y: (!i) ? 2 : 1,
									E: 18,
									F: $author$project$Main$rightPad(
										_List_fromArray(
											[
												$elm$core$String$fromInt(run),
												$author$project$Main$scoreToString(score),
												$author$project$Main$scoreToString(totalScore)
											])),
									ah: (scoresTop + 24) + (i * 24)
								},
								cmds));
					}),
				_Utils_Tuple2(0, commands),
				A2(
					$elm$core$List$take,
					10,
					A2(
						$elm$core$List$cons,
						newestScore,
						A2(
							$elm$core$List$sortWith,
							F2(
								function (a, b) {
									return A2(
										$elm$core$Basics$compare,
										function () {
											var _v3 = b.bf;
											var tsA = _v3;
											return tsA;
										}(),
										function () {
											var _v4 = a.bf;
											var tsB = _v4;
											return tsB;
										}());
								}),
							scores))));
			var cs = _v2.b;
			return cs;
		} else {
			return commandsIn;
		}
	});
var $author$project$Main$drawTitle = function (scores) {
	var halfHeight = function () {
		var _v0 = $author$project$Game$pixelHeight;
		var h = _v0;
		return h / 2;
	}();
	return A2(
		$elm$core$Basics$composeR,
		$elm$core$Array$push($author$project$Ports$drawOverlay),
		A2(
			$elm$core$Basics$composeR,
			$author$project$Main$pushText(
				{x: true, y: 0, E: 70, F: 'BROUGHLIKE', ah: halfHeight - 110}),
			A2(
				$elm$core$Basics$composeR,
				$author$project$Main$pushText(
					{x: true, y: 0, E: 40, F: 'tutori-elm', ah: halfHeight - 55}),
				$author$project$Main$drawScores(scores))));
};
var $author$project$Main$withCmdsMap = F2(
	function (mapper, _v0) {
		var a = _v0.a;
		var cmds = _v0.b;
		return _Utils_Tuple2(
			mapper(a),
			cmds);
	});
var $author$project$Main$draw = function (model) {
	var gameToModel = function (g) {
		return _Utils_update(
			model,
			{t: g});
	};
	var _v0 = model;
	var scores = _v0.D;
	var game = _v0.t;
	switch (game.$) {
		case 1:
			if (game.a.$ === 1) {
				var _v2 = game.a;
				return _Utils_Tuple2(
					model,
					A2($author$project$Main$drawTitle, scores, $elm$core$Array$empty));
			} else {
				var state = game.a.a;
				var seed = game.b;
				var _v3 = $author$project$Main$drawState(state);
				var newState = _v3.a;
				var cmds = _v3.b;
				return A2(
					$author$project$Main$withCmdsMap,
					function (s) {
						return gameToModel(
							A2(
								$author$project$GameModel$Title,
								$elm$core$Maybe$Just(s),
								seed));
					},
					_Utils_Tuple2(
						newState,
						A2($author$project$Main$drawTitle, scores, cmds)));
			}
		case 2:
			var state = game.a;
			return A2(
				$author$project$Main$withCmdsMap,
				A2($elm$core$Basics$composeR, $author$project$GameModel$Running, gameToModel),
				$author$project$Main$drawState(state));
		case 3:
			var state = game.a;
			return A2(
				$author$project$Main$withCmdsMap,
				A2($elm$core$Basics$composeR, $author$project$GameModel$Dead, gameToModel),
				$author$project$Main$drawState(state));
		default:
			return _Utils_Tuple2(
				model,
				A2($elm$core$Array$push, $author$project$Ports$drawOverlay, $elm$core$Array$empty));
	}
};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Main$performWithModel = function (_v0) {
	var model = _v0.a;
	var cmds = _v0.b;
	return _Utils_Tuple2(
		model,
		$author$project$Ports$perform(cmds));
};
var $author$project$Game$DX0 = 0;
var $author$project$Game$DX1 = 1;
var $author$project$Game$DXm1 = 2;
var $author$project$Game$DY0 = 0;
var $author$project$Game$DY1 = 1;
var $author$project$Game$DYm1 = 2;
var $author$project$Ports$Spell = 4;
var $author$project$Tile$addTreasure = function (tile) {
	return _Utils_update(
		tile,
		{aM: true});
};
var $author$project$GameModel$runningWithNoCmds = function (state) {
	return _Utils_Tuple2(
		$author$project$GameModel$Running(state),
		$author$project$Ports$noCmds);
};
var $author$project$GameModel$changeTiles = F2(
	function (tiles, state) {
		return $author$project$GameModel$runningWithNoCmds(
			_Utils_update(
				state,
				{a: tiles}));
	});
var $author$project$Game$moveX = F2(
	function (dx, xx) {
		var x = xx;
		switch (dx) {
			case 0:
				return x;
			case 1:
				return x + 1;
			default:
				return x - 1;
		}
	});
var $author$project$Game$moveY = F2(
	function (dy, yy) {
		var y = yy;
		switch (dy) {
			case 0:
				return y;
			case 1:
				return y + 1;
			default:
				return y - 1;
		}
	});
var $author$project$Tiles$getNeighbor = F3(
	function (tiles, _v0, _v1) {
		var xPos = _v0.L;
		var yPos = _v0.M;
		var dx = _v1.a;
		var dy = _v1.b;
		return A2(
			$author$project$Tiles$get,
			tiles,
			{
				L: A2($author$project$Game$moveX, dx, xPos),
				M: A2($author$project$Game$moveY, dy, yPos)
			});
	});
var $author$project$Tiles$getAdjacentNeighborsUnshuffled = F2(
	function (tiles, positioned) {
		var gn = A2($author$project$Tiles$getNeighbor, tiles, positioned);
		return _List_fromArray(
			[
				gn(
				_Utils_Tuple2(0, 2)),
				gn(
				_Utils_Tuple2(0, 1)),
				gn(
				_Utils_Tuple2(2, 0)),
				gn(
				_Utils_Tuple2(1, 0))
			]);
	});
var $author$project$Tile$isPassable = function (tile) {
	var _v0 = tile.I;
	switch (_v0) {
		case 0:
			return true;
		case 1:
			return false;
		default:
			return true;
	}
};
var $elm$core$Basics$not = _Basics_not;
var $author$project$Tile$Floor = 0;
var $author$project$Tile$floor = $author$project$Tile$withKind(0);
var $author$project$GameModel$replaceWallWithFloor = function (tile) {
	return $author$project$Tile$isPassable(tile) ? tile : $author$project$Tile$floor(tile);
};
var $author$project$GameModel$alchemy = function (state) {
	var tiles = A3(
		$elm$core$List$foldr,
		$author$project$Tiles$transform(
			function (tile) {
				return ((!$author$project$Tile$isPassable(tile)) && $author$project$Tiles$inBounds(tile)) ? $author$project$Tile$addTreasure(
					$author$project$GameModel$replaceWallWithFloor(tile)) : tile;
			}),
		state.a,
		A2($author$project$Tiles$getAdjacentNeighborsUnshuffled, state.a, state.m));
	return A2($author$project$GameModel$changeTiles, tiles, state);
};
var $author$project$Monster$HP = $elm$core$Basics$identity;
var $author$project$Monster$die = function (monster) {
	return _Utils_update(
		monster,
		{am: true, ad: 1});
};
var $author$project$Monster$maxHP = 6;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Monster$heal = F2(
	function (damage, target) {
		var _v0 = _Utils_Tuple2(target.a$, damage);
		var hp = _v0.a;
		var d = _v0.b;
		var newHP = A2($elm$core$Basics$min, $author$project$Monster$maxHP, hp + d);
		var newMonster = _Utils_update(
			target,
			{a$: newHP});
		return (newHP <= 0) ? $author$project$Monster$die(newMonster) : newMonster;
	});
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Game$plainPositioned = function (_v0) {
	var xPos = _v0.L;
	var yPos = _v0.M;
	return {L: xPos, M: yPos};
};
var $author$project$Tile$setEffect = F2(
	function (index, tile) {
		return _Utils_update(
			tile,
			{
				O: $elm$core$Maybe$Just(
					A2($author$project$Tile$Effect, index, $author$project$Tile$maxEffectCount))
			});
	});
var $author$project$GameModel$aura = function (state) {
	var healPositions = A2(
		$elm$core$List$cons,
		state.m,
		A2(
			$elm$core$List$map,
			$author$project$Game$plainPositioned,
			A2($author$project$Tiles$getAdjacentNeighborsUnshuffled, state.a, state.m)));
	return $author$project$GameModel$runningWithNoCmds(
		_Utils_update(
			state,
			{
				a: A3(
					$elm$core$List$foldr,
					$author$project$Tiles$transform(
						function (tile) {
							return A2(
								$author$project$Tile$setEffect,
								13,
								_Utils_update(
									tile,
									{
										e: A2(
											$elm$core$Maybe$map,
											$author$project$Monster$heal(1),
											tile.e)
									}));
						}),
					state.a,
					healPositions)
			}));
};
var $author$project$GameModel$boltEffect = function (_v0) {
	var dy = _v0.b;
	return 15 + function () {
		switch (dy) {
			case 1:
				return 1;
			case 2:
				return 1;
			default:
				return 0;
		}
	}();
};
var $author$project$Ports$Hit1 = 0;
var $author$project$Ports$Hit2 = 1;
var $author$project$Ports$playSound = function (sound) {
	var soundName = function () {
		switch (sound) {
			case 0:
				return 'hit1';
			case 1:
				return 'hit2';
			case 2:
				return 'treasure';
			case 3:
				return 'newLevel';
			default:
				return 'spell';
		}
	}();
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'kind',
				$elm$json$Json$Encode$string('playSound')),
				_Utils_Tuple2(
				'soundName',
				$elm$json$Json$Encode$string(soundName))
			]));
};
var $author$project$Monster$hit = F2(
	function (damage, target) {
		if (target.a9 > 0) {
			return _Utils_Tuple2(target, $author$project$Ports$noCmds);
		} else {
			var _v0 = _Utils_Tuple2(target.a$, damage);
			var hp = _v0.a;
			var d = _v0.b;
			var newHP = hp - d;
			var hitMonster = _Utils_update(
				target,
				{a$: newHP});
			var newMonster = (newHP <= 0) ? $author$project$Monster$die(hitMonster) : hitMonster;
			return _Utils_Tuple2(
				newMonster,
				A2(
					$elm$core$Array$repeat,
					1,
					function () {
						var _v1 = newMonster.I;
						if (!_v1.$) {
							return $author$project$Ports$playSound(0);
						} else {
							return $author$project$Ports$playSound(1);
						}
					}()));
		}
	});
var $author$project$GameModel$boltTravel = F4(
	function (deltas, effect, damage, stateIn) {
		var newTile = A2($author$project$Tiles$get, stateIn.a, stateIn.m);
		var hit = $author$project$Monster$hit(damage);
		var loop = F2(
			function (prevTile, _v0) {
				var state = _v0.a;
				var cmdsIn = _v0.b;
				var testTile = A3($author$project$Tiles$getNeighbor, state.a, prevTile, deltas);
				var _v1 = function () {
					var _v2 = testTile.e;
					if (!_v2.$) {
						var m = _v2.a;
						var _v3 = hit(m);
						var a = _v3.a;
						var b = _v3.b;
						return _Utils_Tuple2(
							$elm$core$Maybe$Just(a),
							b);
					} else {
						return _Utils_Tuple2($elm$core$Maybe$Nothing, $author$project$Ports$noCmds);
					}
				}();
				var hitMonster = _v1.a;
				var hitCmds = _v1.b;
				var tiles = A2(
					$author$project$Tiles$set,
					A2(
						$author$project$Tile$setEffect,
						effect,
						_Utils_update(
							testTile,
							{e: hitMonster})),
					state.a);
				return $author$project$Tile$isPassable(testTile) ? A2(
					loop,
					testTile,
					_Utils_Tuple2(
						_Utils_update(
							state,
							{a: tiles}),
						A2($elm$core$Array$append, cmdsIn, hitCmds))) : _Utils_Tuple2(state, cmdsIn);
			});
		return A2(
			loop,
			newTile,
			_Utils_Tuple2(stateIn, $author$project$Ports$noCmds));
	});
var $author$project$GameModel$requirePlayer = F2(
	function (spellMaker, state) {
		var _v0 = A2($author$project$Tiles$get, state.a, state.m).e;
		if (_v0.$ === 1) {
			return _Utils_Tuple2(
				$author$project$GameModel$Error('Could not find player'),
				$author$project$Ports$noCmds);
		} else {
			var player = _v0.a;
			return A2(spellMaker, player, state);
		}
	});
var $author$project$GameModel$runningWithCmds = function (_v0) {
	var state = _v0.a;
	var cmds = _v0.b;
	return _Utils_Tuple2(
		$author$project$GameModel$Running(state),
		cmds);
};
var $author$project$GameModel$bolt = $author$project$GameModel$requirePlayer(
	function (player) {
		return A2(
			$elm$core$Basics$composeR,
			A3(
				$author$project$GameModel$boltTravel,
				player.Y,
				$author$project$GameModel$boltEffect(player.Y),
				4),
			$author$project$GameModel$runningWithCmds);
	});
var $author$project$Monster$isPlayer = function (kind) {
	if (!kind.$) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Monster$stun = function (monster) {
	return _Utils_update(
		monster,
		{aJ: true});
};
var $author$project$GameModel$bravery = function (state) {
	return A2(
		$author$project$GameModel$changeTiles,
		A3(
			$author$project$Tiles$foldMonsters,
			F2(
				function (monster, ts) {
					return A3(
						$author$project$Tiles$transform,
						function (tile) {
							return _Utils_update(
								tile,
								{
									e: $elm$core$Maybe$Just(
										$author$project$Monster$isPlayer(monster.I) ? _Utils_update(
											monster,
											{a9: 2}) : $author$project$Monster$stun(monster))
								});
						},
						monster,
						ts);
				}),
			state.a,
			state.a),
		state);
};
var $author$project$GameModel$SpellBook = $elm$core$Basics$identity;
var $author$project$GameModel$foldSpellKeysr = F2(
	function (folder, acc) {
		return A2(
			folder,
			1,
			A2(
				folder,
				2,
				A2(
					folder,
					3,
					A2(
						folder,
						4,
						A2(
							folder,
							5,
							A2(
								folder,
								6,
								A2(
									folder,
									7,
									A2(
										folder,
										8,
										A2(folder, 9, acc)))))))));
	});
var $author$project$GameModel$bubble = function (state) {
	return $author$project$GameModel$runningWithNoCmds(
		_Utils_update(
			state,
			{
				n: function () {
					var _v0 = state.n;
					var spellbook = _v0;
					return A2(
						$author$project$GameModel$foldSpellKeysr,
						F2(
							function (key, spellsIn) {
								var _v1 = A2($elm$core$Dict$get, key, spellsIn);
								if (!_v1.$) {
									return spellsIn;
								} else {
									var _v2 = A2($elm$core$Dict$get, key - 1, spellsIn);
									if (_v2.$ === 1) {
										return spellsIn;
									} else {
										var name = _v2.a;
										return A3($elm$core$Dict$insert, key, name, spellsIn);
									}
								}
							}),
						spellbook);
				}()
			}));
};
var $author$project$GameModel$cross = function (stateIn) {
	var damage = 2;
	return $author$project$GameModel$runningWithCmds(
		A3(
			$elm$core$List$foldr,
			F2(
				function (deltas, _v0) {
					var state = _v0.a;
					var cmds = _v0.b;
					var _v1 = A4(
						$author$project$GameModel$boltTravel,
						deltas,
						$author$project$GameModel$boltEffect(deltas),
						damage,
						state);
					var s = _v1.a;
					var newCmds = _v1.b;
					return _Utils_Tuple2(
						s,
						A2($elm$core$Array$append, cmds, newCmds));
				}),
			_Utils_Tuple2(stateIn, $author$project$Ports$noCmds),
			_List_fromArray(
				[
					_Utils_Tuple2(0, 2),
					_Utils_Tuple2(0, 1),
					_Utils_Tuple2(2, 0),
					_Utils_Tuple2(1, 0)
				])));
};
var $author$project$GameModel$dashPosHelper = F3(
	function (tiles, deltas, newPos) {
		var testTile = A3($author$project$Tiles$getNeighbor, tiles, newPos, deltas);
		return ($author$project$Tile$isPassable(testTile) && _Utils_eq(testTile.e, $elm$core$Maybe$Nothing)) ? A3(
			$author$project$GameModel$dashPosHelper,
			tiles,
			deltas,
			$author$project$Game$plainPositioned(testTile)) : newPos;
	});
var $elm$random$Random$andThen = F2(
	function (callback, _v0) {
		var genA = _v0;
		return function (seed) {
			var _v1 = genA(seed);
			var result = _v1.a;
			var newSeed = _v1.b;
			var _v2 = callback(result);
			var genB = _v2;
			return genB(newSeed);
		};
	});
var $elm$random$Random$constant = function (value) {
	return function (seed) {
		return _Utils_Tuple2(value, seed);
	};
};
var $elm$random$Random$int = F2(
	function (a, b) {
		return function (seed0) {
			var _v0 = (_Utils_cmp(a, b) < 0) ? _Utils_Tuple2(a, b) : _Utils_Tuple2(b, a);
			var lo = _v0.a;
			var hi = _v0.b;
			var range = (hi - lo) + 1;
			if (!((range - 1) & range)) {
				return _Utils_Tuple2(
					(((range - 1) & $elm$random$Random$peel(seed0)) >>> 0) + lo,
					$elm$random$Random$next(seed0));
			} else {
				var threshhold = (((-range) >>> 0) % range) >>> 0;
				var accountForBias = function (seed) {
					accountForBias:
					while (true) {
						var x = $elm$random$Random$peel(seed);
						var seedN = $elm$random$Random$next(seed);
						if (_Utils_cmp(x, threshhold) < 0) {
							var $temp$seed = seedN;
							seed = $temp$seed;
							continue accountForBias;
						} else {
							return _Utils_Tuple2((x % range) + lo, seedN);
						}
					}
				};
				return accountForBias(seed0);
			}
		};
	});
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $author$project$Randomness$swapAt = F3(
	function (i, j, list) {
		swapAt:
		while (true) {
			if (_Utils_eq(i, j) || (i < 0)) {
				return list;
			} else {
				if (_Utils_cmp(i, j) > 0) {
					var $temp$i = j,
						$temp$j = i,
						$temp$list = list;
					i = $temp$i;
					j = $temp$j;
					list = $temp$list;
					continue swapAt;
				} else {
					var jInIAndAfter = j - i;
					var iAndAfter = A2($elm$core$List$drop, i, list);
					var iToBeforeJ = A2($elm$core$List$take, jInIAndAfter, iAndAfter);
					var jAndAfter = A2($elm$core$List$drop, jInIAndAfter, iAndAfter);
					var beforeI = A2($elm$core$List$take, i, list);
					var _v0 = _Utils_Tuple2(iToBeforeJ, jAndAfter);
					if (_v0.a.b && _v0.b.b) {
						var _v1 = _v0.a;
						var valueAtI = _v1.a;
						var afterIToJ = _v1.b;
						var _v2 = _v0.b;
						var valueAtJ = _v2.a;
						var rest = _v2.b;
						return $elm$core$List$concat(
							_List_fromArray(
								[
									beforeI,
									A2($elm$core$List$cons, valueAtJ, afterIToJ),
									A2($elm$core$List$cons, valueAtI, rest)
								]));
					} else {
						return list;
					}
				}
			}
		}
	});
var $author$project$Randomness$shuffleHelper = F2(
	function (list, i) {
		return A2(
			$elm$random$Random$andThen,
			function (randomIndex) {
				var newList = A3($author$project$Randomness$swapAt, i, randomIndex, list);
				var newI = i + 1;
				return (_Utils_cmp(
					newI,
					$elm$core$List$length(newList)) < 0) ? A2($author$project$Randomness$shuffleHelper, newList, newI) : $elm$random$Random$constant(newList);
			},
			A2($elm$random$Random$int, 0, i));
	});
var $author$project$Randomness$shuffle = function (list) {
	return A2($author$project$Randomness$shuffleHelper, list, 1);
};
var $author$project$Tiles$getAdjacentNeighbors = F2(
	function (tiles, positioned) {
		return $author$project$Randomness$shuffle(
			A2($author$project$Tiles$getAdjacentNeighborsUnshuffled, tiles, positioned));
	});
var $author$project$Tiles$ToTile = {$: 0};
var $author$project$Tiles$moveDirectly = F3(
	function (monsterIn, _v0, tiles) {
		var xPos = _v0.L;
		var yPos = _v0.M;
		var oldTile = A2($author$project$Tiles$get, tiles, monsterIn);
		var newTile = A2(
			$author$project$Tiles$get,
			tiles,
			{L: xPos, M: yPos});
		var monster = _Utils_update(
			monsterIn,
			{L: xPos, M: yPos});
		return {
			av: monster,
			a: A2(
				$author$project$Tiles$set,
				_Utils_update(
					newTile,
					{
						e: $elm$core$Maybe$Just(monster)
					}),
				A2(
					$author$project$Tiles$set,
					_Utils_update(
						oldTile,
						{e: $elm$core$Maybe$Nothing}),
					tiles))
		};
	});
var $author$project$Tiles$moveInner = F4(
	function (movement, monsterIn, _v0, tiles) {
		var xPos = _v0.L;
		var yPos = _v0.M;
		var _v1 = function () {
			if (!movement.$) {
				return _Utils_Tuple2(
					function () {
						var _v3 = _Utils_Tuple2(monsterIn.L, xPos);
						var oldX = _v3.a;
						var newX = _v3.b;
						return oldX - newX;
					}(),
					function () {
						var _v4 = _Utils_Tuple2(monsterIn.M, yPos);
						var oldY = _v4.a;
						var newY = _v4.b;
						return oldY - newY;
					}());
			} else {
				var _v5 = movement.a;
				var ox = _v5.a;
				var oy = _v5.b;
				return _Utils_Tuple2(ox, oy);
			}
		}();
		var offsetX = _v1.a;
		var offsetY = _v1.b;
		var monster = _Utils_update(
			monsterIn,
			{U: offsetX, V: offsetY});
		return A3(
			$author$project$Tiles$moveDirectly,
			monster,
			{L: xPos, M: yPos},
			tiles);
	});
var $author$project$Tiles$move = $author$project$Tiles$moveInner($author$project$Tiles$ToTile);
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$GameModel$dash = $author$project$GameModel$requirePlayer(
	F2(
		function (player, state) {
			var newPos = A3($author$project$GameModel$dashPosHelper, state.a, player.Y, state.m);
			if (!_Utils_eq(
				$author$project$Game$plainPositioned(player),
				newPos)) {
				var folder = F2(
					function (tile, _v5) {
						var tilesIn = _v5.a;
						var commandsIn = _v5.b;
						var _v3 = tile.e;
						if (!_v3.$) {
							var monster = _v3.a;
							var _v4 = A2($author$project$Monster$hit, 1, monster);
							var hitMonster = _v4.a;
							var newCmds = _v4.b;
							return _Utils_Tuple2(
								A3(
									$author$project$Tiles$transform,
									function (t) {
										return A2(
											$author$project$Tile$setEffect,
											14,
											_Utils_update(
												t,
												{
													e: $elm$core$Maybe$Just(
														$author$project$Monster$stun(hitMonster))
												}));
									},
									tile,
									tilesIn),
								A2($elm$core$Array$append, commandsIn, newCmds));
						} else {
							return _Utils_Tuple2(tilesIn, commandsIn);
						}
					});
				var _v0 = A3($author$project$Tiles$move, player, newPos, state.a);
				var tiles = _v0.a;
				var moved = _v0.av;
				var _v1 = A2(
					$elm$random$Random$step,
					A2($author$project$Tiles$getAdjacentNeighbors, tiles, newPos),
					state.g);
				var adjacentNeighbors = _v1.a;
				var seed = _v1.b;
				var _v2 = A3(
					$elm$core$List$foldr,
					folder,
					_Utils_Tuple2(tiles, $author$project$Ports$noCmds),
					adjacentNeighbors);
				var tilesOut = _v2.a;
				var commands = _v2.b;
				return _Utils_Tuple2(
					$author$project$GameModel$Running(
						_Utils_update(
							state,
							{
								m: $author$project$Game$plainPositioned(moved),
								g: seed,
								a: tilesOut
							})),
					commands);
			} else {
				return $author$project$GameModel$runningWithNoCmds(state);
			}
		}));
var $author$project$GameModel$dig = function (state) {
	var folder = function (xy) {
		return A2(
			$author$project$Tiles$transform,
			function (tile) {
				var _v0 = A2(
					$elm$core$Maybe$andThen,
					function (m) {
						return $author$project$Monster$isPlayer(m.I) ? $elm$core$Maybe$Just(m) : $elm$core$Maybe$Nothing;
					},
					tile.e);
				if (!_v0.$) {
					var monsterIn = _v0.a;
					return $author$project$GameModel$replaceWallWithFloor(
						A2(
							$author$project$Tile$setEffect,
							13,
							_Utils_update(
								tile,
								{
									e: $elm$core$Maybe$Just(
										A2($author$project$Monster$heal, 2, monsterIn))
								})));
				} else {
					return $author$project$GameModel$replaceWallWithFloor(tile);
				}
			},
			xy);
	};
	var tiles = A2($author$project$Tiles$foldXY, folder, state.a);
	return A2($author$project$GameModel$changeTiles, tiles, state);
};
var $author$project$GameModel$ex = function (stateIn) {
	var effect = 14;
	var damage = 3;
	return $author$project$GameModel$runningWithCmds(
		A3(
			$elm$core$List$foldr,
			F2(
				function (deltas, _v0) {
					var state = _v0.a;
					var cmds = _v0.b;
					var _v1 = A4($author$project$GameModel$boltTravel, deltas, effect, damage, state);
					var s = _v1.a;
					var newCmds = _v1.b;
					return _Utils_Tuple2(
						s,
						A2($elm$core$Array$append, cmds, newCmds));
				}),
			_Utils_Tuple2(stateIn, $author$project$Ports$noCmds),
			_List_fromArray(
				[
					_Utils_Tuple2(2, 2),
					_Utils_Tuple2(2, 1),
					_Utils_Tuple2(1, 2),
					_Utils_Tuple2(1, 1)
				])));
};
var $author$project$GameModel$kingmaker = function (state) {
	var folder = function (xy) {
		return A2(
			$author$project$Tiles$transform,
			function (tile) {
				var _v0 = A2(
					$elm$core$Maybe$andThen,
					function (m) {
						return $author$project$Monster$isPlayer(m.I) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(m);
					},
					tile.e);
				if (!_v0.$) {
					var monsterIn = _v0.a;
					return $author$project$Tile$addTreasure(
						_Utils_update(
							tile,
							{
								e: $elm$core$Maybe$Just(
									A2($author$project$Monster$heal, 1, monsterIn))
							}));
				} else {
					return tile;
				}
			},
			xy);
	};
	var tiles = A2($author$project$Tiles$foldXY, folder, state.a);
	return A2($author$project$GameModel$changeTiles, tiles, state);
};
var $author$project$Tiles$NoPassableTile = 0;
var $author$project$Tile$hasMonster = function (_v0) {
	var monster = _v0.e;
	if (!monster.$) {
		return true;
	} else {
		return false;
	}
};
var $author$project$Randomness$tryToHelper = F2(
	function (generator, timeout) {
		return A2(
			$elm$random$Random$andThen,
			function (result) {
				if (!result.$) {
					var a = result.a;
					return $elm$random$Random$constant(
						$elm$core$Result$Ok(a));
				} else {
					var e = result.a;
					return (timeout <= 0) ? $elm$random$Random$constant(
						$elm$core$Result$Err(e)) : A2($author$project$Randomness$tryToHelper, generator, timeout - 1);
				}
			},
			generator);
	});
var $author$project$Randomness$tryToCustom = function (generator) {
	return A2($author$project$Randomness$tryToHelper, generator, 1000);
};
var $elm$random$Random$map2 = F3(
	function (func, _v0, _v1) {
		var genA = _v0;
		var genB = _v1;
		return function (seed0) {
			var _v2 = genA(seed0);
			var a = _v2.a;
			var seed1 = _v2.b;
			var _v3 = genB(seed1);
			var b = _v3.a;
			var seed2 = _v3.b;
			return _Utils_Tuple2(
				A2(func, a, b),
				seed2);
		};
	});
var $author$project$Tiles$xyGen = function () {
	var coordIntGen = A2($elm$random$Random$int, 0, $author$project$Game$numTiles - 1);
	return A3(
		$elm$random$Random$map2,
		F2(
			function (xPos, yPos) {
				return {L: xPos, M: yPos};
			}),
		A2($elm$random$Random$map, $elm$core$Basics$identity, coordIntGen),
		A2($elm$random$Random$map, $elm$core$Basics$identity, coordIntGen));
}();
var $author$project$Tiles$randomPassableTile = function (tiles) {
	return $author$project$Randomness$tryToCustom(
		A2(
			$elm$random$Random$map,
			function (xy) {
				var t = A2($author$project$Tiles$get, tiles, xy);
				return ($author$project$Tile$isPassable(t) && (!$author$project$Tile$hasMonster(t))) ? $elm$core$Result$Ok(t) : $elm$core$Result$Err(0);
			},
			$author$project$Tiles$xyGen));
};
var $author$project$GameModel$maelstrom = function (state) {
	var folder = F2(
		function (monster, _v3) {
			var ts = _v3.a;
			var seedIn = _v3.b;
			if ($author$project$Monster$isPlayer(monster.I)) {
				return _Utils_Tuple2(ts, seedIn);
			} else {
				var _v1 = A2(
					$elm$random$Random$step,
					$author$project$Tiles$randomPassableTile(ts),
					seedIn);
				var passableTile = _v1.a;
				var seedOut = _v1.b;
				var target = function () {
					if (!passableTile.$) {
						var t = passableTile.a;
						return $author$project$Game$plainPositioned(t);
					} else {
						return $author$project$Game$plainPositioned(monster);
					}
				}();
				return _Utils_Tuple2(
					A3(
						$author$project$Tiles$move,
						_Utils_update(
							monster,
							{bd: 2}),
						target,
						ts).a,
					seedOut);
			}
		});
	var _v0 = A3(
		$author$project$Tiles$foldMonsters,
		folder,
		_Utils_Tuple2(state.a, state.g),
		state.a);
	var tiles = _v0.a;
	var seed = _v0.b;
	return $author$project$GameModel$runningWithNoCmds(
		_Utils_update(
			state,
			{g: seed, a: tiles}));
};
var $author$project$Tile$Exit = 2;
var $author$project$Monster$Player = function (a) {
	return {$: 0, a: a};
};
var $author$project$Monster$teleportCounterDefault = 2;
var $author$project$Monster$fromSpec = function (monsterSpec) {
	var _v0 = function () {
		var _v1 = monsterSpec.I;
		switch (_v1.$) {
			case 0:
				var startingHp = _v1.a;
				return _Utils_Tuple3(0, startingHp, 0);
			case 1:
				return _Utils_Tuple3(4, 3, $author$project$Monster$teleportCounterDefault);
			case 2:
				return _Utils_Tuple3(5, 1, $author$project$Monster$teleportCounterDefault);
			case 3:
				return _Utils_Tuple3(6, 2, $author$project$Monster$teleportCounterDefault);
			case 4:
				return _Utils_Tuple3(7, 1, $author$project$Monster$teleportCounterDefault);
			default:
				return _Utils_Tuple3(8, 2, $author$project$Monster$teleportCounterDefault);
		}
	}();
	var sprite = _v0.a;
	var hp = _v0.b;
	var teleportCounter = _v0.c;
	return {
		aS: false,
		aU: 0,
		am: false,
		a$: hp,
		I: monsterSpec.I,
		Y: _Utils_Tuple2(2, 0),
		U: 0,
		V: 0,
		a9: 0,
		ad: sprite,
		aJ: false,
		bd: teleportCounter,
		L: monsterSpec.L,
		M: monsterSpec.M
	};
};
var $author$project$Tiles$addMonster = F2(
	function (tiles, monsterSpec) {
		var monster = $author$project$Monster$fromSpec(monsterSpec);
		return A3($author$project$Tiles$move, monster, monster, tiles).a;
	});
var $elm$core$Result$andThen = F2(
	function (callback, result) {
		if (!result.$) {
			var value = result.a;
			return callback(value);
		} else {
			var msg = result.a;
			return $elm$core$Result$Err(msg);
		}
	});
var $author$project$GameModel$emptySpells = $elm$core$Dict$empty;
var $author$project$Monster$Bird = {$: 1};
var $author$project$Monster$Eater = {$: 4};
var $author$project$Monster$Jester = {$: 5};
var $author$project$Monster$Snake = {$: 2};
var $author$project$Monster$Tank = {$: 3};
var $author$project$Randomness$lengthNonEmpty = function (_v0) {
	var rest = _v0.b;
	return 1 + $elm$core$List$length(rest);
};
var $author$project$Randomness$swapAtNonEmpty = F3(
	function (i, j, list) {
		swapAtNonEmpty:
		while (true) {
			if (_Utils_eq(i, j) || (i < 0)) {
				return list;
			} else {
				if (_Utils_cmp(i, j) > 0) {
					var $temp$i = j,
						$temp$j = i,
						$temp$list = list;
					i = $temp$i;
					j = $temp$j;
					list = $temp$list;
					continue swapAtNonEmpty;
				} else {
					var _v0 = list;
					var head = _v0.a;
					var rest = _v0.b;
					if (!i) {
						var jAndAfter = A2($elm$core$List$drop, j - 1, rest);
						var beforeJ = A2($elm$core$List$take, j - 1, rest);
						if (jAndAfter.b) {
							var valueAtJ = jAndAfter.a;
							var restOfRest = jAndAfter.b;
							return _Utils_Tuple2(
								valueAtJ,
								$elm$core$List$concat(
									_List_fromArray(
										[
											beforeJ,
											A2($elm$core$List$cons, head, restOfRest)
										])));
						} else {
							return list;
						}
					} else {
						return _Utils_Tuple2(
							head,
							A3($author$project$Randomness$swapAt, i - 1, j - 1, rest));
					}
				}
			}
		}
	});
var $author$project$Randomness$shuffleNonEmptyHelper = F2(
	function (list, i) {
		return A2(
			$elm$random$Random$andThen,
			function (randomIndex) {
				var newList = A3($author$project$Randomness$swapAtNonEmpty, i, randomIndex, list);
				var newI = i + 1;
				return (_Utils_cmp(
					newI,
					$author$project$Randomness$lengthNonEmpty(newList)) < 0) ? A2($author$project$Randomness$shuffleNonEmptyHelper, newList, newI) : $elm$random$Random$constant(newList);
			},
			A2($elm$random$Random$int, 0, i));
	});
var $author$project$Randomness$shuffleNonEmpty = function (list) {
	return A2($author$project$Randomness$shuffleNonEmptyHelper, list, 1);
};
var $author$project$Randomness$genFromNonEmpty = function (nonEmptyList) {
	return A2(
		$elm$random$Random$map,
		function (_v0) {
			var head = _v0.a;
			return head;
		},
		$author$project$Randomness$shuffleNonEmpty(nonEmptyList));
};
var $author$project$Map$nonPlayerMonsterKindGen = $author$project$Randomness$genFromNonEmpty(
	_Utils_Tuple2(
		$author$project$Monster$Bird,
		_List_fromArray(
			[$author$project$Monster$Snake, $author$project$Monster$Tank, $author$project$Monster$Eater, $author$project$Monster$Jester])));
var $author$project$Map$addMonsters = F2(
	function (count, tilesIn) {
		return (count <= 0) ? $elm$random$Random$constant(
			$elm$core$Result$Ok(tilesIn)) : A2(
			$elm$random$Random$andThen,
			function (kind) {
				return A2(
					$elm$random$Random$andThen,
					function (tileResult) {
						if (tileResult.$ === 1) {
							var e = tileResult.a;
							return $elm$random$Random$constant(
								$elm$core$Result$Err(e));
						} else {
							var xPos = tileResult.a.L;
							var yPos = tileResult.a.M;
							return A2(
								$author$project$Map$addMonsters,
								count - 1,
								A2(
									$author$project$Tiles$addMonster,
									tilesIn,
									{I: kind, L: xPos, M: yPos}));
						}
					},
					$author$project$Tiles$randomPassableTile(tilesIn));
			},
			$author$project$Map$nonPlayerMonsterKindGen);
	});
var $author$project$Map$generateMonsters = F2(
	function (levelNum, tiles) {
		var numMonsters = function () {
			var level = levelNum;
			return level + 1;
		}();
		return A2($author$project$Map$addMonsters, numMonsters, tiles);
	});
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (!result.$) {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $author$project$Tiles$noPassableTileToString = function (_v0) {
	return 'get random passable tile';
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $author$project$Tiles$getAdjacentPassableNeighbors = F2(
	function (tiles, located) {
		return A2(
			$elm$random$Random$map,
			$elm$core$List$filter($author$project$Tile$isPassable),
			A2($author$project$Tiles$getAdjacentNeighbors, tiles, located));
	});
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Map$pop = function (list) {
	var newLength = $elm$core$List$length(list) - 1;
	return A2(
		$elm$core$Maybe$map,
		function (popped) {
			return _Utils_Tuple2(
				A2($elm$core$List$take, newLength, list),
				popped);
		},
		$elm$core$List$head(
			A2($elm$core$List$drop, newLength, list)));
};
var $author$project$Map$getConnectedTilesHelper = F3(
	function (tiles, connectedTiles, frontier) {
		var _v0 = $author$project$Map$pop(frontier);
		if (_v0.$ === 1) {
			return $elm$random$Random$constant(connectedTiles);
		} else {
			var _v1 = _v0.a;
			var newFrontier = _v1.a;
			var popped = _v1.b;
			return A2(
				$elm$random$Random$andThen,
				function (passableNeighbors) {
					var uncheckedNeighbors = A2(
						$elm$core$List$filter,
						function (t) {
							return !A2($elm$core$List$member, t, connectedTiles);
						},
						passableNeighbors);
					return A3(
						$author$project$Map$getConnectedTilesHelper,
						tiles,
						_Utils_ap(connectedTiles, uncheckedNeighbors),
						_Utils_ap(newFrontier, uncheckedNeighbors));
				},
				A2($author$project$Tiles$getAdjacentPassableNeighbors, tiles, popped));
		}
	});
var $author$project$Map$getConnectedTiles = F2(
	function (tiles, tile) {
		return A3(
			$author$project$Map$getConnectedTilesHelper,
			tiles,
			_List_fromArray(
				[tile]),
			_List_fromArray(
				[tile]));
	});
var $elm$core$Array$fromListHelp = F3(
	function (list, nodeList, nodeListSize) {
		fromListHelp:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, list);
			var jsArray = _v0.a;
			var remainingItems = _v0.b;
			if (_Utils_cmp(
				$elm$core$Elm$JsArray$length(jsArray),
				$elm$core$Array$branchFactor) < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					true,
					{d: nodeList, b: nodeListSize, c: jsArray});
			} else {
				var $temp$list = remainingItems,
					$temp$nodeList = A2(
					$elm$core$List$cons,
					$elm$core$Array$Leaf(jsArray),
					nodeList),
					$temp$nodeListSize = nodeListSize + 1;
				list = $temp$list;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue fromListHelp;
			}
		}
	});
var $elm$core$Array$fromList = function (list) {
	if (!list.b) {
		return $elm$core$Array$empty;
	} else {
		return A3($elm$core$Array$fromListHelp, list, _List_Nil, 0);
	}
};
var $elm$core$Elm$JsArray$indexedMap = _JsArray_indexedMap;
var $elm$core$Array$indexedMap = F2(
	function (func, _v0) {
		var len = _v0.a;
		var tree = _v0.c;
		var tail = _v0.d;
		var initialBuilder = {
			d: _List_Nil,
			b: 0,
			c: A3(
				$elm$core$Elm$JsArray$indexedMap,
				func,
				$elm$core$Array$tailIndex(len),
				tail)
		};
		var helper = F2(
			function (node, builder) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldl, helper, builder, subTree);
				} else {
					var leaf = node.a;
					var offset = builder.b * $elm$core$Array$branchFactor;
					var mappedLeaf = $elm$core$Array$Leaf(
						A3($elm$core$Elm$JsArray$indexedMap, func, offset, leaf));
					return {
						d: A2($elm$core$List$cons, mappedLeaf, builder.d),
						b: builder.b + 1,
						c: builder.c
					};
				}
			});
		return A2(
			$elm$core$Array$builderToArray,
			true,
			A3($elm$core$Elm$JsArray$foldl, helper, initialBuilder, tree));
	});
var $elm$random$Random$listHelp = F4(
	function (revList, n, gen, seed) {
		listHelp:
		while (true) {
			if (n < 1) {
				return _Utils_Tuple2(revList, seed);
			} else {
				var _v0 = gen(seed);
				var value = _v0.a;
				var newSeed = _v0.b;
				var $temp$revList = A2($elm$core$List$cons, value, revList),
					$temp$n = n - 1,
					$temp$gen = gen,
					$temp$seed = newSeed;
				revList = $temp$revList;
				n = $temp$n;
				gen = $temp$gen;
				seed = $temp$seed;
				continue listHelp;
			}
		}
	});
var $elm$random$Random$list = F2(
	function (n, _v0) {
		var gen = _v0;
		return function (seed) {
			return A4($elm$random$Random$listHelp, _List_Nil, n, gen, seed);
		};
	});
var $author$project$Randomness$probability = A2($elm$random$Random$float, 0, 1);
var $author$project$Tiles$tileCount = $author$project$Game$numTiles * $author$project$Game$numTiles;
var $author$project$Tiles$toXYPos = function (index) {
	return {
		L: A2($elm$core$Basics$modBy, $author$project$Game$numTiles, index),
		M: (index / $author$project$Game$numTiles) | 0
	};
};
var $author$project$Tiles$possiblyDisconnectedTilesGen = function () {
	var toTile = F2(
		function (index, isWall) {
			var xy = $author$project$Tiles$toXYPos(index);
			return isWall ? $author$project$Tile$wall(xy) : $author$project$Tile$floor(xy);
		});
	var toTiles = A2(
		$elm$core$Basics$composeR,
		$elm$core$Array$indexedMap(toTile),
		$elm$core$Basics$identity);
	var toPassableCount = A2(
		$elm$core$Array$foldl,
		F2(
			function (isWall, count) {
				return isWall ? count : (count + 1);
			}),
		0);
	var isWallArrayGen = A2(
		$elm$random$Random$map,
		$elm$core$Array$indexedMap(
			F2(
				function (i, bool) {
					return bool || (!$author$project$Tiles$inBounds(
						$author$project$Tiles$toXYPos(i)));
				})),
		A2(
			$elm$random$Random$map,
			$elm$core$Array$fromList,
			A2(
				$elm$random$Random$list,
				$author$project$Tiles$tileCount,
				A2(
					$elm$random$Random$map,
					function (x) {
						return x < 0.3;
					},
					$author$project$Randomness$probability))));
	return A2(
		$elm$random$Random$map,
		function (bools) {
			return _Utils_Tuple2(
				toTiles(bools),
				toPassableCount(bools));
		},
		isWallArrayGen);
}();
var $author$project$Map$tilesGen = A2(
	$elm$random$Random$andThen,
	function (_v0) {
		var tiles = _v0.a;
		var passableCount = _v0.b;
		return A2(
			$elm$random$Random$andThen,
			function (tileResult) {
				if (tileResult.$ === 1) {
					var e = tileResult.a;
					return $elm$random$Random$constant(
						$elm$core$Result$Err(
							$author$project$Tiles$noPassableTileToString(e)));
				} else {
					var tile = tileResult.a;
					return A2(
						$elm$random$Random$map,
						function (connectedTiles) {
							return _Utils_eq(
								passableCount,
								$elm$core$List$length(connectedTiles)) ? $elm$core$Result$Ok(tiles) : $elm$core$Result$Err('generate connected tiles');
						},
						A2($author$project$Map$getConnectedTiles, tiles, tile));
				}
			},
			$author$project$Tiles$randomPassableTile(tiles));
	},
	$author$project$Tiles$possiblyDisconnectedTilesGen);
var $author$project$Randomness$tryTo = function (generator) {
	return A2(
		$elm$random$Random$map,
		$elm$core$Result$mapError(
			$elm$core$Basics$append('Timeout while trying to ')),
		A2($author$project$Randomness$tryToHelper, generator, 1000));
};
var $author$project$Map$generateLevel = function (level) {
	return $author$project$Randomness$tryTo(
		A2(
			$elm$random$Random$andThen,
			function (tilesResult) {
				if (tilesResult.$ === 1) {
					var e = tilesResult.a;
					return $elm$random$Random$constant(
						$elm$core$Result$Err(e));
				} else {
					var tiles = tilesResult.a;
					return A2(
						$elm$random$Random$map,
						$elm$core$Result$mapError($author$project$Tiles$noPassableTileToString),
						A2($author$project$Map$generateMonsters, level, tiles));
				}
			},
			$author$project$Map$tilesGen));
};
var $author$project$GameModel$initialSpawnRate = 15;
var $elm$core$Result$map = F2(
	function (func, ra) {
		if (!ra.$) {
			var a = ra.a;
			return $elm$core$Result$Ok(
				func(a));
		} else {
			var e = ra.a;
			return $elm$core$Result$Err(e);
		}
	});
var $elm$random$Random$pair = F2(
	function (genA, genB) {
		return A3(
			$elm$random$Random$map2,
			F2(
				function (a, b) {
					return _Utils_Tuple2(a, b);
				}),
			genA,
			genB);
	});
var $author$project$GameModel$ALCHEMY = 8;
var $author$project$GameModel$AURA = 4;
var $author$project$GameModel$BOLT = 12;
var $author$project$GameModel$BRAVERY = 11;
var $author$project$GameModel$BUBBLE = 10;
var $author$project$GameModel$CROSS = 13;
var $author$project$GameModel$DASH = 5;
var $author$project$GameModel$DIG = 6;
var $author$project$GameModel$EX = 14;
var $author$project$GameModel$KINGMAKER = 7;
var $author$project$GameModel$MAELSTROM = 2;
var $author$project$GameModel$MULLIGAN = 3;
var $author$project$GameModel$POWER = 9;
var $author$project$GameModel$QUAKE = 1;
var $author$project$GameModel$WOOP = 0;
var $author$project$GameModel$spellNameGen = $author$project$Randomness$genFromNonEmpty(
	_Utils_Tuple2(
		0,
		_List_fromArray(
			[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])));
var $author$project$GameModel$spellsGen = function (numSpells) {
	var ns = A2(
		$elm$core$Basics$max,
		1,
		A2($elm$core$Basics$min, numSpells, 9));
	return A2(
		$elm$random$Random$map,
		$elm$core$Basics$identity,
		A2(
			$elm$random$Random$map,
			$elm$core$Dict$fromList,
			A2(
				$elm$random$Random$map,
				$elm$core$List$indexedMap(
					F2(
						function (a, b) {
							return _Utils_Tuple2(a + 1, b);
						})),
				A2($elm$random$Random$list, ns, $author$project$GameModel$spellNameGen))));
};
var $author$project$GameModel$refreshSpells = function (state) {
	var _v0 = A2(
		$elm$random$Random$step,
		$author$project$GameModel$spellsGen(state.A),
		state.g);
	var spells = _v0.a;
	var seed = _v0.b;
	return _Utils_update(
		state,
		{g: seed, n: spells});
};
var $author$project$GameModel$toResultOfListHelper = F2(
	function (results, output) {
		if (!results.b) {
			return $elm$core$Result$Ok(output);
		} else {
			if (!results.a.$) {
				var a = results.a.a;
				var rest = results.b;
				return A2(
					$author$project$GameModel$toResultOfListHelper,
					rest,
					A2($elm$core$List$cons, a, output));
			} else {
				var e = results.a.a;
				return $elm$core$Result$Err(e);
			}
		}
	});
var $author$project$GameModel$toResultOfList = function (results) {
	return A2($author$project$GameModel$toResultOfListHelper, results, _List_Nil);
};
var $author$project$GameModel$startLevel = F6(
	function (score, seedIn, hp, previousSpells, numSpells, levelNum) {
		var _v0 = A2(
			$elm$random$Random$step,
			$author$project$Map$generateLevel(levelNum),
			seedIn);
		var levelRes = _v0.a;
		var seed1 = _v0.b;
		var stateRes = A2(
			$elm$core$Result$andThen,
			function (tilesIn) {
				var tileGen = $author$project$Tiles$randomPassableTile(tilesIn);
				var _v2 = A2(
					$elm$random$Random$step,
					A2(
						$elm$random$Random$map,
						function (pair) {
							if ((!pair.b.a.$) && (!pair.b.b.$)) {
								var listOfResults = pair.a;
								var _v4 = pair.b;
								var t1 = _v4.a.a;
								var t2 = _v4.b.a;
								var _v5 = $author$project$GameModel$toResultOfList(listOfResults);
								if (!_v5.$) {
									var list = _v5.a;
									return $elm$core$Result$Ok(
										_Utils_Tuple3(t1, t2, list));
								} else {
									return $elm$core$Result$Err(0);
								}
							} else {
								return $elm$core$Result$Err(0);
							}
						},
						A2(
							$elm$random$Random$pair,
							A2($elm$random$Random$list, 3, tileGen),
							A2($elm$random$Random$pair, tileGen, tileGen))),
					seed1);
				var startingTilesRes = _v2.a;
				var seed = _v2.b;
				return A2(
					$elm$core$Result$map,
					function (_v6) {
						var playerTile = _v6.a;
						var exitTile = _v6.b;
						var treasureTiles = _v6.c;
						var player = {L: playerTile.L, M: playerTile.M};
						var tiles = A3(
							$author$project$Tiles$transform,
							function (t) {
								return _Utils_update(
									t,
									{I: 2});
							},
							exitTile,
							function (ts) {
								return A3(
									$elm$core$List$foldl,
									$author$project$Tiles$transform($author$project$Tile$addTreasure),
									ts,
									treasureTiles);
							}(
								A2(
									$author$project$Tiles$addMonster,
									tilesIn,
									{
										I: $author$project$Monster$Player(hp),
										L: player.L,
										M: player.M
									})));
						var state = {
							Z: levelNum,
							A: numSpells,
							m: player,
							a8: score,
							g: seed,
							W: {X: 0, ag: 0, ah: 0},
							aH: $author$project$GameModel$initialSpawnRate,
							aI: $author$project$GameModel$initialSpawnRate,
							n: $author$project$GameModel$emptySpells,
							a: tiles
						};
						if (!previousSpells.$) {
							var spells = previousSpells.a;
							return _Utils_update(
								state,
								{n: spells});
						} else {
							return $author$project$GameModel$refreshSpells(state);
						}
					},
					A2($elm$core$Result$mapError, $author$project$Tiles$noPassableTileToString, startingTilesRes));
			},
			levelRes);
		if (stateRes.$ === 1) {
			var e = stateRes.a;
			return $author$project$GameModel$Error(e);
		} else {
			var s = stateRes.a;
			return $author$project$GameModel$Running(s);
		}
	});
var $author$project$Ports$withNoCmd = function (a) {
	return _Utils_Tuple2(a, $author$project$Ports$noCmds);
};
var $author$project$GameModel$mulligan = function (state) {
	return $author$project$Ports$withNoCmd(
		A6(
			$author$project$GameModel$startLevel,
			state.a8,
			state.g,
			1,
			$elm$core$Maybe$Just(state.n),
			state.A,
			state.Z));
};
var $author$project$GameModel$power = $author$project$GameModel$requirePlayer(
	F2(
		function (player, state) {
			var newPlayer = _Utils_update(
				player,
				{aU: 5});
			var tiles = A3($author$project$Tiles$move, newPlayer, newPlayer, state.a).a;
			return A2($author$project$GameModel$changeTiles, tiles, state);
		}));
var $author$project$GameModel$quake = function (state) {
	var shakeIn = state.W;
	var folder = F2(
		function (xy, _v4) {
			var ts = _v4.a;
			var seedIn = _v4.b;
			var cmds = _v4.c;
			var tile = A2($author$project$Tiles$get, ts, xy);
			var _v1 = tile.e;
			if (!_v1.$) {
				var monsterIn = _v1.a;
				var _v2 = A2(
					$elm$random$Random$step,
					A2(
						$elm$random$Random$map,
						$elm$core$List$length,
						A2($author$project$Tiles$getAdjacentPassableNeighbors, ts, tile)),
					seedIn);
				var passableCount = _v2.a;
				var seedOut = _v2.b;
				var numWalls = 4 - passableCount;
				var _v3 = A2($author$project$Monster$hit, numWalls * 2, monsterIn);
				var monster = _v3.a;
				var hitCmds = _v3.b;
				return _Utils_Tuple3(
					A2(
						$author$project$Tiles$set,
						_Utils_update(
							tile,
							{
								e: $elm$core$Maybe$Just(monster)
							}),
						ts),
					seedOut,
					A2($elm$core$Array$append, cmds, hitCmds));
			} else {
				return _Utils_Tuple3(ts, seedIn, cmds);
			}
		});
	var _v0 = A2(
		$author$project$Tiles$foldXY,
		folder,
		_Utils_Tuple3(state.a, state.g, $author$project$Ports$noCmds));
	var tiles = _v0.a;
	var seed = _v0.b;
	var cmdsOut = _v0.c;
	return _Utils_Tuple2(
		$author$project$GameModel$Running(
			_Utils_update(
				state,
				{
					g: seed,
					W: _Utils_update(
						shakeIn,
						{X: 20}),
					a: tiles
				})),
		cmdsOut);
};
var $author$project$GameModel$woop = function (state) {
	var _v0 = A2(
		$elm$random$Random$step,
		$author$project$Tiles$randomPassableTile(state.a),
		state.g);
	var result = _v0.a;
	var seed = _v0.b;
	if (!result.$) {
		var target = result.a;
		var _v2 = A2($author$project$Tiles$get, state.a, state.m).e;
		if (_v2.$ === 1) {
			return _Utils_Tuple2(
				$author$project$GameModel$Error('Could not locate player'),
				$author$project$Ports$noCmds);
		} else {
			var player = _v2.a;
			var _v3 = A3($author$project$Tiles$move, player, target, state.a);
			var tiles = _v3.a;
			var moved = _v3.av;
			return $author$project$GameModel$runningWithNoCmds(
				_Utils_update(
					state,
					{
						m: $author$project$Game$plainPositioned(moved),
						a: tiles
					}));
		}
	} else {
		var _v4 = result.a;
		return _Utils_Tuple2(
			$author$project$GameModel$Error(
				$author$project$Tiles$noPassableTileToString(0)),
			$author$project$Ports$noCmds);
	}
};
var $author$project$GameModel$cast = function (name) {
	switch (name) {
		case 0:
			return $author$project$GameModel$woop;
		case 1:
			return $author$project$GameModel$quake;
		case 2:
			return $author$project$GameModel$maelstrom;
		case 3:
			return $author$project$GameModel$mulligan;
		case 4:
			return $author$project$GameModel$aura;
		case 5:
			return $author$project$GameModel$dash;
		case 6:
			return $author$project$GameModel$dig;
		case 7:
			return $author$project$GameModel$kingmaker;
		case 8:
			return $author$project$GameModel$alchemy;
		case 9:
			return $author$project$GameModel$power;
		case 10:
			return $author$project$GameModel$bubble;
		case 11:
			return $author$project$GameModel$bravery;
		case 12:
			return $author$project$GameModel$bolt;
		case 13:
			return $author$project$GameModel$cross;
		default:
			return $author$project$GameModel$ex;
	}
};
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === -1) && (dict.d.$ === -1)) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.e.d.$ === -1) && (!dict.e.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.d.d.$ === -1) && (!dict.d.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === -1) && (!left.a)) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === -1) && (right.a === 1)) {
					if (right.d.$ === -1) {
						if (right.d.a === 1) {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === -1) && (dict.d.$ === -1)) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor === 1) {
			if ((lLeft.$ === -1) && (!lLeft.a)) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === -1) {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === -1) && (left.a === 1)) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === -1) && (!lLeft.a)) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === -1) {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === -1) {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === -1) {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $author$project$GameModel$removeSpellName = F2(
	function (state, spellPage) {
		var _v0 = state.n;
		var spells = _v0;
		var key = function () {
			switch (spellPage) {
				case 0:
					return 1;
				case 1:
					return 2;
				case 2:
					return 3;
				case 3:
					return 4;
				case 4:
					return 5;
				case 5:
					return 6;
				case 6:
					return 7;
				case 7:
					return 8;
				default:
					return 9;
			}
		}();
		var _v1 = A2($elm$core$Dict$get, key, spells);
		if (!_v1.$) {
			var spellName = _v1.a;
			return $elm$core$Maybe$Just(
				_Utils_Tuple2(
					spellName,
					_Utils_update(
						state,
						{
							n: A2($elm$core$Dict$remove, key, spells)
						})));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Game$Loss = 0;
var $author$project$Ports$addScore = F2(
	function (score, outcome) {
		var scoreRow = {
			aQ: function () {
				if (!outcome) {
					return false;
				} else {
					return true;
				}
			}(),
			a7: 1,
			a8: score,
			bf: score
		};
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'kind',
					$elm$json$Json$Encode$string('addScore')),
					_Utils_Tuple2(
					'scoreObject',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								'score',
								function () {
									var _v0 = scoreRow.a8;
									var s = _v0;
									return $elm$json$Json$Encode$int(s);
								}()),
								_Utils_Tuple2(
								'run',
								$elm$json$Json$Encode$int(scoreRow.a7)),
								_Utils_Tuple2(
								'totalScore',
								function () {
									var _v1 = scoreRow.bf;
									var ts = _v1;
									return $elm$json$Json$Encode$int(ts);
								}()),
								_Utils_Tuple2(
								'active',
								$elm$json$Json$Encode$bool(scoreRow.aQ))
							])))
				]));
	});
var $author$project$Main$getPlayer = function (state) {
	return A2($author$project$Tiles$get, state.a, state.m).e;
};
var $author$project$Map$spawnMonster = function (tiles) {
	return A2($author$project$Map$addMonsters, 1, tiles);
};
var $author$project$Game$delatXFrom = F2(
	function (sourceX, targetX) {
		var _v0 = _Utils_Tuple2(sourceX, targetX);
		var sX = _v0.a;
		var tX = _v0.b;
		var delta = tX - sX;
		return _Utils_eq(delta, -1) ? $elm$core$Maybe$Just(2) : ((!delta) ? $elm$core$Maybe$Just(0) : ((delta === 1) ? $elm$core$Maybe$Just(1) : $elm$core$Maybe$Nothing));
	});
var $author$project$Game$delatYFrom = F2(
	function (sourceY, targetY) {
		var _v0 = _Utils_Tuple2(sourceY, targetY);
		var sY = _v0.a;
		var tY = _v0.b;
		var delta = tY - sY;
		return _Utils_eq(delta, -1) ? $elm$core$Maybe$Just(2) : ((!delta) ? $elm$core$Maybe$Just(0) : ((delta === 1) ? $elm$core$Maybe$Just(1) : $elm$core$Maybe$Nothing));
	});
var $author$project$Game$deltasFrom = function (_v0) {
	var source = _v0.ba;
	var target = _v0.bc;
	var _v1 = _Utils_Tuple2(
		A2($author$project$Game$delatXFrom, source.L, target.L),
		A2($author$project$Game$delatYFrom, source.M, target.M));
	if ((!_v1.a.$) && (!_v1.b.$)) {
		var dx = _v1.a.a;
		var dy = _v1.b.a;
		return $elm$core$Maybe$Just(
			_Utils_Tuple2(dx, dy));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Game$dist = F2(
	function (tile, other) {
		var _v0 = _Utils_Tuple2(tile.L, tile.M);
		var tX = _v0.a;
		var tY = _v0.b;
		var _v1 = _Utils_Tuple2(other.L, other.M);
		var oX = _v1.a;
		var oY = _v1.b;
		return $elm$core$Basics$abs(tX - oX) + $elm$core$Basics$abs(tY - oY);
	});
var $elm$core$List$sortBy = _List_sortBy;
var $author$project$Tiles$Bump = function (a) {
	return {$: 1, a: a};
};
var $author$project$Tiles$tryMove = F4(
	function (shake, monsterIn, deltas, tiles) {
		var newTile = A3($author$project$Tiles$getNeighbor, tiles, monsterIn, deltas);
		if ($author$project$Tile$isPassable(newTile)) {
			var monster = _Utils_update(
				monsterIn,
				{Y: deltas});
			return $elm$core$Maybe$Just(
				function () {
					var _v0 = newTile.e;
					if (_v0.$ === 1) {
						var tilesWithMoved = A3($author$project$Tiles$move, monster, newTile, tiles);
						return {aW: $elm$core$Array$empty, av: tilesWithMoved.av, W: shake, a: tilesWithMoved.a};
					} else {
						var target = _v0.a;
						if (!_Utils_eq(
							$author$project$Monster$isPlayer(monster.I),
							$author$project$Monster$isPlayer(target.I))) {
							var newMonster = _Utils_update(
								monster,
								{aS: true, aU: 0});
							var bumpMovement = $author$project$Tiles$Bump(
								_Utils_Tuple2(
									function () {
										var _v2 = _Utils_Tuple2(monster.L, target.L);
										var mX = _v2.a;
										var tX = _v2.b;
										return (tX - mX) / 2;
									}(),
									function () {
										var _v3 = _Utils_Tuple2(monster.M, target.M);
										var mY = _v3.a;
										var tY = _v3.b;
										return (tY - mY) / 2;
									}()));
							var _v1 = A2(
								$author$project$Monster$hit,
								1 + monster.aU,
								$author$project$Monster$stun(target));
							var newTarget = _v1.a;
							var cmds = _v1.b;
							return {
								aW: cmds,
								av: newMonster,
								W: _Utils_update(
									shake,
									{X: 5}),
								a: A4(
									$author$project$Tiles$moveInner,
									bumpMovement,
									newMonster,
									newMonster,
									A3($author$project$Tiles$move, newTarget, newTarget, tiles).a).a
							};
						} else {
							return {aW: $elm$core$Array$empty, av: monster, W: shake, a: tiles};
						}
					}
				}());
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Tiles$doStuff = F2(
	function (state, monster) {
		return A2(
			$elm$random$Random$map,
			function (neighbors) {
				var _v1 = A2(
					$elm$core$Maybe$andThen,
					function (newTile) {
						return A2(
							$elm$core$Maybe$andThen,
							function (deltas) {
								return A4($author$project$Tiles$tryMove, state.W, monster, deltas, state.a);
							},
							$author$project$Game$deltasFrom(
								{ba: monster, bc: newTile}));
					},
					$elm$core$List$head(
						A2(
							$elm$core$List$sortBy,
							$author$project$Game$dist(state.m),
							neighbors)));
				if (!_v1.$) {
					var tiles = _v1.a.a;
					var moved = _v1.a.av;
					var shake = _v1.a.W;
					var cmds = _v1.a.aW;
					return {
						aW: cmds,
						av: moved,
						k: _Utils_update(
							state,
							{W: shake, a: tiles})
					};
				} else {
					return {aW: $elm$core$Array$empty, av: monster, k: state};
				}
			},
			A2(
				$elm$random$Random$map,
				$elm$core$List$filter(
					function (t) {
						var _v0 = A2($author$project$Tiles$get, state.a, t).e;
						if (!_v0.$) {
							var m = _v0.a;
							return $author$project$Monster$isPlayer(m.I);
						} else {
							return true;
						}
					}),
				A2($author$project$Tiles$getAdjacentPassableNeighbors, state.a, monster)));
	});
var $author$project$Tiles$replace = F2(
	function (constructor, _v0) {
		var xPos = _v0.L;
		var yPos = _v0.M;
		var positioned = {L: xPos, M: yPos};
		return $author$project$Tiles$set(
			constructor(positioned));
	});
var $author$project$Tiles$setMonster = F2(
	function (monster, state) {
		var _v0 = A3($author$project$Tiles$moveDirectly, monster, monster, state.a);
		var tiles = _v0.a;
		var moved = _v0.av;
		return {
			aW: $elm$core$Array$empty,
			av: moved,
			k: _Utils_update(
				state,
				{a: tiles})
		};
	});
var $author$project$Tiles$updateMonsterInner = F2(
	function (monsterIn, stateIn) {
		var monster = _Utils_update(
			monsterIn,
			{bd: monsterIn.bd - 1});
		if (monster.aJ || (monster.bd > 0)) {
			return A2(
				$author$project$Tiles$setMonster,
				_Utils_update(
					monster,
					{aJ: false}),
				stateIn);
		} else {
			var noChange = {aW: $elm$core$Array$empty, av: monster, k: stateIn};
			var gen = function () {
				var _v1 = monster.I;
				switch (_v1.$) {
					case 0:
						return $elm$random$Random$constant(noChange);
					case 1:
						return A2($author$project$Tiles$doStuff, stateIn, monster);
					case 2:
						return A2(
							$elm$random$Random$andThen,
							function (_v2) {
								var state = _v2.k;
								var moved = _v2.av;
								return moved.aS ? $elm$random$Random$constant(noChange) : A2($author$project$Tiles$doStuff, state, moved);
							},
							A2(
								$author$project$Tiles$doStuff,
								stateIn,
								_Utils_update(
									monster,
									{aS: false})));
					case 3:
						return A2($author$project$Tiles$doStuff, stateIn, monster);
					case 4:
						return A2(
							$elm$random$Random$andThen,
							function (neighbors) {
								if (!neighbors.b) {
									return A2($author$project$Tiles$doStuff, stateIn, monster);
								} else {
									var head = neighbors.a;
									return $elm$random$Random$constant(
										function (_v4) {
											var state = _v4.k;
											var moved = _v4.av;
											return {aW: $elm$core$Array$empty, av: moved, k: state};
										}(
											A2(
												$author$project$Tiles$setMonster,
												A2($author$project$Monster$heal, 0.5, monster),
												_Utils_update(
													stateIn,
													{
														a: A3($author$project$Tiles$replace, $author$project$Tile$floor, head, stateIn.a)
													}))));
								}
							},
							A2(
								$elm$random$Random$map,
								$elm$core$List$filter(
									function (t) {
										return (!$author$project$Tile$isPassable(t)) && $author$project$Tiles$inBounds(t);
									}),
								A2($author$project$Tiles$getAdjacentNeighbors, stateIn.a, monster)));
					default:
						return A2(
							$elm$random$Random$map,
							function (neighbors) {
								if (!neighbors.b) {
									return noChange;
								} else {
									var head = neighbors.a;
									var _v6 = A2(
										$elm$core$Maybe$andThen,
										function (deltas) {
											return A4($author$project$Tiles$tryMove, stateIn.W, monster, deltas, stateIn.a);
										},
										$author$project$Game$deltasFrom(
											{ba: monster, bc: head}));
									if (_v6.$ === 1) {
										return noChange;
									} else {
										var tiles = _v6.a.a;
										var moved = _v6.a.av;
										var shake = _v6.a.W;
										var cmds = _v6.a.aW;
										return {
											aW: cmds,
											av: moved,
											k: _Utils_update(
												stateIn,
												{W: shake, a: tiles})
										};
									}
								}
							},
							A2($author$project$Tiles$getAdjacentPassableNeighbors, stateIn.a, monster));
				}
			}();
			return function (_v0) {
				var output = _v0.a;
				var state = output.k;
				var seed = _v0.b;
				return _Utils_update(
					output,
					{
						k: _Utils_update(
							state,
							{g: seed})
					});
			}(
				A2($elm$random$Random$step, gen, stateIn.g));
		}
	});
var $author$project$Tiles$updateMonster = F2(
	function (monster, _v0) {
		var stateIn = _v0.a;
		var cmdsIn = _v0.b;
		var _v1 = monster.I;
		if (_v1.$ === 3) {
			var startedStunned = monster.aJ;
			var _v2 = A2($author$project$Tiles$updateMonsterInner, monster, stateIn);
			var state = _v2.k;
			var moved = _v2.av;
			var cmds = _v2.aW;
			if (startedStunned) {
				return _Utils_Tuple2(state, cmds);
			} else {
				var newMonster = $author$project$Monster$stun(moved);
				var _v3 = A3($author$project$Tiles$moveDirectly, newMonster, newMonster, state.a);
				var tiles = _v3.a;
				return _Utils_Tuple2(
					_Utils_update(
						state,
						{a: tiles}),
					cmds);
			}
		} else {
			var record = A2($author$project$Tiles$updateMonsterInner, monster, stateIn);
			return _Utils_Tuple2(
				record.k,
				A2($elm$core$Array$append, cmdsIn, record.aW));
		}
	});
var $author$project$Main$tick = function (stateIn) {
	return function (_v7) {
		var s = _v7.a;
		var cmds = _v7.b;
		var _v8 = $author$project$Main$getPlayer(s);
		if (_v8.$ === 1) {
			return _Utils_Tuple2(
				$author$project$GameModel$Running(s),
				cmds);
		} else {
			var player = _v8.a;
			return player.am ? _Utils_Tuple2(
				$author$project$GameModel$Dead(s),
				A2(
					$elm$core$Array$push,
					A2($author$project$Ports$addScore, s.a8, 0),
					cmds)) : _Utils_Tuple2(
				$author$project$GameModel$Running(s),
				cmds);
		}
	}(
		function (_v3) {
			var state = _v3.a;
			var cmds = _v3.b;
			var s = _Utils_update(
				state,
				{aH: state.aH - 1});
			return _Utils_Tuple2(
				(s.aH <= 0) ? function (_v4) {
					var tilesRes = _v4.a;
					var seed = _v4.b;
					return _Utils_update(
						s,
						{
							g: seed,
							aH: s.aI,
							aI: s.aI - 1,
							a: function () {
								if (!tilesRes.$) {
									var tiles = tilesRes.a;
									return tiles;
								} else {
									var _v6 = tilesRes.a;
									return s.a;
								}
							}()
						});
				}(
					function (tilesGen) {
						return A2($elm$random$Random$step, tilesGen, s.g);
					}(
						$author$project$Map$spawnMonster(s.a))) : s,
				cmds);
		}(
			A3(
				$elm$core$List$foldr,
				F2(
					function (_v1, _v2) {
						var tile = _v1.a;
						var m = _v1.b;
						var state = _v2.a;
						var cmds = _v2.b;
						return $author$project$Monster$isPlayer(m.I) ? _Utils_Tuple2(
							_Utils_update(
								state,
								{
									a: A2(
										$author$project$Tiles$set,
										_Utils_update(
											tile,
											{
												e: $elm$core$Maybe$Just(
													_Utils_update(
														m,
														{a9: m.a9 - 1}))
											}),
										state.a)
								}),
							cmds) : (m.am ? _Utils_Tuple2(
							_Utils_update(
								state,
								{
									a: A2(
										$author$project$Tiles$set,
										_Utils_update(
											tile,
											{e: $elm$core$Maybe$Nothing}),
										state.a)
								}),
							cmds) : A2(
							$author$project$Tiles$updateMonster,
							m,
							_Utils_Tuple2(state, cmds)));
					}),
				_Utils_Tuple2(stateIn, $elm$core$Array$empty),
				A2(
					$author$project$Tiles$foldXY,
					F2(
						function (xy, list) {
							var _v0 = function (t) {
								return A2(
									$elm$core$Maybe$map,
									function (m) {
										return _Utils_Tuple2(t, m);
									},
									t.e);
							}(
								A2($author$project$Tiles$get, stateIn.a, xy));
							if (_v0.$ === 1) {
								return list;
							} else {
								var pair = _v0.a;
								return A2($elm$core$List$cons, pair, list);
							}
						}),
					_List_Nil))));
};
var $author$project$Main$castSpell = F2(
	function (state, spellPage) {
		var _v0 = A2($author$project$GameModel$removeSpellName, state, spellPage);
		if (_v0.$ === 1) {
			return $author$project$Ports$withNoCmd(
				$author$project$GameModel$Running(state));
		} else {
			var _v1 = _v0.a;
			var spellName = _v1.a;
			var spellRemovedState = _v1.b;
			var _v2 = A2($author$project$GameModel$cast, spellName, spellRemovedState);
			switch (_v2.a.$) {
				case 2:
					var runningState = _v2.a.a;
					var cmds = _v2.b;
					var _v3 = $author$project$Main$tick(runningState);
					var runningTickState = _v3.a;
					var tickCmds = _v3.b;
					return _Utils_Tuple2(
						runningTickState,
						A2(
							$elm$core$Array$push,
							$author$project$Ports$playSound(4),
							A2($elm$core$Array$append, tickCmds, cmds)));
				case 3:
					var deadState = _v2.a.a;
					var cmds = _v2.b;
					var _v4 = $author$project$Main$tick(deadState);
					var deadTickState = _v4.a;
					var tickCmds = _v4.b;
					return _Utils_Tuple2(
						deadTickState,
						A2(
							$elm$core$Array$push,
							$author$project$Ports$playSound(4),
							A2($elm$core$Array$append, tickCmds, cmds)));
				default:
					var otherwise = _v2;
					return otherwise;
			}
		}
	});
var $author$project$Ports$NewLevel = 3;
var $author$project$Ports$Treasure = 2;
var $author$project$Game$Win = 1;
var $author$project$GameModel$maxNumSpells = 9;
var $elm$core$List$sort = function (xs) {
	return A2($elm$core$List$sortBy, $elm$core$Basics$identity, xs);
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$GameModel$addSpell = F2(
	function (book, seedIn) {
		var spellsIn = book;
		var list = $elm$core$Dict$toList(spellsIn);
		var lastIndex = $elm$core$List$length(list) - 1;
		var maxKey = A2(
			$elm$core$Maybe$withDefault,
			0,
			$elm$core$List$head(
				A2(
					$elm$core$List$drop,
					lastIndex,
					$elm$core$List$sort(
						A2(
							$elm$core$List$map,
							function (_v2) {
								var i = _v2.a;
								return i;
							},
							list)))));
		var _v1 = A2($elm$random$Random$step, $author$project$GameModel$spellNameGen, seedIn);
		var newSpell = _v1.a;
		var seed = _v1.b;
		return (_Utils_cmp(maxKey, $author$project$GameModel$maxNumSpells) < 0) ? _Utils_Tuple2(
			A3($elm$core$Dict$insert, maxKey + 1, newSpell, spellsIn),
			seed) : _Utils_Tuple2(book, seedIn);
	});
var $author$project$GameModel$addSpellViaTreasureIfApplicable = function (state) {
	if (function () {
		var _v0 = state.a8;
		var score = _v0;
		return !(score % 3);
	}() && (_Utils_cmp(state.A, $author$project$GameModel$maxNumSpells) < 0)) {
		var _v1 = A2($author$project$GameModel$addSpell, state.n, state.g);
		var spells = _v1.a;
		var seed = _v1.b;
		return _Utils_update(
			state,
			{A: state.A + 1, g: seed, n: spells});
	} else {
		return state;
	}
};
var $author$project$Game$LevelNum = $elm$core$Basics$identity;
var $author$project$Game$incLevel = function (levelNum) {
	var l = levelNum;
	return l + 1;
};
var $author$project$Main$incScore = function (score) {
	var s = score;
	return s + 1;
};
var $author$project$Main$numLevels = 6;
var $author$project$Main$movePlayer = F2(
	function (deltas, stateIn) {
		var m = A2(
			$elm$core$Maybe$andThen,
			function (p) {
				return A2(
					$elm$core$Maybe$map,
					function (record) {
						return _Utils_Tuple2(record, p);
					},
					A4($author$project$Tiles$tryMove, stateIn.W, p, deltas, stateIn.a));
			},
			$author$project$Main$getPlayer(stateIn));
		if (m.$ === 1) {
			return $author$project$Ports$withNoCmd(
				$author$project$GameModel$Running(stateIn));
		} else {
			var _v1 = m.a;
			var record = _v1.a;
			var player = _v1.b;
			var movedTiles = record.a;
			var moved = record.av;
			var movedState = _Utils_update(
				stateIn,
				{
					m: {L: moved.L, M: moved.M},
					W: record.W,
					a: movedTiles
				});
			var tile = A2($author$project$Tiles$get, movedTiles, moved);
			var _v2 = function () {
				var _v3 = tile.I;
				switch (_v3) {
					case 2:
						if (_Utils_eq(movedState.Z, $author$project$Main$numLevels)) {
							return function (s) {
								return _Utils_Tuple2(
									A2(
										$author$project$GameModel$Title,
										$elm$core$Maybe$Just(s),
										s.g),
									A2(
										$elm$core$Array$repeat,
										1,
										A2($author$project$Ports$addScore, s.a8, 1)));
							}(movedState);
						} else {
							var hp = function () {
								var _v4 = player.a$;
								var h = _v4;
								return A2($elm$core$Basics$min, $author$project$Monster$maxHP, h + 1);
							}();
							return _Utils_Tuple2(
								A6(
									$author$project$GameModel$startLevel,
									movedState.a8,
									movedState.g,
									hp,
									$elm$core$Maybe$Nothing,
									movedState.A,
									$author$project$Game$incLevel(movedState.Z)),
								A2(
									$elm$core$Array$repeat,
									1,
									$author$project$Ports$playSound(3)));
						}
					case 0:
						if (tile.aM) {
							var collectedTiles = A2(
								$author$project$Tiles$set,
								_Utils_update(
									tile,
									{aM: false}),
								movedState.a);
							var _v5 = A2(
								$elm$random$Random$step,
								$author$project$Map$spawnMonster(collectedTiles),
								movedState.g);
							var tilesRes = _v5.a;
							var seed = _v5.b;
							var tiles = function () {
								if (tilesRes.$ === 1) {
									return collectedTiles;
								} else {
									var ts = tilesRes.a;
									return ts;
								}
							}();
							return _Utils_Tuple2(
								$author$project$GameModel$Running(
									$author$project$GameModel$addSpellViaTreasureIfApplicable(
										_Utils_update(
											movedState,
											{
												a8: $author$project$Main$incScore(movedState.a8),
												g: seed,
												a: tiles
											}))),
								A2(
									$elm$core$Array$repeat,
									1,
									$author$project$Ports$playSound(2)));
						} else {
							return $author$project$Ports$withNoCmd(
								$author$project$GameModel$Running(movedState));
						}
					default:
						return $author$project$Ports$withNoCmd(
							$author$project$GameModel$Running(movedState));
				}
			}();
			var preTickModel = _v2.a;
			var preTickCmds = _v2.b;
			var _v7 = function () {
				_v8$3:
				while (true) {
					switch (preTickModel.$) {
						case 2:
							var s = preTickModel.a;
							return $author$project$Main$tick(s);
						case 3:
							var s = preTickModel.a;
							return $author$project$Main$tick(s);
						case 1:
							if (!preTickModel.a.$) {
								var s = preTickModel.a.a;
								var seed = preTickModel.b;
								var _v9 = $author$project$Main$tick(s);
								var gm = _v9.a;
								var cmds = _v9.b;
								_v10$3:
								while (true) {
									switch (gm.$) {
										case 2:
											var st = gm.a;
											return _Utils_Tuple2(
												A2(
													$author$project$GameModel$Title,
													$elm$core$Maybe$Just(st),
													seed),
												cmds);
										case 3:
											var st = gm.a;
											return _Utils_Tuple2(
												A2(
													$author$project$GameModel$Title,
													$elm$core$Maybe$Just(st),
													seed),
												cmds);
										case 1:
											if (!gm.a.$) {
												var st = gm.a.a;
												var seed2 = gm.b;
												return _Utils_Tuple2(
													A2(
														$author$project$GameModel$Title,
														$elm$core$Maybe$Just(st),
														seed2),
													cmds);
											} else {
												break _v10$3;
											}
										default:
											break _v10$3;
									}
								}
								return $author$project$Ports$withNoCmd(preTickModel);
							} else {
								break _v8$3;
							}
						default:
							break _v8$3;
					}
				}
				return $author$project$Ports$withNoCmd(preTickModel);
			}();
			var postTickModel = _v7.a;
			var postTickCmds = _v7.b;
			return _Utils_Tuple2(
				postTickModel,
				A2(
					$elm$core$Array$append,
					A2($elm$core$Array$append, record.aW, preTickCmds),
					postTickCmds));
		}
	});
var $author$project$Main$startingHp = 3;
var $author$project$Main$startGame = function (seedIn) {
	return A6($author$project$GameModel$startLevel, 0, seedIn, $author$project$Main$startingHp, $elm$core$Maybe$Nothing, 1, 1);
};
var $author$project$Main$updateGame = F2(
	function (input, model) {
		switch (model.$) {
			case 1:
				var seed = model.b;
				return $author$project$Ports$withNoCmd(
					$author$project$Main$startGame(seed));
			case 2:
				var state = model.a;
				switch (input.$) {
					case 1:
						return A2(
							$author$project$Main$movePlayer,
							_Utils_Tuple2(0, 2),
							state);
					case 2:
						return A2(
							$author$project$Main$movePlayer,
							_Utils_Tuple2(0, 1),
							state);
					case 3:
						return A2(
							$author$project$Main$movePlayer,
							_Utils_Tuple2(2, 0),
							state);
					case 4:
						return A2(
							$author$project$Main$movePlayer,
							_Utils_Tuple2(1, 0),
							state);
					case 5:
						var spellIndex = input.a;
						return A2($author$project$Main$castSpell, state, spellIndex);
					default:
						return $author$project$Ports$withNoCmd(
							$author$project$GameModel$Running(state));
				}
			case 3:
				var state = model.a;
				return $author$project$Ports$withNoCmd(
					A2(
						$author$project$GameModel$Title,
						$elm$core$Maybe$Just(state),
						state.g));
			default:
				return $author$project$Ports$withNoCmd(model);
		}
	});
var $author$project$Main$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 0:
				return $author$project$Main$performWithModel(
					$author$project$Main$draw(model));
			case 1:
				var input = msg.a;
				var _v1 = A2($author$project$Main$updateGame, input, model.t);
				var game = _v1.a;
				var updateCmds = _v1.b;
				var newModel = _Utils_update(
					model,
					{t: game});
				var _v2 = $author$project$Main$draw(newModel);
				var finalModel = _v2.a;
				var drawCmds = _v2.b;
				return _Utils_Tuple2(
					finalModel,
					$author$project$Ports$perform(
						A2($elm$core$Array$append, updateCmds, drawCmds)));
			default:
				if (!msg.a.$) {
					var scores = msg.a.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{D: scores}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
		}
	});
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Main$view = function (model) {
	var _v0 = model.t;
	if (!_v0.$) {
		var e = _v0.a;
		return $elm$html$Html$text(e);
	} else {
		return $elm$html$Html$text('');
	}
};
var $author$project$Main$main = $elm$browser$Browser$element(
	{a1: $author$project$Main$init, bb: $author$project$Main$subscriptions, bg: $author$project$Main$update, bh: $author$project$Main$view});
_Platform_export({'Main':{'init':$author$project$Main$main($elm$json$Json$Decode$value)(0)}});}(this));