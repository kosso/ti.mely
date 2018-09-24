//
//  MSWeakTimer.m
//  MindSnacks (https://github.com/mindsnacks/MSWeakTimer)
//
//  Created by Javier Soto (https://github.com/mindsnacks) on 1/23/13.
//

#import "MSWeakTimer.h"

#import <libkern/OSAtomic.h>

#if !__has_feature(objc_arc)
    #error MSWeakTimer is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#if OS_OBJECT_USE_OBJC
    #define ms_gcd_property_qualifier strong
    #define ms_release_gcd_object(object)
#else
    #define ms_gcd_property_qualifier assign
    #define ms_release_gcd_object(object) dispatch_release(object)
#endif

@interface MSWeakTimer ()
{
    struct
    {
        uint32_t timerIsInvalidated;
    } _timerFlags;
}

@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL repeats;

@property (nonatomic, ms_gcd_property_qualifier) dispatch_queue_t privateSerialQueue;

@property (nonatomic, ms_gcd_property_qualifier) dispatch_source_t timer;

@end

@implementation MSWeakTimer

+ (MSWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                         target:(id)target
                                       selector:(SEL)selector
                                       userInfo:(id)userInfo
                                        repeats:(BOOL)repeats
                                  dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    NSParameterAssert(target);
    NSParameterAssert(selector);
    NSParameterAssert(dispatchQueue);

    MSWeakTimer *weakTimer = [[self alloc] init];

    weakTimer.timeInterval = timeInterval;
    weakTimer.target = target;
    weakTimer.selector = selector;
    weakTimer.userInfo = userInfo;
    weakTimer.repeats = repeats;

    NSString *privateQueueName = [NSString stringWithFormat:@"com.mindsnacks.msweaktimer.%p", weakTimer];
    weakTimer.privateSerialQueue = dispatch_queue_create([privateQueueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(weakTimer.privateSerialQueue, dispatchQueue);

    [weakTimer schedule];

    return weakTimer;
}

- (void)dealloc
{
    [self invalidate];

    ms_release_gcd_object(_privateSerialQueue);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> time_interval=%f target=%@ selector=%@ userInfo=%@ repeats=%d timer=%@",
            NSStringFromClass([self class]),
            self,
            self.timeInterval,
            self.target,
            NSStringFromSelector(self.selector),
            self.userInfo,
            self.repeats,
            self.timer];
}

#pragma mark -

- (void)schedule
{
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                        0,
                                        0, // TODO: maybe offer to set the leeway via the API?
                                        self.privateSerialQueue);

    int64_t intervalInNanoseconds = (int64_t)(self.timeInterval * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer,
                              dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds),
                              (uint64_t)intervalInNanoseconds,
                              0);

    __weak __typeof(&*self)weakSelf = self;
    //__typeof(self) __weak weakSelf = self;
    //__typeof(&*self) __weak weakSelf = self;
    //__weak typeof(self) weakSelf = self;

    dispatch_source_set_event_handler(self.timer, ^{
        [weakSelf timerFired];
    });

    dispatch_resume(self.timer);
}

- (void)fire
{
    [self timerFired];
}

- (void)invalidate
{
    // We check with an atomic operation if it has already been invalidated. Ideally we would synchronize this on the private queue,
    // but since we can't know the context from which this method will be called, dispatch_sync might cause a deadlock.
    if (!OSAtomicTestAndSetBarrier(7, &_timerFlags.timerIsInvalidated))
    {
        dispatch_source_t timer = self.timer;
        dispatch_async(self.privateSerialQueue, ^{
            dispatch_source_cancel(timer);
            ms_release_gcd_object(timer);
        });
    }
}

- (void)timerFired
{
    // Checking attomatically if the timer has already been invalidated.
    if (OSAtomicAnd32OrigBarrier(1, &_timerFlags.timerIsInvalidated))
    {
        return;
    }

    // We're not worried about this warning because the selector we're calling doesn't return a +1 object.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.selector withObject:self];
    #pragma clang diagnostic pop

    if (!self.repeats)
    {
        [self invalidate];
    }
}

@end
