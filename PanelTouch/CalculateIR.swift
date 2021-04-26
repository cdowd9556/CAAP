//
//  CalculateIR.swift
//  PanelTouch
//
//  Created by CD on 3/15/21.
//  Copyright © 2021 Connor Dowd. All rights reserved.
//

import Foundation
import Accelerate

let irInstance = CalculateIR();

class CalculateIR {
    
    let fs:Float = 44100.0;
    let lic:Int = 1;
    let signalLength:Float = 5.0; //length of sine sweep in seconds
    let signalLengthN:Float = 220500; //length of sine sweep in samples
    let responseLength:Int = 5 * 44100; // number of samples in impulse response. Currently 4 seconds * samplerate
    
    var scale:Float = 1;
    var low:Float = 100;
    var high:Float = 15000;
    
    //var cleansweep: [Float] = [Float](repeating: 1, count: 1000)
    
    let stride = vDSP_Stride(1)
    
    //func calcIR(recorded: [Float], cleansweep: [Float]) -> [Float] {
    func calcIR( recorded: inout [Float], cleansweep: inout [Float]) -> [Float] {
        //var cleansweep: [Float] = [Float](repeating: 1, count: 44100) //dummy arguments
        //var recorded: [Float] = [Float](repeating: 1, count: 44100) //dummy arguments
        
        vDSP.reverse(&cleansweep) //reverse the sweep
        
        //create time vector
        let t: [Float] = vDSP.ramp(withInitialValue: 0.0, increment: 1.0, count: Int(signalLengthN)) //time vector
        var mtresult: [Float] = [Float](repeating : 0.0, count : t.count)
        vDSP_mtrans(t, stride, &mtresult, stride, vDSP_Length(t.count), vDSP_Length(1)) //transpose and divide by Fs
        mtresult = vDSP.divide(mtresult, fs)
        
        //initialize argument for exponent operation
        let r: Float = log10(high/low)
        var kgen = r / signalLengthN * fs
        var kgenresult: [Float] = [Float](repeating : 0.0, count : mtresult.count)
        
        vDSP_vsmul(mtresult, stride, &kgen, &kgenresult, stride, vDSP_Length(kgenresult.count))
        
        // exp(t*R/signalLengthN*fs) is realized here, then multiply by scale
        var expresult: [Float] = [Float](repeating : 0.0, count : kgenresult.count)
        vForce.exp(kgenresult, result: &expresult)
        vDSP_vsmul(expresult, stride, &scale, &expresult, stride, vDSP_Length(kgenresult.count))
        
        //vector dot division by k
        let scaledinverse: [Float] = vDSP.divide(cleansweep, expresult)
        
        //zero pad to n+m-1 and perform linear convolution
        let resultSize = recorded.count + scaledinverse.count - 1
        var result = [Float](repeating : 0.0, count : resultSize)
        let kEnd = UnsafePointer<Float>(scaledinverse).advanced(by: scaledinverse.count - 1)
        let xPad: [Float] = [Float](repeating: 0.0, count: scaledinverse.count-1)
        let xPadded = xPad + recorded + xPad
        vDSP_conv(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(scaledinverse.count))
        result.removeSubrange(ClosedRange(uncheckedBounds: (lower: Int((signalLength * fs) + Float(responseLength)), upper: result.count-1)))
        let finalTrim = Array(result.dropFirst(Int((signalLength - 0.15) * fs)))
        
        return finalTrim
        //zeropad .5 seconds evenly
//        let zpd: [Float] = [Float](repeating : 0.0, count : Int(0.5 * fs))
//        scaledinverse = zpd + scaledinverse
//        scaledinverse = scaledinverse + zpd
//
//        let la: Int = recorded.count
//        let lb: Int = scaledinverse.count
//        let zpd2: [Float] = [Float](repeating : 0.0, count : lb-1) // more zero padding
//        scaledinverse = scaledinverse + zpd2
//        let zpd3: [Float] = [Float](repeating : 0.0, count : la-1) // more zero padding
//        recorded = recorded + zpd3

        // initialize output vector
//        var output: [Float] = [Float](repeating : 0.0, count : (recorded.count + scaledinverse.count))
//        vDSP_conv(scaledinverse, stride, recorded, -stride, &output, stride, vDSP_Length(output.count-1), vDSP_Length(recorded.count))
        
        //remove zero padding
//        let delpad = Int(fs*(signalLength+0.5) + 1)
//        let delpad2 = Int(fs*(signalLength+0.5) + Float(responseLength))
//        output.removeSubrange(ClosedRange(uncheckedBounds: (lower: delpad2+1, upper: output.count-1)))
//        let result = Array(output.dropFirst(Int(delpad-1)))
        
    }
}
