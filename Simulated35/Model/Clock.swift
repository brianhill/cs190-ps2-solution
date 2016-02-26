//
//  Clock.swift
//  Simulated35
//
//  Created by Brian Hill github.com/brianhill on 2/7/16.
//

import Foundation

// The conventions were taken from:
//  * http://www.nand2tetris.org/lectures/PDF/ (Slide 4 of "lecture 03 sequential logic.pdf")
//  * https://www.cs.umd.edu/class/sum2003/cmsc311/Notes/ ("What's a Clock?" and "Introduction to Flip Flops: D and T")


enum ClockTransition {
    case LowToHigh
    case HighToLow
}

enum ClockPhase {
    case High // the phase after a low-to-high transition -- usually known as the Tock phase
    case Low // the phase after a high-to-low transition -- usually known as the Tick phase
    case Unstable // during the transition
}

protocol Clocked {
    func transition(transition: ClockTransition)
}

protocol Driven {
    func drive()
}

class Clock: Driven {
    
    static let sharedInstance = Clock()
    
    var phase = ClockPhase.Low // clock starts out low
    var clockedElements: [Clocked] = []
    
    func addClocked(clocked: Clocked) {
        clockedElements.append(clocked)
    }
    
    func transitionAll(transition: ClockTransition) {
        for clockedElement in clockedElements {
            clockedElement.transition(transition)
        }
    }
    
    func drive() {
        switch self.phase {
        case ClockPhase.High:
            // transition high-to-low
            self.phase = ClockPhase.Unstable
            self.transitionAll(ClockTransition.HighToLow)
            self.phase = ClockPhase.Low
        case ClockPhase.Low:
            // transition low-to-high
            self.phase = ClockPhase.Unstable
            self.transitionAll(ClockTransition.LowToHigh)
            self.phase = ClockPhase.High
        case ClockPhase.Unstable:
            break
        }
    }
    
}
