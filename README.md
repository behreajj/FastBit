# Table of Contents

   1. [Introduction](#introduction)
   1. [Two Bits](#two-bits)
   2. [Three Bits](#three-bits)
   3. [Four Bits](#four-bits)
   4. [Five Bits](#five-bits)
   5. [Six Bits](#six-bits)

## Introduction

This is a fork of [WolftrooperNo86](https://github.com/WolftrooperNo86)'s [FastBit](https://github.com/WolftrooperNo86/FastBit) Lua script for [Aseprite](https://www.aseprite.org/), a pixel art editor. For general information on how to install a script in Aseprite, see [the documentation](https://www.aseprite.org/docs/scripting/); for the scripting API, see this [Github repo](https://github.com/aseprite/api). For discussion about the original script in the Aseprite community forum, see this [thread](https://community.aseprite.org/t/script-fastbit-color-picker-v1-2/5687).

_This script was tested in Aseprite version 1.3-beta-5._

![Screen Capture](screenCap.png)

I have refactored the code for general readability and maintainability.

Color bit-depth can now be changed without separate dialog windows. There are no plans to support uniform control over RGB bit-depth.

Foreground and background colors are no longer  updated by the dialog; this is to avoid overwriting color entries in unlocked palettes. Furthermore, the dialog is no longer concerned about a sprite's color mode, or whether a sprite is open at all. You can left click on the color preview to assign to the foreground color; right click, to the background color. You can also copy and paste the hexadecimal code.

As seen in the screen capture above, the underlined letters on the buttons show that `Alt+F` gets the foreground color; `Alt+B`, the background color; `Alt+W` creates a new sprite with a color wheel; `Alt+C` closes the dialog.

The HSL color wheel is not guaranteed to give you every color available for the selected channel bit-depths. The number of frames to animate the lightness of the color wheel is based on the maximum bit-depth for red, green and blue channels. HSL is not perceptually uniform. It is used only because it is popular and is built-in. See instead [HSLuv](https://www.hsluv.org/) or [LCH](https://css.land/lch/).

The palette assigned to the sprite containing the color wheel is clamped to 256 maximum. Index 0 is set to the alpha mask. There's no point in using Aseprite's palette creation algorithms, as the condensed palette will not preserve bit-depth safe colors. 

I am still researching the proper expansions from low bit to standard RGB. The tables below are diagnostic print-outs for both myself and for interested readers to compare this script's outputs against other standards and palettes. The one, seven and eight bit tables are omitted. I count the number of bits per _one_ color channel, so readers may need to multiply by three to match other naming conventions. For example, "five bits" would be "fifteen bit RGB." Differences are included in cases where 256 - 1 divided by the number of steps - 1 does not yield an integer quotient.

## Two Bits
`2 ^ 2 = 4`, `1 << 2 = 4`, `255 / (4 - 1) = 85`

![Bit 2](bit2.png)

[https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#6-bit_RGB](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#6-bit_RGB)*

Step|Decimal|Hex
---:|------:|--:|
0|0|00
1|85|55
2|170|AA
3|255|FF

*The reference image contains channel values such as `1` and `171` (`AB`).

## Three Bits
`2 ^ 3 = 8`, `1 << 3 = 8`, `255 / (8 - 1) = 36.42857142857143`

![Bit 3](bit3.png)

[https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#9-bit_RGB](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#9-bit_RGB)

Step|Decimal|Hex|Diff|
---:|------:|--:|---:|
0|0|00|
1|36|24|36
2|72|48|36
3|109|6D|37
4|145|91|36
5|182|B6|37
6|218|DA|36
7|255|FF|37

## Four Bits
`2 ^ 4 = 16`, `1 << 4 = 16`, `255 / (16 - 1) = 17`

![Bit 4](bit4.png)

[https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#12-bit_RGB](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#12-bit_RGB)

Step|Decimal|Hex|
---:|------:|--:|
0|0|00
1|17|11
2|34|22
3|51|33
4|68|44
5|85|55
6|102|66
7|119|77
8|136|88
9|153|99
10|170|AA
11|187|BB
12|204|CC
13|221|DD
14|238|EE
15|255|FF

## Five Bits
`2 ^ 5 = 32`, `1 << 5 = 32`, `255 / (32 - 1) = 8.225806451612903`

![Bit 5](bit5.png)

[https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#15-bit_RGB](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#15-bit_RGB)*

Step|Decimal|Hex|Diff|
---:|------:|--:|---:|
0|0|00|
1|8|08|8
2|16|10|8
3|24|18|8
4|32|20|8
5|41|29|9
6|49|31|8
7|57|39|8
8|65|41|8
9|74|4A|9
10|82|52|8
11|90|5A|8
12|98|62|8
13|106|6A|8
14|115|73|9
15|123|7B|8
16|131|83|8
17|139|8B|8
18|148|94|9
19|156|9C|8
20|164|A4|8
21|172|AC|8
22|180|B4|8
23|189|BD|9
24|197|C5|8
25|205|CD|8
26|213|D5|8
27|222|DE|9
28|230|E6|8
29|238|EE|8
30|246|F6|8
31|255|FF|9

*There are numerous discrepancies between the refactor, the original fast bit script and the Wikipedia reference. A formula specific to the SNES palette can be found at [https://wiki.superfamicom.org/palettes](https://wiki.superfamicom.org/palettes).

## Six Bits
`2 ^ 6 = 64`, `1 << 6 = 64`, `255 / (64 - 1) = 4.047619047619048`

![Bit 6](bit6.png)

[https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#18-bit_RGB](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_color_formats?oldformat=true#18-bit_RGB)

Step|Decimal|Hex|Diff|
---:|------:|--:|---:|
0|0|00|
1|4|04|4
2|8|08|4
3|12|0C|4
4|16|10|4
5|20|14|4
6|24|18|4
7|28|1C|4
8|32|20|4
9|36|24|4
10|40|28|4
11|44|2C|4
12|48|30|4
13|52|34|4
14|56|38|4
15|60|3C|4
16|64|40|4
17|68|44|4
18|72|48|4
19|76|4C|4
20|80|50|4
21|85|55|5
22|89|59|4
23|93|5D|4
24|97|61|4
25|101|65|4
26|105|69|4
27|109|6D|4
28|113|71|4
29|117|75|4
30|121|79|4
31|125|7D|4
32|129|81|4
33|133|85|4
34|137|89|4
35|141|8D|4
36|145|91|4
37|149|95|4
38|153|99|4
39|157|9D|4
40|161|A1|4
41|165|A5|4
42|170|AA|5
43|174|AE|4
44|178|B2|4
45|182|B6|4
46|186|BA|4
47|190|BE|4
48|194|C2|4
49|198|C6|4
50|202|CA|4
51|206|CE|4
52|210|D2|4
53|214|D6|4
54|218|DA|4
55|222|DE|4
56|226|E2|4
57|230|E6|4
58|234|EA|4
59|238|EE|4
60|242|F2|4
61|246|F6|4
62|250|FA|4
63|255|FF|5