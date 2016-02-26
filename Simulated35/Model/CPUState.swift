//
//  CPUState.swift
//  Simulated35
//
//  Created by Brian Hill github.com/brianhill on 2/12/16.
//

// CPUState defines the various CPU registers we need to simulate an HP-35.
//
// This reference is the most thorough, but at the moment a bunch of the image links are broken:
//
// http://home.citycable.ch/pierrefleur/Jacques-Laporte/A&R.htm
//
// This reference is sufficient:
//
// http://www.hpmuseum.org/techcpu.htm

import Foundation

typealias Nibble = UInt8 // This should be UInt4, but the smallest width unsigned integer Swift has is UInt8.

typealias Pointer = UInt8 // Also should be UInt4. In any case, we are not currently using this or Status.

typealias Status = UInt16 // Should be a UInt12 if we wanted exactly as many status bits as the HP-35.

// This is how many nibbles there are in a register:
let RegisterLength = 14

// This is how many of the nibbles are devoted to the exponent:
let ExponentLength = 3

// Two utilities for testing and display:
func nibbleFromCharacter(char: Character) -> Nibble {
    let nibble = Nibble(Int(String(char))!)
    return nibble
}

func hexCharacterFromNibble(nibble: Nibble) -> Character {
    return Character(String(format:"%1X", nibble))
}

// A register is 14 nibbles (56 bits). Mostly nibbles are used to represent the digits 0-9, but the leftmost one, nibble 13, corresponds to the sign of the mantissa, nibbles 12 to 3 inclusive represent 10 digits of mantissa, and nibbles 2 to 0 represent the exponent.
struct Register {
    var nibbles: [Nibble] = [Nibble](count:RegisterLength, repeatedValue: UInt8(0))
    
    // Hmmm. It seems I need the empty initializer because I created init(fromDecimalString:).
    init() {}
    
    // Initialize a register from a fourteen-digit decimal string (e.g., "91250000000902")
    init(fromDecimalString: String) {
        let characters = Array(fromDecimalString.characters)
        assert(RegisterLength == characters.count)
        var characterIdx = 0
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let char: Character = characters[characterIdx]
            let nibble = nibbleFromCharacter(char)
            nibbles[nibbleIdx] = nibble
            characterIdx += 1
            nibbleIdx -= 1
        }
    }
    
    func asDecimalString() -> String {
        var digits: String = ""
        var nibbleIdx = RegisterLength - 1
        while nibbleIdx >= 0 {
            let nibble = nibbles[nibbleIdx]
            let hexChar = hexCharacterFromNibble(nibble)
            digits.append(hexChar)
            nibbleIdx -= 1
        }
        return digits 
    }
    
    mutating func setNibble(index: Int, value: Nibble) {
        nibbles[index] = value
    }
}

class CPUState {
    
    // The singleton starts in the traditional state that an HP-35 is in when you power it on.
    // The display just shows 0 and a decimal point.
    static let sharedInstance = CPUState(decimalStringA: "00000000000000", decimalStringB: "02999999999999")
    
    var registers = [Register](count:7, repeatedValue:Register())
    
    // All the important initialization is done above when registers is assigned.
    init() {}
    
    // A method provided prinicipally for testing. Allows the state of the registers that record user input to be
    // initialized from decimal strings. Register C will be canonicalized from registers A and B. The remaining
    // registers will be initialized to zeros.
    init(decimalStringA: String, decimalStringB: String) {
        let registerA = Register(fromDecimalString: decimalStringA)
        let registerB = Register(fromDecimalString: decimalStringB)
        
        registers[RegId.A.rawValue] = registerA
        registers[RegId.B.rawValue] = registerB
        
        canonicalize()
    }
    
