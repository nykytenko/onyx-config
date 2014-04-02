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
	 * Primary constructors
	 */
	this(string filePath)
	{
		_conf = buildConfContainer(filePath);
	}


	this(string[] confLines)
	{
		_conf = buildConfContainer(confLines);
	}


	private this(immutable GlValue[GlKey] conf)
	{
		_conf = conf;
	}
	

	/**
	 * Get Global value from configure container
	 *
	 * Returns: GlValue - content of one configure block
	 * Throws: ConfException
	 */
	pure immutable (GlValue) getGlValue(GlKey glKey)
	{
		if (glKey is null) throw new ConfException("Global key is null");
		if (!(glKey in _conf)) throw new ConfException("In conf bundle no present Global Key: ["~glKey~"]");
		if (_conf[glKey].length == 0)
			throw new ConfException("In conf bundle for  Global Key: ["~glKey~"] no filled by content");
		return _conf[glKey];
	}
	

	/**
	 * Get Values from container
	 *
	 * Returns: Values - content of one configure line
	 * Throws: ConfException
	 */
	pure immutable (Values) getValues(GlKey glKey, Key key)
	{
		if (key is null) throw new ConfException("Get config values for key = null");
		immutable glValue = getGlValue(glKey);
		if (!(key in glValue)) throw new ConfException("In conf bundle no present key: ["~glKey~"] -> "~key);
		immutable values = glValue[key];
		if ((values is null) || (values.length == 0))
			throw new ConfException("["~glKey~"] -> "~key~" = values is no present");
		return values;
	} 


	/**
	 * Get one value from container
	 *
	 * Returns: Value - one string value from configure line
	 * Throws: ConfException
	 */
	pure immutable (string) getValue(GlKey glKey, Key key, int pos)
	{
		if (pos<0)
			throw new ConfException("In conf bundle get config value from position < 0 (pos = "~to!string(pos)~")");
		immutable tValues = getValues(glKey, key);
		if ((tValues.length <= pos) || (tValues[pos] is null))
			throw new ConfException("["~glKey~"] -> "~key~" = values["~to!string(pos)~"] is no present");
		return tValues[pos];
	}
	

	/**
	 * Get one value from container
	 *
	 * Returns: Value - first string value from configure line
	 * Throws ConfException
	 */
	pure immutable (string) getValue(GlKey glKey, Key key) {return getValue(glKey, key, 0);}


	/**
	 * Get one int value from container
	 *
	 * Returns: Value - first int value from configure line
	 * Value formats: dec (123), hex (0x123), bin (0b101)
	 *
	 * Throws: ConfException, ConvException, ConvOverflowException
	 */
	pure immutable(int) getIntValue(GlKey glKey, Key key) {return strToInt(getValue(glKey, key));}

	/**
	 * Short for getting value with "general" GlKey
	 *
	 * Returns: Value - first string value from  line in "general" configure block
	 * Throws: ConfException
	 */
	pure immutable (string) getGeneralValue(Key key) {return getValue("general", key, 0);}
	

	/**
	 * Check if value present in configure bundle (pos value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	pure nothrow bool isValuePresent(GlKey glKey, Key key, int pos)
	{
		try
		{
			getValue(glKey, key, pos);
			return true;
		}
		catch(Exception e){return false;}
	}
	

	/**
	 * Check is value present in configure bundle (First value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	pure bool isValuePresent(GlKey glKey, Key key){return isValuePresent(glKey, key, 0);}
	

	/**
	 * Check is global key present in configure bundle 
	 *
	 * Returns: if key present in bundle - true, else - false
	 */
	bool isGlKeyPresent(GlKey glKey){return ((glKey in _conf)==null)?false:true;}


	GlKey[] glKeys()
	{
		return _conf.keys;
	}

	Key[] keys(GlKey glKey)
	{
		return _conf[glKey].keys;
	}


	/**
	 * Add two bundles (this and rConf)
	 *
	 * Returns: New Configuration bundle with data from this bundle and rConf bundle
	 *
	 * Example:
	 * auto bundle1 = ConfBundle("./conf1/receiver1.conf");
	 * auto bundle2 = ConfBundle(confArray);
	 * auto bundle = bundle1 + bundle2;
	 */
	ConfBundle opBinary(string op)(ConfBundle rConf) if (op == "+")
	{
		GlValue[GlKey] conf = (cast(GlValue[GlKey])_conf);

		foreach (glKey; rConf.glKeys)
		{
			auto rGlValue = cast(GlValue)rConf.getGlValue(glKey);
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
		return ConfBundle(cast (immutable) conf);
	}

	/**
	 * Get from this bundle one global data part
	 *
	 * Returns: New bundle with one global part data
	 */
	ConfBundle subBundle(GlKey glKey)
	{
		return ConfBundle([glKey:_conf[glKey]]);
	}
}

