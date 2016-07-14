//
//  CandleStickChartRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


public class CandleStickChartRenderer: LineScatterCandleRadarChartRenderer
{
    public weak var dataProvider: CandleChartDataProvider?
    
    public init(dataProvider: CandleChartDataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler?)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context context: CGContext)
    {
        guard let dataProvider = dataProvider, candleData = dataProvider.candleData else { return }

        for set in candleData.dataSets as! [ICandleChartDataSet]
        {
            if set.isVisible && set.entryCount > 0
            {
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    private var _shadowPoints = [CGPoint](count: 4, repeatedValue: CGPoint())
    private var _rangePoints = [CGPoint](count: 2, repeatedValue: CGPoint())
    private var _openPoints = [CGPoint](count: 2, repeatedValue: CGPoint())
    private var _closePoints = [CGPoint](count: 2, repeatedValue: CGPoint())
    private var _bodyRect = CGRect()
    private var _lineSegments = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    public func drawDataSet(context context: CGContext, dataSet: ICandleChartDataSet)
    {
        guard let
            dataProvider = dataProvider,
            animator = animator
            else { return }
        
        let entryCount = dataSet.entryCount

        let trans = dataProvider.getTransformer(dataSet.axisDependency)
        
        let phaseX = max(0.0, min(1.0, animator.phaseX))
        let phaseY = animator.phaseY
        let barSpace = dataSet.barSpace
        let showCandleBar = dataSet.showCandleBar
        
        let lowX = dataProvider.lowestVisibleXIndex
        let highX = dataProvider.highestVisibleXIndex
        
        guard let
            entryFrom = dataSet.entryForXPos(lowX, rounding: .Down),
            entryTo = dataSet.entryForXPos(highX, rounding: .Up)
            else { return }
        
        let diff = (entryFrom == entryTo) ? 1 : 0
        let minx = max(dataSet.entryIndex(entry: entryFrom) - diff, 0)
        let maxx = min(max(minx + 2, dataSet.entryIndex(entry: entryTo) + 1), entryCount);
        
        CGContextSaveGState(context)
        
        CGContextSetLineWidth(context, dataSet.shadowWidth)
        
        for j in Int(minx).stride(to: Int(ceil(Double(maxx - minx) * phaseX + Double(minx))), by: 1)
        {
            // get the entry
            guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { continue }
            
            let xPos = e.x
            
            if xPos < Double(minx) || xPos >= Double(maxx)
            {
                continue
            }
            
            let open = e.open
            let close = e.close
            let high = e.high
            let low = e.low
            
            if (showCandleBar)
            {
                // calculate the shadow
                
                _shadowPoints[0].x = CGFloat(xPos)
                _shadowPoints[1].x = CGFloat(xPos)
                _shadowPoints[2].x = CGFloat(xPos)
                _shadowPoints[3].x = CGFloat(xPos)
                
                if (open > close)
                {
                    _shadowPoints[0].y = CGFloat(high * phaseY)
                    _shadowPoints[1].y = CGFloat(open * phaseY)
                    _shadowPoints[2].y = CGFloat(low * phaseY)
                    _shadowPoints[3].y = CGFloat(close * phaseY)
                }
                else if (open < close)
                {
                    _shadowPoints[0].y = CGFloat(high * phaseY)
                    _shadowPoints[1].y = CGFloat(close * phaseY)
                    _shadowPoints[2].y = CGFloat(low * phaseY)
                    _shadowPoints[3].y = CGFloat(open * phaseY)
                }
                else
                {
                    _shadowPoints[0].y = CGFloat(high * phaseY)
                    _shadowPoints[1].y = CGFloat(open * phaseY)
                    _shadowPoints[2].y = CGFloat(low * phaseY)
                    _shadowPoints[3].y = _shadowPoints[1].y
                }
                
                trans.pointValuesToPixel(&_shadowPoints)
                
                // draw the shadows
                
                var shadowColor: NSUIColor! = nil
                if (dataSet.shadowColorSameAsCandle)
                {
                    if (open > close)
                    {
                        shadowColor = dataSet.decreasingColor ?? dataSet.colorAt(j)
                    }
                    else if (open < close)
                    {
                        shadowColor = dataSet.increasingColor ?? dataSet.colorAt(j)
                    }
                    else
                    {
                        shadowColor = dataSet.neutralColor ?? dataSet.colorAt(j)
                    }
                }
                
                if (shadowColor === nil)
                {
                    shadowColor = dataSet.shadowColor ?? dataSet.colorAt(j);
                }
                
                CGContextSetStrokeColorWithColor(context, shadowColor.CGColor)
                CGContextStrokeLineSegments(context, _shadowPoints, 4)
                
                // calculate the body
                
                _bodyRect.origin.x = CGFloat(xPos) - 0.5 + barSpace
                _bodyRect.origin.y = CGFloat(close * phaseY)
                _bodyRect.size.width = (CGFloat(xPos) + 0.5 - barSpace) - _bodyRect.origin.x
                _bodyRect.size.height = CGFloat(open * phaseY) - _bodyRect.origin.y
                
                trans.rectValueToPixel(&_bodyRect)
                
                // draw body differently for increasing and decreasing entry
                
                if (open > close)
                {
                    let color = dataSet.decreasingColor ?? dataSet.colorAt(j)
                    
                    if (dataSet.isDecreasingFilled)
                    {
                        CGContextSetFillColorWithColor(context, color.CGColor)
                        CGContextFillRect(context, _bodyRect)
                    }
                    else
                    {
                        CGContextSetStrokeColorWithColor(context, color.CGColor)
                        CGContextStrokeRect(context, _bodyRect)
                    }
                }
                else if (open < close)
                {
                    let color = dataSet.increasingColor ?? dataSet.colorAt(j)
                    
                    if (dataSet.isIncreasingFilled)
                    {
                        CGContextSetFillColorWithColor(context, color.CGColor)
                        CGContextFillRect(context, _bodyRect)
                    }
                    else
                    {
                        CGContextSetStrokeColorWithColor(context, color.CGColor)
                        CGContextStrokeRect(context, _bodyRect)
                    }
                }
                else
                {
                    let color = dataSet.neutralColor ?? dataSet.colorAt(j)
                    
                    CGContextSetStrokeColorWithColor(context, color.CGColor)
                    CGContextStrokeRect(context, _bodyRect)
                }
            }
            else
            {
                _rangePoints[0].x = CGFloat(xPos)
                _rangePoints[0].y = CGFloat(high * phaseY)
                _rangePoints[1].x = CGFloat(xPos)
                _rangePoints[1].y = CGFloat(low * phaseY)

                _openPoints[0].x = CGFloat(xPos) - 0.5 + barSpace
                _openPoints[0].y = CGFloat(open * phaseY)
                _openPoints[1].x = CGFloat(xPos)
                _openPoints[1].y = CGFloat(open * phaseY)

                _closePoints[0].x = CGFloat(xPos) + 0.5 - barSpace
                _closePoints[0].y = CGFloat(close * phaseY)
                _closePoints[1].x = CGFloat(xPos)
                _closePoints[1].y = CGFloat(close * phaseY)
                
                trans.pointValuesToPixel(&_rangePoints)
                trans.pointValuesToPixel(&_openPoints)
                trans.pointValuesToPixel(&_closePoints)
                
                // draw the ranges
                var barColor: NSUIColor! = nil
                
                if (open > close)
                {
                    barColor = dataSet.decreasingColor ?? dataSet.colorAt(j)
                }
                else if (open < close)
                {
                    barColor = dataSet.increasingColor ?? dataSet.colorAt(j)
                }
                else
                {
                    barColor = dataSet.neutralColor ?? dataSet.colorAt(j)
                }
                
                CGContextSetStrokeColorWithColor(context, barColor.CGColor)
                CGContextStrokeLineSegments(context, _rangePoints, 2)
                CGContextStrokeLineSegments(context, _openPoints, 2)
                CGContextStrokeLineSegments(context, _closePoints, 2)
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    public override func drawValues(context context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            viewPortHandler = self.viewPortHandler,
            candleData = dataProvider.candleData,
            animator = animator
            else { return }
        
        // if values are drawn
        if (candleData.yValCount < Int(ceil(CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX)))
        {
            var dataSets = candleData.dataSets
            
            let phaseX = max(0.0, min(1.0, animator.phaseX))
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for i in 0 ..< dataSets.count
            {
                let dataSet = dataSets[i]
                
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let entryCount = dataSet.entryCount
                
                let minx = max(Int(floor(dataProvider.lowestVisibleXIndex)), 0)
                let maxx = min(Int(ceil(dataProvider.highestVisibleXIndex)), entryCount)
                
                let lineHeight = valueFont.lineHeight
                let yOffset: CGFloat = lineHeight + 5.0
                
                for j in minx.stride(to: Int(ceil(Double(maxx - minx) * phaseX + Double(minx))), by: 1)
                {
                    guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { break }
                    
                    pt.x = CGFloat(e.x)
                    pt.y = CGFloat(e.high * phaseY)
                    pt = CGPointApplyAffineTransform(pt, valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y))
                    {
                        continue
                    }
                    
                    ChartUtils.drawText(
                        context: context,
                        text: formatter.stringFromNumber(e.high)!,
                        point: CGPoint(
                            x: pt.x,
                            y: pt.y - yOffset),
                        align: .Center,
                        attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)])
                }
            }
        }
    }
    
    public override func drawExtras(context context: CGContext)
    {
    }
    
    public override func drawHighlighted(context context: CGContext, indices: [ChartHighlight])
    {
        guard let
            dataProvider = dataProvider,
            candleData = dataProvider.candleData,
            animator = animator
            else { return }
        
        CGContextSaveGState(context)
        
        for high in indices
        {
            let minDataSetIndex = high.dataSetIndex == -1 ? 0 : high.dataSetIndex
            let maxDataSetIndex = high.dataSetIndex == -1 ? candleData.dataSetCount : (high.dataSetIndex + 1)
            if maxDataSetIndex - minDataSetIndex < 1 { continue }
            
            for dataSetIndex in minDataSetIndex..<maxDataSetIndex
            {
                guard let set = candleData.getDataSetByIndex(dataSetIndex) as? ICandleChartDataSet else { continue }
                
                if (!set.isHighlightEnabled)
                {
                    continue
                }
                
                let xPos = high.x; // get the x-position
                
                guard let e = set.entryForXPos(xPos) as? CandleChartDataEntry else { continue }
                
                if e.x != xPos
                {
                    continue
                }
                
                let trans = dataProvider.getTransformer(set.axisDependency)
                
                CGContextSetStrokeColorWithColor(context, set.highlightColor.CGColor)
                CGContextSetLineWidth(context, set.highlightLineWidth)
                if (set.highlightLineDashLengths != nil)
                {
                    CGContextSetLineDash(context, set.highlightLineDashPhase, set.highlightLineDashLengths!, set.highlightLineDashLengths!.count)
                }
                else
                {
                    CGContextSetLineDash(context, 0.0, nil, 0)
                }
                
                let lowValue = e.low * Double(animator.phaseY)
                let highValue = e.high * Double(animator.phaseY)
                let y = (lowValue + highValue) / 2.0
                
                let pt = trans.pixelForValue(x: xPos, y: y)
                
                // draw the lines
                drawHighlightLines(context: context, point: pt, set: set)
            }
        }
        
        CGContextRestoreGState(context)
    }
}