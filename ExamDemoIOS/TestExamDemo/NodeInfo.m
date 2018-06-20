//
//  NodeInfo.m
//  TestExamDemo
//
//  Created by wenjianfen on 2018/6/20.
//  Copyright © 2018年 cmcc. All rights reserved.
//

#import "NodeInfo.h"
#import "TaskInfo.h"

@implementation NodeInfo

- (id)init{
    self = [super init];
    if (self) {
        _status = 0;
        _totalConsumption = 0;
        _taskCount = 0;
        _tasks = [NSMutableArray array];
    }
    return self;
}

- (int)addTask:(int)taskId{
    if (taskId <= 0) {
        return 0;
    }
    TaskInfo *task = [self taskInfoForKey:taskId];
    if (task.taskId > 0) {
        return 2;
    }
    TaskInfo *newTask = [TaskInfo new];
    newTask.taskId = taskId;
    newTask.nodeId = self.nodeId;
    @synchronized(_tasks){
        [_tasks addObject:newTask];
    }
    return 1;
}

- (int)removeTask:(int)taskId{
    if (taskId <= 0) {
        return 0;
    }
    TaskInfo *task = [self taskInfoForKey:taskId];
    if (!task) {
        return 2;
    }
    @synchronized(_tasks){
        [_tasks removeObject:task];
    }
    return 1;
}

- (TaskInfo *)taskInfoWithId:(int)taskId{
    if (taskId <= 0) {
        return nil;
    }
    return [self taskInfoForKey:taskId];
}

- (int)taskCount{
    return (int)_tasks.count;
}

- (int)totalConsumption{
    if (_tasks.count == 0) {
        return 0;
    }
    int total = 0;
    for (TaskInfo *task in _tasks) {
        total += task.consumption;
    }
    return total;
}

- (int)status{
    return self.taskCount>0 ? 1:0;
}

#pragma mark - private
- (TaskInfo *)taskInfoForKey:(int)taskId{
    if (taskId <= 0 || _tasks.count == 0) {
        return nil;
    }
    for (TaskInfo *task in _tasks) {
        if (task.taskId == taskId && task.nodeId == self.nodeId) {
            return task;
        }
    }
    return nil;
}

@end
