# MuseScore Takadimi Plugin

A MuseScore plugin to apply Takadimi rhythm syllables to beats in a score.

![00](https://github.com/yonah-ag/musescore-takadimi/blob/main/images/takadimi00.png)
![02](https://github.com/yonah-ag/musescore-takadimi/blob/main/images/takadimi02.png)

### License

Copyright (C) 2022 yonah_ag

This program is free software; you can redistribute it or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation and appearing in the LICENSE file.

See https://github.com/yonah-ag/musescore-takadimi/blob/main/LICENSE

### Installation

This plugin requires version 3.x of MuseScore.  
Download Takadimi.qml then follow the handbook instructions: https://musescore.org/en/handbook/3/plugins

### Using the Plugin

Select a range of measures, or use without selection to apply to all, then from the **Plugins** menu select **Takadimi**.  
Set the options as required then press **Apply**.  
Use the **X** button to close the plugin dialogue window.

![03](https://github.com/yonah-ag/musescore-takadimi/blob/main/images/takadimi03.png)

#### Options

+ **Text Style**
  + Lower: Use lower case syllables
  + Upper: Use UPPER case syllables
  + Title: Use Title Case Syllables
  + Custom: Use Custon case Syllables as defined in the plugin code
+ **Rest Style**
  + No Text: Don't show any text for rests
  + Brackets: Show the Takadimi syllable in brackets
  + Hyphen: Show a rest as (-)
+ **Voices**
  + Select the number of voices to process
  + Syllables in voices 1 and 3 are added above the stave
  + Syllables in voices 2 and 4 are added below the stave
+ **Offsets**
  + Use these to set the vertical position of the syllables relative to the stave
+ **Autoplace**
  + Choose whether to use MuseScore's auto-placement feature or not

### Additional Info

Takadimi is the work of Richard Hoffman, William Pelto, and John W. White.  
For full details see the official Takadimi homepage at http://www.takadimi.net/

The repository file **Takadimi.mscz** is the Takadimi short guide in MuseScore format.

The MuseScore project page for this plugin can be found at https://musescore.org/en/project/takadimi-rhythm
