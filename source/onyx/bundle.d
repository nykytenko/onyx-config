/**
 * Container for data (for example configurations data)
 *
 * Copyright: © 2014-2015
 * License: MIT license. License terms written in licence.txt file
 *
 * Authors: Oleg Nykytenko (onyx), onyx.itdevelopment@gmail.com
 *
 * Version: 1.xx Date: 11.02.2014
 *
 * Version: 2.xx Date: 25.10.2015
 *
 *
 *
 * Examples:
 * ------------------------------------------------------------------------
 * Build immutable Bundle from config text file:
 * ------------------------------------------------------------------------
 * auto bundle = new immutable Bundle("../conf/file.conf");
 *
 * ------------------------------------------------------------------------
 * Build Bundle from string array:
 * ------------------------------------------------------------------------
 * string[] s = 
 *		["[general]",
 *		 "module_name = KPR",
 *		 "mod_type = RptR11Transceiver",
 *		 "[protocol]",
 *		 "data_flow = input"];	
 *
 * auto bundle = new immutable Bundle(s);
 *
 *
 * ------------------------------------------------------------------------
 * Build Bundle with custom parameters:
 * ------------------------------------------------------------------------
 * auto parameters = immutable Parameters(
 * 		"[",				// Start Global key symbols
 *		"]",				// End Global key symbols
 *		["=", " ", "->"],	// Separator symbols between "Key" and "Values"
 *		"#");				// Comment symbols
 *
 *	auto bundle = new immutable Bundle(s, parameters);
 *
 * ------------------------------------------------------------------------
 * Configuration file Exaple:
 * ------------------------------------------------------------------------
 *
 * # This is config file for RptR11 protocol Transceiver
 *
 * [general]
 * #------------------------------------------------------------
 * mod_name = KPR
 * mod_type = RptR11Transceiver
 *
 *
 * [log]
 * #-----------------------------------------------------------------
 * level = debug
 * appender = FileAppender
 * rolling = SizeBasedRollover
 * maxSize = 2K
 * maxHistory = 4
 * fileName = ./log/MainDebug.log
 *
 *
 * [protocol]
 * #------------------------------------------------------------
 * regime = slave #master - KPR; slave - OIK;
 * adr_RTU = 0x0A
 *
 *
 * [data_receive]
 * #----------------------------------------------------------------------------------------------------
 * # Addr in	Addr_out	type_of_data	name_of_data		send_to_next	channel		Formula
 * # KPR_adr	UTS_PMZ															priority
 * #----------------------------------------------------------------------------------------------------
 * #
 * 0xC000	->	0xC000		0x0B			XGES_Р_Станції		yes					1		(2*{0xC000}+10)+(-0.2*{0xC179}-5)+(0
 * 0xC000~1	->  0xC001		0x0B			XYGES_Р_Станції		yes					2		(1*{0xC000}+0)
 * 0xC179	->	0xC179		0x0B			XaES_Р_Станції		yes					1		1*{0xC179}+0
 *
 */
 

module onyx.bundle;

@safe:


/************************************************************************************/
/* Bundle element types 															*/
/************************************************************************************/

/**
 * Values - save one set of data in array.
 *
 * string[] - data array
 */
alias string[] Values;


/**
 * Key - string key for Values
 */
alias string Key;


/**
 * GlValue - Bundle global data group
 */
alias Values[Key] GlValue; 


/**
 * GlKey - string key in Bundle for data group
 */
alias string GlKey;



/**
 * Configuration exception
 */
class BundleException:Exception 
{
	@safe
	this(string exString) pure nothrow
	{
		super(exString);
	}
}


/**
 * Construct exception with parrent: ConfException
 *
 */
template childBundleException(string exceptionName)
{
	const char[] childBundleException =

	"class " ~exceptionName~":BundleException 
	{
		@safe
		this(string exString) pure nothrow
		{
			super(exString);
		}
	}";
}


