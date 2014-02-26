# onyx-config

"onyx-config" designed for working with configuration data in run time.


## Key features:
 - The ConfBundle is container for save configuration data.
 - A ConfBundle may be created from text file or string array in run-time.
 - "#" is comment symbol in text file.
 - "=" and "->" is Key to Value separators in text file.




## Examples:

Configuration text file ("./conf/test.conf"):

	[general] # <-- This is Global Key (GlKey)
	#------------------------------------------------------------
	mod_name = KPR
	#  ^
	#  |--- This is Key
 
	mod_type = RptR11Transceiver
	#               ^
	#               |--- This is Value

	[log]
	#-----------------------------------------------------------------
	logging = on #off
	#       ^
	#       |--- This is Key to Value Separator

	file_name_pattern = KPR.%d{yyyy-MM-dd}.log.gz
	level = info #error, warn, debug, info, trace
	max_history = 30
	out_pattern = %d{yyyy-MM-dd HH:mm:ss.SSS}%-5level%logger{36}[%thread]-%msg%n

	[protocol]
	#------------------------------------------------------------
	regime = slave #master - KPR; slave - OIK;
	adr_RTU = 0x0A
	channel_switch_timeout = 1000 100 10		# many values in one line is possible

	[data_receive] # <-- This is "data" prefix Global Key (GlKey)
	#----------------------------------------------------------------------------------------------------
	# Addr in Addr_out type_of_data name_of_data send_to_next channel  Formula
	# KPR_adr UTS_PMZ					  priority
	#----------------------------------------------------------------------------------------------------
	#
	0xC000	 ->  0xC000   0x0B	        XGES_Р		yes	    1      (2*{0xC000}+10)+(-0.2*{0xC179}-5)
	#        ^
	#        |--- This is Key to Value Separator too

	0xC000~1 ->  0xC001   0x0B	      	XYGES_Р		yes	    2      (1*{0xC000}+0)
	#  ^
	#  |--- This is Key

	0xC179	 ->  0xC179   0x0B	      	XaES_Р		yes	    1	   1*{0xC179}+0
	#                      ^
	#                      |--- This is possition 1 Value
	#            ^
	#            |--- This is possition 0 Value 
		


Source code example:

	import onyx.config.bundle;

	void main()
	{
		/* Build ConfBundle from config file */
		auto bundle = ConfBundle("../test/test.conf");

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
		auto value4 = bundle.getValue("data_receive", "0xC000", 3);
		assert (value4 == "yes");
		
		/* Build another bundle from string array */
		string[] s2 = 
		  ["[protocol]",
		   "data_flow = input",
		   "[new_gl_key]",
		   "test_key = value1 value2"];	
		auto bundle2 = ConfBundle(s2);
		
		/* Add two bundles. Created new bundle with data from both bundles */
		auto newBundle = bundle + bundle2;
		auto value5 = newBundle.getValue("log", "level"); 
		assert (value5 == "info");
		auto value6 = newBundle.getValue("new_gl_key", "test_key", 1); 
		assert (value6 == "value2");
		
		/* Get from bundle one global data part (in example with global key: "log")
		auto partBundle = newBundle.subBundle("log");
	}


 
 



