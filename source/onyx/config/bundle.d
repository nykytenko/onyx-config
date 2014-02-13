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
 */
module onyx.config.bundle;

import std.typecons;
import std.exception;
import std.conv;

/**
 * ConfigBundle save data in container (associative array GlValue[GlKey]).
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
 * 										|=> line_numberA -> [DataValue1, DataValue2, ... DataValueP]
 * 											line_numberB -> [DataValue1, DataValue2, ... DataValueQ]
 * 											........................................................
 * 											line_numberX -> [DataValue1, DataValue2, ... DataValueR]
 */

/************************************************************************************/
/* Configure bundle element types 													*/
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
alias Tuple!(int, string[]) Values;


/************************************************************************************/
/* Configure's data container 														*/
/************************************************************************************/
struct ConfBundle
{
	/*
	 * Configure's data inner container
	 */
	private immutable GlValue[GlKey] _conf;
	
	/**
	 * Primary constructor
	 */
	this(immutable GlValue[GlKey] conf)
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
		if (/*(values is null) ||*/ (values[1].length == 0))
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
		if ((tValues[1].length <= pos) || (tValues[1][pos] is null))
			throw new ConfException("["~glKey~"] -> "~key~" = values["~to!string(pos)~"] is no present");
		return tValues[1][pos];
	}
	
	/**
	 * Get one value from container
	 *
	 * Returns: Value - first string value from configure line
	 * Throws ConfException
	 */
	pure immutable (string) getValue(GlKey glKey, Key key) {return getValue(glKey, key, 0);}
	
	/**
	 * Short for getting value with "general" GlKey
	 *
	 * Returns: Value - first string value from  line in "general" configure block
	 * Throws: ConfException
	 */
	pure immutable (string) getGeneralValue(Key key) {return getValue("general", key, 0);}
	
	/*
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
	
	/*
	 * Check is value present in configure bundle (First value from line)
	 *
	 * Returns: if value present in bundle - true, else - false
	 */
	pure bool isValuePresent(GlKey glKey, Key key){return isValuePresent(glKey, key, 0);}
	
	/*
	 * Check is global key present in configure bundle 
	 *
	 * Returns: if key present in bundle - true, else - false
	 */
	bool isGlKeyPresent(GlKey glKey){return ((glKey in _conf)==null)?false:true;}
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

/**
 * Lib tests
 */
unittest
{
	import std.stdio;
	import onyx.config.parser;

	writeln("unittest start");
	string[int] s = 
		[1:"[general]",
		 2:"module_name = Main",
		 3:"[log]",
		 4:"logging = on",
		 5:"level = info",
		 6:"[data_receive]",
		 7:"0xC000		0x014B		0x0B		Рстанции	yes		1		(32*{0xC000}+0)"];
	auto bundle = buildConfBundle(s); 

	// getGlValue test
	{
		auto glValue = bundle.getGlValue("general");
		assert (glValue == cast (immutable)["module_name":tuple(2, ["Main"])]);
	}

	// getValues test
	{
		auto values = bundle.getValues("log", "level");
		assert (values == tuple(5, ["info"]));
	}

	// getValue test (3 pos)
	{ 
		auto value = bundle.getValue("data_receive", "0xC000", 3);
		assert (value == "yes");
	}

	// getValue test (0 pos)
	{
		auto value = bundle.getValue("data_receive", "0xC000");
		assert (value == "0x014B");
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