mixin(childBundleException!"GlKeyNotFoundException");
mixin(childBundleException!"KeyNotFoundException");
mixin(childBundleException!"ValuesNotFoundException");
mixin(childBundleException!"ValueNotFoundException");



/************************************************************************************/
/* Parameters for parsing and building bundle										*/
/************************************************************************************/
struct Parameters
{
	/*
	 * Start and End Global key symbols
	 */
	immutable string startGlKeySymbol = "[";
	immutable string endGlKeySymbol = "]";


	/*
	 * Separator symbol between "Key" and "Values"
	 */
	immutable string[] keySeparators = ["="];


	/*
	 *  Comment symbol
	 */
	immutable string commentSymbol = "#";


	/**
	 * Create parameters
	 */
	immutable nothrow pure
	this(immutable string startGlKeySymbol,
		immutable string endGlKeySymbol,
		immutable string[] keySeparators,
		immutable string commentSymbol)
	{
		this.startGlKeySymbol = startGlKeySymbol;
		this.endGlKeySymbol = endGlKeySymbol;
		this.keySeparators = keySeparators;
		this.commentSymbol = commentSymbol;
	}
}



unittest
{
	auto parameters = immutable Parameters("<", ")", ["=", " ", "->"], "#");
}



/************************************************************************************/
/* Data container 																	*/
/************************************************************************************/
/**
 * Bundle save data in container (associative array GlValue[GlKey]).
 *
 * Container structure:
 * 		GlKey1 -> GlValue1
 *		GlKey2 -> GlValue2
 *		GlKey3 -> GlValue3
 *		..................
 *		GlKeyN -> GlValueN
 * 						|
 * 						|=> Key1 -> Values1
 * 							Key2 -> Values2
 * 							..............
 * 							KeyM -> ValuesM
 * 										|
 * 										|=> [DataValue1, DataValue2, ... DataValueP]
 */
class Bundle
{
	/*
	 * Data inner container
	 */
	private GlValue[GlKey] container;



	/**
	 * Build Bundle from text file
	 *
	 * Throws: BundleException, GlKeyNotFoundException, KeyNotFoundException, ValuesNotFoundException, Exception
	 */
	@trusted
	this(string filePath, immutable Parameters pars = immutable Parameters()) immutable
	{
		auto lines = copyFileToStrings(filePath);
		this(lines, pars);
	}
	


	/**
	 * Build Bundle from string array
	 *
	 * Throws: BundleException, GlKeyNotFoundException, KeyNotFoundException, ValuesNotFoundException, Exception
	 */
	this(string[] lines, immutable Parameters pars = immutable Parameters()) immutable
	{
		string[int] nlines;
		int index = 0;
		foreach(line; lines)	nlines[++index] = line;
		this(nlines, pars);
	}



	/**
	 * Build Bundle from string array
	 *
	 * Throws: BundleException, GlKeyNotFoundException, KeyNotFoundException, ValuesNotFoundException, Exception
	 */
	@trusted
	this(string[int] lines, immutable Parameters pars = immutable Parameters()) immutable
	{
		container = buildContainer(lines, pars);
	}


	/**
	 * Build Bundle from Bundle
	 */
	private this(immutable GlValue[GlKey] c) nothrow pure immutable
	{
		container = c;
	}



	/**
	 * Get Global value from bundle
	 *
	 * Returns: GlValue - content of one bundle block
	 *
	 * Throws: GlKeyNotFoundException, BundleException
	 */
	immutable (GlValue) glValue(GlKey glKey) pure immutable
	{
		if (glKey is null)
		{
			throw new BundleException("Global Key is null");
		}
		if (glKey !in container) 
		{
			throw new GlKeyNotFoundException("Not found Global Key: ["~glKey~"]");
		}
		return container[glKey];
	}



