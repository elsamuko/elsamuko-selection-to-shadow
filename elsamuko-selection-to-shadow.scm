; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
; http://www.gnu.org/licenses/gpl-3.0.html
;
; Copyright (C) 2010 elsamuko <elsamuko@web.de>
;
; Version 0.1 - Creates an enlarged drop shadow from selection
;

(define (elsamuko-selection-to-shadow img draw)

  (let* (
         (owidth (car (gimp-image-width img)))
         (oheight (car (gimp-image-height img)))
         ; selection
         (bounds (gimp-selection-bounds img))
         (boundsX (cadr bounds))
         (boundsY (caddr bounds))
         (boundsW (- (cadr (cddr bounds)) boundsX))
         (boundsH (- (caddr (cddr bounds)) boundsY))
         ; with 15px for shadow
         (boundsWPlus (+ 15 boundsW))
         (boundsHPlus (+ 15 boundsH))
         ; after resize
         (newWidth (+ 40 (* boundsW 2)))
         (newHeight (+ 40 (* boundsH 2)))
         ; layers
         (layerObj (gimp-image-get-layers img))
         (layerCount (car layerObj))
         (layerVector (cadr layerObj))
         (layerList (vector->list layerVector))
         (lowestLayer (aref layerVector (- layerCount 1)))
         (shadowGroup (car (gimp-layer-group-new img)))
         (addedLayer (car (gimp-layer-new img
                                          boundsWPlus
                                          boundsHPlus
                                          RGBA-IMAGE
                                          "Selection"
                                          100
                                          LAYER-MODE-NORMAL)))
         (shadowLayer (car (gimp-layer-new img
                                           boundsWPlus
                                           boundsHPlus
                                           RGBA-IMAGE
                                           "Shadow"
                                           100
                                           LAYER-MODE-NORMAL)))
         )
    
    ; init
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (gimp-context-set-interpolation INTERPOLATION-LINEAR)

    ; unlink 1st and 2nd level layers
    (map (lambda (current) (begin
                             (if (= (car (gimp-item-is-group current)) TRUE)
                                 (begin
                                   (let* (
                                          (groupObj (gimp-item-get-children current))
                                          (groupVector (cadr groupObj))
                                          (groupList (vector->list groupVector))
                                          )
                                     (map (lambda (current) (gimp-item-set-linked current FALSE)) groupList)
                                     )
                                   )
                                 (gimp-item-set-linked current FALSE)
                                 )
                             )) layerList)

    ; add shadow layer as new layer
    (gimp-image-insert-layer img shadowGroup 0 0)
    (gimp-item-set-name shadowGroup "Selection + Shadow")
    (gimp-image-insert-layer img shadowLayer shadowGroup 0)
    (gimp-layer-set-offsets shadowLayer boundsX boundsY)

    ; fill shadow with black
    (gimp-context-set-foreground '(0 0 0))
    (gimp-edit-bucket-fill shadowLayer FG-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)

    ; add selection from lowest layer as new layer to shadow group
    (gimp-image-insert-layer img addedLayer shadowGroup 0)
    (gimp-layer-set-offsets addedLayer boundsX boundsY)
    (gimp-edit-copy lowestLayer)
    (gimp-floating-sel-anchor (car (gimp-edit-paste addedLayer FALSE)))

    ; scale 200% + 40px
    (gimp-layer-scale shadowGroup newWidth newHeight TRUE)

    ; move shadow
    (gimp-drawable-offset shadowLayer FALSE OFFSET-TRANSPARENT 20 20)
    (plug-in-gauss RUN-NONINTERACTIVE img shadowLayer 10 10 1)

    ; link selection and shadow
    (gimp-item-set-linked addedLayer TRUE)
    (gimp-item-set-linked shadowLayer TRUE)
          
    ; tidy up
    (gimp-image-undo-group-end img)
    (gimp-displays-flush)
    (gimp-context-pop)
    )
  )

(script-fu-register "elsamuko-selection-to-shadow"
                    _"_Selection to Shadow"
                    "Add selection as shadow"
                    "elsamuko <elsamuko@web.de>"
                    "elsamuko"
                    "2018-06-25"
                    "*"
                    SF-IMAGE       "Input image"           0
                    SF-DRAWABLE    "Input drawable"        0
                    )

(script-fu-menu-register "elsamuko-selection-to-shadow" _"<Image>/Image")
