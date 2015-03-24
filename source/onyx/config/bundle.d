/**
 * Container for configuration data
 *
 * Copyright: © 2014 onyx
 * License: MIT license. License terms written in licence.txt file
 *
 * Authors: Oleg Nykytenko (onyx), onyx.itdevelopment@gmail.com
 *
 * Version: 1.xx
 *
 * Date: 11.02.2014
 *
 *
 *
 *
 * Examples:
 * ------------------------------------------------------------------------
 * Build ConfBundle from config file:
 * ------------------------------------------------------------------------
 * auto bundle = ConfBundle("../conf/file.conf");
 *
 * ------------------------------------------------------------------------
 * Build ConfBundle from string array:
 * ------------------------------------------------------------------------
 * private pure nothrow string[] buildConfLines()
 * {
 *		return 	["[general]",
 *				 "module_name = main",
 *				 "[log]",
 *				 "logging = "on",
 *				 "level = info",
 *				 "file_archive = yes,
 *				 "file_name_pattern = main.log"];
 * }
 *
 * auto bundle = ConfBundle(buildConfLines());
 *
 *
 *
 * ------------------------------------------------------------------------
 * Configuration file Exaple:
 * ------------------------------------------------------------------------
 * # This is config file for KPR RptR11 protocol Transceiver
 *
 * [general]
 * #------------------------------------------------------------
 * mod_name = KPR
 * mod_type = RptR11Transceiver
 *
 * [log]
 * #-----------------------------------------------------------------
 * logging = on #off
 * file_name_pattern = KPR.%d{yyyy-MM-dd}.log.gz
 * level = info #error, warn, debug, info, trace
 * max_history = 30
 * out_pattern = %d{yyyy-MM-dd HH:mm:ss.SSS}%-5level%logger{36}[%thread]-%msg%n
 *
 *
 * [protocol]
 * #------------------------------------------------------------
 * regime = slave #master - KPR; slave - OIK;
 * adr_RTU = 0x0A
 * data_flow = input # input; output; io; no_io
 * channel_switch_timeout = 1000
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
 

module onyx.config.bundle;

@safe:

import std.typecons;
import std.exception;
import std.conv;

/************************************************************************************/
/* Configuration bundle element types 												*/
/************************************************************************************/
/**
 * GlKey - string key in ConfBundle data array
 */
alias string GlKey;

/**
 * GlValue - ConfigBundle global data group
 */
alias Values[Key] GlValue; 

/**
 * Key - string key in global data group
 */
alias string Key;

/**
 * Values - save one line config data in tuple.
 * int - line number in configure file
 * string[] - config data
 */
alias string[] Values;


