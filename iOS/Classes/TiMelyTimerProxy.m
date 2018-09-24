/**
 * Time.ly Titanium Timer Project
 * Copyright (c) 2013 by Benjamin Bahrenburg. All Rights Reserved.
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 * 
 * Available at https://github.com/benbahrenburg/ti.mely
 *
 */

#import "TiMelyTimerProxy.h"
#import "TiUtils.h"


@implementation TiMelyTimerProxy

- (id)init
{
    if ((self = [super init]))
    {
        self->privateQueue = dispatch_queue_create("timely.private_queue", DISPATCH_QUEUE_CONCURRENT);
        isRunning = NO;
        providedInterval = 1000;
        counter = 0;
        isInDebug = NO;
        self->repeats = YES;
    }
    
    return self;
}

- (void)dealloc
{
    if(isRunning){
        [self->timer invalidate];
    }
    
    // [timer invalidate];
}

- (void)start:(id)args
{
    
	// Validate correct number of arguments
	ENSURE_SINGLE_ARG(args, NSDictionary);
    
    providedInterval = [TiUtils floatValue:@"interval" properties:args def:1000];
    
    isInDebug = [TiUtils boolValue:@"debug" properties:args def:NO];
    
    if(isRunning){
        [self stop:nil];
    }
    
    if(isInDebug){
        NSLog(@"[DEBUG] Starting Timer");
    }
    
    [self rememberSelf];
    
    self->timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[NSNumber numberWithFloat:(providedInterval/1000)] doubleValue]
                                                      target:self
                                                    selector:@selector(mainThreadTimerDidFire:)
                                                    userInfo:nil
                                                     repeats:self->repeats
                                               dispatchQueue:self->privateQueue];
    
    isRunning = YES;
}

- (void)stop:(id)unused
{
    if(isInDebug){
        NSLog(@"[DEBUG] Stopping Timer");
    }
    
    if(isRunning){
        [self->timer invalidate];
    }
    
    isRunning = NO;
    counter = 0;
    
    self->callback = nil;
    
    [self forgetSelf];
}


- (IBAction)fireTimer
{
    [self->timer fire];
}

- (void)sendTickFired
{

    if([self _hasListeners:@"onIntervalChange"]){
        
        counter++;
        
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
							   NUMFLOAT(providedInterval),@"interval",
                               [NSNumber numberWithLong:counter],@"intervalCount",
							   nil
							   ];
        [self fireEvent:@"onIntervalChange" withObject:event];
        
        if(isInDebug){
            NSLog(@"[DEBUG] onIntervalChange event fired");
        }
    }
    
}

// setInterval and setTimeout parity..

- (void)setTimeout:(id)args
{
    KrollCallback *cb = [args objectAtIndex:0];
    ENSURE_TYPE(cb, KrollCallback);
    self->callback = cb;
    if([args objectAtIndex:1] != nil){
        providedInterval = [TiUtils floatValue:[args objectAtIndex:1] def:1000];
    }
    if([args objectAtIndex:2] != nil){
        isInDebug = [TiUtils boolValue:[args objectAtIndex:2] def:NO];
    }
    // NSLog(@"[INFO] Starting setTimeout with interval: %f", providedInterval);
    
    self->repeats = NO;

    if(isRunning){
        [self stop:nil];
    }
    if(isInDebug){
        NSLog(@"[DEBUG] Starting setTimeout with interval %f", providedInterval);
    }

    [self rememberSelf];
    
    self->timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[NSNumber numberWithFloat:(providedInterval/1000)] doubleValue]
                                                      target:self
                                                    selector:@selector(mainThreadTimeoutDidFire:)
                                                    userInfo:nil
                                                     repeats:self->repeats
                                               dispatchQueue:self->privateQueue];
    
    isRunning = YES;
    
}

- (void)setInterval:(id)args
{
    KrollCallback *cb = [args objectAtIndex:0];
    ENSURE_TYPE(cb, KrollCallback);
    self->callback = cb;
    
    if([args objectAtIndex:1] != nil){
        providedInterval = [TiUtils floatValue:[args objectAtIndex:1] def:1000];
    }
    // NSLog(@"[INFO] Starting setInterval with interval: %f", providedInterval);

    self->repeats = YES;
    
    if([args objectAtIndex:2] != nil){
        isInDebug = [TiUtils boolValue:[args objectAtIndex:2] def:NO];
    }
    
    if(isRunning){
        [self stop:nil];
    }
    if(isInDebug){
        NSLog(@"[DEBUG] Starting setInterval with interval %f", providedInterval);
    }
    
    [self rememberSelf];
    
    self->timer = [MSWeakTimer scheduledTimerWithTimeInterval:[[NSNumber numberWithFloat:(providedInterval/1000)] doubleValue]
                                                      target:self
                                                    selector:@selector(mainThreadIntervalDidFire:)
                                                    userInfo:nil
                                                     repeats:self->repeats
                                               dispatchQueue:self->privateQueue];
    
    isRunning = YES;
    
}


- (void)clearTimeout:(id)args;
{
    if(isInDebug){
        NSLog(@"[DEBUG] clearTimeout");
    }
    
    [self stop:nil];
}

- (void)clearInterval:(id)args
{
    if(isInDebug){
        NSLog(@"[DEBUG] clearInterval");
    }

    [self stop:nil];
}


#pragma mark - MSWeakTimerDelegate

// Timer with added onIntervalChange listener
- (void)mainThreadTimerDidFire:(MSWeakTimer *)timer
{
    if(isInDebug){
        NSLog(@"[DEBUG] Timer fired on main thread");
    }
    
    [self sendTickFired];
}

// Timeout with callback.
- (void)mainThreadTimeoutDidFire:(MSWeakTimer *)timer
{
    if(isInDebug){
        NSLog(@"[DEBUG] setTimeout fired on main thread");
    }
    if(self->callback != nil){
        NSDictionary *cbArgs = @{
                                 @"interval": NUMFLOAT(providedInterval)
                                 };
        [self _fireEventToListener:@"timeout" withObject:cbArgs listener:self->callback thisObject:nil];

    }
    
    self->callback = nil;
    
}

// Interval with callback
- (void)mainThreadIntervalDidFire:(MSWeakTimer *)timer
{
    if(isInDebug){
        NSLog(@"[DEBUG] setInterval fired on main thread");
    }
    if(self->callback != nil){
        NSDictionary *cbArgs = @{
                                 @"interval": NUMFLOAT(providedInterval)
                                 };
        [self _fireEventToListener:@"interval" withObject:cbArgs listener:self->callback thisObject:nil];
    }
}


@end