    // Computes and stores into register C whatever is currently showing to the user in A and B. Note that it
    // is possible for canonicalization to fail. For example 123.4567890 99 overflows when canonicalized. When it
    // fails due to overflow (or underflow), registers A and B are overwritten with overflow (or underflow) values.
    //
    // This solution works but isn't great style, because such a large function is easy to introduce bugs into. 
    // However, I wanted the entire solution to be in one place. Also, it is very procedural. That style was 
    // trying to be a bit like the way the actual HP-35 code steps through the nibbles.
    //
    // Read the comments and the references mentioned at the top of DisplayDecoder.swift if you want to understand
    // more about why and how the registers of A and B are being used to construct the contents of register C.
    func canonicalize() {
        let nibblesA = registers[RegId.A.rawValue].nibbles // Register A's nibbles determine almost everything.
        let nibblesB = registers[RegId.B.rawValue].nibbles // Register B's nibbles just determine the decimal.
        
        var registerC = Register() // A fresh, empty register.
        
        var idxA = RegisterLength - 1
        var idxB = RegisterLength - 1
        var idxC = RegisterLength - 1
        let positive = nibblesA[idxA] != RegisterASpecialValues.Minus.rawValue
        registerC.setNibble(idxC, value: positive ? UInt8(0) : RegisterASpecialValues.Minus.rawValue)
        idxA -= 1
        idxC -= 1
        
        // The following var will stay false until we find the decimal point.
        var foundDecimal = false
        // The following var will stay false until we find a non-zero digit.
        var foundDigit = false
        // In the canonical representation, the decimal point comes after 1 mantissa digit.
        // The user does not have to adhere to this convention and can do a variety of things.
        var digitsBeforeDecimal = 0
        
        while idxA >= ExponentLength  {
            let nibbleA = nibblesA[idxA]
            foundDigit = foundDigit || nibbleA != Nibble(0)
            idxA -= 1
            foundDecimal = foundDecimal || nibblesB[idxB] == RegisterBSpecialValues.Point.rawValue
            idxB -= 1
            // Copy over mantissa digits only once we have found a leading digit.
            if foundDigit {
                registerC.setNibble(idxC, value: nibbleA)
                idxC -= 1
            }
            digitsBeforeDecimal += Int(foundDigit && !foundDecimal) - Int(foundDecimal && !foundDigit)
        }
        
        // Done with mantissa. Move on to exponent. Exponent is tricky because--as was noted in DisplayDecoder.swift--
        // it is coded in tens complement notation. So 985 means -15. We have to do something quite different
        // depending on whether we encounter a 9 as its first nibble.
        
        // Ok, so per the previous comment, we check the exponent's first nibble to get its sign:
        let exponentIsNegative = nibblesA[idxA] == RegisterASpecialValues.Minus.rawValue
        idxA -= 1
        
        // Now accumulate the exponent.
        var exponent = 0
        while idxA >= 0 {
            let digit = Int(nibblesA[idxA])
            let shifted = 10 * exponent
            exponent = shifted + digit
            idxA -= 1
        }
        if exponentIsNegative { exponent *= -1 }
        
        // Apply the exponent adjustment.
        var adjustedExponent = exponent + digitsBeforeDecimal - 1
        
        // Early returns in case of overflow or underflow
        if adjustedExponent > 99 {
            overflow(positive)
            return
        } else if adjustedExponent < -99 {
            underflow()
            return
        }
        
        // Finally write out the adjusted exponent nibbles.
        let adjustedExponentIsNegative = adjustedExponent < 0
        
        // We have to put the exponent into 10's complement if it's negative:
        if adjustedExponentIsNegative {
            adjustedExponent += 1
            adjustedExponent *= -1
        }
        
        for idxC = 0; idxC < ExponentLength; idxC += 1 {
            let digit = UInt8(adjustedExponent % 10)
            registerC.setNibble(idxC, value: adjustedExponentIsNegative ? 9 - digit : digit)
            adjustedExponent -= Int(digit)
            adjustedExponent = adjustedExponent / 10
        }
        
        registers[RegId.C.rawValue] = registerC
    }
    
    // Displays positive or negative overflow value
    func overflow(positive: Bool) {
        registers[RegId.A.rawValue] = Register(fromDecimalString: positive ? "09999999999099" : "99999999999099")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02000000000000")
        canonicalize()
    }
    
    // Displays underflow value
    func underflow() {
        registers[RegId.A.rawValue] = Register(fromDecimalString: "00000000000000")
        registers[RegId.B.rawValue] = Register(fromDecimalString: "02999999999999")
        canonicalize()
    }
    
    func decimalStringForRegister(regId: RegId) -> String {
        let register = registers[regId.rawValue]
        return register.asDecimalString()
    }
    
}

enum RegId: Int {
    case A = 0 // General Purpose (math or scratchpad)
    case B = 1 // General Purpose (math or scratchpad)
    case C = 2 // X Register
    case D = 3 // Y Register
    case E = 4 // Z Register
    case F = 5 // T (top or trigonemtric) Register
    case M = 6 // Scratchpad (like A and B, but no math)
}