/************************************************************************************/
/* Configure's data container 														*/
/************************************************************************************/
/**
 * ConfigBundle save data in immutable container (associative array GlValue[GlKey]).
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
struct ConfBundle
{
	/*
	 * Configure's data inner container
	 */
	private immutable GlValue[GlKey] _conf;
	

	/**
	 * Build Bundle from text file
	 *
	 * Throws: ConfException, Exception
	 */
	this(string filePath) immutable
	{
		_conf = buildConfContainer(filePath);
	}


	/**
	 * Build Bundle from string array
	 *
	 * Throws: ConfException, Exception	 
	 */
	this(string[] confLines) immutable
	{
		_conf = buildConfContainer(confLines);
	}


	/**
	 * Build Bundle from Bundle
	 */
	private this(immutable GlValue[GlKey] conf) nothrow pure immutable
	{
		_conf = conf;
	}
	

	/**
	 * Get Global value from configure container
	 *
	 * Returns: GlValue - content of one configure block
	 *
	 * Throws: GlKeyNotFoundException, ConfException
	 */
	immutable (GlValue) glValue(GlKey glKey) pure immutable
	{
		if (glKey is null)
		{
			throw new ConfException("Global Key is null");
		}
		if (!(glKey in _conf)) 
		{
			throw new GlKeyNotFoundException("Not found Global Key: ["~glKey~"]");
		}
		return _conf[glKey];
	}
	

	/**
	 * Get Values from container
	 *
	 * Returns: Values - content of one configure line
	 *
	 * Throws: ValuesNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 */
	immutable (Values) values(GlKey glKey, Key key) pure immutable
	{
		if (key is null)
		{
			throw new ConfException("Key is null");
		}
		immutable glV = glValue(glKey);
		if (!(key in glV)) 
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
	 * Get one value from container
	 *
	 * Returns: Value - one string value from configure line
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 */
	immutable (string) value(GlKey glKey, Key key, uint pos) pure immutable
	{
		string vExceptionMsg = "Not found value: ["~glKey~"] -> "~key~" = values["~to!string(pos)~"]";
		try
		{
			immutable tValues = values(glKey, key);
			if ((tValues.length <= pos) || (tValues[pos] is null))
			{
				throw new ValueNotFoundException(vExceptionMsg);
			}
			return tValues[pos];
		}
		catch (ValuesNotFoundException vse)
		{
			throw new ValueNotFoundException(vExceptionMsg);
		}
	}
	

	/**
	 * Get one value from container
	 *
	 * Returns: Value - first string value from configure line
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 */
	immutable (string) value(GlKey glKey, Key key) pure immutable
	{
		return value(glKey, key, 0);
	}


	/**
	 * Get one int value from container
	 *
	 * Returns: Value - first int value from configure line
	 * Value formats: dec (123), hex (0x123), bin (0b101)
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 * Throws: ConvException, ConvOverflowException
	 */
	immutable(int) intValue(GlKey glKey, Key key) pure immutable 
	{
			return strToInt(value(glKey, key));
	}


	/**
	 * Short for getting value with "general" GlKey
	 *
	 * Returns: Value - first string value from  line in "general" configure block
	 *
	 * Throws: ValueNotFoundException, KeyNotFoundException, GlKeyNotFoundException, ConfException
	 */
	immutable (string) generalValue(Key key) pure immutable
	{
		return value("general", key, 0);
	}
	

	/**
	 * Check if value present in configure bundle (pos value from line)
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
	 * Check is value present in configure bundle (First value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	bool isValuePresent(GlKey glKey, Key key) pure immutable nothrow
	{
		return isValuePresent(glKey, key, 0);
	}
	

	/**
	 * Check is global key present in configure bundle 
	 *
	 * Returns: if key present in bundle - true, else - false
	 */
	bool isGlKeyPresent(GlKey glKey) immutable pure nothrow
	{
		return ((glKey in _conf)==null)?false:true;
	}


	/**
	 * Get global keys present in configure bundle 
	 *
	 * Returns: GlKey array
	 */
	@trusted /* array.keys is system */
	immutable (GlKey[]) glKeys() immutable pure nothrow
	{
		return _conf.keys;
	}


	/**
	 * Get keys present in configure bundle 
	 *
	 * Returns: Key array
	 */
	@trusted /* array.keys is system */
	immutable (Key[]) keys(GlKey glKey) immutable pure nothrow
	{
		return _conf[glKey].keys;
	}


	/**
	 * Add two bundles (this and rConf)
	 *
	 * Returns: New Configuration bundle with data from this bundle and rConf bundle
	 *
	 * Throws: ConfException
	 *
	 * Example:
	 * auto bundle1 = ConfBundle("./conf1/receiver1.conf");
	 * auto bundle2 = ConfBundle(confArray);
	 * auto bundle = bundle1 + bundle2;
	 */
	@trusted
	immutable (ConfBundle) opBinary(string op)(immutable ConfBundle rConf) immutable if (op == "+")
	{
		try
		{
			GlValue[GlKey] conf = (cast(GlValue[GlKey])_conf);

			foreach (glKey; rConf.glKeys)
			{
				auto rGlValue = cast(GlValue)rConf.glValue(glKey);
				if (!this.isGlKeyPresent(glKey))
					conf[glKey] = rGlValue;
				else
				{
					auto lGlValue = conf[glKey];
					foreach (key; rConf.keys(glKey))
					{
						if (!this.isValuePresent(glKey, key))
						{
							lGlValue[key] = rGlValue[key];
						}
					}
				}
			}
			return immutable ConfBundle(cast (immutable) conf);
		}
		catch (ConfException e)
		{
			throw cast(ConfException)e;
		}
	}

	/**
	 * Get from this bundle one global data part
	 *
	 * Returns: New bundle with one global part data
	 */
	immutable (ConfBundle) subBundle(GlKey glKey) immutable
	{
		return immutable ConfBundle([glKey:_conf[glKey]]);
	}
}


