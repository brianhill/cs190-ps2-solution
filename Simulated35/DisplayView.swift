//
//  DisplayView.swift
//  Simulated35
//
//  Created by Brian Hill github.com/brianhill on 1/26/16.
//

// DisplayView is a subclass of UIView that draws 15 seven-segment components into whatever space is alotted to it.

import UIKit

// Each digit has 8 segments, lettered a-h.
let segments = 8

// We'll still call it a seven-segment component (SSC), even though the decimal point gives it an eighth part.

// Coordinates within an 11x20 grid.

let gridWidth = CGFloat(11)
let gridHeight = CGFloat(20)

// Overstrikes are shown with x's in the diagram below.

//              11
//    012345678901
//  0 aaaaaaaaabb
//  1 aaaaaaaaabb
//  2 ff       bb
//  3 ff       bb
//  4 ff       bb
//  5 ff       bb
//  6 ff       bb
//  7 ff       bb
//  8 ff       bb
//  9 fxgggggggxb
// 10 exgggggggxc
// 11 ee       cc
// 12 ee       cc
// 13 ee       cc
// 14 ee       cc
// 15 ee       cc
// 16 ee   hh  cc
// 17 ee   hh  cc
// 18 dddddddddcc
// 19 dddddddddcc
// 20

let segmentOutlines = [
    0,  0,  9,  0,  9,  2,  0,  2, // a
    9,  0, 11,  0, 11, 10,  9, 10, // b
    9, 10, 11, 10, 11, 20,  9, 20, // c
    0, 18,  9, 18,  9, 20,  0, 20, // d
    0, 10,  2, 10,  2, 18,  0, 18, // e
    0,  2,  2,  2,  2, 10,  0, 10, // f
    1,  9, 10,  9, 10, 11,  1, 11, // g -- g actually overstrikes a bit of b, c, e and f.
    5, 16,  7, 16,  7, 18,  5, 18, // h
]

let middle = gridHeight / 2.0
let tiltPlusMinus = CGFloat(1.0)

typealias Mask = UInt8

enum Masks: Mask {
    case M0 = 0b00111111 // Digit 0
    case M1 = 0b00000110 // Digit 1
    case M2 = 0b01011011 // Digit 2
    case M3 = 0b01001111 // Digit 3
    case M4 = 0b01100110 // Digit 4
    case M5 = 0b01101101 // Digit 5
    case M6 = 0b01111101 // Digit 6
    case M7 = 0b00000111 // Digit 7
    case M8 = 0b01111111 // Digit 8
    case M9 = 0b01101111 // Digit 9
    case Point = 0b10000000 // Decimal Point
    case Minus = 0b01000000 // Minus Sign
    case Blank = 0b00000000 // Blank or Masked
}

// A dictionary of masks by character is super-handy for converting.
let masksByCharacter = [
    DisplayableCharacters.Char0: Masks.M0,
    DisplayableCharacters.Char1: Masks.M1,
    DisplayableCharacters.Char2: Masks.M2,
    DisplayableCharacters.Char3: Masks.M3,
    DisplayableCharacters.Char4: Masks.M4,
    DisplayableCharacters.Char5: Masks.M5,
    DisplayableCharacters.Char6: Masks.M6,
    DisplayableCharacters.Char7: Masks.M7,
    DisplayableCharacters.Char8: Masks.M8,
    DisplayableCharacters.Char9: Masks.M9,
    DisplayableCharacters.Point: Masks.Point,
    DisplayableCharacters.Minus: Masks.Minus,
    DisplayableCharacters.Blank: Masks.Blank,
]

let ledOnColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [1.0, 0.1, 0.2, 1.0]) // mostly red
let ledDimColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [0.8, 0.08, 0.16, 1.0]) // dimmed variant of ledOnColor
let ledOffColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), [0.2, 0.02, 0.04, 1.0]) // dark variant of ledOnColor

