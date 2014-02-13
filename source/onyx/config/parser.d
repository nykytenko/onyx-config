/**
 * Parse configure file (or configure string array) to ConfBundle
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
 * Examples:
 * ------------------------------------------------------------------------
 * Build ConfBundle from config file:
 * ------------------------------------------------------------------------
 * auto bundle = buildConfBundle("./conf/file.conf")
 *
 * ------------------------------------------------------------------------
 * Build ConfBundle from string array:
 * ------------------------------------------------------------------------
 * private pure nothrow string[int] buildConfLines()
 * {
 *		return 	[1:"[general]",
 *				 2:"module_name = main",
 *				 3:"[log]",
 *				 4:"logging = "on",
 *				 5:"level = info",
 *				 6:"file_archive = yes,
 *				 7:"file_name_pattern = main.log"];
 * }
 *
 * auto bundle = buildConfBundle(buildConfLines());
 *
 * ------------------------------------------------------------------------
 * Configure file Exaple:
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
 * # Adr in		Adr_out		type_of_data	name_of_data		send_to_next	channel		Formula
 * # KPR_adr	UTS_PMZ															priority
 * #----------------------------------------------------------------------------------------------------
 * #
 * #0xC000		0xC000		0x0B			XGES_Р_Станції		yes					1		(2*{0xC000}+10)+(-0.2*{0xC179}-5)+(0*{0xC180}+0)
 * #0xC000~1	0xC001		0x0B			XGES_Р_Станції		yes					2		(1*{0xC000}+0)
 * #0xC179		0xC179		0x0B			XaES_Р_Станції		yes					1		1*{0xC179}+0
 *
 * #KrGES											
 * 0xC000		0x014B		0x0B			Рстанции			yes					1		(32*{0xC000}+0)
 *
 *
 */
module onyx.config.parser;

import onyx.config.bundle;

import std.stdio; // Manipulation with File
import std.string;
import std.conv;
import std.typecons;
import std.exception;

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
 * Separator symbols in all lines, exclude placed after GlKey with prefix: dataGlKeyPrefix
 */
immutable keySeparator = "=";

/*
 * Separator symbols in lines, placed after GlKey with prefix: dataGlKeyPrefix
 * Examples: GlKey examples [data], [data_receive], [datapost]
 */
immutable keySeparatorData0 = to!string(' ');
immutable keySeparatorData1 = "\t";

immutable dataGlKeyPrefix = "data";

/++
 * Build ConfBundle from configure file
 *
 * Returns: builded configure bundle
 * Throws: ConfException
 +/
ConfBundle buildConfBundle(string configFilePath)
{
	try
	{
    	return buildConfBundle(copyFileToStrings(configFilePath));
    }
	catch (ErrnoException ee)
		throw new ConfException("errno = "~to!string(ee.errno)~" in file = "~ee.file~
			"in line = "~to!string(ee.line)~"msg = "~ee.msg);
	catch (StdioException ioe) 
		throw new ConfException("errno = "~to!string(ioe.errno)~" in file = "~ioe.file~
			"in line = "~to!string(ioe.line)~"msg = "~ioe.msg);
}

/++
 * Build ConfBundle from configure Array of strings
 *
 * Returns: builded configure bundle
 * Throws: ConfException
 +/
ConfBundle buildConfBundle(string[int] configStrings)
{
	return parse(cleanTrash(configStrings));
}

/**
 * Parse array and place data to bundle
 *
 * Returns: builded configure bundle
 * Throws: ConfException
 */
private ConfBundle parse(string[int] lines)
{
	GlValue[GlKey] bundle;
	//if (lines == null) return *(new ConfBundle(cast (immutable GlValue[GlKey]) bundle));	//!!!!!!!!!!!!!!!
	if (lines == null) return ConfBundle(cast (immutable GlValue[GlKey]) bundle);	//!!!!!!!!!!!!!!!
	
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
	return ConfBundle(cast (immutable GlValue[GlKey]) bundle);
}

    
/**
 * Convert one string line to configure record
 *
 * Returns: packed configure line
 * Throws: ConfException
 */
private Tuple!(Key, Values) lineToConf(int lineNumber, string line, string glKey)
{
	auto separator0 = (startsWith(glKey, dataGlKeyPrefix))?keySeparatorData0:keySeparator;
	auto separator1 = (startsWith(glKey, dataGlKeyPrefix))?keySeparatorData1:keySeparator;
	
	auto separatorPos0 = line.indexOf(separator0);
	auto separatorPos1 = line.indexOf(separator1);
	if ((separatorPos0 <= 0) && (separatorPos1 <=0)) 
		throw new ConfException ("Кеу is no in line "~to!string(lineNumber)~": "~line);
	
	long separatorPos;
	if (separatorPos0 == separatorPos1) separatorPos=separatorPos0;
	else if (separatorPos0 < separatorPos1) {separatorPos=(separatorPos0 > 0)?separatorPos0:separatorPos1;}
	else if (separatorPos0 > separatorPos1) {separatorPos=(separatorPos1 > 0)?separatorPos1:separatorPos0;}
	else separatorPos=0;
	
	auto key = line[0..separatorPos].strip;
	
	auto workLine = line[separatorPos+1..$].strip;
	if (workLine == "") throw new ConfException ("Value for key is no in line "~to!string(lineNumber)~": "~line);
	
	auto values = tuple(lineNumber, workLine.split());
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
	int index;
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
	if (init == null) return null;
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


unittest
{
	auto s = [1:"	  String with spaces, tabs, "~commentSymbol~"comments"];
	assert (cleanTrash(s) == [1:"String with spaces, tabs,"]);
}