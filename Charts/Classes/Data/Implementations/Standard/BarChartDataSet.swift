//
//  BarChartDataSet.swift
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


public class BarChartDataSet: BarLineScatterCandleBubbleChartDataSet, IBarChartDataSet
{
    private func initialize()
    {
        self.highlightColor = NSUIColor.blackColor()
        
        self.calcStackSize(values as! [BarChartDataEntry])
        self.calcEntryCountIncludingStacks(values as! [BarChartDataEntry])
    }
    
    public required init()
    {
        super.init()
        initialize()
    }
    
    public override init(values: [ChartDataEntry]?, label: String?)
    {
        super.init(values: values, label: label)
        initialize()
    }

    // MARK: - Data functions and accessors
    
    /// the maximum number of bars that are stacked upon each other, this value
    /// is calculated from the Entries that are added to the DataSet
    private var _stackSize = 1
    
    /// the overall entry count, including counting each stack-value individually
    private var _entryCountStacks = 0
    
    /// Calculates the total number of entries this DataSet represents, including
    /// stacks. All values belonging to a stack are calculated separately.
    private func calcEntryCountIncludingStacks(yVals: [BarChartDataEntry]!)
    {
        _entryCountStacks = 0
        
        for i in 0 ..< yVals.count
        {
            let vals = yVals[i].yValues
            
            if (vals == nil)
            {
                _entryCountStacks += 1
            }
            else
            {
                _entryCountStacks += vals!.count
            }
        }
    }
    
    /// calculates the maximum stacksize that occurs in the Entries array of this DataSet
    private func calcStackSize(yVals: [BarChartDataEntry]!)
    {
        for i in 0 ..< yVals.count
        {
            if let vals = yVals[i].yValues
            {
                if vals.count > _stackSize
                {
                    _stackSize = vals.count
                }
            }
        }
    }
    
    public override func calcMinMax()
    {
        if _values.count == 0
        {
            return
        }
    
        _yMin = DBL_MAX
        _yMax = -DBL_MAX
        
        _xMin = DBL_MAX
        _xMax = -DBL_MAX
        
        for e in _values as! [BarChartDataEntry]
        {
            if !e.y.isNaN
            {
                if e.yValues == nil
                {
                    if e.y < _yMin
                    {
                        _yMin = e.y
                    }
                    
                    if e.y > _yMax
                    {
                        _yMax = e.y
                    }
                }
                else
                {
                    if -e.negativeSum < _yMin
                    {
                        _yMin = -e.negativeSum
                    }
                    
                    if e.positiveSum > _yMax
                    {
                        _yMax = e.positiveSum
                    }
                }
                
                if e.x < _xMin
                {
                    _xMin = e.x
                }
                
                if e.x > _xMax
                {
                    _xMax = e.x
                }
            }
        }
        
        if (_yMin == DBL_MAX)
        {
            _yMin = 0.0
            _yMax = 0.0
        }
        
        if (_xMin == DBL_MAX)
        {
            _xMin = 0.0
            _xMax = 0.0
        }
    }
    
    /// - returns: the maximum number of bars that can be stacked upon another in this DataSet.
    public var stackSize: Int
    {
        return _stackSize
    }
    
    /// - returns: true if this DataSet is stacked (stacksize > 1) or not.
    public var isStacked: Bool
    {
        return _stackSize > 1 ? true : false
    }
    
    /// - returns: the overall entry count, including counting each stack-value individually
    public var entryCountStacks: Int
    {
        return _entryCountStacks
    }
    
    /// array of labels used to describe the different values of the stacked bars
    public var stackLabels: [String] = ["Stack"]
    
    // MARK: - Styling functions and accessors
    
    /// the color used for drawing the bar-shadows. The bar shadows is a surface behind the bar that indicates the maximum value
    public var barShadowColor = NSUIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1.0)

    /// the width used for drawing borders around the bars. If borderWidth == 0, no border will be drawn.
    public var barBorderWidth : CGFloat = 0.0

    /// the color drawing borders around the bars.
    public var barBorderColor = NSUIColor.blackColor()

    /// the alpha value (transparency) that is used for drawing the highlight indicator bar. min = 0.0 (fully transparent), max = 1.0 (fully opaque)
    public var highlightAlpha = CGFloat(120.0 / 255.0)
    
    // MARK: - NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! BarChartDataSet
        copy._stackSize = _stackSize
        copy._entryCountStacks = _entryCountStacks
        copy.stackLabels = stackLabels

        copy.barShadowColor = barShadowColor
        copy.highlightAlpha = highlightAlpha
        return copy
    }
}