	/**
	 * Get Values from bundle
	 *
	 * Returns: Values - content of one bundle line
	 *
	 * Throws: ValuesNotFoundException, KeyNotFoundException, GlKeyNotFoundException, BundleException
	 */
	immutable (Values) values(GlKey glKey, Key key) pure immutable
	{
		if (key is null)
		{
			throw new BundleException("Key is null");
		}
		immutable glV = glValue(glKey);
		if (key !in glV)
		{
			throw new KeyNotFoundException("Not found Key: ["~glKey~"] -> "~key);
		}
		immutable vs = glV[key];
		if ((vs is null) || (vs.length == 0))
		{
			throw new ValuesNotFoundException("For key: ["~glKey~"] -> "~key~" values not found");
		}
		return vs;
	}



	/**
	 * Get one value from bundle
	 *
	 * Returns: Value - one string value from bundle line
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, BundleException
	 */
	@trusted
	immutable (T) value(T=string)(GlKey glKey, Key key, uint pos) pure immutable
	{
		string vExceptionMsg = "Not found value: ["~glKey~"] -> "~key~" = values["~to!string(pos)~"]";
		try
		{
			immutable tValues = values(glKey, key);
			if ((tValues.length <= pos) || (tValues[pos] is null))
			{
				throw new ValueNotFoundException(vExceptionMsg);
			}
			return strToNum!T(tValues[pos]);
		}
		catch (ValuesNotFoundException vse)
		{
			throw new ValueNotFoundException(vExceptionMsg);
		}
	}


	/**
	 * Get one value from bundle
	 *
	 * Returns: Value - first string value from bundle line
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 */
	immutable (T) value(T=string)(GlKey glKey, Key key) pure immutable
	{
		return value!T(glKey, key, 0);
	}


	/**
	 * Check if value present in bundle (pos value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	bool isValuePresent(GlKey glKey, Key key, int pos) nothrow pure immutable
	{
		try
		{
			value(glKey, key, pos);
			return true;
		}
		catch(Exception e)
		{
			return false;
		}
	}



	/**
	 * Check is value present in bundle (First value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	bool isValuePresent(GlKey glKey, Key key) pure immutable nothrow
	{
		return isValuePresent(glKey, key, 0);
	}



	/**
	 * Check is global key present in bundle 
	 *
	 * Returns: if key present in bundle - true, else - false
	 */
	bool isGlKeyPresent(GlKey glKey) immutable pure nothrow
	{
		return ((glKey in container)==null)?false:true;
	}



	/**
	 * Get global keys present in bundle 
	 *
	 * Returns: GlKey array
	 */
	@trusted /* array.keys is system */
	immutable (GlKey[]) glKeys() immutable pure nothrow
	{
		return container.keys;
	}


	/**
	 * Get keys present in bundle at one global key
	 *
	 * Returns: Key array
	 */
	@trusted /* array.keys is system */
	immutable (Key[]) keys(GlKey glKey) immutable pure nothrow
	{
		return container[glKey].keys;
	}



	/**
	 * Add two bundles (this and rBundle)
	 *
	 * Returns: New Configuration bundle with data from this bundle and rBundle bundle
	 *
	 * Throws: ConfException
	 *
	 * Example:
	 * auto bundle1 = ConfBundle("./conf1/receiver1.conf");
	 * auto bundle2 = ConfBundle(confArray);
	 * auto bundle = bundle1 + bundle2;
	 */
	@trusted
	immutable (Bundle) opBinary(string op)(immutable Bundle rBundle) immutable if (op == "+")
	{
		auto mutc = Bundle.dup(this);
		auto mutcr = Bundle.dup(rBundle);

		//std.stdio.writeln(mutc.type);

		foreach (glKey; mutcr.keys)
		{
			auto rGlValue = mutcr[glKey];
			if (glKey !in mutc)
					mutc[glKey] = rGlValue;
				else
				{
					auto lGlValue = mutc[glKey];
					foreach (key; rGlValue.keys)
					{
						if (key !in mutc[glKey])
						{
							lGlValue[key] = rGlValue[key];
						}
					}
				}
		}
		import std.exception;
		return new immutable Bundle(assumeUnique(mutc));
	}



