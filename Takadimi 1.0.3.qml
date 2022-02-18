/* Copyright © 2020, 2021 mirabilos <m@mirbsd.org> : Count note beats code
 * Copyright © 2022 yonah_ag : Takadimi code
 *
 * Provided that these terms and disclaimer and all copyright notices are retained or reproduced in an
 * accompanying document, permission is granted to deal in this work without restriction, including
 * unlimited rights to use, publicly perform, distribute, sell, modify, merge, give away, or sublicence.
 *
 * This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to the utmost extent permitted by applicable law,
 * neither express nor implied; without malicious intent or gross negligence. In no event may a licensor, author or
 * contributor be held liable for indirect, direct, other damage, loss, or other issues arising in any way out of
 * dealing in the work, even if advised of the possibility of such damage or existence of a defect, except proven
 * that it results out of said person's immediate fault when using the work as intended.
 */

import MuseScore 3.0

MuseScore
{
   description: "Add Takadimi texts to beats";
   requiresScore: true;
   version: "1.0.3";
   menuPath: "Plugins.Takadimi";
   
   property var taStyle : 0; // style = 0:lower, 1:UPPER, 2:Title, 3:CusTom
   property var takaOff : 2.5; // text Y-Offset
   
   property var sylSim : ["Ta","ka","Di","mi"]; // simple meter
   property var sylCom : ["Ta","va","ki","Di","da","ma"]; // compound meter
   property var sylTup : ["Ta","Di",
                           "Ta","ki","da",
                           "Ta","ka","Di","Mi",
                           "Ta","Ka","Di","Mi","Na",
                           "Ta","va","ki","Di","da","ma",
                           "Ta","Va","Ki","Di","Da","Ma","Vi",
                           "Ta","Ka","Di","Mi","Na","Ka","Di","Mi",
                           "Ta","Va","Ki","Di","Da","Ma","Vi","Na","Mi"];
   property var sylAsm : ["Ta","la","ka","la","di","la","mi","la"];
   property var sylDef : "La" // Default syllable
   property var sylRep : 8; // repeat syllables offset
   property var aSym : [5,7,11,13,17,19]; // asymmetric meters 
   property var itup : 0; // tuplet index
   property var itun : 0; // tuplet actual no. of notes
   property var itux : 0; // tuplet start index (triangle numbers)
   
   function buildMeasureMap(score)
   {
      var map = {};
      var nom = 1;
      var cursor = score.newCursor();
      cursor.rewind(Cursor.SCORE_START);
      while (cursor.measure) {
         var cm = cursor.measure;
         var tick = cm.firstSegment.tick;
         var tsnu = cm.timesigActual.numerator;
         var tsde = cm.timesigActual.denominator;
         var tsty = 1; // timesig Type 1:Simple, 2:Compound, 3:Asymmetric, 4:Unsupported
         if (tsnu > 5 && tsnu % 3 == 0)
            tsty = 2;
         else if (aSym.indexOf(tsnu) > -1)
            tsty = 3;
         else if (tsnu > 19)
            tsty = 4;
         var ticksB = division * 4.0 / tsde;
         var ticksM = ticksB * tsnu;
         nom += cm.noOffset;
         var cur =
         {
            "tick": tick,
            "tsD": tsde,
            "tsN": tsnu,
            "ticksB": ticksB,
            "ticksM": ticksM,
            "past" : (tick + ticksM),
            "nom": nom,
            "tsT": tsty
         };
         map[cur.tick] = cur;
         if (!cm.irregular) ++nom;
         cursor.nextMeasure();
      }
      return map;
   }

   function labelScore(cb)
   {
      var args = Array.prototype.slice.call(arguments, 1);
      var staveBeg;
      var staveEnd;
      var tickEnd;
      var rewindMode;
      var toEOF;
      var cursor = curScore.newCursor();

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

      for (var stave = staveBeg; stave <= staveEnd; ++stave) {
         for (var voice = 0; voice < 4; ++voice) {
            cursor.staffIdx = stave;
            cursor.voice = voice;
            cursor.rewind(rewindMode);
            cursor.staffIdx = stave;
            cursor.voice = voice;
            while (cursor.segment && (toEOF || cursor.tick < tickEnd))
            {
               if (cursor.element) cb.apply(null,[cursor].concat(args));
               cursor.next();
            }
         }
      }
   }

   function labelBeat(cursor, mezuMap, doneMap)
   {
      var txt = "" // Text for Takadimi syllable
      var cor = 0; // Chord or Rest = 1:chord, 2:rest, 0:other
      switch (cursor.element.type) {
         case Element.CHORD: cor=1; break;
         case Element.REST: cor=2; break;
      }
      if (cor == 0) return;

      var tik = cursor.segment.tick;
      if (doneMap[tik]) return;

      doneMap[tik] = true;
      if (cor == 1)
         if (cursor.element.notes[0].tieBack) cor = 2; // format a tie like a rest

      var mm = mezuMap[cursor.measure.firstSegment.tick];
      var bt = 0;
      if (mm && tik >= mm.tick && tik < mm.past) bt = 1 + (tik - mm.tick) / mm.ticksB;
      if (bt == 0) return;

      var bto = 0; // beat.modulus
      var bti = 0; // bto.int
      var btf = 0; // bto.frac
      var taka = newElement(Element.STAFF_TEXT);
      
      if (itup > 0) {
        txt = sylTup[itux];
        ++itup;
        if (itup > itun)
           itup = 0
        else {
           ++itux;
           if (itux >= sylTup.length) itux -= sylRep;
        }
      }
      if (itup == 0) {
         switch (mm.tsT) {
            case 1:
               bto = 4 * (bt % 1);
               bti = parseInt(bto);
               btf = bto - bti;
               if (btf == 0) {
                  txt = sylSim[bto];
                  if (cursor.element.tuplet != null) {
                     itup = 1;
                     itun = cursor.element.tuplet.actualNotes;
                     itux = ((itun-1)*itun)/2;
                     if (itux >= sylTup.length) itux = sylTup.length - sylRep;
                  }
               }
               else
                  txt = sylDef;
               break;
            case 2:
               bto = (2*(bt - 1)) % 6;
               bti = parseInt(bto);
               btf = bto - bti;
               if (btf == 0) {
                  txt = sylCom[bto];
                  if (cursor.element.tuplet != null) {
                     itup = 1;
                     itun = cursor.element.tuplet.actualNotes;
                     itux = ((itun-1)*itun)/2;
                     if (itux >= sylTup.length) itux = sylTup.length - sysRept;
                  }
               }
               else
                  txt = sylDef;
               break;
            case 3:
               if (bt < 4) {
                  bto = (2*(bt - 1)) % 6;
                  bti = parseInt(bto);
                  btf = bto - bti;
                  if (btf == 0)
                     txt = sylCom[bto];
                  else
                     txt = sylDef;
               }
               else {
                  bto = 4 * (bt % 2);
                  bti = parseInt(bto);
                  btf = bto - bti;
                  if (btf == 0)
                     txt = sylAsm[bto];
                  else
                     txt = "ni";
               }
               break;
            default:
               txt = sylDef;
         }
      }
      switch (taStyle) {
         case 0: txt = txt.toLowerCase(); break;
         case 1: txt = txt.toUpperCase(); break;
         case 2: txt = txt.substr(0,1).toUpperCase() + txt.substr(1,1);
      }
      if (cor == 1)
         taka.text = txt
      else
         taka.text = "(" + txt + ")";

      taka.placement = Placement.BELOW;
      taka.offsetY = takaOff;
      taka.align = Align.BASELINE;
      cursor.add(taka);
   }

   onRun:
   {
      var mezuMap = buildMeasureMap(curScore);
      var doneMap = {};
      labelScore(labelBeat, mezuMap, doneMap);
      Qt.quit();
   }
   
}