/**
 * Configure exception
 */
class ConfException:Exception 
{
	@safe pure nothrow this(string exString)
	{
		super(exString);
	}
}



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
 * Returns: builded configure bundle
 * Throws: ConfException
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
 * Throws: ConfException
 +/
private immutable (GlValue[GlKey]) buildConfContainer(string[int] configLines)
{
	return parse(cleanTrash(configLines));
}

/**
 * Parse array and place data to bundle
 *
 * Returns: builded configure bundle
 * Throws: ConfException
 */
private immutable (GlValue[GlKey]) parse(string[int] lines)
{
	GlValue[GlKey] bundle;
	if (lines == null) return cast (immutable GlValue[GlKey]) bundle;	//!!!!!!!!!!!!!!!
	
	GlKey glKey = "";
	Values[Key] glValue;
	foreach(num; lines.keys.sort)
	{
		auto glKeyInLine = getFromLineGlKey(num, lines[num]);
		if (glKeyInLine != "")
		{
			if((glKeyInLine in bundle) != null) 
				throw new ConfException ("Double use key "~glKey~"  in line "~to!string(num)~": "~lines[num]);// need to testing
			if(glKey != "") bundle[glKey]=glValue.dup;
			glKey = glKeyInLine;
			glValue = null;
		}
		else
		{
			if (glKey=="") 
				throw new ConfException("First nonvoid line not contain global key: "~to!string(num)~": "~lines[num]);
			Tuple!(Key, Values) parsedLine = lineToConf(num, lines[num], glKey);
			glValue[parsedLine[0]] = parsedLine[1];
		}
	}
	if(glKey!="") bundle[glKey]=glValue.dup;
	return cast (immutable GlValue[GlKey]) bundle;
}

    
/**
 * Convert one string line to configure record
 *
 * Returns: packed configure line
 * Throws: ConfException
 */
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
 */
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
 * Throws: ErrnoException - open file exception
 * Throws: StdioException - read from file exception
 */
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
 * Throws: ??Exception from string.indexOf 
 */
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
		 "[data_receive]",
		 "0xC000 ->		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];

	auto bundle = ConfBundle(s);

	// getGlValue test
	{
		auto glValue = bundle.getGlValue("general");
		assert (glValue == cast (immutable)["module_name":["Main"]]);
	}

	// getValues test
	{
		auto values = bundle.getValues("log", "level");
		assert (values == ["info"]);

	}

	// getValue test (N pos)
	{ 
		auto value = bundle.getValue("data_receive", "0xC000", 3);
		assert (value == "yes");
	}

	// getValue test (0 pos)
	{
		auto value = bundle.getValue("data_receive", "0xC000");
		assert (value == "0x014B");
	}

	// getIntValue test (0 pos)
	{
		auto value = bundle.getIntValue("data_receive", "0xC000");
		assert (value == 0x014B);
	}

	// getGeneralValue test
	{
		auto value = bundle.getGeneralValue("module_name");
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
		auto bundle = ConfBundle("../test/test.conf");

		// getGlValue test
		{
			auto glValue = bundle.getGlValue("general");
			assert (glValue == cast (immutable)["mod_name":["KPR"], "mod_type":["RptR11Transceiver"]]);
		}

		// getValues test
		{
			auto values = bundle.getValues("protocol", "data_flow");
			assert (values == ["input"]);
		}

		// getValue test (N pos)
		{ 
			auto value = bundle.getValue("data_receive", "0xC000~1", 5);
			assert (value == "(1*{0xC000}+0)");
		}

		// getValue test (0 pos)
		{
			auto value = bundle.getValue("data_receive", "0xC179");
			assert (value == "0xC179");
		}

		// getGeneralValue test
		{
			auto value = bundle.getGeneralValue("mod_name");
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

	auto bundle1 = ConfBundle(s1);
	auto bundle2 = ConfBundle(s2);

	auto bundle = bundle1 + bundle2;

	auto value1 = bundle.getValue("general", "module_name");
	assert (value1 == "Main");

	auto value2 = bundle.getValue("general", "mod_type");
	assert (value2 == "RptR11Transceiver");	

	auto value3 = bundle.getValue("log", "level");
	assert (value3 == "info");	

	auto value4 = bundle.getValue("protocol", "data_flow");
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

	auto bundle = ConfBundle(s);

	auto newBundle = bundle.subBundle("log");

	assert(newBundle.isGlKeyPresent("log") == true);
	assert(newBundle.isGlKeyPresent("general") == false);
	assert(newBundle.isValuePresent("log", "level") == true);
}