func indicesToPoint(i: Int, j: Int, insetRect: CGRect) -> CGPoint {
    let offset = 8 * i + 2 * j
    let rawX = segmentOutlines[offset]
    let rawY = segmentOutlines[offset + 1]
    let tilt = tiltPlusMinus * (CGFloat(rawY) - middle) / middle
    let x = insetRect.origin.x + (CGFloat(rawX) - tilt) * insetRect.size.width / gridWidth
    let y = insetRect.origin.y + CGFloat(rawY) * insetRect.size.height / gridHeight
    return CGPointMake(x, y)
}

let insetFraction = CGFloat(0.25)

// This function creates a rect that is inset from the supplied rect.
// The SSC will actually only fill the inset rect.
func rectToInsetRect(rect: CGRect) -> CGRect {
    let width = rect.size.width
    let height = rect.size.height
    let insetWidthAmount = insetFraction * width
    let insetHeightAmount = insetFraction * height
    let newWidth = width - 2.0 * insetWidthAmount
    let newHeight = height - 2.0 * insetHeightAmount
    return CGRectMake(rect.origin.x + insetWidthAmount, rect.origin.y + insetHeightAmount, newWidth, newHeight)
}

class DisplayView: UIView {
    
    // To save batteries, the original HP calculators had the LEDs off some of the time.
    // This variable is consulted in drawSegment.
    var strobeOn = true
    
    // Draws a segment given its four corners, supplied in clockwise order.
    // On determines whether the segment should be on.
    // However the segment is off if strobeOn is false.
    func drawSegment(context: CGContextRef,
                     upperLeft: CGPoint,
                     upperRight: CGPoint,
                     lowerRight: CGPoint,
                     lowerLeft: CGPoint,
                     on:Bool)
    {
        // Compound ternary operator (icch). Covers all the cases though.
        // on && strobeOn --> ledOnColor
        // on && strobeOff --> ledDimColor
        // off --> ledOffColor
        let color = on && strobeOn ? ledOnColor : (on ? ledDimColor : ledOffColor)
        CGContextSetFillColorWithColor(context, color)
        CGContextMoveToPoint(context, upperLeft.x, upperLeft.y)
        CGContextAddLineToPoint(context, upperRight.x, upperRight.y)
        CGContextAddLineToPoint(context, lowerRight.x, lowerRight.y)
        CGContextAddLineToPoint(context, lowerLeft.x, lowerLeft.y)
        CGContextAddLineToPoint(context, upperLeft.x, upperLeft.y)
        CGContextFillPath(context)
    }
    
    // Draws one seven-segment component (SSC).
    func drawSSC(context:CGContextRef, sscRect:CGRect, mask:UInt8) {
        let insetRect = rectToInsetRect(sscRect)
        for segment in 0 ..< segments {
            let upperLeft  = indicesToPoint(segment, j:0, insetRect:insetRect)
            let upperRight = indicesToPoint(segment, j:1, insetRect:insetRect)
            let lowerRight = indicesToPoint(segment, j:2, insetRect:insetRect)
            let lowerLeft  = indicesToPoint(segment, j:3, insetRect:insetRect)
            let on = Bool(Int(mask) & 1<<segment)
            self.drawSegment(context,
                             upperLeft:upperLeft,
                             upperRight:upperRight,
                             lowerRight:lowerRight,
                             lowerLeft:lowerLeft,
                             on:on)
        }
    }

    // This is the entry point for our custom drawing code.
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        let bounds = self.bounds
        let segmentWidth = bounds.size.width / CGFloat(numberOfSSCs)
        let segmentHeight = bounds.size.height
        let xOrigin = bounds.origin.x
        let yOrigin = bounds.origin.y
        let cpuState = CPUState.sharedInstance
        let registerA = cpuState.registers[RegId.A.rawValue]
        let registerB = cpuState.registers[RegId.B.rawValue]
        let displayDecoder = DisplayDecoder.sharedInstance
        let displayableCharacters = displayDecoder.getDisplayableCharacters(registerA, registerB: registerB)
        // Loop to draw each of the 15 SSCs
        for i in 0..<numberOfSSCs {
            let sscRect = CGRectMake(xOrigin + CGFloat(i) * segmentWidth, yOrigin, segmentWidth, segmentHeight)
            let mask: UInt8 = masksByCharacter[displayableCharacters[i]]!.rawValue
            drawSSC(context, sscRect:sscRect, mask:mask)
        }
    }

}