/**
 * Configuration exception
 */
class ConfException:Exception 
{
	@safe pure nothrow this(string exString)
	{
		super(exString);
	}
}


/**
 * Construct exception with parrent: ConfException
 *
 */
template childConfException(string exceptionName)
{
	const char[] childConfException =

	"class " ~exceptionName~":ConfException 
	{
		@safe pure nothrow this(string exString)
		{
			super(exString);
		}
	}";
}

mixin(childConfException!"GlKeyNotFoundException");
mixin(childConfException!"KeyNotFoundException");
mixin(childConfException!"ValuesNotFoundException");
mixin(childConfException!"ValueNotFoundException");




import std.stdio;
import std.string;
import std.array : split;

private
{
	/*
	 *  Comment symbol
	 */
	immutable commentSymbol = "#";

	/*
	 * Global key Start and End symbols in config file
	 */
	immutable startGlKeySymbol = "[";
	immutable endGlKeySymbol = "]";

	/*
	 * Separator symbol in all lines, exclude placed after GlKey with prefix: dataGlKeyPrefix
	 */
	immutable keySeparator = ["=", "->"];
}

/*
 * Separator symbols in lines, placed after GlKey with prefix: dataGlKeyPrefix
 * Examples: GlKey examples [data], [data_receive], [datapost]
 */
//immutable keySeparatorData0 = to!string(' ');
//immutable keySeparatorData1 = "\t";

//immutable dataGlKeyPrefix = "data";

/++
 * Build ConfBundle from configure file
 *
 * Returns: builded configuration bundle
 *
 * Throws: ConfException, Exception
 +/
private immutable (GlValue[GlKey]) buildConfContainer(string configFilePath)
{
	try
	{
    	return buildConfContainer(copyFileToStrings(configFilePath));
    }
	catch (ErrnoException ee)
		throw new ConfException("errno = "~to!string(ee.errno)~" in file = "~ee.file~
			"in line = "~to!string(ee.line)~"msg = "~ee.msg);
	catch (StdioException ioe) 
		throw new ConfException("errno = "~to!string(ioe.errno)~" in file = "~ioe.file~
			"in line = "~to!string(ioe.line)~"msg = "~ioe.msg);
}


/++
 * Build ConfBundle from string array
 *
 * Returns: builded configuration bundle
 *
 * Throws: ConfException, Exception
 +/
private immutable (GlValue[GlKey]) buildConfContainer(string[] configLines)
{
	string[int] outStr;
	int index = 0;
	foreach(line; configLines)	outStr[++index] = line;
	return buildConfContainer(outStr);
}


/++
 * Build ConfBundle from configure Array of strings
 *
 * Returns: builded configure bundle
 *
 * Throws: ConfException, Exception
 +/
private immutable (GlValue[GlKey]) buildConfContainer(string[int] configLines)
{
	return parse(cleanTrash(configLines));
}


/**
 * Parse array and place data to bundle
 *
 * Returns: builded configure bundle
 *
 * Throws: ConfException, Exception
 */
