/* Copyright © 2022 yonah_ag
 *
 *  This program is free software; you can redistribute it or modify it under
 *  the terms of the GNU General Public License version 3 as published by the
 *  Free Software Foundation and appearing in the accompanying LICENCE file.
 *
 *  Releases
 *  --------
 *  1.0.3 : Initial release
 *  1.1.0 : Add parameters and UI dialog
 */

import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

MuseScore
{
   description: "Add Takadimi texts to beats";
   requiresScore: true;
   version: "1.1";
   menuPath: "Plugins.Takadimi";
   pluginType: "dialog";
   width:  250;
   height: 205;

// Parameters

   property var pSty : 0; // takadimi style = 0:lower, 1:UPPER, 2:Title, 3:CusTom
   property var pyAb : -5; // text Y-Offset above
   property var pyBe : 5.5; // text Y-Offset below
   property var pVox : 2 // number of voices to process 1-4
   property var pRst : 1 // rest style = 0:no text, 1:(brackets), 2:(-)
   property var pAuto : false // autoplacement
   
// Takadimi syllables

   property var sylT : ["Ta","Di",
                        "Ta","ki","da",
                        "Ta","ka","Di","Mi",
                        "Ta","Ka","Di","Mi","Na",
                        "Ta","va","ki","Di","da","ma",
                        "Ta","Va","Ki","Di","Da","Ma","Vi",
                        "Ta","Ka","Di","Mi","Na","Ka","Di","Mi",
                        "Ta","Va","Ki","Di","Da","Ma","Vi","Na","Mi"]; // takadimi syllables
                           
   property var sylS : ["Ta","ka","Di","mi"]; // syllables for simple meter
   property var sylC : ["Ta","va","ki","Di","da","ma"]; // syllables for compound meter
   property var sylA : ["Ta","la","ka","la","di","la","mi","la"]; // syllables for assymetric meter
   property var sylD : "La" // default syllable

   property var nRpt : 8; // repeat syllables offset
   property var aSym : [5,7,11,13,17,19]; // asymmetric meters 
   property var itup : 0; // tuplet index
   property var itun : 0; // tuplet actual no. of notes
   property var itux : 0; // tuplet start index
   
   property var mMap : [] // measure map
   property var nofApply: 0; // Count of "Apply" presses for use with "Undo"
   
   function mapMeasures(score)
   {
      var nom = 1;
      var cursor = score.newCursor();
      cursor.rewind(Cursor.SCORE_START);
      while (cursor.measure) {
         var cur = cursor.measure;
         var tick = cur.firstSegment.tick;
         var tsnu = cur.timesigActual.numerator;
         var tsde = cur.timesigActual.denominator;
         var ttyp = 1; // timesig Type 1:Simple, 2:Compound, 3:Asymmetric, 4:Unsupported
         if (tsnu > 5 && tsnu % 3 == 0)
            ttyp = 2;
         else if (aSym.indexOf(tsnu) > -1)
            ttyp = 3;
         else if (tsnu > 19)
            ttyp = 4;
         var ticksB = division * 4.0 / tsde;
         var ticksM = ticksB * tsnu;
         nom += cur.noOffset;
         var elm =
         {
            "tick": tick,
            "tsD": tsde,
            "tsN": tsnu,
            "ticksB": ticksB,
            "ticksM": ticksM,
            "past" : (tick + ticksM),
            "nom": nom,
            "tsT": ttyp
         };
         mMap[elm.tick] = elm;
         if (!cur.irregular) ++nom;
         cursor.nextMeasure();
      }
//      return map;
   }

   function takaScore(cb)
   {
      var args = Array.prototype.slice.call(arguments, 1);
      var staveBeg;
      var staveEnd;
      var tickEnd;
      var rewindMode;
      var toEOF;
      var cursor = curScore.newCursor();

// Get Parameters

      pSty = (txtSty.currentIndex);
      pVox = (txtVox.currentIndex)+1;
      pAuto = (txtAuto.currentIndex > 0);
      pRst = (txtRst.currentIndex);
      
      if(isNaN(txtpyAb.text))
         pyAb = 0
      else
         pyAb = txtpyAb.text;

      if(isNaN(txtpyBe.text))
         pyBe = 0
      else
         pyBe = txtpyBe.text;

      
      cursor.rewind(Cursor.SELECTION_START);
      if (cursor.segment) {
         staveBeg = cursor.staffIdx;
         cursor.rewind(Cursor.SELECTION_END);
         staveEnd = cursor.staffIdx;
         if (!cursor.tick) {
            toEOF = true;
         } else {
            toEOF = false;
            tickEnd = cursor.tick;
         }
         rewindMode = Cursor.SELECTION_START;
      } else {
         staveBeg = 0; // no selection
         staveEnd = curScore.nstaves - 1;
         toEOF = true;
         rewindMode = Cursor.SCORE_START;
      }

      curScore.startCmd();
      for (var stave = staveBeg; stave <= staveEnd; ++stave) {
         for (var voice = 0; voice < pVox; ++voice) {
            cursor.staffIdx = stave;
            cursor.voice = voice;
            cursor.rewind(rewindMode);
            cursor.staffIdx = stave;
            cursor.voice = voice;
            while (cursor.segment && (toEOF || cursor.tick < tickEnd)) {
               if (cursor.element) cb.apply(null,[cursor].concat(args));
               cursor.next();
            }
         }
      }
      curScore.endCmd();
      ++nofApply;
   }

   function takaBeat(cursor)
   {
      var txt = "" // Text for Takadimi syllable
      var cor = 0; // Chord or Rest = 1:chord, 2:rest, 0:other
      switch (cursor.element.type) {
         case Element.CHORD: cor=1; break;
         case Element.REST: cor=2; break;
      }
      if (cor == 0) return; // when not chord or rest
      if (cor == 2 && pRst==0) return; // when not processing rests

      var tik = cursor.segment.tick;
      if (cor == 1)
         if (cursor.element.notes[0].tieBack) cor = 2; // format a tie like a rest

      var mm = mMap[cursor.measure.firstSegment.tick];
      var bt = 0;
      if (mm && tik >= mm.tick && tik < mm.past) bt = 1 + (tik - mm.tick) / mm.ticksB;
      if (bt == 0) return;

      var bto = 0; // beat.mod
      var bti = 0; // bto.int
      var btf = 0; // bto.frac
      var elm = newElement(Element.STAFF_TEXT);
      
      if (itup > 0) {
        txt = sylT[itux];
        ++itup;
        if (itup > itun)
           itup = 0
        else {
           ++itux;
           if (itux >= sylT.length) itux -= nRpt;
        }
      }
      if (itup == 0) {
         switch (mm.tsT) {
            case 1:
               bto = 4 * (bt % 1);
               bti = parseInt(bto);
               btf = bto - bti;
               if (btf == 0) {
                  txt = sylS[bto];
                  if (cursor.element.tuplet != null) {
                     itup = 1;
                     itun = cursor.element.tuplet.actualNotes;
                     itux = ((itun-1)*itun)/2;
                     if (itux >= sylT.length) itux = sylT.length - nRpt;
                  }
               }
               else
                  txt = sylD;
               break;
            case 2:
               bto = (2*(bt - 1)) % 6;
               bti = parseInt(bto);
               btf = bto - bti;
               if (btf == 0) {
                  txt = sylC[bto];
                  if (cursor.element.tuplet != null) {
                     itup = 1;
                     itun = cursor.element.tuplet.actualNotes;
                     itux = ((itun-1)*itun)/2;
                     if (itux >= sylT.length) itux = sylT.length - sysRept;
                  }
               }
               else
                  txt = sylD;
               break;
            case 3:
               if (bt < 4) {
                  bto = (2*(bt - 1)) % 6;
                  bti = parseInt(bto);
                  btf = bto - bti;
                  if (btf == 0)
                     txt = sylC[bto];
                  else
                     txt = sylD;
               }
               else {
                  bto = 4 * (bt % 2);
                  bti = parseInt(bto);
                  btf = bto - bti;
                  if (btf == 0)
                     txt = sylA[bto];
                  else
                     txt = "ni";
               }
               break;
            default:
               txt = sylD;
         }
      }
      switch (pSty) {
         case 0: txt = txt.toLowerCase(); break;
         case 1: txt = txt.toUpperCase(); break;
         case 2: txt = txt.substr(0,1).toUpperCase() + txt.substr(1,1);
      }
      if (cor == 1)
         elm.text = txt
      else
         if(pRst==1)
            elm.text = "(" + txt + ")"
         else
            elm.text = "(-)";

      if(cursor.voice==0 || cursor.voice==2) {
         elm.placement = Placement.ABOVE;
         elm.offsetY = pyAb;
      }
      else {
         elm.placement = Placement.BELOW;
         elm.offsetY = pyBe;
      }
      elm.autoplace = pAuto;
      elm.align = Align.BASELINE
      elm.fontFace = "FreeSans";
      elm.fontSize = 8;
      cursor.add(elm);
   }

   function unApply()
   {
      if (nofApply > 0) {
         cmd("undo");
         --nofApply;
      }
   }

   onRun:
   {
      mapMeasures(curScore);
   }

   GridLayout { id: winUI
   
      anchors.fill: parent
      anchors.margins: 5
      columns: 3
      columnSpacing: 2
      rowSpacing: 2

      Label { id: lblSty
         visible : true
         text: "Text Style"
         Layout.preferredWidth: 60
      }
      ComboBox { id: txtSty
         visible: true
         enabled: true
         Layout.preferredWidth: 90
         Layout.preferredHeight: 30
         currentIndex: 0
         model: ListModel { id: selSty
            ListElement { text: "Lower"  }
            ListElement { text: "Upper" }
            ListElement { text: "Title" }
            ListElement { text: "Custom" }
         }
      }
      Button { id: btnApply
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         text: "Apply"
         onClicked: takaScore(takaBeat)
      }
      
      Label { id: lblRst; visible: true; text: "Rest Style";
              Layout.preferredWidth: 60 }
      ComboBox { id: txtRst
         visible: true
         enabled: true
         Layout.preferredWidth: 90
         Layout.preferredHeight: 30
         currentIndex: 1
         model: ListModel { id: selRst
            ListElement { text: "No text"  }
            ListElement { text: "Brackets" }
            ListElement { text: "Hyphen" }
         }
      }
      Button { id: btnUndo
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         text: "Undo"
         onClicked: unApply()
      }
      
      Label { id: lblVox
         visible : true
         text: "Voices"
         Layout.preferredWidth: 60
      }
      ComboBox { id: txtVox
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         currentIndex: 1
         model: ListModel { id: selVox
            ListElement { text: "1"  }
            ListElement { text: "2" }
            ListElement { text: "3" }
            ListElement { text: "4" }
         }
      }
      Label { id: lblNulC; visible: true;
              text: ""; Layout.preferredWidth: 0 }
      
      Label { id: lblYoffA; visible: true; text: "Offset Above" }
      TextField { id: txtpyAb
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         text: pyAb
      }
      Label { id: lblNulB; visible: true; text: "" }
      Label { id: lblYoffB; visible: true; text: "Offset Below" }
      TextField { id: txtpyBe
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         text: pyBe
      }
      Label { id: lblNulA; visible: true; text: "" }
      Label { id: lblAuto; visible: true; text: "Autoplace" }
      ComboBox { id: txtAuto
         visible: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 30
         currentIndex: 0
         model: ListModel { id: selAuto
            ListElement { text: "No"  }
            ListElement { text: "Yes" }
         }
      }
   } // GridLayout
}
