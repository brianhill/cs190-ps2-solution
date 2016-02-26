//
//  KeyboardInput.swift
//  Simulated35
//
//  Created by Brian Hill github.com/brianhill on 2/15/16.
//

// The keyboard layout along with the octal key codes:
//
// x^y     log     ln    e^x     CLR
// 0o00    0o01    0o02  0o03    0o04
//
// x^1/2   arc     sin   cos     tan
// 0o10    0o11    0o12  0o13    0o14
//
// 1/x     x~y     Rv    STO     RCL
// 0o20    0o21    0o22  0o23    0o24
//
//    ENTER        CHS   EEX     CLx
//    0o30         0o31  0o32    0o33
//
//  -      7          8           9
// 0o40   0o41       0o42        0o43
//
//  +      4          5           6
// 0o50   0o51       0o52        0o53
//
//  *      1          2           3
// 0o60   0o61       0o62        0o63
//
//  /      0          .          PI
// 0o70   0o71       0o72        0o73
//
// The key codes must agree with the view tags set using Xcode and the storyboard.
// View tags are set in Xcode in the attributes inspector for each button.
// However, in Xcode, you don't enter view tag codes in octal, so you have to convert
// to decimal. E.g., you'd enter 57 for the view tag for key 0, not 0o71.

typealias KeyCode = UInt8

enum Key: KeyCode {
    case KeyPwr = 0o00; case KeyLog = 0o01; case KeyLn  = 0o02; case KeyExp = 0o03; case KeyCLR = 0o04
    case KeySqt = 0o10; case KeyArc = 0o11; case KeySin = 0o12; case KeyCos = 0o13; case KeyTan = 0o14
    case KeyInv = 0o20; case KeyExc = 0o21; case KeyRv  = 0o22; case KeySTO = 0o23; case KeyRCL = 0o24
    case KeyENT = 0o30; case KeyCHS = 0o31; case KeyEEX = 0o32; case KeyCLx = 0o33
    case KeySub = 0o40; case Key7   = 0o41; case Key8   = 0o42; case Key9   = 0o43
    case KeyAdd = 0o50; case Key4   = 0o51; case Key5   = 0o52; case Key6   = 0o53
    case KeyMul = 0o60; case Key1   = 0o61; case Key2   = 0o62; case Key3   = 0o63
    case KeyDiv = 0o70; case Key0   = 0o71; case KeyPnt = 0o72; case KeyPI  = 0o73
}