@trusted /* assumeUnique is system */
private immutable (GlValue[GlKey]) parse(string[int] lines)
{
	GlValue[GlKey] bundle;
	if (lines == null) return assumeUnique(bundle);	//!!!!!!!!!!!!!!!
	
	GlKey glKey = "";
	Values[Key] glValue;
	foreach(num; lines.keys.sort)
	{
		auto glKeyInLine = getFromLineGlKey(num, lines[num]);
		if (glKeyInLine != "")
		{
			if((glKeyInLine in bundle) != null) 
				throw new ConfException ("Double use key "~glKey~"  in line "~to!string(num)~": "~lines[num]);// need to testing
			if(glKey != "") bundle[glKey]=glValue/*.dup*/;
			glKey = glKeyInLine;
			glValue = null;
		}
		else
		{
			if (glKey=="") 
				throw new ConfException("First nonvoid line not contained global key: "~to!string(num)~": "~lines[num]);
			Tuple!(Key, Values) parsedLine = lineToConf(num, lines[num], glKey);
			glValue[parsedLine[0]] = parsedLine[1];
		}
	}
	if(glKey!="") bundle[glKey]=glValue/*.dup*/;
	return assumeUnique(bundle);
}

    
/**
 * Convert one string line to configure record
 *
 * Returns: packed configure line
 *
 * Throws: ConfException, Exception
 */
@trusted /* std.string.indexOf and std.array.split is system */
private Tuple!(Key, Values) lineToConf(int lineNumber, string line, string glKey)
{
	long separatorPos = -1;
	string separator;
	foreach(currentSeparator; keySeparator)
	{
		auto pos = line.indexOf(currentSeparator);
		if (pos >= 0)
		{
			separatorPos = pos;
			separator = currentSeparator;
			break;
		}
	}

	if (separatorPos <= 0) 
		throw new ConfException ("Кеу is no in line "~to!string(lineNumber)~": "~line);

	auto sLine = line.split(separator);
	
	auto key = sLine[0].strip;
	
	auto workLine = sLine[1].strip;
	if (workLine == "") throw new ConfException ("Value for key is no in line "~to!string(lineNumber)~": "~line);
	
	auto values = workLine.split();
	return tuple(key, values);
}


/**
 * Seek global key in line, return it if present
 *
 * Returns: global key or ""
 *
 * Throws: ??Exception from string.indexOf 
 */
@trusted /* std.string.indexOf is system */
private string getFromLineGlKey(int lineNumber, string line)
{
	auto startGlKeySymbolIndex = line.indexOf(startGlKeySymbol);
	auto endGlKeySymbolIndex = line.indexOf(endGlKeySymbol);
	if ((startGlKeySymbolIndex == 0) && (endGlKeySymbolIndex == (line.length - 1)))
	{
		return line[startGlKeySymbolIndex+1..endGlKeySymbolIndex];
	}
	else return "";
}

/**
 * read file and place configure data to Array of strings (Array key - line number in file)
 *
 * Returns: configure data packed in array of strings
 *
 * Throws: ErrnoException - open file exception
 * Throws: StdioException - read from file exception
 */
@trusted /* std.string.indexOf is system */
private string[int] copyFileToStrings(string filePath)
{
	string[int] outStr;
	auto rlines = File(filePath, "r").byLine();
	int index = 0;
	foreach(line; rlines)	outStr[++index] = to!string(line);
	return outStr;
}

/**
 * Trim in lines spaces, tabs, comments
 *
 * Returns: lines without trash on sides
 *
 * Throws: ??Exception from string.indexOf 
 */
@trusted /* std.string.indexOf is system */
private string[int] cleanTrash(string[int] init)
{
	if (init is null) return null;
	else 
	{
		string[int] _out;
		foreach(key;init.byKey())
		{
			string s;
			if (init[key].indexOf(commentSymbol)>=0)
			{
				s = init[key][0..init[key].indexOf(commentSymbol)].strip;
			}
			else 
				s = init[key].strip;
			if (s != "") _out[key] = s;		
		}
		return _out;
	}
}

/**
 * String to int convert
 * dec, hex and bin formats
 *
 * Throws: ConvException, ConvOverflowException
 */
