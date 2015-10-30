# onyx-config

Container for data (for example configurations data)


## Key features:
 - The Bundle is immutable container for save data.
 - A Bundle may be created from text file or string array in run-time.
 - bundle1 + bundle2 operation




## Examples:

Configuration text file ("./test/test.conf"):

	[general] # <-- This is Global Key (GlKey)
	#------------------------------------------------------------
	mod_name = KPR
	#  ^
	#  |--- This is Key

	mod_type = RptR11Transceiver
	#        ^       ^
	#        |       |--- This is Value
	#        |
	#        |--- This is Key to Value Separator


	[protocol]
	#------------------------------------------------------------
	channel_switch_timeout = 1000 100 10		# many values in one line is possible


	[data_receive]
	#----------------------------------------------------------------------------------------------------
	# Addr in  	Addr_out	type 	name 	send_to_next channel  Formula
	# KPR_adr  	UTS_PMZ					  				 priority
	#----------------------------------------------------------------------------------------------------
	#
	0xC000	 ->  0xC000   	0x0B	XGES_Р		yes	    	1      (2*{0xC000}+10)+(-0.2*{0xC179}-5)
	#        ^
	#        |--- This is Key to Value Separator too

	0xC000~1 ->  0xC001   	0x0B	XYGES_Р		yes	    	2      (1*{0xC000}+0)
	#  ^
	#  |--- This is Key

	0xC179	 ->  0xC179   	0x0B	XaES_Р		yes	    	1	   1*{0xC179}+0
	#               ^  		  ^
	#               |      	  |--- This is possition 1 Value
	#            	|
	#            	|--- This is possition 0 Value 
		


Source code example:

	import onyx.bundle;

	void main()
	{

		/* Custom file parsing parameters */
		auto parameters = immutable Parameters(
		 		"[",		// Start Global key symbols
				"]",		// End Global key symbols
				["=", "->"],	// Separator symbols between "Key" and "Values"
				"#");		// Comment symbols


		auto bundle = new immutable Bundle("./test/test.conf", parameters);

		/* get GlValue */
		auto glValue = bundle.glValue("general");
		immutable gv = ["mod_name":["KPR"], "mod_type":["RptR11Transceiver"]];
		assert (glValue == gv);

		/* get Values */
		auto values = bundle.values("protocol", "channel_switch_timeout");
		assert (values == ["1000", "100", "10"]);

		/* get value for line with many values from possition 1 */
		auto value1 = bundle.value("protocol", "channel_switch_timeout", 1); 
		assert (value1 == "100");


		/* get value for GlKey:"data_receive", Key:"0xC000~1, position:5 */
		auto value2 = bundle.value("data_receive", "0xC000~1", 5);
		assert (value2 == "(1*{0xC000}+0)");


		/* getValue test (0 position) */
		auto value3 = bundle.value!int("data_receive", "0xC179");
		assert (value == 0xC179);


		/* Build another bundle from string array */
		string[] s2 = 
		  ["[protocol]",
		   "data_flow = input",
		   "[new_gl_key]",
		   "test_key = value1 value2"];	
		auto bundle2 = new immutable ConfBundle(s2);
		
		/* Add two bundles. Created new bundle with data from both bundles */
		auto newBundle = bundle + bundle2;
		auto value5 = newBundle.value("general", "mod_name"); 
		assert (value5 == "KPR");
		auto value6 = newBundle.value("new_gl_key", "test_key", 1); 
		assert (value6 == "value2");
		
		/* Get from bundle one global data part (in example with global key: "protocol")
		auto partBundle = newBundle.subBundle("protocol");
	}


 
 



