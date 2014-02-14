# onyx-config

Read configuration data from text file in run-time and  packs data into container (ConfBundle).

## Examples:

Configuration text file ("./conf/test.conf"):

	[general] # <-- This is Global Key (GlKey)
	#------------------------------------------------------------
	mod_name = KPR
	#  ^
	#  |--- This is Key
 
	mod_type = RptR11Transceiver
	#  		^
	#  		|--- This is Value

	[log]
	#-----------------------------------------------------------------
	logging = on #off
	#  	^
	#  	|--- This is Key to Value Separator

	file_name_pattern = KPR.%d{yyyy-MM-dd}.log.gz
	level = info #error, warn, debug, info, trace
	max_history = 30
	out_pattern = %d{yyyy-MM-dd HH:mm:ss.SSS}%-5level%logger{36}[%thread]-%msg%n

	[protocol]
	#------------------------------------------------------------
	regime = slave #master - KPR; slave - OIK;
	adr_RTU = 0x0A
	data_flow = input # input; output; io; no_io
	channel_switch_timeout = 1000 100 10		# many values in one line is possible

	[data_receive] # <-- This is "data" prefix Global Key (GlKey)
	#----------------------------------------------------------------------------------------------------
	# Addr in Addr_out type_of_data name_of_data send_to_next channel  Formula
	# KPR_adr UTS_PMZ					  priority
	#----------------------------------------------------------------------------------------------------
	#
	0xC000	  0xC000   0x0B	        XGES_Р		yes	    1      (2*{0xC000}+10)+(-0.2*{0xC179}-5)
	#  	^
	#  	|--- This is Key to Value Separator for GlKey with prefix "data"

	0xC000~1  0xC001   0x0B	      	XYGES_Р		yes	    2      (1*{0xC000}+0)
	#  ^
	#  |--- This is Key

	0xC179	  0xC179   0x0B	      	XaES_Р		yes	    1	   1*{0xC179}+0
	#  		    ^
	#  		    |--- This is possition 1 Value
	#	     ^
	#  	     |--- This is possition 0 Value 
		


Source code example:

	import onyx.config.parser;
	import onyx.config.bundle;

	void main()
	{
		/* Build ConfBundle from config file */
		auto bundle = buildConfBundle("./conf/file.conf");

		/* get value for GlKey:"log", Key:"level" */
		auto value1 = bundle.getValue("log", "level"); 
		assert (value1 == "info");

		/* short form to get the value for GlKey:"general", Key:"module_name" */
		auto value2 = bundle.getGeneralValue("module_name");
		assert (value2 == "KPR");

		/* get value for line with many values from possition 1 */
		auto value3 = bundle.getValue("protocol", "channel_switch_timeout", 1); 
		assert (value3 == "100");

		/* get value for GlKey:"data_receive", Key:"0xC00", position:3
		auto value3 = bundle.getValue("data_receive", "0xC000", 3);
		assert (value3 == "yes");
	}

## Key features:

 - "#" is comment symbol
 - "=" is Key to Value separator for all line
 - "space" or "tab" is Key to Value separator in lines, place after GlKey with prefix "data" (for example [data_receive])
 = 