	/**
	 * Get from this bundle one global data part
	 *
	 * Returns: New bundle with one global part data
	 */
	immutable (Bundle) subBundle(GlKey glKey) immutable
	{
		return new immutable Bundle([glKey:container[glKey]]);
	}



	/**
	 * Make muttable copy of bundle container
	 *
	 * Returns: bundle container
	 */
	@trusted
	static GlValue[GlKey] dup(immutable Bundle bundle)
	{
		GlValue[GlKey] mutc;
		foreach (glKey; bundle.container.keys)
		{
			Values[Key] mutglValue;
			
			auto glValue = bundle.container[glKey];

			foreach(key; glValue.keys)
			{
				mutglValue[key] = glValue[key].dup;
			}
			mutc[glKey] = mutglValue;
			mutglValue = null;			
		}
		return mutc;
	}

}


/************************************************************************************/
/* Lib tests 																		*/
/************************************************************************************/
unittest
{
	string[] s = 
		["[general] 			# GlKey = general",
		 "module_name = Main 	# Key = module_name, Values[0] = Main, keySeparator = EQUALS SIGN",
		 "[DebugLogger]			# GlKey = DebugLogger",
		 "level = debug",
		 "appender = FileAppender",
		 "rolling = SizeBasedRollover",
		 "fileName = ./log/MainDebug.log",
		 "[empty_gl_key]", // Test GlKey with empty GlValue
		 "[data_receive]",
		 "# Key = 0xC000, Values[0] = 0x014B, Values[1] = 0x0B, keySeparator = SPACE",
		 "0xC000 		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];

	auto p = immutable Parameters("[", "]", ["=", " "], "#");

	auto bundle = new immutable Bundle(s, p);


	// glValue test
	{
		auto glValue = bundle.glValue("general");
		immutable gv = ["module_name":["Main"]];
		assert (glValue == gv);
	}

	// Emty GlValue test
	{
		auto glValue = bundle.glValue("empty_gl_key");
		assert (glValue == null);
	}

	// values test
	{
		auto values = bundle.values("DebugLogger", "level");
		assert (values == ["debug"]);

	}

	// Value test (N pos)
	{ 
		auto value = bundle.value("data_receive", "0xC000", 3);
		//assert (value == "yes");
	}

	// Value test (0 pos)
	{
		auto value = bundle.value("data_receive", "0xC000");
		assert (value == "0x014B");
	}

	// int Value test (0 pos)
	{
		auto value = bundle.value!int("data_receive", "0xC000");
		assert (value == 0x014B);
	}


	// isValuePresent test
	{
		auto present = bundle.isValuePresent("data_receive", "0xC000", 1);
		assert (present == true);
		auto nopresent = bundle.isValuePresent("general", "module_name", 5);
		assert (nopresent == false);
	}

	// isGlKeyPresent
	{
		auto present = bundle.isGlKeyPresent("DebugLogger");
		assert (present == true);
		auto nopresent = bundle.isGlKeyPresent("superkey");
		assert (nopresent == false);
	}
}



unittest
{
	version(vTest)
	{
		auto p = immutable Parameters("[", "]", ["=", "->"], "#");

		auto bundle = new immutable Bundle("./test/test.conf", p);

		// getGlValue test
		{
			auto glValue = bundle.glValue("general");
			immutable gv = ["mod_name":["KPR"], "mod_type":["RptR11Transceiver"]];
			assert (glValue == gv);
		}

		// getValues test
		{
			auto values = bundle.values("protocol", "channel_switch_timeout");
			assert (values == ["1000", "100", "10"]);
		}


		/* get value for line with many values from possition 1 */
		{
			auto value = bundle.value("protocol", "channel_switch_timeout", 1); 
			assert (value == "100");
		}

		// getValue test (N pos)
		{ 
			auto value = bundle.value("data_receive", "0xC000~1", 5);
			assert (value == "(1*{0xC000}+0)");
		}

		// getValue test (0 pos)
		{
			auto value = bundle.value!int("data_receive", "0xC179");
			assert (value == 0xC179);
		}

	}
}



unittest
{
	string[] s;

	s ~= ["[general]"];
	s ~= ["module_name = Main"];
	s ~= ["[DebugLogger]"];
	s ~= ["level = debug"];
	s ~= ["appender = FileAppender"];

	auto p = immutable Parameters("[", "]", ["="], "#");

	auto bundle = new immutable Bundle(s, p);

	GlValue[GlKey] mutc = Bundle.dup(bundle);

	assert(bundle.container["general"]["module_name"] == ["Main"]);
	assert(mutc["general"]["module_name"] == ["Main"]);

	mutc["general"]["module_name"] = ["Two"];

	assert(bundle.container["general"]["module_name"] == ["Main"]);
	assert(mutc["general"]["module_name"] == ["Two"]);
}



unittest
{
	string[] s1 = 
		["[general]",
		 "module_name = Main",
		 "[log]",
		 "level = info",
		 "[data_receive]",
		 "0xC000 ->		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];

	string[] s2 = 
		["[general]",
		 "module_name = KPR",
		 "mod_type = RptR11Transceiver",
		 "[protocol]",
		 "data_flow = input"];	 

	auto p = immutable Parameters("[", "]", ["=", "->"], "#");

	auto bundle1 = new immutable Bundle(s1, p);
	auto bundle2 = new immutable Bundle(s2, p);

	auto bundle = bundle1 + bundle2;

	auto value1 = bundle.value("general", "module_name");
	assert (value1 == "Main");

	auto value2 = bundle.value("general", "mod_type");
	assert (value2 == "RptR11Transceiver");	

	auto value3 = bundle.value("log", "level");
	assert (value3 == "info");	

	auto value4 = bundle.value("protocol", "data_flow");
	assert (value4 == "input");	
}


unittest
{
	string[] s = 
		["[general]",
		 "module_name = Main",
		 "[log]",
		 "level = info",
		 "[data_receive]",
		 "0xC000 ->		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];

	auto p = immutable Parameters("[", "]", ["=", "->"], "#");

	auto bundle = new immutable Bundle(s, p);

	auto newBundle = bundle.subBundle("log");

	assert(newBundle.isGlKeyPresent("log") == true);
	assert(newBundle.isGlKeyPresent("general") == false);
	assert(newBundle.isValuePresent("log", "level") == true);
}


@system
unittest
{
	import std.concurrency;
	import core.thread;

	auto bundle = new immutable Bundle(["[general]", "module_name = KPR"]);

	static void func()
	{
		auto rec = receiveTimeout(dur!("msecs")(100),
			(immutable Bundle msg)
			{
				assert(msg.value("general", "module_name") == "KPR");
			},
		);
	}

	auto pid = spawn(&func);
	pid.send(bundle);
}





private:


import std.typecons;
import std.string:indexOf;
import std.conv:to;


/++
 * Build Bundle container from numereted array of strings
 *
 * Returns: builded bundle container
 *
 * Throws: BundleException, GlKeyNotFoundException, KeyNotFoundException, ValuesNotFoundException, Exception
 +/
@trusted
immutable (GlValue[GlKey]) buildContainer(string[int] lines, immutable Parameters pars)
{
	return parse(cleanTrash(lines, pars), pars);
}



@system:

/**
 * Parse array and place data to container
 *
 * Returns: builded bundle container
 *
 * Throws: BundleException, GlKeyNotFoundException, KeyNotFoundException, ValuesNotFoundException, Exception
 */
immutable (GlValue[GlKey]) parse(string[int] lines, immutable Parameters pars)
{
	import std.exception;

	GlValue[GlKey] container;

	if ((lines is null) || (lines.length == 0))
		return assumeUnique(container);
	
	GlKey glKey = "";
	Values[Key] glValue;
	foreach(num; std.algorithm.sorting.sort(lines.keys))
	{
		auto glKeyInLine = getFromLineGlKey(lines[num], pars);
		if (glKeyInLine != "")
		{
			if((glKeyInLine in container) !is null)
				throw new BundleException ("Double use global key "~glKey~"  in line "~to!string(num)~": "~lines[num]);// need to testing
			if(glKey != "") container[glKey]=glValue;
			glKey = glKeyInLine;
			glValue = null;
		}
		else
		{
			if (glKey=="") 
				throw new GlKeyNotFoundException("First nonvoid line not contained global key: "~to!string(num)~": "~lines[num]);
			Tuple!(Key, Values) parsedLine = lineToRecord(num, lines[num], pars);
			glValue[parsedLine[0]] = parsedLine[1];
		}
	}
	if(glKey!="") container[glKey]=glValue;

	GlValue[GlKey] rc = container.rehash;
	return assumeUnique(rc);
}


unittest
{
	string[int] lines;
	lines[0] = "[glk1]";
	lines[1] = "1 = a a1";
	lines[2] = "2 = b b1";
	lines[3] = "[glk2]";
	lines[4] = "1 = aa aa1";
	lines[5] = "2 = bb bb1";

	auto c = parse(lines, immutable Parameters());

	assert(c["glk1"]["1"] == ["a", "a1"]);
	assert(c["glk1"]["2"] == ["b", "b1"]);

	assert(c["glk2"]["1"] == ["aa", "aa1"]);
	assert(c["glk2"]["2"] == ["bb", "bb1"]);
}



/**
 * Convert one string line to record
 *
 * Returns: packed record
 *
 * Throws: KeyNotFoundException, ValuesNotFoundException, Exception
 */
Tuple!(Key, Values) lineToRecord(int lineNumber, string line, immutable Parameters pars)
{
	import std.string:strip;
	import std.string:split;

	ptrdiff_t separatorPos = -1;
	string separator;
	foreach(currentSeparator; pars.keySeparators)
	{
		separatorPos = line.indexOf(currentSeparator);
		if (separatorPos >= 0)
		{
			separator = currentSeparator;
			break;
		}
	}

	if (separatorPos <= 0) 
		throw new KeyNotFoundException ("Кеу is not present in line "~to!string(lineNumber)~": "~line);

	auto key = line[0..separatorPos].strip;
	auto workLine = line[separatorPos+separator.length..$].strip;

	if (workLine == "") throw new ValuesNotFoundException ("Values for key is not present in line "~to!string(lineNumber)~": "~line);
	
	auto values = workLine.split();
	return tuple(key, values);
}



/**
 * Seek global key in line, return it if present
 *
 * Returns: global key or ""
 *
 * Throws: Exception from string.indexOf 
 */
string getFromLineGlKey(string line, immutable Parameters pars)
{
	auto startGlKeySymbolIndex = line.indexOf(pars.startGlKeySymbol);
	auto endGlKeySymbolIndex = line.indexOf(pars.endGlKeySymbol);
	if ((startGlKeySymbolIndex == 0) && (endGlKeySymbolIndex == (line.length - pars.endGlKeySymbol.length)))
	{
		return line[startGlKeySymbolIndex+pars.startGlKeySymbol.length..endGlKeySymbolIndex];
	}
	else return "";
}


unittest
{
	auto pars = immutable Parameters();
	string line;
	line = "[data]";
	assert(getFromLineGlKey(line, pars) == "data");

	auto pars1 = immutable Parameters("<<|", "|>>", ["="], "#");
	line = "<<|tag|>>";
	assert(getFromLineGlKey(line, pars1) == "tag");
}



/**
 * read file and place data to Array of strings (Array key - line number in file)
 *
 * Returns: data packed in array of strings
 *
 * Throws: ErrnoException - open file exception
 * Throws: StdioException - read from file exception
 */
string[int] copyFileToStrings(string filePath)
{
	import std.stdio;
	import std.stdio:StdioException;
	import std.exception:ErrnoException;
	try
	{
		string[int] outStr;
		auto rlines = File(filePath, "r").byLine();
		int index = 0;
		foreach(line; rlines)	outStr[++index] = to!string(line);
		return outStr;
	}
	catch (ErrnoException ee)
	{
		throw new BundleException("errno = "~to!string(ee.errno)~" in file = "~ee.file~
			"in line = "~to!string(ee.line)~"msg = "~ee.msg);
	}
	catch (StdioException ioe)
	{
		throw new BundleException("errno = "~to!string(ioe.errno)~" in file = "~ioe.file~
			"in line = "~to!string(ioe.line)~"msg = "~ioe.msg);
	}
}


/**
 * Trim in lines spaces, tabs, comments, Remove empty lines
 *
 * Returns: lines without trash on sides
 *
 * Throws: ??Exception from string.indexOf 
 */
string[int] cleanTrash(string[int] init, immutable Parameters pars)
{
	import std.string:strip;

	if (init is null) return null;
	else 
	{
		string[int] _out;
		foreach(key;init.byKey())
		{
			string s;
			auto commentIndex = init[key].indexOf(pars.commentSymbol);
			if (commentIndex>=0)
			{
				s = init[key][0..commentIndex].strip;
			}
			else
			{
				s = init[key].strip;
			}
			if (s != "") _out[key] = s;		
		}
		return _out;
	}
}


unittest
{
	auto pars = immutable Parameters("[[", "]]", ["=>"], "#//");

	string[int] init;
	init[0] = "[[data]] #// global key \"data\"";
	init[1] = "  par1 => 58  ";
	init[2] = "	 #//Only comment  	";
	init[3] = "		par2 => 100		";

	auto outAr = cleanTrash(init, pars);
	assert(init.length == 4);
	assert(outAr.length == 3);
	assert(outAr[0] == "[[data]]");
	assert(outAr[1] == "par1 => 58");
	assert(outAr[3] == "par2 => 100");
}




/**
 * Convert hex string to integral number
 *
 * Throws: Exception
 */
import std.traits;

N strToNum(N)(string strNum) if (isIntegral!N)
{
	string sign = "";

	if (strNum.length == 0) return 0;
	
	if (strNum.length == 1) 
	{
		if ((strNum[0] == '-') || (strNum[0] == '+') || (strNum[0] == '0')) return 0;
		return to!N(strNum); 
	}
	
	if (strNum[0] == '-')
	{
		sign = "-";
		strNum = strNum[1..$];
	}
	else if (strNum[0] == '+')
	{
		sign = "+";
		strNum = strNum[1..$];
	}

	if (strNum.length < 3) return to!N(sign ~ strNum);

	if ((strNum[0..2] == "0X") || (strNum[0..2] == "0x")) return to!N(strNum[2..$], 16);
	else if ((strNum[0..2] == "0B") || (strNum[0..2] == "0b")) return to!N(strNum[2..$], 2);
	else return to!N(sign ~ strNum);
}


/**
 * Convert hex string to double
 *
 * Throws: Exception
 */
F strToNum(F)(string strNum) if (isFloatingPoint!F)
{
	if ((strNum.indexOf("0x")>=0) || (strNum.indexOf("0X")>=0) ||
		(strNum.indexOf("0B")>=0) || (strNum.indexOf("0B")>=0))
		return cast(double)strToNum!uint(strNum);
	return to!F(strNum);
}


/**
 * Complement another types
 */
S strToNum(S)(string strNum) nothrow pure if (isSomeString!S)
{
	return strNum;
}



unittest
{
	assert (strToNum!int("0x22") == 0x22);
	assert (strToNum!int("-21") == -21);
	assert (strToNum!double("0x22") == 0x22);
	assert (strToNum!double("0.25") == 0.25);
	assert (strToNum!double("-1e-12") == -1e-12);
}