private pure int strToInt (string strNum){
	string sign = "";

	if (strNum.length == 0) return 0;
	
	if (strNum.length == 1) {
		if ((strNum[0] == '-') || (strNum[0] == '+') || (strNum[0] == '0')) return 0;
		return to!int(strNum); 
	}
	
	if (strNum[0] == '-'){
		sign = "-";
		strNum = strNum[1..$];
	}else if (strNum[0] == '+'){
		sign = "+";
		strNum = strNum[1..$];
	}

	if (strNum.length < 3) return to!int(sign ~ strNum);

	if ((strNum[0..2] == "0X") || (strNum[0..2] == "0x")) return to!int(strNum[2..$], 16);
	else if ((strNum[0..2] == "0B") || (strNum[0..2] == "0b")) return to!int(strNum[2..$], 2);
	else return to!int(sign ~ strNum);
}



/************************************************************************************/
/* Lib tests 																		*/
/************************************************************************************/
unittest
{
	auto s = [1:"	  String with spaces, tabs, "~commentSymbol~"comments"];
	assert (cleanTrash(s) == [1:"String with spaces, tabs,"]);
}

unittest
{
	string[] s = 
		["[general]",
		 "module_name = Main",
		 "[log]",
		 "logging = on",
		 "level = info",
		 "[empty_gl_key]", // Test GlKey with empty GlValue
		 "[data_receive]",
		 "0xC000 ->		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];

	auto bundle = immutable ConfBundle(s);

	// get GlValue test
	{
		auto glValue = bundle.glValue("general");
		immutable gv = ["module_name":["Main"]];
		assert (glValue == gv);
	}

	// get emty GlValue test
	{
		auto glValue = bundle.glValue("empty_gl_key");
		assert (glValue == null);
	}

	// getValues test
	{
		auto values = bundle.values("log", "level");
		assert (values == ["info"]);

	}

	// getValue test (N pos)
	{ 
		auto value = bundle.value("data_receive", "0xC000", 3);
		assert (value == "yes");
	}

	// getValue test (0 pos)
	{
		auto value = bundle.value("data_receive", "0xC000");
		assert (value == "0x014B");
	}

	// getIntValue test (0 pos)
	{
		auto value = bundle.intValue("data_receive", "0xC000");
		assert (value == 0x014B);
	}

	// getGeneralValue test
	{
		auto value = bundle.generalValue("module_name");
		assert (value == "Main");
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
		auto present = bundle.isGlKeyPresent("log");
		assert (present == true);
		auto nopresent = bundle.isGlKeyPresent("superkey");
		assert (nopresent == false);
	}
}

unittest
{
	version(configFileUnittest)
	{
		auto bundle = immutable ConfBundle("./test/test.conf");

		// getGlValue test
		{
			auto glValue = bundle.glValue("general");
			immutable gv = ["mod_name":["KPR"], "mod_type":["RptR11Transceiver"]];
			assert (glValue == gv);
		}

		// getValues test
		{
			auto values = bundle.values("protocol", "data_flow");
			assert (values == ["input"]);
		}

		// getValue test (N pos)
		{ 
			auto value = bundle.value("data_receive", "0xC000~1", 5);
			assert (value == "(1*{0xC000}+0)");
		}

		// getValue test (0 pos)
		{
			auto value = bundle.value("data_receive", "0xC179");
			assert (value == "0xC179");
		}

		// getGeneralValue test
		{
			auto value = bundle.generalValue("mod_name");
			assert (value == "KPR");
		}
	}
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

	auto bundle1 = immutable ConfBundle(s1);
	auto bundle2 = immutable ConfBundle(s2);

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

	auto bundle = immutable ConfBundle(s);

	auto newBundle = bundle.subBundle("log");

	assert(newBundle.isGlKeyPresent("log") == true);
	assert(newBundle.isGlKeyPresent("general") == false);
	assert(newBundle.isValuePresent("log", "level") == true);
}
