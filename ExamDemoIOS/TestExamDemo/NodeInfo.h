//
//  NodeInfo.h
//  TestExamDemo
//
//  Created by wenjianfen on 2018/6/20.
//  Copyright © 2018年 cmcc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TaskInfo;

@interface NodeInfo : NSObject
@property (nonatomic, assign) int nodeId;
@property (nonatomic, assign) int taskCount;//总任务数
@property (nonatomic, assign) int totalConsumption;//总消耗量
@property (nonatomic, assign) int status;// 0:空闲 1:有任务
@property (nonatomic, strong) NSMutableArray *tasks;

/*
 return 0:失败 1:成功 2:任务已经存在
 */
- (int)addTask:(int)taskId;//添加任务
/*
 return 0:失败 1:成功 2:任务不存在
 */
- (int)removeTask:(int)taskId;//删除任务

- (TaskInfo *)taskInfoWithId:(int)taskId;//查询编号为taskId的任务

@end
