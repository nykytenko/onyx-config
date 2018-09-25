# onyx-config

Container for configurations data


## Key features:
 - A Bundle is immutable container for saving data.
 - A Bundle may be created from text file or string array in run-time.
 - bundle1 + bundle2 operation


## Simple Example:

Simple configuration text file ("./test/simple.conf"):

    [config]
    user = Mark
    connecting = true
    timeout = 2000
    tmax = 26.7

Source code example:

```D
import onyx.bundle;

void main()
{
    auto bundle = new immutable Bundle("./test/simple.conf");

    auto user = bundle.value("config", "user");
    assert (user == "Mark");

    auto connecting = bundle.value!bool("config", "connecting");
    assert (connecting == true);

    auto timeout = bundle.value!int("config", "timeout");
    assert (timeout == 2000);

    auto tmax = bundle.value!double("config", "tmax");
    assert (tmax == 26.7);
}
```


## More Examples:

Configuration text file ("./test/test.conf"):

    [general] # <-- Global Key (GlKey)
    #------------------------------------------------------------
    mod_name = KPR
    #  ^
    #  |--- Key

    mod_type = RptR11Transceiver
    #        ^       ^
    #        |       |--- Value
    #        |
    #        |--- Key to Value Separator


    [protocol]
    #------------------------------------------------------------
    channel_switch_timeout = 1000 100 10        # many values in one line is possible


    [data_receive]
    #--------------------------------------------------------------------------------------------------------
    # Addr in    Addr_out    type    name       send_to_next    channel     Formula
    # KPR_adr    UTS_PMZ                                        priority
    #--------------------------------------------------------------------------------------------------------
    #
    0xC000   ->   0xC000     0x0B    XGES_Р         yes             1       (2*{0xC000}+10)+(-0.2*{0xC179}-5)
    #        ^
    #        |--- Key to Value Separator too

    0xC000~1 ->   0xC001     0x0B    XYGES_Р        yes             2       (1*{0xC000}+0)
    #  ^
    #  |--- Key

    0xC179   ->   0xC179     0x0B    XaES_Р         yes             1       1*{0xC179}+0
    #               ^         ^
    #               |         |--- Position 1 Value
    #               |
    #               |--- Position 0 Value



Source code example:

```D
import onyx.bundle;

void main()
{
    /* Custom file parsing parameters */
    auto parameters = immutable Parameters(
            "[",        // Start Global key symbols. "[" by default.
            "]",        // End Global key symbols "]" by default.
            ["=", "->"],// Separator symbols between "Key" and "Values". "=" by default.
            "#");       // Comment symbol. "#" by default.

    /* Create bundle from file */
    auto bundle = new immutable Bundle("./test/test.conf", parameters);

    /* get string value from bundle */
    auto val1 = bundle.value("general", "mod_name");
    assert (val1 == "KPR");

    /* get integer value for line with many values from possition 1 */
    auto val2 = bundle.value!int("protocol", "channel_switch_timeout", 1);
    assert (val2 == 100);

    /* get integer hex value (0 position) */
    auto val3 = bundle.value!int("data_receive", "0xC179");
    assert (val3 == 0xC179);

    /* get value for GlKey:"data_receive", Key:"0xC000~1, position:5 */
    auto val4 = bundle.value("data_receive", "0xC000~1", 5);
    assert (val4 == "(1*{0xC000}+0)");

    /* get Values array */
    auto values = bundle.values("protocol", "channel_switch_timeout");
    assert (values == ["1000", "100", "10"]);

    /* get GlValue */
    auto glValue = bundle.glValue("general");
    immutable gv = ["mod_name":["KPR"], "mod_type":["RptR11Transceiver"]];
    assert (glValue == gv);


    /* Build another bundle from string array */
    string[] s2 =
       ["[protocol]",
       "data_flow = input",
       "[new_gl_key]",
       "test_key = value1 value2"];

    /* Create bundle from string array */
    auto bundle2 = new immutable Bundle(s2);

    /* Add two bundles. Created new bundle with data from both bundles */
    auto newBundle = bundle + bundle2;
    auto val5 = newBundle.value("general", "mod_name");
    assert (val5 == "KPR");
    auto val6 = newBundle.value("new_gl_key", "test_key", 1);
    assert (val6 == "value2");

    /* Get from bundle one global data part (in example with global key: "protocol") */
    auto partBundle = newBundle.subBundle("protocol");
}
```
