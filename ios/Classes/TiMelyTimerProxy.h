/**
 * Time.ly Titanium Timer Project
 * Copyright (c) 2013 by Benjamin Bahrenburg. All Rights Reserved.
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 * Available at https://github.com/benbahrenburg/ti.mely
 *
 * Modified by Kosso. Added setTimeout and setInterval methods for parity with 'native' JS methods.
 */

#import "TiProxy.h"
#import "MSWeakTimer.h"
@interface TiMelyTimerProxy : TiProxy {
    @private
    MSWeakTimer *timer;
    BOOL isRunning;
    BOOL isInDebug;
    BOOL repeats;
    float providedInterval;
    long counter;
    dispatch_queue_t privateQueue;
    KrollCallback *callback;
}

//@property (strong, nonatomic) MSWeakTimer *timer;

- (void)setTimeout:(id)args;
- (void)setInterval:(id)args;
- (void)clearTimeout:(id)args;
- (void)clearInterval:(id)args;

@end
